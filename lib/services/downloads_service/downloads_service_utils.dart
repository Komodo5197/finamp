import 'dart:convert';
import 'dart:io';

// The actual FileDownloaderClass should not be used from this file
import 'package:background_downloader/background_downloader.dart' as downloader;
import 'package:collection/collection.dart';
import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path_helper;

import '../../models/finamp_models.dart';
import '../../models/jellyfin_models.dart';

part 'downloads_service_utils.g.dart';

/// This determines the target directory for new downloads, during migrations from the old download system, and during repairs.
/// Must not be changed without migrations. Additionally, directory cleaning in downloads repair should cover all folders ever used.
const FINAMP_BASE_DOWNLOAD_DIRECTORY = "songs";

const FINAMP_BASE_IMAGES_DIRECTORY = "images";

final anchor = DownloadStub.fromId(id: BaseItemId("Anchor"), type: DownloadItemType.anchor, name: null);

/// A wrapper for storing various types of download related data in isar as JSON.
/// Do not confuse the id of this type with the ids that the content types have.
/// They will not match.
@collection
class IsarTaskData<T> {
  IsarTaskData(this.id, this.type, this.jsonData, this.age);

  /// Id of IsarTaskData.  Do not confuse with id of DownloadItem.
  final Id id;
  String jsonData;
  @Enumerated(EnumType.ordinal)
  @Index()
  final IsarTaskDataType<T> type;

  // This allows prioritization and uniqueness checking by delete buffer
  // It is also used as a retry counter by sync buffer.
  final int age;

  static int globalAge = 0;

  IsarTaskData.build(String stringId, this.type, T data, {int? age})
    : id = IsarTaskData.getHash(type, stringId),
      jsonData = _toJson(data),
      age = age ?? globalAge++;

  static int getHash(IsarTaskDataType type, String id) => _fastHash(type.name + id);

  @ignore
  T get data => type.fromJson(jsonDecode(jsonData) as Map<String, dynamic>);

  set data(T item) => jsonData = _toJson(item);

  static String _toJson(dynamic item) {
    switch (item) {
      case int id:
        return jsonEncode({"id": id});
      case _:
        return jsonEncode((item as dynamic).toJson());
    }
  }

  /// FNV-1a 64bit hash algorithm optimized for Dart Strings
  /// Provided by Isar documentation
  /// Do not use directly, use getHash
  static int _fastHash(String string) {
    var hash = 0xcbf29ce484222325;

    var i = 0;
    while (i < string.length) {
      final codeUnit = string.codeUnitAt(i++);
      hash ^= codeUnit >> 8;
      hash *= 0x100000001b3;
      hash ^= codeUnit & 0xFF;
      hash *= 0x100000001b3;
    }

    return hash;
  }

  @override
  bool operator ==(Object other) {
    return other is IsarTaskData && other.id == id;
  }

  @override
  @ignore
  int get hashCode => id;
}

/// Type enum for IsarTaskData
/// Enumerated by Isar, do not modify order or delete existing entries.
enum IsarTaskDataType<T> {
  pausedTask<downloader.Task>(downloader.Task.createFromJson),
  taskRecord<downloader.TaskRecord>(downloader.TaskRecord.fromJson),
  resumeData<downloader.ResumeData>(downloader.ResumeData.fromJson),
  deleteNode<int>(_deleteFromJson),
  syncNode<SyncNode>(SyncNode.fromJson);

  const IsarTaskDataType(this.fromJson);

  static int _deleteFromJson(Map<String, dynamic> map) {
    return map["id"] as int;
  }

  final T Function(Map<String, dynamic>) fromJson;

  void check(T data) {}
}

// These could be called from either the foreground or the background
// TODO make foreground/background orchestrators extend this
class SyncUtils {
  final _downloadsLogger = Logger("downloadsSyncUtils");
  final _isar = GetIt.instance<Isar>();

  SyncUtils(this._orchestrator);

  final DownloadOrchestrator _orchestrator;

  /// Updates the state of a DownloadItem and inserts into Isar.  If the state changed,
  /// the downloads status stream is updated and any parent items that may have changed
  /// state are recalculated.
  /// This should only be called inside an isar write transaction.
  void updateItemState(DownloadItem item, DownloadItemState newState, {bool alwaysPut = false}) {
    if (item.state == newState) {
      if (alwaysPut) {
        _isar.downloadItems.putSync(item, saveLinks: false);
      }
    } else {
      if (item.type.hasFiles) {
        _orchestrator.updateDownloadStatuses(increment: newState, decrement: item.state);
      } else {
        if (item.state == DownloadItemState.syncFailed) {
          _orchestrator.updateDownloadStatuses(decrement: item.state);
        } else if (newState == DownloadItemState.syncFailed) {
          _orchestrator.updateDownloadStatuses(increment: newState);
        }
      }
      item.state = newState;
      _isar.downloadItems.putSync(item, saveLinks: false);
      List<DownloadItem> parents = _isar.downloadItems
          .where()
          .typeNotEqualTo(DownloadItemType.track)
          .filter()
          .requires((q) => q.isarIdEqualTo(item.isarId))
          .or()
          .info((q) => q.isarIdEqualTo(item.isarId))
          .findAllSync();
      for (var parent in parents) {
        syncItemState(parent);
      }
    }
  }

  /// Syncs the download state of a collection based on the states of its children.
  /// Non-required artists/genres may have unknown non-downloaded children and thus
  /// are always considered not downloaded.
  /// This should only be called inside an isar write transaction.
  void syncItemState(DownloadItem item, {bool removeSyncFailed = false}) {
    if (item.type.hasFiles) return;
    if (item.state == DownloadItemState.syncFailed && !removeSyncFailed) return;
    Set<DownloadItemState> childStates = {};
    if (item.baseItemType == BaseItemDtoType.album || item.baseItemType == BaseItemDtoType.playlist) {
      // Use full list of tracks in info links for album/playlist
      childStates.addAll(
        item.info
            .filter()
            .typeEqualTo(DownloadItemType.track)
            .or()
            .typeEqualTo(DownloadItemType.image)
            .distinctByState()
            .stateProperty()
            .findAllSync(),
      );
    } else {
      // Non-required artists/genres have unknown children and should never be considered downloaded.
      if (item.requiredBy.filter().countSync() == 0) {
        return updateItemState(item, DownloadItemState.notDownloaded);
      }
      childStates.addAll(item.requires.filter().distinctByState().stateProperty().findAllSync());
      // playlist metadata info links collections which are not nessecarilly downloaded,
      // and should still be considered downloaded.
      if (item.finampCollection?.type != FinampCollectionType.allPlaylistsMetadata) {
        // add dependency on image in info links
        childStates.addAll(item.info.filter().distinctByState().stateProperty().findAllSync());
      }
    }
    if (childStates.contains(DownloadItemState.notDownloaded)) {
      return updateItemState(item, DownloadItemState.notDownloaded);
    } else if (childStates.contains(DownloadItemState.failed) || childStates.contains(DownloadItemState.syncFailed)) {
      return updateItemState(item, DownloadItemState.failed);
    } else if (childStates.contains(DownloadItemState.enqueued) ||
        childStates.contains(DownloadItemState.downloading)) {
      // DownloadItemState.enqueued should only be reachable via _initiateDownload
      return updateItemState(item, DownloadItemState.downloading);
    } else {
      return updateItemState(item, DownloadItemState.complete);
    }
  }

  /// Sync the downloadLocationId and transcodingProfile to match those of the items
  /// parent.  If there are multiple required parents with different values, the download
  /// location and transcode settings with the highest quality are selected.  If syncImages
  /// is true, update info along info links to validate download locations for images.
  /// Otherwise, only update required items.
  /// This should only be called inside an isar write transaction.
  void syncItemDownloadSettings(DownloadItem item, {bool syncImages = false}) {
    var transcodeProfiles = item.requiredBy.filter().syncTranscodingProfileProperty().findAllSync();
    bool requireProfile = true;
    transcodeProfiles.add(item.userTranscodingProfile);
    if (transcodeProfiles.nonNulls.isEmpty) {
      if (syncImages) {
        transcodeProfiles = item.infoFor.filter().syncTranscodingProfileProperty().findAllSync();
        requireProfile = false;
      } else {
        _downloadsLogger.severe("Attempting to sync download settings for non-required item ${item.name}");
        return;
      }
    }
    bool? doNullUpdate;
    if (transcodeProfiles.nonNulls.isEmpty) {
      if (requireProfile) {
        _downloadsLogger.severe("No valid download profiles for required item ${item.name}");
        return;
      } else {
        doNullUpdate = item.syncDownloadLocation != null;
      }
    }

    // Prioritize original quality if allowed, otherwise choose highest quality approximation
    DownloadProfile? bestProfile = transcodeProfiles.nonNulls
        .sorted((i, j) => ((j.quality - i.quality) * 1000).toInt())
        .firstOrNull;
    if (doNullUpdate ??
        (!transcodeProfiles.nonNulls.contains(item.syncTranscodingProfile) ||
            (bestProfile!.quality > (item.syncTranscodingProfile!.quality + 2000) &&
                item.type != DownloadItemType.image))) {
      _downloadsLogger.finest("Updating download settings for ${item.name}");
      item.syncTranscodingProfile = bestProfile;
      if ((item.state == DownloadItemState.enqueued ||
              item.state == DownloadItemState.downloading ||
              item.state == DownloadItemState.complete) &&
          item.type.hasFiles &&
          _orchestrator.shouldRedownloadTranscodes) {
        if (item.state == DownloadItemState.complete) {
          updateItemState(item, DownloadItemState.needsRedownloadComplete, alwaysPut: true);
        } else {
          updateItemState(item, DownloadItemState.needsRedownload, alwaysPut: true);
        }
        addSyncs([item.isarId], <int>[], null);
      } else {
        _isar.downloadItems.putSync(item, saveLinks: false);
      }
      var children = item.requires.filter().findAllSync();
      if (syncImages) {
        children = children.toSet().union(item.info.filter().findAllSync().toSet()).toList();
      }
      for (var child in children) {
        syncItemDownloadSettings(child, syncImages: syncImages);
      }
    }
  }

  /// Add nodes to be deleted at a later time.  This should
  /// be called before nodes are unlinked to guarantee nodes cannot be lost.
  /// This should only be called inside an isar write transaction
  void addDeletes(Iterable<int> isarIds) {
    var items = isarIds.map((e) => IsarTaskData.build(e.toString(), IsarTaskDataType.deleteNode, e)).toList();
    _isar.isarTaskDatas.putAllSync(items, saveLinks: false);
  }

  /// Add nodes to be synced at a later time.
  /// Must be called inside an Isar write transaction.
  void addSyncs(Iterable<int> required, Iterable<int> info, BaseItemId? viewId) {
    var items = required
        .map(
          (e) => IsarTaskData.build(
            "required $e",
            IsarTaskDataType.syncNode,
            SyncNode(stubIsarId: e, required: true, viewId: viewId),
            age: 0,
          ),
        )
        .toList();
    items.addAll(
      info.map(
        (e) => IsarTaskData.build(
          "info $e",
          IsarTaskDataType.syncNode,
          SyncNode(stubIsarId: e, required: false, viewId: viewId),
          age: 1,
        ),
      ),
    );
    _isar.isarTaskDatas.putAllSync(items, saveLinks: false);
  }

  /// Verify a download is complete and the associated file exists.  Update
  /// the item to be notDownloaded otherwise.  Used by [gettrackDownload] and
  /// [getImageDownload].
  bool verifyDownload(DownloadItem item) {
    assert(item.type.hasFiles);
    if (!item.state.isComplete) return false;
    if (item.file?.existsSync() ?? false) return true;
    if (item.path != null) {
      for (var location in _orchestrator.getDownloadLocationsMap.values) {
        var path = path_helper.join(location.currentPath, item.path);
        if (File(path).existsSync()) {
          _isar.writeTxnSync(() {
            var canonItem = _isar.downloadItems.getSync(item.isarId);
            canonItem!.fileTranscodingProfile!.downloadLocationId = location.id;
            _isar.downloadItems.putSync(canonItem, saveLinks: false);
          });
          _downloadsLogger.info("${item.name} found in unexpected location ${location.name}");
          return true;
        }
      }
    }
    _isar.writeTxnSync(() {
      var canonItem = _isar.downloadItems.getSync(item.isarId);
      if (canonItem != null) {
        updateItemState(canonItem, DownloadItemState.notDownloaded);
      }
    });
    _downloadsLogger.info("${item.name} failed download verification, not located at ${item.file?.path}.");
    return false;
  }
}

class MissingServerItemException implements Exception {
  MissingServerItemException(this.item);

  final DownloadStub item;

  @override
  String toString() {
    return "MissingServerItemException(id: ${item.id}, name:${item.name})";
  }
}

@JsonSerializable(explicitToJson: true, anyMap: true, converters: [BaseItemIdConverter()])
class SyncNode {
  SyncNode({required this.stubIsarId, required this.required, required this.viewId});

  int stubIsarId;
  bool required;
  BaseItemId? viewId;

  factory SyncNode.fromJson(Map<String, dynamic> json) => _$SyncNodeFromJson(json);

  Map<String, dynamic> toJson() => _$SyncNodeToJson(this);
}

abstract class DownloadOrchestrator {
  void updateDownloadStatuses({DownloadItemState? increment, DownloadItemState? decrement});
  bool get shouldRedownloadTranscodes;
  Map<String, DownloadLocation> get getDownloadLocationsMap;
}

class SyncOptions {
  SyncOptions({
    this.deletesOnly = false,
    this.isUserDelete = false,
    required this.waitFowDownloads,
    this.useFullSpeed = false,
    this.forceFullSync = false,
  }) : assert(isUserDelete == false || deletesOnly);

  final bool deletesOnly;
  final bool isUserDelete;
  final bool waitFowDownloads;
  final bool useFullSpeed;
  final bool forceFullSync;
}
