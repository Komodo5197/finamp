import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:background_downloader/background_downloader.dart';
import 'package:collection/collection.dart';
import 'package:finamp/services/isar_downloads_background.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:isar/isar.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path_helper;

import '../models/finamp_models.dart';
import '../models/jellyfin_models.dart';
import 'finamp_settings_helper.dart';
import 'finamp_user_helper.dart';
import 'get_internal_song_dir.dart';
import 'jellyfin_api_helper.dart';

final downloadStatusProvider = StreamProvider.family
    .autoDispose<DownloadItemState, DownloadStub>((ref, stub) {
  final isar = GetIt.instance<Isar>();
  return isar.downloadItems
      .watchObject(stub.isarId, fireImmediately: true)
      .map((event) => event?.state ?? DownloadItemState.notDownloaded);
});

class IsarDownloads {
  IsarDownloads(this._commandSender, this._eventSender, this._commandReceiver) {
    FileDownloader().updates.listen(_eventSender.send);
    _commandReceiver.listen((message) async {
      //_downloadsLogger.finest("Recieved command $message");
      switch (message) {
        case (
            IsarForegroundCommands.log,
            (
              String name,
              Level level,
              Object? message,
              Object? error,
              String trace,
            )
          ):
          StackTrace;
          Logger(name).log(level, message, error,
              trace == "null" ? null : StackTrace.fromString(trace));
        case (IsarForegroundCommands.getIds, SendPort port):
          port.send(await FileDownloader().allTaskIds());
        case (IsarForegroundCommands.enqueue, DownloadTask task):
          if (!await FileDownloader().enqueue(task)) {
            _downloadsLogger.severe(
                "Adding download for ${task
                    .displayName} failed! This should never happen...");
          }
        case (IsarForegroundCommands.cancel, String id): await FileDownloader().cancelTaskWithId(id);
        case _:
          _downloadsLogger.severe("Unknown command $message");
      }
    });
  }

  final _downloadsLogger = Logger("IsarDownloads");

  final _jellyfinApiData = GetIt.instance<JellyfinApiHelper>();
  final _finampUserHelper = GetIt.instance<FinampUserHelper>();
  final _isar = GetIt.instance<Isar>();

  final _anchor =
      DownloadStub.fromId(id: "Anchor", type: DownloadItemType.anchor);
  final ReceivePort _commandReceiver;
  final SendPort _eventSender;
  final SendPort _commandSender;

  Stream<DownloadStatusSummary?> get downloadStatusesStream =>
      _isar.downloadStatusSummarys.watchObject(0, fireImmediately: true);

  // TODO use download groups to send notification when item fully downloaded?
  Future<void> addDownload({
    required DownloadStub stub,
    required DownloadLocation downloadLocation,
  }) =>
      _sendCommand(IsarBackgroundCommands.addDownload, stub, downloadLocation);

  Future<void> _sendCommand(IsarBackgroundCommands command,
      [Object? arg1, Object? arg2]) async {
    ReceivePort returnPort = ReceivePort();
    if (arg1 == null && arg2 == null) {
      _commandSender.send((returnPort.sendPort, (command)));
    } else if (arg2 == null) {
      _commandSender.send((returnPort.sendPort, (command, arg1)));
    } else {
      _commandSender.send((returnPort.sendPort, (command, arg1, arg2)));
    }

    var output = await returnPort.first;
    returnPort.close();
    if (output != null) {
      _downloadsLogger.severe("Exception in background command: $output");
      throw output;
    }
  }

  Future<void> deleteDownload({required DownloadStub stub}) => _sendCommand(IsarBackgroundCommands.deleteDownload, stub);

  Future<void> resyncAll() => _sendCommand(IsarBackgroundCommands.syncItem, _anchor);

  // TODO add clear download metadata option in settings?  Add some option to clear all links in settings??
  // or maybe clear all links but add warning to user about deletes occuring if server connection fails
  // or maybe provide list of nodes to be deleted to user and ask for delete confirmation?
  Future<void> repairAllDownloads() => _sendCommand(IsarBackgroundCommands.repairAll);

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

  // - first go through boxes and create nodes for all downloaded images/songs
  // then go through all downloaded parents and create anchor-attached nodes, and stitch to children/image.
  // then run standard verify all command - if it fails due to networking the
  // TODO make synchronous?  Should be slightly faster.
  Future<void> migrateFromHive() async {
    await FinampSettingsHelper.resetDefaultDownloadLocation();
    await Future.wait([
      Hive.openBox<DownloadedParent>("DownloadedParents"),
      Hive.openBox<DownloadedSong>("DownloadedItems"),
      Hive.openBox<DownloadedImage>("DownloadedImages"),
    ]);
    await _migrateImages();
    await _migrateSongs();
    await _migrateParents();
    try {
      await repairAllDownloads();
    } catch (error) {
      _downloadsLogger
          .severe("Error $error in hive migration downloads repair.");
      // TODO this should still be fine, the user can re-run verify manually later.
      // TODO we should display this somehow.
    }
    //TODO decide if we want to delete metadata here
  }

  Future<void> _migrateImages() async {
    final downloadedItemsBox = Hive.box<DownloadedSong>("DownloadedItems");
    final downloadedParentsBox =
        Hive.box<DownloadedParent>("DownloadedParents");
    final downloadedImagesBox = Hive.box<DownloadedImage>("DownloadedImages");

    List<DownloadItem> nodes = [];

    for (final image in downloadedImagesBox.values) {
      BaseItemDto baseItem;
      var hiveSong = downloadedItemsBox.get(image.requiredBy.first);
      if (hiveSong != null) {
        baseItem = hiveSong.song;
      } else {
        var hiveParent = downloadedParentsBox.get(image.requiredBy.first);
        if (hiveParent != null) {
          baseItem = hiveParent.item;
        } else {
          _downloadsLogger.severe(
              "Could not find item associated with image during migration to isar.");
          continue;
        }
      }

      var isarItem =
          DownloadStub.fromItem(type: DownloadItemType.image, item: baseItem)
              .asItem(image.downloadLocationId);
      isarItem.path = (image.downloadLocationId ==
              FinampSettingsHelper.finampSettings.internalSongDir.id)
          ? path_helper.join("songs", image.path)
          : image.path;
      isarItem.state = DownloadItemState.complete;
      nodes.add(isarItem);
    }

    await _isar.writeTxn(() async {
      await _isar.downloadItems.putAll(nodes);
      var summary =
          await _isar.downloadStatusSummarys.get(0) ?? DownloadStatusSummary();
      summary.update(
          DownloadItemState.notDownloaded, DownloadItemState.complete,
          count: nodes.length);
      await _isar.downloadStatusSummarys.put(summary);
    });
  }

  Future<void> _migrateSongs() async {
    final downloadedItemsBox = Hive.box<DownloadedSong>("DownloadedItems");

    List<DownloadItem> nodes = [];

    for (final song in downloadedItemsBox.values) {
      var isarItem =
          DownloadStub.fromItem(type: DownloadItemType.song, item: song.song)
              .asItem(song.downloadLocationId);
      String? newPath;
      if (song.downloadLocationId == null) {
        for (MapEntry<String, DownloadLocation> entry in FinampSettingsHelper
            .finampSettings.downloadLocationsMap.entries) {
          if (song.path.contains(entry.value.path)) {
            isarItem.downloadLocationId = entry.key;
            newPath = path_helper.relative(song.path, from: entry.value.path);
            break;
          }
        }
        if (newPath == null) {
          _downloadsLogger
              .severe("Could not find ${song.path} during migration to isar.");
          continue;
        }
      } else if (song.downloadLocationId ==
          FinampSettingsHelper.finampSettings.internalSongDir.id) {
        newPath = path_helper.join("songs", song.path);
      } else {
        newPath = song.path;
      }
      isarItem.path = newPath;
      isarItem.mediaSourceInfo = song.mediaSourceInfo;
      isarItem.state = DownloadItemState.complete;
      nodes.add(isarItem);
    }

    await _isar.writeTxn(() async {
      await _isar.downloadItems.putAll(nodes);
      var summary =
          await _isar.downloadStatusSummarys.get(0) ?? DownloadStatusSummary();
      summary.update(
          DownloadItemState.notDownloaded, DownloadItemState.complete,
          count: nodes.length);
      await _isar.downloadStatusSummarys.put(summary);
      for (var node in nodes) {
        if (node.baseItem?.blurHash != null) {
          var image = await _isar.downloadItems.get(DownloadStub.getHash(
              node.baseItem!.blurHash!, DownloadItemType.image));
          if (image != null) {
            await node.requires.update(link: [image]);
          }
        }
      }
    });
  }

  Future<void> _migrateParents() async {
    final downloadedParentsBox =
        Hive.box<DownloadedParent>("DownloadedParents");
    final downloadedItemsBox = Hive.box<DownloadedSong>("DownloadedItems");

    for (final parent in downloadedParentsBox.values) {
      var songId = parent.downloadedChildren.values.firstOrNull?.id;
      if (songId == null) {
        _downloadsLogger.severe(
            "Could not find item associated with parent during migration to isar.");
        continue;
      }
      var song = downloadedItemsBox.get(songId);
      if (song == null) {
        _downloadsLogger.severe(
            "Could not find item associated with parent during migration to isar.");
        continue;
      }
      var isarItem = DownloadStub.fromItem(
              type: DownloadItemType.collectionDownload, item: parent.item)
          .asItem(song.downloadLocationId);
      List<DownloadItem> required = parent.downloadedChildren.values
          .map((e) =>
              DownloadStub.fromItem(type: DownloadItemType.song, item: e)
                  .asItem(song.downloadLocationId))
          .toList();
      isarItem.orderedChildren = required.map((e) => e.isarId).toList();
      required.add(
          DownloadStub.fromItem(type: DownloadItemType.image, item: parent.item)
              .asItem(song.downloadLocationId));
      required.add(DownloadStub.fromItem(
              type: DownloadItemType.collectionInfo, item: parent.item)
          .asItem(song.downloadLocationId));
      isarItem.state = DownloadItemState.complete;

      await _isar.writeTxn(() async {
        await _isar.downloadItems.put(isarItem);
        var anchorItem = _anchor.asItem(null);
        await _isar.downloadItems.put(anchorItem);
        await anchorItem.requires.update(link: [isarItem]);
        var existing = await _isar.downloadItems
            .getAll(required.map((e) => e.isarId).toList());
        await _isar.downloadItems
            .putAll(required.toSet().difference(existing.toSet()).toList());
        isarItem.requires.addAll(required);
        await isarItem.requires.save();
      });
    }
  }

  List<DownloadItem> getUserDownloaded() => getVisibleChildren(_anchor);

  List<DownloadItem> getVisibleChildren(DownloadStub stub) {
    return _isar.downloadItems
        .where()
        .typeNotEqualTo(DownloadItemType.collectionInfo)
        .filter()
        .requiredBy((q) => q.isarIdEqualTo(stub.isarId))
        .not()
        .typeEqualTo(DownloadItemType.image)
        .findAllSync();
  }

  // TODO refactor into async?
  // TODO show downloading/failed songs as well as complete?
  List<DownloadItem> getCollectionSongs(BaseItemDto item) {
    var infoId = DownloadStub.getHash(item.id, DownloadItemType.collectionInfo);
    var downloadId =
        DownloadStub.getHash(item.id, DownloadItemType.collectionDownload);

    var query = _isar.downloadItems
        .where()
        .typeEqualTo(DownloadItemType.song)
        .filter()
        .group((q) => q
            .requires((q) => q.isarIdEqualTo(infoId))
            .or()
            .requiredBy((q) => q.isarIdEqualTo(downloadId)))
        .stateEqualTo(DownloadItemState.complete);
    if (BaseItemDtoType.fromItem(item) == BaseItemDtoType.playlist) {
      List<DownloadItem> playlist = query.findAllSync();
      var canonItem = _isar.downloadItems.getSync(
          DownloadStub.getHash(item.id, DownloadItemType.collectionDownload));
      if (canonItem?.orderedChildren == null) {
        return playlist;
      } else {
        Map<int, DownloadItem> childMap =
            Map.fromIterable(playlist, key: (e) => e.isarId);
        return canonItem!.orderedChildren!
            .map((e) => childMap[e])
            .whereNotNull()
            .toList();
      }
    } else {
      return query
          .sortByParentIndexNumber()
          .thenByBaseIndexNumber()
          .thenByName()
          .findAllSync();
    }
  }

  // TODO decide if we want to show all songs or just properly downloaded ones
  List<DownloadItem> getAllSongs({String? nameFilter}) => _getAll(
      DownloadItemType.song,
      DownloadItemState.complete,
      nameFilter,
      null,
      null);

  // TODO decide if we want all possible collections or just hard-downloaded ones.
  List<DownloadItem> getAllCollections(
          {String? nameFilter,
          BaseItemDtoType? baseTypeFilter,
          BaseItemDto? relatedTo}) =>
      _getAll(DownloadItemType.collectionInfo, null, nameFilter, baseTypeFilter,
          relatedTo);

  // TODO make async
  List<DownloadItem> _getAll(DownloadItemType type, DownloadItemState? state,
      String? nameFilter, BaseItemDtoType? baseType, BaseItemDto? relatedTo) {
    return _isar.downloadItems
        .where()
        .typeEqualTo(type)
        .filter()
        .optional(state != null, (q) => q.stateEqualTo(state!))
        .optional(nameFilter != null,
            (q) => q.nameContains(nameFilter!, caseSensitive: false))
        .optional(baseType != null, (q) => q.baseItemTypeEqualTo(baseType!))
        .optional(
            relatedTo != null,
            (q) => q.requiredBy((q) => q.requires((q) => q.isarIdEqualTo(
                DownloadStub.getHash(
                    relatedTo!.id, DownloadItemType.collectionInfo)))))
        .findAllSync();
  }

  DownloadItem? getImageDownload(BaseItemDto item) => _getDownload(
      DownloadStub.fromItem(type: DownloadItemType.image, item: item));
  DownloadItem? getSongDownload(BaseItemDto item) => _getDownload(
      DownloadStub.fromItem(type: DownloadItemType.song, item: item));
  DownloadItem? getMetadataDownload(BaseItemDto item) => _getDownload(
      DownloadStub.fromItem(type: DownloadItemType.collectionInfo, item: item));
  // Use getCollectionDownload for download buttons, getMetadataDownload elsewhere
  DownloadItem? getCollectionDownload(BaseItemDto item) => _getDownload(
      DownloadStub.fromItem(type: DownloadItemType.collectionInfo, item: item));
  DownloadItem? _getDownload(DownloadStub stub) {
    // TODO add verify download here, remove verify method.  add check method to avoid calling this for status.
    // or maybe make verification a flag?
    var item = _isar.downloadItems.getSync(stub.isarId);
    if ((item?.type.hasFiles ?? true) &&
        item?.state != DownloadItemState.complete) {
      return null;
    }
    return item;
  }

  DownloadItem? getAlbumDownloadFromSong(BaseItemDto song) {
    if (song.albumId == null) return null;
    return _isar.downloadItems.getSync(
        DownloadStub.getHash(song.albumId!, DownloadItemType.collectionInfo));
  }

  int getDownloadCount({DownloadItemType? type, DownloadItemState? state}) {
    return _isar.downloadItems
        .where()
        .optional(type != null, (q) => q.typeEqualTo(type!))
        .filter()
        .optional(state != null, (q) => q.stateEqualTo(state!))
        .countSync();
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

  Future<int> getFileSize(DownloadStub item) async {
    var canonItem = await _isar.downloadItems.get(item.isarId);
    if (canonItem == null) return 0;
    return _getFileSize(canonItem, []);
  }

  Future<int> _getFileSize(
      DownloadItem item, List<DownloadStub> completed) async {
    if (completed.contains(item)) {
      return 0;
    } else {
      completed.add(item);
    }
    int size = 0;
    for (var child in item.requires.toList()) {
      size += await _getFileSize(child, completed);
    }
    if (item.type == DownloadItemType.song &&
        item.state == DownloadItemState.complete) {
      size += item.mediaSourceInfo?.size ?? 0;
    }
    if (item.type == DownloadItemType.image && item.downloadLocation != null) {
      var statSize =
          await item.file.stat().then((value) => value.size).catchError((e) {
        _downloadsLogger
            .fine("No file for image ${item.name} when calculating size.");
        return 0;
      });
      size += statSize;
    }

    return size;
  }
}
