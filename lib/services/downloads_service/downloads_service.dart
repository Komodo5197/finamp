import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:finamp/components/global_snackbar.dart';
import 'package:finamp/l10n/app_localizations.dart';
import 'package:finamp/services/downloads_service/downloads_service_utils.dart';
import 'package:finamp/services/finamp_user_helper.dart';
import 'package:finamp/services/jellyfin_api_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:isar/isar.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path_helper;
import 'package:rxdart/rxdart.dart';

import '../../models/finamp_models.dart';
import '../../models/jellyfin_models.dart';
import '../finamp_settings_helper.dart';
import 'downloads_service_foreground.dart';
import 'downloads_service_isolate.dart';

const isarDatabaseName = "finamp_db.isar";
const repairStepTrackingName = "repairStep";

class DownloadsService implements DownloadOrchestrator {
  final _downloadsLogger = Logger("downloadsService");
  final _isar = GetIt.instance<Isar>();
  final _finampUserHelper = GetIt.instance<FinampUserHelper>();
  late final _channel = DownloadsMethodChannel.foreground(this);
  late final _utils = SyncUtils(this);
  late final _downloadTaskQueue = IsarTaskQueue(_utils);

  // These track total downloads for the overview on the downloads screen
  final Map<DownloadItemState, int> downloadStatuses = {};
  late final Stream<Map<DownloadItemState, int>> downloadStatusesStream;
  final StreamController<Map<DownloadItemState, int>> _downloadStatusesStreamController = StreamController.broadcast();

  // This triggers refresh of music/artist screens on item deletion
  late final Stream<void> offlineDeletesStream;
  final StreamController<void> _offlineDeletesStreamController = StreamController.broadcast();

  // These track node counts for the overview on the downloads screen
  final Map<String, int> downloadCounts = {repairStepTrackingName: 0};
  late final Stream<Map<String, int>> downloadCountsStream;
  final StreamController<Map<String, int>> _downloadCountsStreamController = StreamController.broadcast();

  //
  // Flags for controlling sync/downloads
  //

  /// Track app background time to trigger startup queue sync if app is in background
  /// for more than 5 hours, even if there is no full restart
  DateTime? _appPauseTime;

  /// Marks whether we have encountered an image with a missing blurhash
  bool serverMissingBlurhash = false;

  /// Flag used to skip showing connection errors that occur while app is in background
  bool _showConnectionMessage = true;

  @override
  bool get shouldRedownloadTranscodes => FinampSettingsHelper.finampSettings.shouldRedownloadTranscodes;

  //
  // Providers
  //

  late final _anchorProvider = StreamProvider((ref) => _isar.downloadItems.watchObjectLazy(anchor.isarId));

  /// Provider for the download state of an item.  This is whether the items associated
  /// files, or its children's file in the case of a collection, are missing, downloading
  /// or completely downloaded.  Useful for showing download status indicators
  /// on tracks and albums.
  final stateProvider = StreamProvider.family.autoDispose<DownloadItemState?, DownloadStub>((ref, stub) {
    assert(stub.type != DownloadItemType.image && stub.type != DownloadItemType.anchor);
    final isar = GetIt.instance<Isar>();
    return isar.downloadItems.watchObject(stub.isarId, fireImmediately: true).map((event) => event?.state).distinct();
  });

  /// Provider for the download status of an item.  See [getStatus] for details.
  /// This provider relies on the fact that [_syncDownload] always re-inserts
  /// processed items into Isar to know when to re-check status.
  late final statusProvider = Provider.family.autoDispose<DownloadItemStatus, (DownloadStub, int?)>((ref, record) {
    var (stub, childCount) = record;
    assert(stub.type != DownloadItemType.image && stub.type != DownloadItemType.anchor);
    // Refresh on addDownload/removeDownload as well as state change
    ref.watch(_anchorProvider);
    var sub = _isar.downloadItems.watchObjectLazy(stub.isarId).listen((_) {
      ref.state = getStatus(stub, childCount);
    });
    ref.onDispose(sub.cancel);
    return getStatus(stub, childCount);
  });

  /// Provider for the actual download item associated with a stub.  This is used
  /// inside the downloads screen.
  final itemProvider = StreamProvider.family.autoDispose<DownloadItem?, DownloadStub>((ref, stub) {
    assert(stub.type != DownloadItemType.image && stub.type != DownloadItemType.anchor);
    final isar = GetIt.instance<Isar>();
    return isar.downloadItems.watchObject(stub.isarId, fireImmediately: true);
  });

  /// Provider for user-downloaded items of a specific category.
  /// Used to show and group downloaded items on the downloads screen.
  late final userDownloadedItemsProvider = Provider.family.autoDispose<List<DownloadStub>, DownloadsScreenCategory>((
    ref,
    category,
  ) {
    // Refresh lists when addDownload or removeDownload is called.
    ref.watch(_anchorProvider);
    final allItems = _isar.downloadItems
        .filter()
        .requiredBy((q) => q.isarIdEqualTo(anchor.isarId))
        .sortByName()
        .findAllSync();

    return allItems
        .where(
          (item) => switch (category) {
            DownloadsScreenCategory.special =>
              item.type == category.type &&
                  item.finampCollection?.type != FinampCollectionType.collectionWithLibraryFilter,

            DownloadsScreenCategory.artists =>
              (item.type == category.type && item.baseItemType == category.baseItemType) ||
                  (item.finampCollection?.type == FinampCollectionType.collectionWithLibraryFilter &&
                      BaseItemDtoType.fromItem(item.finampCollection!.item!) == BaseItemDtoType.artist),

            DownloadsScreenCategory.genres =>
              (item.type == category.type && item.baseItemType == category.baseItemType) ||
                  (item.finampCollection?.type == FinampCollectionType.collectionWithLibraryFilter &&
                      BaseItemDtoType.fromItem(item.finampCollection!.item!) == BaseItemDtoType.genre),
            _ =>
              item.type == category.type &&
                  (category.baseItemType == null || item.baseItemType == category.baseItemType),
          },
        )
        .toList();
  });

  /// Constructs the service.  startQueues should also be called to complete initialization.
  Future<void> initialize() async {
    // Initialize downloadStatuses dict with actual counts of items in isar with
    // that state.  Calls to updateItemState will keep this up to date as the
    // state of an item is changed.
    for (var state in DownloadItemState.values) {
      downloadStatuses[state] = _isar.downloadItems
          .where()
          .optional(
            state != DownloadItemState.syncFailed,
            (q) => q.typeEqualTo(DownloadItemType.track).or().typeEqualTo(DownloadItemType.image),
          )
          .filter()
          .stateEqualTo(state)
          .countSync();
    }

    downloadStatusesStream = _downloadStatusesStreamController.stream.throttleTime(
      const Duration(milliseconds: 200),
      leading: false,
      trailing: true,
    );
    offlineDeletesStream = _offlineDeletesStreamController.stream;
    downloadCountsStream = _downloadCountsStreamController.stream;

    updateDownloadCounts();

    await _channel.openChannel();

    FileDownloader().addTaskQueue(_downloadTaskQueue);

    // This handler is called every time background_downloader emits a status update.
    // It updates the DownloadItem in isar to the matching DownloadItemState.
    // Updates for items which are already complete/failed are assumed to be coming
    // in out of order and are ignored.  Failed items may be moved to enqueued instead
    // of failed depending on the exception.
    FileDownloader().updates.listen((event) {
      if (event is TaskStatusUpdate) {
        _channel.callMethod(DownloadsMethods.processDownloadProgress, event);
      }
    });

    // Sometimes we temporarily lose connection while the screen is locked.
    // Try to restart downloads when the user begins interacting again
    AppLifecycleListener(
      onRestart: () {
        _downloadsLogger.info("App returning from background, restarting downloads.");
        // If app is in background for more than 5 hours, treat it like a restart
        // and potentially resync all items
        if (FinampSettingsHelper.finampSettings.resyncOnStartup &&
            _appPauseTime != null &&
            DateTime.now().difference(_appPauseTime!).inHours > 5) {
          _isar.writeTxnSync(() {
            _utils.addSyncs([anchor.isarId], <int>[], null);
          });
        }
        _appPauseTime = null;
        restartDownloads();
      },
      onHide: () {
        _showConnectionMessage = false;
      },
      onShow: () {
        _showConnectionMessage = true;
      },
      onPause: () {
        _downloadsLogger.info("App is being paused by OS.");
        _appPauseTime = DateTime.now();
      },
    );

    await FileDownloader().requireWiFi(
      FinampSettingsHelper.finampSettings.requireWifiForDownloads ? RequireWiFi.forAllTasks : RequireWiFi.forNoTasks,
    );

    bool oldOffline = FinampSettingsHelper.finampSettings.isOffline;
    bool oldRequireWifi = FinampSettingsHelper.finampSettings.requireWifiForDownloads;
    FinampSettingsHelper.finampSettingsListener.addListener(() {
      var newOffline = FinampSettingsHelper.finampSettings.isOffline;
      var newRequireWifi = FinampSettingsHelper.finampSettings.requireWifiForDownloads;
      if (oldOffline && !newOffline) {
        restartDownloads();
      }
      if (oldRequireWifi != newRequireWifi) {
        FileDownloader().requireWiFi(newRequireWifi ? RequireWiFi.forAllTasks : RequireWiFi.forNoTasks);
      }
      oldOffline = newOffline;
      oldRequireWifi = newRequireWifi;
    });
  }

  /// Shows a connection error message if app is not currently in background
  void showConnectionError() {
    if (_showConnectionMessage && !FinampSettingsHelper.finampSettings.isOffline) {
      GlobalSnackbar.message((scaffold) => AppLocalizations.of(scaffold)!.connectionInterrupted);
    } else if (!FinampSettingsHelper.finampSettings.isOffline) {
      if (Platform.isAndroid) {
        GlobalSnackbar.message((scaffold) => AppLocalizations.of(scaffold)!.connectionInterruptedBackgroundAndroid);
      } else {
        GlobalSnackbar.message((scaffold) => AppLocalizations.of(scaffold)!.connectionInterruptedBackground);
      }
    }
  }

  @override
  void updateDownloadStatuses({DownloadItemState? increment, DownloadItemState? decrement}) {
    if (increment != null) {
      downloadStatuses[increment] = downloadStatuses[increment]! + 1;
    }
    if (decrement != null) {
      downloadStatuses[decrement] = downloadStatuses[decrement]! - 1;
    }

    _downloadStatusesStreamController.add(downloadStatuses);
  }

  /// Begin processing stored downloads/deletes.  This should only be called
  /// after background_downloader is fully set up.
  Future<void> startQueues() async {
    if (FinampSettingsHelper.finampSettings.resyncOnStartup) {
      _isar.writeTxnSync(() {
        _utils.addSyncs([anchor.isarId], <int>[], null);
      });
    }

    await _downloadTaskQueue.initializeQueue();

    // Wait a few seconds to not slow initial library load
    _finampUserHelper.runUserHook(() async {
      await Future<void>.delayed(const Duration(seconds: 10));
      try {
        await _channel.callMethod(DownloadsMethods.executeSyncs, SyncOptions(waitFowDownloads: true));
      } catch (e) {
        _downloadsLogger.severe("Error $e while restarting download/delete queues on startup.");
      }
    });
  }

  /// Attempt to resume syncing/downloading.  Called when leaving offline mode,
  /// coming out of background, and switching to downloads screen
  void restartDownloads() {
    if (!FinampSettingsHelper.finampSettings.isOffline && _finampUserHelper.currentUser != null) {
      unawaited(
        Future.sync(() async {
          try {
            await _channel.callMethod(DownloadsMethods.resetConnectionErrors, false);
            _downloadsLogger.info("Attempting to restart queues.");
            await _channel.callMethod(DownloadsMethods.executeSyncs, SyncOptions(waitFowDownloads: true));
          } catch (e) {
            _downloadsLogger.severe("Error $e while restarting syncs/downloads while gaining focus");
          }
        }),
      );
    }
  }

  /// Update download counts with current values.  Repeatedly called
  /// while on downloads screen to update overview.
  void updateDownloadCounts() {
    _isar.txnSync(() {
      downloadCounts["track"] = _isar.downloadItems
          .where()
          .typeEqualTo(DownloadItemType.track)
          .filter()
          .not()
          .stateEqualTo(DownloadItemState.notDownloaded)
          .countSync();
      downloadCounts["image"] = _isar.downloadItems.where().typeEqualTo(DownloadItemType.image).countSync();
      downloadCounts["sync"] = _isar.isarTaskDatas
          .where()
          .typeEqualTo(IsarTaskDataType.syncNode)
          .or()
          .typeEqualTo(IsarTaskDataType.deleteNode)
          .countSync();
      _downloadCountsStreamController.add(downloadCounts);
    });
  }

  // TODO use download groups to send notification when item fully downloaded?
  /// Triggers a persistent and independent download of the given item by linking
  /// it to the anchor as required and then syncing.
  Future<void> addDownload({
    required DownloadStub stub,
    required DownloadProfile transcodeProfile,
    BaseItemId? viewId,
  }) async {
    // Comment https://github.com/jmshrv/finamp/issues/134#issuecomment-1563441355
    // suggests this does not make a request and always returns failure
    /*if (downloadLocation.needsPermission) {
      if (await Permission.accessMediaLocation.isGranted) {
        _downloadsLogger.severe("Storage permission is not granted, exiting");
        return Future.error(
            "Storage permission is required for external storage");
      }
    }*/
    _isar.writeTxnSync(() {
      DownloadItem canonItem = _isar.downloadItems.getSync(stub.isarId) ?? stub.asItem(transcodeProfile);
      canonItem.userTranscodingProfile = transcodeProfile;
      _isar.downloadItems.putSync(canonItem, saveLinks: false);
      var anchorItem = anchor.asItem(null);
      // This may be the first download ever, so the anchor might not be present
      _isar.downloadItems.putSync(anchorItem, saveLinks: false);
      anchorItem.requires.updateSync(link: [canonItem]);
      // Update download location id/transcode profile for all our children
      _utils.syncItemDownloadSettings(canonItem);
    });

    await resync(stub, viewId);
  }

  /// Removes the anchor link to an item and sync deletes it.  This will allow the
  /// item to be deleted but may not result in deletion actually occurring as the
  /// item may be required by other collections.
  Future<void> deleteDownload({required DownloadStub stub}) async {
    DownloadItem? canonItem;
    _isar.writeTxnSync(() {
      var anchorItem = anchor.asItem(null);
      canonItem = _isar.downloadItems.getSync(stub.isarId);
      if (canonItem == null) {
        _downloadsLogger.warning("User attempted to delete missing item ${stub.name}");
        return;
      }
      // This is required to trigger status recalculation
      _isar.downloadItems.putSync(anchorItem, saveLinks: false);
      _utils.addDeletes([stub.isarId]);
      // Actual item is not required for updating links
      anchorItem.requires.updateSync(unlink: [canonItem!]);
      canonItem!.userTranscodingProfile = null;
      _isar.downloadItems.putSync(canonItem!, saveLinks: false);
    });
    if (canonItem == null) {
      return;
    }
    try {
      // Pause syncing/downloading if the user initiates a delete
      await _channel.callMethod(
        DownloadsMethods.executeSyncs,
        SyncOptions(deletesOnly: true, isUserDelete: true, waitFowDownloads: false, useFullSpeed: true),
      );
      if (FinampSettingsHelper.finampSettings.isOffline) {
        _offlineDeletesStreamController.add(null);
      }
    } catch (error, stackTrace) {
      _downloadsLogger.severe("Isar failure $error", error, stackTrace);
      rethrow;
    }
    restartDownloads();
  }

  /// Re-syncs every download node.
  Future<void> resyncAll({bool forceSync = false}) => resync(anchor, null, forceSync: forceSync);

  /// Re-syncs the specified stub and all descendants.  For this to work correctly
  /// it is required that [_syncDownload] strictly follows the node graph hierarchy
  /// and only syncs children appropriate for an info node if reaching a node along
  /// an info link, even if children appropriate for a required node are present.
  Future<void> resync(DownloadStub stub, BaseItemId? viewId, {bool keepSlow = false, bool forceSync = false}) async {
    await _channel.callMethod(DownloadsMethods.resetConnectionErrors, true);
    // All sync actions from now until app closure are the direct result of user
    // input and should run at full speed, so we set the full speed sync flag by default

    // If asked to sync an album or track, force full sync to actually process it
    forceSync = forceSync || (stub.type.requiresItem && !stub.baseItemType.expectChanges);

    var requiredByCount = _isar.downloadItems.filter().requires((q) => q.isarIdEqualTo(stub.isarId)).countSync();
    try {
      bool required = requiredByCount != 0;
      _downloadsLogger.info("Starting sync of ${stub.name}.");
      _isar.writeTxnSync(() {
        _utils.addSyncs(required ? [stub.isarId] : [], required ? [] : [stub.isarId], viewId);
      });
      await _channel.callMethod(
        DownloadsMethods.executeSyncs,
        SyncOptions(waitFowDownloads: false, useFullSpeed: !keepSlow, forceFullSync: forceSync),
      );

      _downloadsLogger.info("Sync of ${stub.name} complete.");
    } catch (error, stackTrace) {
      _downloadsLogger.severe("Isar failure $error", error, stackTrace);
      rethrow;
    }
  }

  /// Attempts to clean up any possible issues with downloads by removing stuck downloads,
  /// deleting node links that violate the node hierarchy, running [_syncDelete] on every node
  /// to clear out any orphans, and deleting any file in the internal download locations with
  /// no completed metadata node pointing to it.  See additional comment on the node hierarchy.
  Future<void> repairAllDownloads() async {
    await _channel.callMethod(DownloadsMethods.repair, null);
  }

  /// Find all downloaded tracks with outdated download location ID or transcoding profile
  /// and mark them for deletion, then resync to delete and redownload them.
  Future<void> markOutdatedTranscodes() {
    return _channel.callMethod(DownloadsMethods.markOutdatedTranscodes, null);
  }

  /// Migrates downloaded track metadata from Hive into Isar.  It first adds nodes
  /// for all images, then adds nodes for all tracks and links them to their appropriate
  /// images.  Then nodes are added for all parents which link to their tracks and
  /// images and are required by the anchor.  Finally, repairAllDownloads is run
  /// to fully download all metadata and clear up any issues.  This will fail if
  /// offline, but the node graph is still usable without this step and it can
  /// always be re-run later by the user.  Note that the existing hive metadata is
  /// not deleted by this migration, we just stop using it.
  Future<void> migrateFromHive() async {
    if (FinampSettingsHelper.finampSettings.downloadLocationsMap.values
        .where((element) => element.baseDirectory == DownloadLocationType.platformDefaultDirectory)
        .isEmpty) {
      final downloadLocation = await DownloadLocation.create(
        name: DownloadLocation.internalStorageName,
        baseDirectory: DownloadLocationType.platformDefaultDirectory,
      );
      FinampSettingsHelper.addDownloadLocation(downloadLocation);
    }
    await Future.wait([
      // ignore: deprecated_member_use_from_same_package
      Hive.openBox<DownloadedParent>("DownloadedParents"),
      // ignore: deprecated_member_use_from_same_package
      Hive.openBox<DownloadedTrack>("DownloadedItems"),
      // ignore: deprecated_member_use_from_same_package
      Hive.openBox<DownloadedImage>("DownloadedImages"),
    ]);

    final steps = DownloadMigrationSteps(anchor, this);

    steps.migrateImages();
    steps.migrateTracks();
    steps.migrateParents();
    unawaited(
      repairAllDownloads().then(
        (value) => null,
        onError: (error) {
          _downloadsLogger.severe("Error $error in hive migration downloads repair.");
          GlobalSnackbar.show(
            (scaffold) => SnackBar(
              content: Text(AppLocalizations.of(scaffold)!.runRepairWarning),
              duration: const Duration(seconds: 20),
            ),
          );
        },
      ),
    );
  }

  Future<void> addDefaultPlaylistInfoDownload() async {
    String? downloadLocation = FinampSettingsHelper.finampSettings.defaultDownloadLocation;
    if (!FinampSettingsHelper.finampSettings.downloadLocationsMap.containsKey(downloadLocation)) {
      downloadLocation = null;
    }
    downloadLocation ??= FinampSettingsHelper.finampSettings.internalTrackDir.id;

    // Automatically download playlist metadata (to enhance the playlist actions dialog and offline mode)
    await addDownload(
      stub: DownloadStub.fromFinampCollection(FinampCollection(type: FinampCollectionType.allPlaylistsMetadata)),
      transcodeProfile: DownloadProfile(
        transcodeCodec: FinampTranscodingCodec.original,
        downloadLocationId: downloadLocation,
      ),
    );
  }

  /// Gets an item which requires the given stub to be downloaded.  Used in
  /// DownloadButton tooltip for incidental downloads.
  DownloadStub? getFirstRequiringItem(DownloadStub stub) {
    return _isar.downloadItems.filter().requires((q) => q.isarIdEqualTo(stub.isarId)).findFirstSync();
  }

  /// Get all non-image children of an item.
  /// Used to show item children on the downloads screen.
  List<DownloadStub> getVisibleChildren(DownloadStub stub) {
    return _isar.downloadItems
        .where()
        .typeNotEqualTo(DownloadItemType.image)
        .filter()
        .requiredBy((q) => q.isarIdEqualTo(stub.isarId))
        .sortByBaseIndexNumber()
        .findAllSync();
  }

  /// Check whether the given item is part of the given collection.  Returns null
  /// if there is no metadata for the collection.
  bool? checkIfInCollection(BaseItemDto collection, BaseItemDto item) {
    var parent = _isar.downloadItems.getSync(DownloadStub.getHash(collection.id.raw, DownloadItemType.collection));
    var childId = DownloadStub.getHash(item.id.raw, item.downloadType);
    return parent?.orderedChildren?.contains(childId);
  }

  // This is for album/playlist screen
  /// Get all tracks in a collection, ordered correctly.  Used to show tracks on
  /// album/playlist screen.  Can return all tracks in the album/playlist or
  /// just fully downloaded ones.
  Future<List<BaseItemDto>> getCollectionTracks(
    BaseItemDto item, {
    bool playable = true,
    BaseItemDto? genreFilter,
    bool onlyFavorites = false,
  }) async {
    List<int> favoriteIds = [];
    if (onlyFavorites) {
      favoriteIds = _getFavoriteIds() ?? [];
    }
    var stub = DownloadStub.fromItem(type: DownloadItemType.collection, item: item);

    var id = DownloadStub.getHash(item.id.raw, DownloadItemType.collection);
    var query = _isar.downloadItems
        .where()
        .typeEqualTo(DownloadItemType.track)
        .filter()
        .infoFor((q) => q.isarIdEqualTo(id))
        .optional(
          playable,
          (q) => q.group(
            (q) =>
                q.stateEqualTo(DownloadItemState.complete).or().stateEqualTo(DownloadItemState.needsRedownloadComplete),
          ),
        )
        .optional(onlyFavorites, (q) => q.anyOf(favoriteIds, (q, v) => q.isarIdEqualTo(v)))
        // Returns items that have a certain genreId assigned
        .optional(
          genreFilter != null,
          (q) => q.infoFor(
            (q) =>
                q.info((q) => q.isarIdEqualTo(DownloadStub.getHash(genreFilter!.id.raw, DownloadItemType.collection))),
          ),
        );

    var canonItem = _isar.downloadItems.getSync(stub.isarId);
    if (canonItem?.orderedChildren == null) {
      var items = await query.sortByParentIndexNumber().thenByBaseIndexNumber().thenByName().findAll();
      return items.map((e) => e.baseItem).nonNulls.toList();
    } else {
      List<DownloadItem> playlist = await query.findAll();
      Map<int, DownloadItem> childMap = Map.fromIterable(playlist, key: (e) => (e as DownloadItem).isarId);
      return canonItem!.orderedChildren!.map((e) => childMap[e]?.baseItem).nonNulls.toList();
    }
  }

  /// Get all downloaded tracks.  Used for tracks tab on music screen.  Can have one
  /// or more filters applied:
  /// + nameFilter - only return tracks containing nameFilter in their name, case insensitive.
  /// + relatedTo - only return tracks which have relatedTo as their artist, album, or genre.
  /// + viewFilter - only return tracks in the given library.
  /// + genreFiter - only return tracks that have the provided genreID assigned
  Future<List<DownloadStub>> getAllTracks({
    String? nameFilter,
    BaseItemDto? relatedTo,
    BaseItemId? viewFilter,
    bool nullableViewFilters = true,
    bool onlyFavorites = false,
    BaseItemDto? genreFilter,
  }) {
    List<int> favoriteIds = [];
    if (onlyFavorites) {
      favoriteIds = _getFavoriteIds() ?? [];
    }
    return _isar.downloadItems
        .where()
        .typeEqualTo(DownloadItemType.track)
        .filter()
        .group(
          (q) =>
              q.stateEqualTo(DownloadItemState.complete).or().stateEqualTo(DownloadItemState.needsRedownloadComplete),
        )
        .optional(onlyFavorites, (q) => q.anyOf(favoriteIds, (q, v) => q.isarIdEqualTo(v)))
        .optional(nameFilter != null, (q) => q.nameContains(nameFilter!, caseSensitive: false))
        .optional(
          relatedTo != null,
          (q) => q.info((q) => q.isarIdEqualTo(DownloadStub.getHash(relatedTo!.id.raw, DownloadItemType.collection))),
        )
        // Returns items that have a certain genreId assigned
        .optional(
          genreFilter != null,
          (q) => q.info((q) => q.isarIdEqualTo(DownloadStub.getHash(genreFilter!.id.raw, DownloadItemType.collection))),
        )
        .optional(
          viewFilter != null,
          (q) => q.group(
            (q) => q
                .isarViewIdEqualTo(viewFilter?.raw)
                .optional(nullableViewFilters, (q) => q.or().isarViewIdEqualTo(null)),
          ),
        )
        .findAll();
  }

  /// Get all user downloaded items in a specific download location.  If checkFiles
  /// is false, only return user downloaded items, otherwise also include all items
  /// with files in the location.
  List<DownloadStub> getDownloadsForLocation(String downloadLocationId, bool checkFiles) {
    return _isar.downloadItems
        .filter()
        .userTranscodingProfile((q) => q.downloadLocationIdEqualTo(downloadLocationId))
        .optional(
          checkFiles,
          (q) => q.or().group(
            (q) => q
                .fileTranscodingProfile((q) => q.downloadLocationIdEqualTo(downloadLocationId))
                .not()
                .stateEqualTo(DownloadItemState.notDownloaded),
          ),
        )
        .findAllSync();
  }

  /// Get all downloaded collections.  Used for non-tracks tabs on music screen and
  /// on artist/genre screens.  Can have one or more filters applied:
  /// + nameFilter - only return collections containing nameFilter in their name, case insensitive.
  /// + baseTypeFilter - only return collections of the given BaseItemDto type.
  /// + relatedTo - only return collections containing tracks which have relatedTo as
  /// their artist, album, or genre.
  /// + fullyDownloaded - only return collections which are fully downloaded.  Artists/genres
  /// must be directly downloaded by the user for this to be true.
  /// + viewFilter - only return collections in the given library.
  /// + childViewFilter - only return collections with children in the given library.
  /// Useful for artists/genres, which may need to be shown in several libraries.
  /// + onlyFavorites - return only favorite items
  /// + infoForType - only return collections that are info childs for the provided type
  /// + genreFilter - only return albums that have the provided genre id assigned
  Future<List<DownloadStub>> getAllCollections({
    String? nameFilter,
    BaseItemDtoType? baseTypeFilter,
    BaseItemDto? relatedTo,
    bool fullyDownloaded = false,
    BaseItemId? viewFilter,
    BaseItemId? childViewFilter,
    bool nullableViewFilters = true,
    bool onlyFavorites = false,
    BaseItemDtoType? infoForType,
    ArtistType? artistType,
    BaseItemDto? genreFilter,
  }) {
    List<int> favoriteIds = [];
    List<int> libraryFilteredIds = [];
    if (onlyFavorites && baseTypeFilter != BaseItemDtoType.genre) {
      favoriteIds = _getFavoriteIds() ?? [];
    }
    if (fullyDownloaded) {
      final libraryId = _finampUserHelper.currentUser?.currentViewId;
      libraryFilteredIds = _isar.downloadItems
          .where()
          .typeEqualTo(DownloadItemType.finampCollection)
          .filter()
          .not()
          .stateEqualTo(DownloadItemState.notDownloaded)
          .findAllSync()
          .where(
            (collection) =>
                collection.finampCollection!.type == FinampCollectionType.collectionWithLibraryFilter &&
                collection.finampCollection!.library?.id == libraryId,
          )
          .map(
            (collection) =>
                DownloadStub.getHash(collection.finampCollection!.item!.id.raw, DownloadItemType.collection),
          )
          .toList();
    }

    return _isar.downloadItems
        .where()
        .typeEqualTo(DownloadItemType.collection)
        .filter()
        .optional(nameFilter != null, (q) => q.nameContains(nameFilter!, caseSensitive: false))
        .optional(baseTypeFilter != null, (q) => q.baseItemTypeEqualTo(baseTypeFilter!))
        // If allPlaylists is info downloaded, we may have info for empty
        // playlists.  We should only return playlists with at least 1 required
        // track in them.
        .optional(
          baseTypeFilter == BaseItemDtoType.playlist,
          (q) => q.info((q) => q.typeEqualTo(DownloadItemType.track).requiredByIsNotEmpty()),
        )
        // Returns albums where the artist (relatedTo) is an Album Artist
        .optional(
          artistType == ArtistType.albumArtist && relatedTo != null,
          (q) => q.info((q) => q.isarIdEqualTo(DownloadStub.getHash(relatedTo!.id.raw, DownloadItemType.collection))),
        )
        // Returns albums related to the performing artist or genre
        .optional(
          artistType != ArtistType.albumArtist && relatedTo != null,
          (q) => q.infoFor(
            (q) => q.info((q) => q.isarIdEqualTo(DownloadStub.getHash(relatedTo!.id.raw, DownloadItemType.collection))),
          ),
        )
        // Returns items that have a certain genreId assigned
        .optional(
          genreFilter != null,
          (q) => q.infoFor(
            (q) =>
                q.info((q) => q.isarIdEqualTo(DownloadStub.getHash(genreFilter!.id.raw, DownloadItemType.collection))),
          ),
        )
        .optional(
          fullyDownloaded,
          (q) => q.group(
            (q) => q
                .not()
                .stateEqualTo(DownloadItemState.notDownloaded)
                .or()
                .anyOf(libraryFilteredIds, (q, v) => q.isarIdEqualTo(v)),
          ),
        )
        .optional(onlyFavorites, (q) => q.anyOf(favoriteIds, (q, v) => q.isarIdEqualTo(v)))
        .optional(
          viewFilter != null,
          (q) => q.group(
            (q) => q
                .isarViewIdEqualTo(viewFilter?.raw)
                .optional(nullableViewFilters, (q) => q.or().isarViewIdEqualTo(null)),
          ),
        )
        .optional(
          childViewFilter != null,
          (q) => q.infoFor(
            (q) => q.group(
              (q) => q
                  .isarViewIdEqualTo(childViewFilter?.raw)
                  .optional(nullableViewFilters, (q) => q.or().isarViewIdEqualTo(null)),
            ),
          ),
        )
        .optional(infoForType != null, (q) => q.infoFor((q) => q.baseItemTypeEqualTo(infoForType!)))
        .findAll();
  }

  /// Get information about a downloaded track by BaseItemDto or id.
  /// Exactly one of the two arguments should be provided.
  Future<DownloadStub?> getTrackInfo({BaseItemDto? item, BaseItemId? id}) {
    assert((item == null) != (id == null));
    return _isar.downloadItems.get(DownloadStub.getHash(id?.raw ?? item!.id.raw, DownloadItemType.track));
  }

  /// Get information about a downloaded collection by BaseItemDto or id.
  /// Exactly one of the two arguments should be provided.
  Future<DownloadStub?> getCollectionInfo({BaseItemDto? item, BaseItemId? id}) {
    assert((item == null) != (id == null));
    return _isar.downloadItems.get(DownloadStub.getHash(id?.raw ?? item!.id.raw, DownloadItemType.collection));
  }

  /// Get a track's DownloadItem by BaseItemDto or id.  This method performs file
  /// verification and should only be used when the downloaded file is actually
  /// needed, such as when building MediaItems.  Otherwise, [getTrackInfo] should
  /// be used instead.  Exactly one of the two arguments should be provided.
  DownloadItem? getTrackDownload({BaseItemDto? item, BaseItemId? id}) {
    assert((item == null) != (id == null));
    return _getDownloadByID(id?.raw ?? item!.id.raw, DownloadItemType.track);
  }

  /// Get an image's DownloadItem by BaseItemDto or id.  This method performs file
  /// verification and should only be used when the downloaded file is actually
  /// needed, such as when building ImageProviders.  Exactly one of the two arguments
  /// should be provided.
  DownloadItem? getImageDownload({BaseItemDto? item, String? blurHash}) {
    assert((item == null) != (blurHash == null));
    String? imageId = blurHash ?? item!.blurHash ?? item!.imageId;
    if (imageId == null) {
      return null;
    }
    if (item != null && item.blurHash == null) {
      serverMissingBlurhash = true;
    }
    return _getDownloadByID(imageId, DownloadItemType.image);
  }

  /// Get DownloadedLyrics by the corresponding track's BaseItemDto.
  Future<DownloadedLyrics?> getLyricsDownload({required BaseItemDto baseItem}) async {
    var item = _isar.downloadedLyrics.getSync(DownloadStub.getHash(baseItem.id.raw, DownloadItemType.track));
    return item;
  }

  bool? isFavorite(BaseItemDto item) {
    var stubId = DownloadStub.getHash(item.id.raw, item.downloadType);
    return _getFavoriteIds()?.contains(stubId);
  }

  List<int>? _getFavoriteIds() {
    var stub = DownloadStub.fromFinampCollection(FinampCollection(type: FinampCollectionType.favorites));
    return _isar.downloadItems.getSync(stub.isarId)?.orderedChildren ?? [];
  }

  /// Get a downloadItem with verified files by id.
  DownloadItem? _getDownloadByID(String id, DownloadItemType type) {
    assert(type.hasFiles);
    var item = _isar.downloadItems.getSync(DownloadStub.getHash(id, type));
    if (item != null && _utils.verifyDownload(item)) {
      return item;
    }
    return null;
  }

  /// Returns a stream of the list of downloads of a given state. Used to display
  /// active/failed/enqueued downloads on the active downloads screen.
  Stream<List<DownloadStub>> getDownloadList(DownloadItemState state) {
    return _isar.downloadItems
        .where()
        .stateEqualTo(state)
        .filter()
        .optional(
          state != DownloadItemState.syncFailed,
          (q) => q.typeEqualTo(DownloadItemType.track).or().typeEqualTo(DownloadItemType.image),
        )
        // Watching queries is expensive and seems to have a memory link.  Avoid using if possible.
        .watch(fireImmediately: true);
  }

  // TODO move getFileSize to sync isolate?

  /// Returns the size of a download by recursively calculating the size of all
  /// required children.  Used to display item sizes on downloads screen.
  Future<int> getFileSize(DownloadStub item) =>
      GetIt.instance<JellyfinApiHelper>().runInIsolate(_getFileSizeBackground(item.isarId));

  static Future<int> Function(dynamic) _getFileSizeBackground(int isarId) {
    // Pass the download location map, as settings cannot be accessed in background
    var map = FinampSettingsHelper.finampSettings.downloadLocationsMap;
    return (dynamic _) async {
      var canonItem = GetIt.instance<Isar>().downloadItems.getSync(isarId);
      if (canonItem == null) return 0;
      Set<DownloadItem> info = {};
      Set<DownloadItem> required = {};
      _getFileChildren(canonItem, required, info, true);
      info = info.difference(required);
      int size = 0;
      for (var item in required) {
        size += await _getFileSize(item, true, map);
      }
      for (var item in info) {
        size += await _getFileSize(item, false, map);
      }
      return size;
    };
  }

  /// Recursive subcomponent of [getFileSize].
  static void _getFileChildren(DownloadItem item, Set<DownloadItem> required, Set<DownloadItem> info, bool isRequired) {
    if (required.contains(item) || (info.contains(item) && !isRequired)) {
      return;
    } else {
      if (isRequired) {
        required.add(item);
      } else {
        info.add(item);
      }
    }
    if (isRequired || item.type == DownloadItemType.track) {
      var children = item.requires.filter().findAllSync();
      for (var child in children) {
        _getFileChildren(child, required, info, isRequired);
      }
    }
    if (isRequired || item.type != DownloadItemType.track) {
      var children = item.info.filter().findAllSync();
      for (var child in children) {
        _getFileChildren(child, required, info, false);
      }
    }
  }

  /// Recursive subcomponent of [getFileSize].
  static Future<int> _getFileSize(DownloadItem item, bool required, Map<String, DownloadLocation> map) async {
    File? file(DownloadItem item) {
      if (map[item.fileTranscodingProfile?.downloadLocationId] == null || item.path == null) {
        return null;
      }
      return File(path_helper.join(map[item.fileTranscodingProfile?.downloadLocationId]!.currentPath, item.path));
    }

    if (item.type == DownloadItemType.track && item.state.isComplete && required) {
      if (item.fileTranscodingProfile == null ||
          item.fileTranscodingProfile!.codec != FinampTranscodingCodec.original ||
          item.baseItem?.mediaSources == null) {
        return await file(item)?.stat().then((value) => value.size).catchError((e) {
              Logger("downloadsServiceBackground").fine("No file for track ${item.name} when calculating size.");
              return 0;
            }) ??
            0;
      } else {
        return item.baseItem?.mediaSources?[0].size ?? 0;
      }
    }
    if (item.type == DownloadItemType.image && item.state == DownloadItemState.complete) {
      return await file(item)?.stat().then((value) => value.size).catchError((e) {
            Logger("downloadsServiceBackground").fine("No file for image ${item.name} when calculating size.");
            return 0;
          }) ??
          0;
    }
    return 0;
  }

  /// Returns the download status of an item.  This is whether the associated item
  /// is directly required by the user, transitively required via a containing collection,
  /// or not required to be downloaded at all.  Useful for determining whether to show
  /// download or delete buttons for an item.  The argument "children" is used
  /// while determining if an item is likely outdated compared to the server.  If this
  /// argument is not null and does not match the amount of children the item has in Isar,
  /// or if the item is neither fully downloaded nor actively downloading, then the item is
  /// considered to be outdated.
  DownloadItemStatus getStatus(DownloadStub stub, int? children) {
    assert(stub.type != DownloadItemType.image && stub.type != DownloadItemType.anchor);
    var item = _isar.downloadItems.getSync(stub.isarId);
    if (item == null) return DownloadItemStatus.notNeeded;
    if (item.state == DownloadItemState.notDownloaded && item.requiredBy.filter().countSync() == 0) {
      return DownloadItemStatus.notNeeded;
    }
    int childCount;
    if (stub.baseItemType == BaseItemDtoType.album || stub.baseItemType == BaseItemDtoType.playlist) {
      // albums/playlists get marked as incidentally required if all info children
      // are required.  Use info links to calculate child count for this case
      childCount = item.info.filter().typeEqualTo(DownloadItemType.track).countSync();
    } else {
      childCount = item.requires.filter().not().typeEqualTo(DownloadItemType.image).countSync();
    }
    var outdated =
        (children != null && childCount != children) ||
        item.state == DownloadItemState.failed ||
        item.state == DownloadItemState.notDownloaded;
    if (item.requiredBy.filter().isarIdEqualTo(anchor.isarId).countSync() > 0) {
      return outdated ? DownloadItemStatus.requiredOutdated : DownloadItemStatus.required;
    } else {
      return outdated ? DownloadItemStatus.incidentalOutdated : DownloadItemStatus.incidental;
    }
  }

  @override
  Map<String, DownloadLocation> get getDownloadLocationsMap => FinampSettingsHelper.finampSettings.downloadLocationsMap;
}
