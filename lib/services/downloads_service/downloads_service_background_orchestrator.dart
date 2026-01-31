import 'dart:async';
import 'dart:collection';
import 'dart:io';

// The actual FileDownloaderClass should not be used from this file
import 'package:background_downloader/background_downloader.dart' as downloader;
import 'package:collection/collection.dart';
import 'package:finamp/services/downloads_service/downloads_service_backend.dart';
import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path_helper;

import '../../models/finamp_models.dart';
import '../../models/jellyfin_models.dart';
import '../jellyfin_api_helper.dart';
import 'downloads_service_isolate.dart';
import 'downloads_service_utils.dart';

class DownloadsBackgroundSettings {
  int downloadWorkers = 5;
  bool isOffline = false;
  bool preferQuickSyncs = true;
  bool trackOfflineFavorites = true;
  Map<String, DownloadLocation> downloadLocationsMap = {};
  DownloadLocation get internalTrackDir => downloadLocationsMap.values.firstWhere(
    (element) => element.baseDirectory == DownloadLocationType.platformDefaultDirectory,
  );
}

class DownloadsServiceBackgroundOrchestrator implements DownloadOrchestrator {
  late final SyncUtils utils = SyncUtils(this);
  final _isar = GetIt.instance<Isar>();
  final _downloadsLogger = Logger("downloadsBackgroundService");

  // TODO real initialization
  final DownloadsBackgroundSettings settings = DownloadsBackgroundSettings();
  late final DownloadsSyncService syncBuffer = DownloadsSyncService(this);
  late final DownloadsDeleteService deleteBuffer = DownloadsDeleteService(this);
  late final _channel = DownloadsMethodChannel();

  // Private flags/counters used to calculate public sync/download flags
  bool _fileSystemFull = false;
  int _consecutiveConnectionErrors = 0;
  bool _connectionMessageShown = false;
  bool _userDeleteRunning = false;

  //
  // Flags for controlling sync/downloads
  //

  /// Run sync at full speed in response to a user request as opposed to running
  /// at ~1/3 speed when autosyncing/autoresuming at startup.
  bool fullSpeedSync = false;

  /// Sync every item completely to ensure everything is completly up-to-date.  Otherwise,
  /// albums/tracks/images with a state of complete will be assumed to remain unchanged
  /// and the sync will skip them, assuming prefer quick sync setting is true.
  bool forceFullSync = false;

  /// Causes the downloads queue to stop processing new items
  bool get allowDownloads => allowSyncs && !syncBuffer.isRunning;

  /// Causes the sync queue to stop processing new items
  bool get allowSyncs => !_fileSystemFull && _consecutiveConnectionErrors < 10 && !_userDeleteRunning;

  /// Attempts to clean up any possible issues with downloads by removing stuck downloads,
  /// deleting node links that violate the node hierarchy, running [_syncDelete] on every node
  /// to clear out any orphans, and deleting any file in the internal download locations with
  /// no completed metadata node pointing to it.  See additional comment on the node hierarchy.
  Future<void> repairAllDownloads() async {
    // Step 1 - Remove invalid links and restore node hierarchy.
    _downloadsLogger.info("Starting downloads repair step 1");
    await _channel.callMethod(DownloadsMethods.setRepairProgress, 1);
    // The node hierarchy is a limitation on what types of nodes can link to what
    // sorts of children.  It enforces a dependency graph with no loops which will
    // be completely deleted if the anchor is removed.  The type hierarchy is anchor->
    // non-album/playlist collection->album/playlist->track->image.  Items can only
    // require types lower in the hierarchy, not ones higher or equal to themselves.
    // Only required items can require other items to maintain this hierarchy.  The exception
    // to this is that anyone can require an image, but images cannot link anyone.
    // Info links have a separate type hierarchy which goes anchor-> album/playlist ->
    // non-album/playlist collection->track->image.  This is only enforced for non-required
    // items, required items can info link any type of node.  This does allow for info
    // loops, but they will always be cleaned as as the participating required member
    // The require and info hierarchies are enforced here.  The global syncDelete
    // in repair step 5 will enforce the restriction that you must be required to require
    // other nodes.
    _isar.writeTxnSync(() {
      List<
        (
          DownloadItemType,
          QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition> Function(
            QueryBuilder<DownloadItem, DownloadItem, QFilterCondition>,
          )?,
        )
      >
      requireFilters = [
        (DownloadItemType.anchor, null),
        (DownloadItemType.finampCollection, null),
        (
          DownloadItemType.collection,
          (q) => q.allOf([
            BaseItemDtoType.album,
            BaseItemDtoType.playlist,
          ], (q, element) => q.not().baseItemTypeEqualTo(element)),
        ),
        (
          DownloadItemType.collection,
          (q) => q.anyOf([
            BaseItemDtoType.album,
            BaseItemDtoType.playlist,
          ], (q, element) => q.baseItemTypeEqualTo(element)),
        ),
        (DownloadItemType.track, null),
        (DownloadItemType.image, null),
      ];
      // Objects matching a require filter cannot require elements matching earlier filters or the current filter.
      // This enforces a strict object hierarchy with no possibility of loops.
      for (int i = 0; i < requireFilters.length; i++) {
        var items = _isar.downloadItems
            .where()
            .typeEqualTo(requireFilters[i].$1)
            .filter()
            .optional(requireFilters[i].$2 != null, (q) => requireFilters[i].$2!(q))
            .requires(
              (q) => q.anyOf(
                requireFilters.slice(0, i + 1),
                (q, element) => q.typeEqualTo(element.$1).optional(element.$2 != null, (q) => element.$2!(q)),
              ),
            )
            .findAllSync();
        for (var item in items) {
          _downloadsLogger.severe("Unlinking invalid requires on node ${item.name}.");
          _downloadsLogger.severe("Current children: ${item.requires.filter().findAllSync()}.");
          item.requires.resetSync();
        }
      }

      List<
        (
          DownloadItemType,
          QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition> Function(
            QueryBuilder<DownloadItem, DownloadItem, QFilterCondition>,
          )?,
        )
      >
      infoFilters = [
        (DownloadItemType.anchor, null),
        (DownloadItemType.finampCollection, null),
        (
          DownloadItemType.collection,
          (q) => q.anyOf([
            BaseItemDtoType.album,
            BaseItemDtoType.playlist,
          ], (q, element) => q.baseItemTypeEqualTo(element)),
        ),
        (
          DownloadItemType.collection,
          (q) => q.allOf([
            BaseItemDtoType.album,
            BaseItemDtoType.playlist,
          ], (q, element) => q.not().baseItemTypeEqualTo(element)),
        ),
        (DownloadItemType.track, null),
        (DownloadItemType.image, null),
      ];

      // Objects matching an info filter cannot require elements matching earlier filters or the current filter.
      // This only applies to info-only items - required items can have any info links they want
      for (int i = 0; i < infoFilters.length; i++) {
        var items = _isar.downloadItems
            .where()
            .typeEqualTo(infoFilters[i].$1)
            .filter()
            .requiredByIsEmpty()
            .optional(infoFilters[i].$2 != null, (q) => infoFilters[i].$2!(q))
            .info(
              (q) => q.anyOf(
                infoFilters.slice(0, i + 1),
                (q, element) => q.typeEqualTo(element.$1).optional(element.$2 != null, (q) => element.$2!(q)),
              ),
            )
            .findAllSync();
        for (var item in items) {
          _downloadsLogger.severe("Unlinking invalid requires on node ${item.name}.");
          _downloadsLogger.severe("Current children: ${item.requires.filter().findAllSync()}.");
          item.requires.resetSync();
        }
      }
    });
    // Allow other tasks to run between these steps, which are both synchronous
    await Future.delayed(const Duration(milliseconds: 100));

    // Step 2 - Get all items into correct state matching filesystem and downloader.
    _downloadsLogger.info("Starting downloads repair step 2");
    await _channel.callMethod(DownloadsMethods.setRepairProgress, 2);
    var itemsWithFiles = _isar.downloadItems
        .where()
        .typeEqualTo(DownloadItemType.track)
        .or()
        .typeEqualTo(DownloadItemType.image)
        .findAllSync();
    for (var item in itemsWithFiles) {
      switch (item.state) {
        case DownloadItemState.complete:
          utils.verifyDownload(item);
        case DownloadItemState.notDownloaded:
          break;
        case DownloadItemState.enqueued: // fall through
        case DownloadItemState.downloading:
        case DownloadItemState.failed:
        case DownloadItemState.syncFailed:
        case DownloadItemState.needsRedownload:
        case DownloadItemState.needsRedownloadComplete:
          await deleteBuffer.deleteDownload(item);
      }
    }
    // Clean up missing download locations.  Download location delete verification should theoretically prevent
    // this from being needed outside dev builds.
    _isar.writeTxnSync(() {
      var userDownloadedItems = _isar.downloadItems.filter().userTranscodingProfileIsNotNull().findAllSync();
      for (var item in userDownloadedItems) {
        var locationId = item.userTranscodingProfile!.downloadLocationId;
        if (!settings.downloadLocationsMap.containsKey(locationId)) {
          _downloadsLogger.severe(
            "Could not find download location $locationId for ${item.name}, resetting to internal directory",
          );
          item.userTranscodingProfile = DownloadProfile(
            downloadLocationId: settings.internalTrackDir.id,
            transcodeCodec: item.userTranscodingProfile!.codec,
            bitrate: item.userTranscodingProfile!.stereoBitrate,
          );
          _isar.downloadItems.putSync(item, saveLinks: false);
        }
      }
    });

    _isar.writeTxnSync(() {
      var itemsWithChildren = _isar.downloadItems
          .where()
          .typeEqualTo(DownloadItemType.collection)
          .or()
          .typeEqualTo(DownloadItemType.finampCollection)
          .findAllSync();
      for (var item in itemsWithChildren) {
        utils.syncItemState(item);
        utils.syncItemDownloadSettings(item, syncImages: true);
      }
    });
    _isar.writeTxnSync(() {
      var itemsWithFiles = _isar.downloadItems
          .where()
          .typeEqualTo(DownloadItemType.track)
          .or()
          .typeEqualTo(DownloadItemType.image)
          .findAllSync();
      for (var item in itemsWithFiles) {
        utils.syncItemDownloadSettings(item, syncImages: true);
      }
    });
    markOutdatedTranscodes();

    // Step 3 - Resync all nodes from anchor to connect up all needed nodes
    _downloadsLogger.info("Starting downloads repair step 3");
    await _channel.callMethod(DownloadsMethods.setRepairProgress, 3);
    await resyncAll(forceSync: true);

    // Step 4 - Fetch all missing lyrics
    _downloadsLogger.info("Starting downloads repair step 4");
    await _channel.callMethod(DownloadsMethods.setRepairProgress, 4);
    final Map<int, LyricDto?> idsWithLyrics = HashMap();
    var allItems = _isar.downloadItems
        .where()
        .stateNotEqualTo(DownloadItemState.notDownloaded)
        .filter()
        .typeEqualTo(DownloadItemType.track)
        .findAllSync();
    final JellyfinApiHelper jellyfinApiData = GetIt.instance<JellyfinApiHelper>();
    for (var item in allItems) {
      if (item.baseItem?.mediaStreams?.any((stream) => stream.type == "Lyric") ?? false) {
        idsWithLyrics[item.isarId] = null;
        LyricDto? lyrics;
        try {
          lyrics = await jellyfinApiData.getLyrics(itemId: BaseItemId(item.id));
          _downloadsLogger.finest("Fetched lyrics for ${item.name}");
          idsWithLyrics[item.isarId] = lyrics;
        } catch (e) {
          _downloadsLogger.warning("Failed to fetch lyrics for ${item.name}.");
        }
      }
    }
    _isar.writeTxnSync(() {
      for (var id in idsWithLyrics.keys.where((id) {
        final oldLyricsVersion = _isar.downloadedLyrics.getSync(id)?.lyricDto?.metadata?.version;
        // if the versions don't match (or it isn't set), apply the new lyrics to be safe
        return idsWithLyrics[id]?.metadata?.version == null || oldLyricsVersion != idsWithLyrics[id]?.metadata?.version;
      })) {
        var canonItem = _isar.downloadItems.getSync(id);
        if (canonItem != null && idsWithLyrics[id] != null) {
          final lyricsItem = DownloadedLyrics.fromItem(isarId: canonItem.isarId, item: idsWithLyrics[id]!);
          _isar.downloadedLyrics.putSync(lyricsItem, saveLinks: false);
          _downloadsLogger.finer("Updated lyrics for '${canonItem.name}'");
        }
      }
    });

    // Step 5 - Make sure there are no unanchored nodes in metadata.
    _downloadsLogger.info("Starting downloads repair step 5");
    await _channel.callMethod(DownloadsMethods.setRepairProgress, 5);
    var allIds = _isar.downloadItems.where().isarIdProperty().findAllSync();
    for (var id in allIds) {
      await deleteBuffer.syncDelete(id);
    }
    await _channel.callMethod(DownloadsMethods.executeSyncs, SyncOptions(deletesOnly: true, waitFowDownloads: false));

    // Step 6 - Make sure there are no orphan files in track directory.
    _downloadsLogger.info("Starting downloads repair step 6");
    await _channel.callMethod(DownloadsMethods.setRepairProgress, 6);
    // This cleans internalSupport/images
    var imageFilePaths = Directory(path_helper.join(settings.internalTrackDir.currentPath, "images"))
        .list()
        .handleError((e) => _downloadsLogger.info("Error while cleaning image directories: $e"))
        .where((event) => event is File)
        .map((event) => path_helper.canonicalize(event.path));
    var filePaths = await imageFilePaths.toSet();
    // This cleans FINAMP_BASE_DOWNLOAD_DIRECTORY in internalSupport
    // and internalDocuments
    for (var trackBasePath
        in settings.downloadLocationsMap.values
            .where((element) => !element.baseDirectory.needsPath)
            .map((e) => e.currentPath)) {
      var trackFilePaths = Directory(path_helper.join(trackBasePath, FINAMP_BASE_DOWNLOAD_DIRECTORY))
          .list()
          .handleError((e) => _downloadsLogger.info("Error while cleaning track directories: $e"))
          .where((event) => event is File)
          .map((event) => path_helper.canonicalize(event.path));
      filePaths.addAll(await trackFilePaths.toSet());
    }
    for (var item
        in _isar.downloadItems
            .where()
            .typeEqualTo(DownloadItemType.track)
            .or()
            .typeEqualTo(DownloadItemType.image)
            .filter()
            .stateEqualTo(DownloadItemState.complete)
            .findAllSync()) {
      if (item.file != null) {
        filePaths.remove(path_helper.canonicalize(item.file!.path));
      }
    }
    for (var filePath in filePaths) {
      _downloadsLogger.info("Deleting orphan file $filePath");
      try {
        await File(filePath).delete();
      } catch (e) {
        _downloadsLogger.info("Error while cleaning directories: $e");
      }
    }

    _downloadsLogger.info("Downloads repair complete.");
    await _channel.callMethod(DownloadsMethods.setRepairProgress, 0);
  }

  Future<void> resyncAll({bool forceSync = false}) async {
    resetConnectionErrors();
    // All sync actions from now until app closure are the direct result of user
    // input and should run at full speed, so we set the full speed sync flag by default

    // If asked to sync an album or track, force full sync to actually process it
    forceSync = forceSync || (anchor.type.requiresItem && !anchor.baseItemType.expectChanges);

    var requiredByCount = _isar.downloadItems.filter().requires((q) => q.isarIdEqualTo(anchor.isarId)).countSync();
    try {
      bool required = requiredByCount != 0;
      _downloadsLogger.info("Starting sync of ${anchor.name}.");
      _isar.writeTxnSync(() {
        utils.addSyncs(required ? [anchor.isarId] : [], required ? [] : [anchor.isarId], null);
      });
      await _channel.callMethod(
        DownloadsMethods.executeSyncs,
        SyncOptions(waitFowDownloads: false, useFullSpeed: true, forceFullSync: forceSync),
      );

      _downloadsLogger.info("Sync of ${anchor.name} complete.");
    } catch (error, stackTrace) {
      _downloadsLogger.severe("Isar failure $error", error, stackTrace);
      rethrow;
    }
  }

  void handleDownloadProgress(downloader.TaskStatusUpdate event) {
    // This handler is called every time background_downloader emits a status update.
    // It updates the DownloadItem in isar to the matching DownloadItemState.
    // Updates for items which are already complete/failed are assumed to be coming
    // in out of order and are ignored.  Failed items may be moved to enqueued instead
    // of failed depending on the exception.
    _isar.writeTxnSync(() {
      DownloadItem? listener = _isar.downloadItems.getSync(int.parse(event.task.taskId));
      if (listener != null) {
        var newState = DownloadItemState.fromTaskStatus(event.status);
        if (!listener.state.isFinal) {
          // Completed images have their extension updated if possible.  Tracks
          // should already have extensions when enqueued.  Extensions only serve
          // to help the user with viewing files stored in custom download locations, so
          // it does not matter if this update does not take place.
          if (event.status == downloader.TaskStatus.complete) {
            resetConnectionErrors();
            _downloadsLogger.fine("Downloaded ${listener.name}");
            String? extension;
            switch (event.mimeType) {
              case "image/jpeg":
                extension = ".jpg";
              case "image/bmp":
                extension = ".bmp";
              case "image/png":
                extension = ".png";
              case "image/gif":
                extension = ".gif";
              case "image/webp":
                extension = ".webp";
            }
            Future.sync(() async {
              assert(
                listener.file?.path == await event.task.filePath() ||
                    (extension != null &&
                        listener.file?.path.replaceFirst(RegExp(r'\.image$'), extension) ==
                            await event.task.filePath()),
                "${listener.name} ${listener.path} ${listener.fileDownloadLocation?.baseDirectory} ${listener.file?.path} ${await event.task.filePath()} $extension",
              );
            });
            if (extension != null && listener.file!.path.endsWith(".image")) {
              // Do not wait for file move to complete to prevent slowing isar write
              unawaited(
                File(listener.file!.path)
                    .rename(listener.file!.path.replaceFirst(RegExp(r'\.image$'), extension))
                    .then((_) => null, onError: (e) => sendErrorSnackbar(e)),
              );
              listener.path = listener.path!.replaceFirst(RegExp(r'\.image$'), extension);
            }
          }

          if (newState == DownloadItemState.failed) {
            if (event.exception is downloader.TaskFileSystemException ||
                (event.exception?.description.contains(RegExp(r'No space left on device')) ?? false)) {
              // Retry items that failed from a full filesystem once the user
              // cleans it up and restarts/resyncs
              newState = DownloadItemState.enqueued;
              if (!_fileSystemFull) {
                _fileSystemFull = true;
                // TODO send snackbar
                //GlobalSnackbar.message((scaffold) => AppLocalizations.of(scaffold)!.filesystemFull);
              }
            } else if (event.exception is downloader.TaskConnectionException) {
              // Retry items with connection errors
              newState = DownloadItemState.enqueued;
              incrementConnectionErrors(weight: 2);
            } else if (event.exception != null) {
              _downloadsLogger.warning("Exception ${event.exception} when downloading ${listener.name}");
            } else {
              _downloadsLogger.warning("Received failed download task ${event.toJson()}");
            }
          }

          // Canceled items are expected to have their status updated by the
          // canceling code.  Cancelled items not handled and left in downloading
          // will be moved back to enqueued on next app restart or sync.
          if (event.status != downloader.TaskStatus.canceled) {
            utils.updateItemState(listener, newState, alwaysPut: event.status == downloader.TaskStatus.complete);
          }
        } else {
          _downloadsLogger.info(
            "Received status event ${event.status} for finalized download ${listener.name}.  Ignoring.",
          );
        }
      } else {
        _downloadsLogger.severe("Could not determine item for id ${event.task.taskId}, event:${event.toString()}");
      }
    });
  }

  /// Should be called whenever a connection to the server succeeds.
  void resetConnectionErrors() {
    _consecutiveConnectionErrors = 0;
    _connectionMessageShown = false;
  }

  /// Should be called whenever a connection to the server fails.  If several
  /// connection attempts in a row fail, we assume we are offline and pause downloads.
  /// Displays a message to the user when pausing if we are not currently in
  /// the background.
  void incrementConnectionErrors({int weight = 1}) {
    _consecutiveConnectionErrors += weight;
    if (_consecutiveConnectionErrors >= 10 && !_connectionMessageShown) {
      _connectionMessageShown = true;
      _downloadsLogger.info("Pausing downloads due to connection issues.");
      _channel.callMethod(DownloadsMethods.showConnectionError, null);
    }
  }

  /// Find all downloaded tracks with outdated download location ID or transcoding profile
  /// and mark them for deletion, then resync to delete and redownload them.
  void markOutdatedTranscodes() {
    _isar.writeTxnSync(() {
      var items = _isar.downloadItems
          .where()
          .typeEqualTo(DownloadItemType.track)
          .or()
          .typeEqualTo(DownloadItemType.image)
          .filter()
          .not()
          .stateEqualTo(DownloadItemState.notDownloaded)
          .requiredByIsNotEmpty()
          .findAllSync();
      for (var item in items) {
        if (item.fileTranscodingProfile != item.syncTranscodingProfile) {
          if (item.state == DownloadItemState.complete) {
            utils.updateItemState(item, DownloadItemState.needsRedownloadComplete);
          } else {
            utils.updateItemState(item, DownloadItemState.needsRedownload);
          }
        }
      }
    });
  }

  Future<bool> verifyQueuedDownload(DownloadItem item) async {
    // TODO implement
    return true;
  }

  Future<void> removeQueuedDownload(DownloadItem item) async {
    // TODO implement
  }

  void sendErrorSnackbar(dynamic e) {
    // TODO implement this
  }

  @override
  // TODO: implement shouldRedownloadTranscodes
  bool get shouldRedownloadTranscodes => throw UnimplementedError();

  @override
  void updateDownloadStatuses({DownloadItemState? increment, DownloadItemState? decrement}) {
    // TODO: implement updateDownloadStatuses
  }

  @override
  Map<String, DownloadLocation> get getDownloadLocationsMap => settings.downloadLocationsMap;
}
