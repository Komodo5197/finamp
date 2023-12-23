import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:background_downloader/background_downloader.dart';
import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:isar/isar.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path_helper;

import '../models/finamp_models.dart';
import '../models/jellyfin_models.dart';
import 'finamp_settings_helper.dart';
import 'finamp_user_helper.dart';
import 'get_internal_song_dir.dart';
import 'jellyfin_api_helper.dart';

enum IsarBackgroundCommands {
  addDownload,
  deleteDownload,
  repairAll,
  syncItem;
}

enum IsarForegroundCommands {
  log,
  enqueue,
  cancel,
  getIds;
}

class IsarDownloadsBackground {
  static startup((SendPort, RootIsolateToken, SendPort) input, {bool inIsolate=true}) async {
    var (startupPort, token, commandSender) = input;
    var commandReceiver = ReceivePort();
    var eventReceiver = ReceivePort();
    if(inIsolate) {
      BackgroundIsolateBinaryMessenger.ensureInitialized(token);
      Logger.root.level = Level.ALL;
      Logger.root.onRecord.listen((event) {
        commandSender.send((
        IsarForegroundCommands.log,
        (
        event.loggerName,
        event.level,
        event.message,
        event.error,
        event.stackTrace.toString()
        )
        ));
      });
      var dir = await getApplicationDocumentsDirectory();
      final isar = await Isar.open(
        [DownloadItemSchema, DownloadStatusSummarySchema, FinampUserSchema],
        directory: dir.path,
      );
      GetIt.instance.registerSingleton(isar);
      GetIt.instance.registerSingleton(FinampUserHelper());
      GetIt.instance.registerSingleton(JellyfinApiHelper());
    }
    startupPort.send((commandReceiver.sendPort, eventReceiver.sendPort));
    IsarDownloadsBackground(commandReceiver, eventReceiver, commandSender);
  }

  IsarDownloadsBackground(
      this._commandReceiver, this._eventReceiver, this._commandSender) {
    DownloadStatusSummary initialSummary = DownloadStatusSummary();
    for (var state in DownloadItemState.values) {
      initialSummary.set(
          state,
          _isar.downloadItems
              .where()
              .typeEqualTo(DownloadItemType.song)
              .or()
              .typeEqualTo(DownloadItemType.image)
              .filter()
              .stateEqualTo(state)
              .countSync());
    }
    _isar.writeTxnSync(() {
      _isar.downloadStatusSummarys.putSync(initialSummary);
    });

    // TODO use database instead of listener?
    _eventReceiver.listen((event) {
      if (event is TaskStatusUpdate) {
        _isar.writeTxn(() async {
          List<DownloadItem> listeners = await _isar.downloadItems
              .where()
              .isarIdEqualTo(int.parse(event.task.taskId))
              .findAll();
          for (var listener in listeners) {
            var newState = DownloadItemState.fromTaskStatus(event.status);
            await _updateItemState(listener, newState);
            if (event.status == TaskStatus.complete) {
              _downloadsLogger.fine("Downloaded ${listener.name}");
            }
          }
          if (listeners.isEmpty) {
            _downloadsLogger.severe(
                "Could not determine item for id ${event.task.taskId}, event:${event.toString()}");
          }
          await _isar.downloadItems.putAll(listeners);
          var summary = await _isar.downloadStatusSummarys.get(0) ??
              DownloadStatusSummary();
          summary.update(
              DownloadItemState.notDownloaded, DownloadItemState.complete,
              count: listeners.length);
          await _isar.downloadStatusSummarys.put(summary);
        });
      }
    });

    _commandReceiver.listen((message) async {
      switch (message) {
        case (SendPort returnPort, Record content):
          Object? output;
          try {
            switch (content) {
              case (
                  IsarBackgroundCommands.addDownload,
                  DownloadStub stub,
                  DownloadLocation location
                ):
                await addDownload(stub: stub, downloadLocation: location);
              case (
              IsarBackgroundCommands.deleteDownload,
              DownloadStub stub,
              ):
                await deleteDownload(stub: stub);
              case (
              IsarBackgroundCommands.repairAll,
              ):
                await repairAllDownloads();
              case (
              IsarBackgroundCommands.syncItem,
              DownloadStub stub,
              ):
                await _syncDownload(stub, []);
              case _:
                _downloadsLogger.severe("Unknown command $content");
            }
          } catch (e) {
            output = e;
          }
          returnPort.send(output);
        case _:
          _downloadsLogger.severe("Malformed command $message");
      }
    });
  }

  final _downloadsLogger = Logger("DownloadsBackground");

  final _jellyfinApiData = GetIt.instance<JellyfinApiHelper>();
  final _finampUserHelper = GetIt.instance<FinampUserHelper>();
  final _isar = GetIt.instance<Isar>();

  final _anchor =
      DownloadStub.fromId(id: "Anchor", type: DownloadItemType.anchor);
  final ReceivePort _commandReceiver;
  final ReceivePort _eventReceiver;
  final SendPort _commandSender;

  Map<String, Future<Map<String, DownloadStub>>> _metadataCache = {};

  // TODO I believe this is still basically synchronous.  Fix or simplify.
  // Need _syncDownload to launch children in parallel for this to run in parallel
  // Do that just that with this cache?
  // Or do that + additional request batching?
  // Or simplify code to remove complicated future structure and keep synchronous.
  Future<List<DownloadStub>> _getCollectionInfo(List<String> ids) async {
    List<Future<DownloadStub?>> output = [];
    Map<String, DownloadStub> itemMap = {};
    Completer<Map<String, DownloadStub>> itemFetch = Completer();
    try {
      List<String> unmappedIds = [];
      for (String id in ids) {
        if (_metadataCache.containsKey(id)) {
          output.add(_metadataCache[id]!.then((value) => value[id]));
        } else {
          _metadataCache[id] = itemFetch.future;
          output.add(itemFetch.future.then((value) => value[id]));
          unmappedIds.add(id);
        }
      }

      List<DownloadItem?> downloadItems = [];
      List<DownloadItem?> infoItems = [];

      List<String> idsToQuery = [];
      if (unmappedIds.isNotEmpty) {
        await _isar.txn(() async {
          downloadItems = await _isar.downloadItems.getAll(unmappedIds
              .map((e) =>
                  DownloadStub.getHash(e, DownloadItemType.collectionDownload))
              .toList());
          infoItems = await _isar.downloadItems.getAll(unmappedIds
              .map((e) =>
                  DownloadStub.getHash(e, DownloadItemType.collectionInfo))
              .toList());
        });
        for (int i = 0; i < unmappedIds.length; i++) {
          if (infoItems[i] != null) {
            itemMap[unmappedIds[i]] = infoItems[i]!;
          } else if (downloadItems[i]?.baseItem != null) {
            itemMap[unmappedIds[i]] = DownloadStub.fromItem(
                type: DownloadItemType.collectionInfo,
                item: downloadItems[i]!.baseItem!);
          } else {
            idsToQuery.add(unmappedIds[i]);
          }
        }
      }
      if (idsToQuery.isNotEmpty) {
        List<BaseItemDto> items =
            await _jellyfinApiData.getItems(itemIds: idsToQuery) ?? [];
        itemMap.addEntries(items.map((e) => MapEntry(
            e.id,
            DownloadStub.fromItem(
                type: DownloadItemType.collectionInfo, item: e))));
      }
      itemFetch.complete(itemMap);
    } catch (e) {
      _downloadsLogger.info("Error downloading metadata: $e");
      itemFetch.completeError("Error downloading metadata: $e");
    }
    return Future.wait(output).then((value) => value.whereNotNull().toList());
  }

  // Make sure the parent and all children are in the metadata collection,
  // and downloaded.
  // TODO add comment warning about require loops
  Future<void> _syncDownload(
      DownloadStub parent, List<DownloadStub> completed) async {
    if (completed.contains(parent)) {
      return;
    } else {
      completed.add(parent);
    }
    _downloadsLogger.finer("Syncing ${parent.name}");

    bool updateChildren = true;
    Set<DownloadStub> children = {};
    List<BaseItemDto>? childItems;
    switch (parent.type) {
      case DownloadItemType.collectionDownload:
        DownloadItemType childType;
        BaseItemDtoType childFilter;
        switch (parent.baseItemType) {
          case BaseItemDtoType.playlist: // fall through
          case BaseItemDtoType.album:
            childType = DownloadItemType.song;
            childFilter = BaseItemDtoType.song;
          case BaseItemDtoType.artist: // fall through
          case BaseItemDtoType.genre:
            childType = DownloadItemType.collectionDownload;
            childFilter = BaseItemDtoType.album;
          case BaseItemDtoType.song:
          case BaseItemDtoType.unknown:
            throw StateError(
                "Impossible typing: ${parent.type} and ${parent.baseItemType}");
        }
        var item = parent.baseItem!;
        if (item.blurHash != null) {
          children.add(
              DownloadStub.fromItem(type: DownloadItemType.image, item: item));
        }
        try {
          childItems = await _jellyfinApiData.getItems(
                  parentItem: item, includeItemTypes: childFilter.idString) ??
              [];
          for (var child in childItems) {
            children.add(DownloadStub.fromItem(type: childType, item: child));
          }
        } catch (e) {
          _downloadsLogger.info("Error downloading children: $e");
          updateChildren = false;
        }
        children.add(DownloadStub.fromItem(
            type: DownloadItemType.collectionInfo, item: item));
      case DownloadItemType.song:
        var item = parent.baseItem!;
        if (item.blurHash != null) {
          children.add(
              DownloadStub.fromItem(type: DownloadItemType.image, item: item));
        }
        List<String> collectionIds = [];
        collectionIds.addAll(item.genreItems?.map((e) => e.id) ?? []);
        collectionIds.addAll(item.artistItems?.map((e) => e.id) ?? []);
        collectionIds.addAll(item.albumArtists?.map((e) => e.id) ?? []);
        if (item.albumId != null) {
          collectionIds.add(item.albumId!);
        }
        try {
          var collectionChildren = await _getCollectionInfo(collectionIds);
          children.addAll(collectionChildren);
        } catch (_) {
          _downloadsLogger.info("Failed to download metadata for ${item.name}");
          updateChildren = false;
        }
      case DownloadItemType.image:
        break;
      case DownloadItemType.anchor:
        updateChildren = false;
      case DownloadItemType.collectionInfo:
        var item = parent.baseItem!;
        if (item.blurHash != null) {
          children.add(
              DownloadStub.fromItem(type: DownloadItemType.image, item: item));
        }
    }

    //if (updateChildren) {
    //  _downloadsLogger.finest(
    //      "Updating children of ${parent.name} to ${children.map((e) => e.name)}");
    //}

    Set<DownloadItem> childrenToUnlink = {};
    String? downloadLocationId;
    if (updateChildren) {
      //TODO update core item with latest?
      await _isar.writeTxn(() async {
        DownloadItem? canonParent =
            await _isar.downloadItems.get(parent.isarId);
        if (canonParent == null) {
          throw StateError("_syncDownload called on missing node ${parent.id}");
        }
        if (parent.baseItemType == BaseItemDtoType.playlist) {
          canonParent.orderedChildren = childItems
              ?.map((e) => DownloadStub.getHash(e.id, DownloadItemType.song))
              .toList();
          await _isar.downloadItems.put(canonParent);
        }
        downloadLocationId = canonParent.downloadLocationId;

        var oldChildren = await canonParent.requires.filter().findAll();
        // anyOf filter allows all objects when given empty list, but we want no objects
        var childrenToLink = (children.isEmpty)
            ? <DownloadItem>[]
            : await _isar.downloadItems
                .where()
                .anyOf(children.map((e) => e.isarId),
                    (q, int id) => q.isarIdEqualTo(id))
                .findAll();
        var childrenToPutAndLink = children
            .difference(childrenToLink.toSet())
            .map((e) => e.asItem(canonParent.downloadLocationId));
        childrenToUnlink = oldChildren.toSet().difference(children);
        assert((childrenToLink + childrenToPutAndLink.toList()).length ==
            children.length);
        await _isar.downloadItems.putAll(childrenToPutAndLink.toList());
        await canonParent.requires.update(
            link: childrenToLink + childrenToPutAndLink.toList(),
            unlink: childrenToUnlink);
        if (childrenToLink.length != oldChildren.length ||
            childrenToUnlink.isNotEmpty) {
          await _syncItemState(canonParent);
        }
      });
    } else {
      await _isar.txn(() async {
        downloadLocationId =
            (await _isar.downloadItems.get(parent.isarId))?.downloadLocationId;
        children = (await _isar.downloadItems
                .filter()
                .requiredBy((q) => q.isarIdEqualTo(parent.isarId))
                .findAll())
            .toSet();
      });
    }

    if (parent.type.hasFiles) {
      if (downloadLocationId == null) {
        _downloadsLogger.severe(
            "could not download ${parent.id}, no download location found.");
      } else {
        await _initiateDownload(parent, downloadLocationId!);
      }
    }

    List<Future<void>> futures=[];
    for (var child in children) {
      futures.add(_syncDownload(child, completed));
    }
    await Future.wait(futures);
    for (var child in childrenToUnlink) {
      await _syncDelete(child.isarId);
    }
  }

  Future<void> _syncDelete(int isarId) async {
    DownloadItem? canonItem = await _isar.downloadItems.get(isarId);
    _downloadsLogger.finer("Sync deleting ${canonItem?.name ?? isarId}");
    if (canonItem == null ||
        canonItem.requiredBy.isNotEmpty ||
        canonItem.type == DownloadItemType.anchor) {
      return;
    }

    if (canonItem.type.hasFiles) {
      await _deleteDownload(canonItem);
    }

    Set<DownloadItem> children = {};
    await _isar.writeTxn(() async {
      DownloadItem? transactionItem =
          await _isar.downloadItems.get(canonItem.isarId);
      if (transactionItem == null) {
        return;
      }
      children = (await transactionItem.requires.filter().findAll()).toSet();
      if (transactionItem.type == DownloadItemType.image ||
          transactionItem.type == DownloadItemType.song) {
        if (transactionItem.state != DownloadItemState.notDownloaded) {
          _downloadsLogger.severe(
              "Could not delete ${transactionItem.id}, may still have files");
          throw StateError(
              "Could not delete ${transactionItem.id}, may still have files");
        }
      }
      await _isar.downloadItems.delete(transactionItem.isarId);
    });

    // TODO consolidate deletes until after all syncs to prevent extra download in special circumstances?
    for (var child in children) {
      await _syncDelete(child.isarId);
    }
  }

  // TODO use download groups to send notification when item fully downloaded?
  Future<void> addDownload({
    required DownloadStub stub,
    required DownloadLocation downloadLocation,
  }) async {
    if (downloadLocation.deletable) {
      if (!await Permission.storage.request().isGranted) {
        _downloadsLogger.severe("Storage permission is not granted, exiting");
        return Future.error(
            "Storage permission is required for external storage");
      }
    }

    await _isar.writeTxn(() async {
      DownloadItem canonItem = await _isar.downloadItems.get(stub.isarId) ??
          stub.asItem(downloadLocation.id);
      canonItem.downloadLocationId = downloadLocation.id;
      await _isar.downloadItems.put(canonItem);
      var anchorItem = _anchor.asItem(null);
      await _isar.downloadItems.put(anchorItem);
      await anchorItem.requires.update(link: [canonItem]);
    });

    return _syncDownload(stub, []).onError((error, stackTrace) {
      _downloadsLogger.severe("Isar failure $error", error, stackTrace);
      throw error!;
    }).then((_) => _metadataCache = {});
  }

  Future<void> deleteDownload({required DownloadStub stub}) async {
    await _isar.writeTxn(() async {
      var anchorItem = _anchor.asItem(null);
      await _isar.downloadItems.put(anchorItem);
      await anchorItem.requires.update(unlink: [stub.asItem(null)]);
    });

    return _syncDelete(stub.isarId).onError((error, stackTrace) {
      _downloadsLogger.severe("Isar failure $error", error, stackTrace);
      throw error!;
    });
  }

  Future<void> _initiateDownload(
      DownloadStub item, String downloadLocationId) async {
    DownloadItem? canonItem = await _isar.downloadItems.get(item.isarId);
    if (canonItem == null) {
      _downloadsLogger.severe(
          "Download metadata ${item.id} missing before download starts");
      return;
    }

    if (!item.type.hasFiles) {
      return;
    }

    switch (canonItem.state) {
      case DownloadItemState.complete:
        return;
      case DownloadItemState.notDownloaded:
        break;
      case DownloadItemState.enqueued: //fall through
      case DownloadItemState.downloading:
        var port = ReceivePort();
        _commandSender.send((IsarForegroundCommands.getIds, port.sendPort));
        var activeTasks = await port.first;
        port.close();
        if (activeTasks.contains(canonItem.isarId.toString())) {
          return;
        }
        await _deleteDownload(canonItem);
      case DownloadItemState.failed:
        // TODO don't retry failed unless we specifically want to?
        await _deleteDownload(canonItem);
    }

    // Refresh canonItem due to possible changes
    canonItem = await _isar.downloadItems.get(item.isarId);
    if (canonItem == null ||
        canonItem.state != DownloadItemState.notDownloaded) {
      throw StateError(
          "Bad state beginning download for ${item.name}: $canonItem");
    }

    //if (FinampSettingsHelper.finampSettings.isOffline){
    //  _downloadsLogger.info("Aborting download of ${item.name}, we are offline.");
    //  return;
    //}

    switch (canonItem.type) {
      case DownloadItemType.song:
        return _downloadSong(canonItem, downloadLocationId);
      case DownloadItemType.image:
        return _downloadImage(canonItem, downloadLocationId);
      case _:
        throw StateError("???");
    }
  }

  Future<void> _downloadSong(
      DownloadItem downloadItem, String downloadLocationId) async {
    assert(downloadItem.type == DownloadItemType.song);
    // TODO allow alternate download locations
    var item = downloadItem.baseItem!;

    // Base URL shouldn't be null at this point (user has to be logged in
    // to get to the point where they can add downloads).
    String songUrl =
        "${_finampUserHelper.currentUser!.baseUrl}/Items/${item.id}/File";

    List<MediaSourceInfo>? mediaSourceInfo =
        await _jellyfinApiData.getPlaybackInfo(item.id);

    String fileName;
    String subDirectory;
    //TODO downloadLocation.useHumanReadableNames
    if (false) {
      if (mediaSourceInfo == null) {
        _downloadsLogger.warning(
            "Media source info for ${item.id} returned null, filename may be weird.");
      }
      subDirectory = path_helper.join("finamp", item.albumArtist);
      // We use a regex to filter out bad characters from song/album names.
      fileName =
          "${item.album?.replaceAll(RegExp('[/?<>\\:*|"]'), "_")} - ${item.indexNumber ?? 0} - ${item.name?.replaceAll(RegExp('[/?<>\\:*|"]'), "_")}.${mediaSourceInfo?[0].container}";
    } else {
      fileName = "${item.id}.${mediaSourceInfo?[0].container}";
      subDirectory = "songs";
    }

    String? tokenHeader = _jellyfinApiData.getTokenHeader();

    // TODO allow pausing?  When to resume?
    BaseDirectory;
    _commandSender.send((IsarForegroundCommands.enqueue,DownloadTask(
        taskId: downloadItem.isarId.toString(),
        displayName: item.name??"",
        url: songUrl,
        headers: {
          if (tokenHeader != null) "X-Emby-Token": tokenHeader,
        },
        filename: fileName)));

    await _isar.writeTxn(() async {
      DownloadItem? canonItem =
          await _isar.downloadItems.get(downloadItem.isarId);
      if (canonItem == null) {
        _downloadsLogger.severe(
            "Download metadata ${downloadItem.id} missing after download starts");
        throw StateError("Could not save download task id");
      }
      canonItem.downloadLocationId = downloadLocationId;
      canonItem.path = path_helper.join(subDirectory, fileName);
      canonItem.mediaSourceInfo = mediaSourceInfo![0];
      await _isar.downloadItems.put(canonItem);
    });
  }

  Future<void> _downloadImage(
      DownloadItem downloadItem, String downloadLocationId) async {
    assert(downloadItem.type == DownloadItemType.image);
    // TODO allow alternate download locations
    var item = downloadItem.baseItem!;

    String subDirectory;
    //TODO downloadLocation.useHumanReadableNames
    if (false) {
      subDirectory = path_helper.join("finamp", item.albumArtist);
    } else {
      subDirectory = "images";
    }

    final imageUrl = _jellyfinApiData.getImageUrl(
      item: item,
      // Download original file
      quality: null,
      format: null,
    );
    final tokenHeader = _jellyfinApiData.getTokenHeader();

    // We still use imageIds for filenames despite switching to blurhashes as
    // blurhashes can include characters that filesystems don't support
    final fileName = item.imageId;

    BaseDirectory;
    _commandSender.send((IsarForegroundCommands.enqueue,DownloadTask(
        taskId: downloadItem.isarId.toString(),
        url: imageUrl.toString(),
        directory: subDirectory,
        headers: {
          if (tokenHeader != null) "X-Emby-Token": tokenHeader,
        },
        filename: fileName)));

    await _isar.writeTxn(() async {
      DownloadItem? canonItem =
          await _isar.downloadItems.get(downloadItem.isarId);
      if (canonItem == null) {
        _downloadsLogger.severe(
            "Download metadata ${downloadItem.id} missing after download starts");
        throw StateError("Could not save download task id");
      }
      canonItem.downloadLocationId = downloadLocationId;
      canonItem.path = path_helper.join(subDirectory, fileName);
      await _isar.downloadItems.put(canonItem);
    });
  }

  Future<void> _deleteDownload(DownloadItem item) async {
    assert(item.type.hasFiles);
    if (item.state == DownloadItemState.notDownloaded) {
      return;
    }

    _commandSender.send((IsarForegroundCommands.cancel, item.isarId.toString()));
    // TODO reimplement deleting files
    /*if (item.downloadLocation != null) {
      try {
        await item.file.delete();
      } on PathNotFoundException {
        _downloadsLogger.finer(
            "File ${item.file.path} for ${item.name} missing during delete.");
      }
    }

    if (item.downloadLocation != null &&
        item.downloadLocation!.useHumanReadableNames) {
      Directory songDirectory = item.file.parent;
      if (await songDirectory.list().isEmpty) {
        _downloadsLogger.info("${songDirectory.path} is empty, deleting");
        try {
          await songDirectory.delete();
        } on PathNotFoundException {
          _downloadsLogger
              .finer("Directory ${songDirectory.path} missing during delete.");
        }
      }
    }*/

    await _isar.writeTxn(() async {
      var transactionItem = await _isar.downloadItems.get(item.isarId);
      await _updateItemState(transactionItem!, DownloadItemState.notDownloaded);
      await _isar.downloadItems.put(transactionItem);
    });
  }

  // TODO add clear download metadata option in settings?  Add some option to clear all links in settings??
  // or maybe clear all links but add warning to user about deletes occuring if server connection fails
  // or maybe provide list of nodes to be deleted to user and ask for delete confirmation?
  Future<void> repairAllDownloads() async {
    //TODO add more error checking so that one very broken item can't block general repairs.
    // Step 1 - Get all items into correct state matching filesystem and downloader.
    _downloadsLogger.fine("Starting downloads repair step 1");
    var itemsWithFiles = await _isar.downloadItems
        .where()
        .typeEqualTo(DownloadItemType.song)
        .or()
        .typeEqualTo(DownloadItemType.image)
        .findAll();
    for (var item in itemsWithFiles) {
      switch (item.state) {
        case DownloadItemState.complete:
          await verifyDownload(item);
        case DownloadItemState.notDownloaded:
          break;
        case DownloadItemState.enqueued: // fall through
        case DownloadItemState.downloading:
          var port = ReceivePort();
          _commandSender.send((IsarForegroundCommands.getIds, port.sendPort));
          var activeTasks = await port.first;
          port.close();
          if (activeTasks.contains(item.isarId.toString())) {
            break;
          }
          await _deleteDownload(item);
        case DownloadItemState.failed:
          await _deleteDownload(item);
      }
    }
    var itemsWithChildren = await _isar.downloadItems
        .where()
        .typeEqualTo(DownloadItemType.collectionDownload)
        .findAll();
    await _isar.writeTxn(() async {
      for (var item in itemsWithChildren) {
        await _syncItemState(item);
      }
    });

    // Step 2 - Make sure all items are linked up to correct children.
    _downloadsLogger.fine("Starting downloads repair step 2");
    List<
        (
          DownloadItemType,
          QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition> Function(
              QueryBuilder<DownloadItem, DownloadItem, QFilterCondition>)?
        )> filters = [
      (DownloadItemType.anchor, null),
      (
        DownloadItemType.collectionDownload,
        (q) => q.allOf([BaseItemDtoType.album, BaseItemDtoType.playlist],
            (q, element) => q.not().baseItemTypeEqualTo(element))
      ),
      (
        DownloadItemType.collectionDownload,
        (q) => q.anyOf([BaseItemDtoType.album, BaseItemDtoType.playlist],
            (q, element) => q.baseItemTypeEqualTo(element))
      ),
      (DownloadItemType.song, null),
      (DownloadItemType.collectionInfo, null),
      (DownloadItemType.image, null),
    ];
    // Objects matching a filter cannot require elements matching earlier filters or the current filter.
    // This enforces a strict object hierarchy with no possibility of loops.
    for (int i = 0; i < filters.length; i++) {
      var items = await _isar.downloadItems
          .where()
          .typeEqualTo(filters[i].$1)
          .filter()
          .optional(filters[i].$2 != null, (q) => filters[i].$2!(q))
          .requires((q) => q.anyOf(
              filters.slice(0, i + 1),
              (q, element) => q
                  .typeEqualTo(element.$1)
                  .optional(element.$2 != null, (q) => element.$2!(q))))
          .findAll();
      for (var item in items) {
        _downloadsLogger.severe("Unlinking invalid node ${item.name}.");
        //await item.requires.reset();
      }
    }
    List<DownloadStub> completed=[];
    for(var anchor in await _isar.downloadItems.where().typeEqualTo(DownloadItemType.anchor).findAll()){
      await _syncDownload(anchor, completed);
    }

    // Step 3 - Make sure there are no unanchored nodes in metadata.
    _downloadsLogger.fine("Starting downloads repair step 3");
    var allIds = await _isar.downloadItems.where().isarIdProperty().findAll();
    for (var id in allIds) {
      await _syncDelete(id);
    }

    // Step 4 - Make sure there are no orphan files in song directory.
    _downloadsLogger.fine("Starting downloads repair step 4");
    final internalSongDir = (await getInternalSongDir()).path;
    var songFilePaths = Directory(path_helper.join(internalSongDir, "songs"))
        .list()
        .handleError((e) =>
            _downloadsLogger.info("Error while cleaning directories: $e"))
        .where((event) => event is File)
        .map((event) => path_helper.normalize(event.path));
    var imageFilePaths = Directory(path_helper.join(internalSongDir, "images"))
        .list()
        .handleError((e) =>
            _downloadsLogger.info("Error while cleaning directories: $e"))
        .where((event) => event is File)
        .map((event) => path_helper.normalize(event.path));
    var filePaths =
        await songFilePaths.toList() + await imageFilePaths.toList();
    for (var item in await _isar.downloadItems
        .where()
        .typeEqualTo(DownloadItemType.song)
        .or()
        .typeEqualTo(DownloadItemType.image)
        .findAll()) {
      filePaths.remove(path_helper.normalize(item.file.path));
    }
    for (var filePath in filePaths) {
      _downloadsLogger.info("Deleting orphan file $filePath");
      try {
        await File(filePath).delete();
      } catch (e) {
        _downloadsLogger.info("Error while cleaning directories: $e");
      }
    }
  }

  // TODO turn into or wrap around resync function that just checks tasklist and file state and updates item appropriatly.
  // unify with download repair in some way
  Future<bool> verifyDownload(DownloadItem item) async {
    if (!item.type.hasFiles) return true;
    if (item.state != DownloadItemState.complete) return false;
    if (item.downloadLocation != null && await item.file.exists()) return true;
    await FinampSettingsHelper.resetDefaultDownloadLocation();
    if (item.downloadLocation != null && await item.file.exists()) return true;
    await _isar.writeTxn(() async {
      await _updateItemState(item, DownloadItemState.notDownloaded);
      await _isar.downloadItems.put(item);
    });
    _downloadsLogger.info(
        "${item.name} failed download verification, not located at ${item.file.path}.");
    return false;
    // TODO add external storage stuff
  }

  // This should only be called inside an isar write transaction
  Future<void> _updateItemState(
      DownloadItem item, DownloadItemState newState) async {
    if (item.state != newState) {
      if (item.type.hasFiles) {
        var summary = await _isar.downloadStatusSummarys.get(0) ??
            DownloadStatusSummary();
        summary.update(item.state, newState);
        await _isar.downloadStatusSummarys.put(summary);
      }
      item.state = newState;
      await _isar.downloadItems.put(item);
      for (var parent in await item.requiredBy.filter().findAll()) {
        await _syncItemState(parent);
      }
    }
  }

  // This should only be called inside an isar write transaction
  Future<void> _syncItemState(DownloadItem item) async {
    if (item.type.hasFiles) return;
    var children = await item.requires.filter().findAll();
    if (children
        .any((element) => element.state == DownloadItemState.notDownloaded)) {
      await _updateItemState(item, DownloadItemState.notDownloaded);
    } else if (children
        .any((element) => element.state == DownloadItemState.failed)) {
      await _updateItemState(item, DownloadItemState.failed);
    } else if (children
        .any((element) => element.state != DownloadItemState.complete)) {
      await _updateItemState(item, DownloadItemState.downloading);
    } else {
      await _updateItemState(item, DownloadItemState.complete);
    }
  }
}
