import 'dart:async';
import 'dart:convert';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/scheduler.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:isar/isar.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path_helper;

import '../../models/finamp_models.dart';
import '../../models/jellyfin_models.dart';
import '../finamp_settings_helper.dart';
import '../finamp_user_helper.dart';
import '../jellyfin_api_helper.dart';
import 'downloads_service_utils.dart';

/// This is a TaskQueue for FileDownloader that enqueues DownloadItems that are in
/// enqueued state.They should already have the file path calculated.
class IsarTaskQueue implements TaskQueue {
  static final _enqueueLog = Logger('IsarTaskQueue');
  final _jellyfinApiData = GetIt.instance<JellyfinApiHelper>();
  final _finampUserHelper = GetIt.instance<FinampUserHelper>();
  final SyncUtils _utils;

  IsarTaskQueue(this._utils);

  /// Set of tasks that are believed to be actively running
  final _activeDownloads = <int>{}; // by TaskId

  Completer<void>? _callbacksComplete;

  final _isar = GetIt.instance<Isar>();

  // TODO add way for this to be updated from background?  or fetch from background instead
  // maybe we should switch to holding queue and use pause/resumeAll?
  bool _allowDownloads = true;

  /// Initialize the queue and start stored downloads.
  /// Should only be called after background_downloader and downloadsService are
  /// fully set up.
  Future<void> initializeQueue() async {
    _activeDownloads.addAll(
      (await FileDownloader().allTasks(includeTasksWaitingToRetry: true)).map((e) => int.parse(e.taskId)),
    );
    List<DownloadItem> completed = [];
    List<DownloadItem> needsEnqueue = [];
    for (var item
        in _isar.downloadItems
            .where()
            .stateEqualTo(DownloadItemState.enqueued)
            .or()
            .stateEqualTo(DownloadItemState.downloading)
            .filter()
            .typeEqualTo(DownloadItemType.track)
            .or()
            .typeEqualTo(DownloadItemType.image)
            .findAllSync()) {
      if (item.file?.existsSync() ?? false) {
        _activeDownloads.remove(item.isarId);
        completed.add(item);
      } else if (item.state == DownloadItemState.downloading) {
        if (!_activeDownloads.contains(item.isarId)) {
          needsEnqueue.add(item);
        }
      }
    }
    _isar.writeTxnSync(() {
      // Images marked as completed this way will not recieve updated extensions like ones
      // processed in status updates, but that's not really important
      for (var item in completed) {
        _utils.updateItemState(item, DownloadItemState.complete);
        _enqueueLog.info("Marking download ${item.name} as complete on startup.");
      }
      for (var item in needsEnqueue) {
        _utils.updateItemState(item, DownloadItemState.enqueued);
        _enqueueLog.info("Re-enqueueing download ${item.name} on startup.");
      }
    });
  }

  /// Execute all pending downloads.
  Future<void> executeDownloads() async {
    if (_callbacksComplete != null) {
      return _callbacksComplete!.future;
    }
    try {
      _callbacksComplete = Completer();
      unawaited(_advanceQueue());
      await _callbacksComplete!.future;
      _enqueueLog.info("All downloads enqueued.");
    } finally {
      _callbacksComplete = null;
    }
  }

  /// Advance the queue if possible and ready, no-op if not.
  /// Will loop until all downloads have been enqueued.  Will enqueue
  /// finampSettings.maxConcurrentDownloads at once.
  Future<void> _advanceQueue() async {
    try {
      while (true) {
        var nextTasks = _isar.downloadItems
            .where()
            .stateEqualTo(DownloadItemState.enqueued)
            .filter()
            .allOf(_activeDownloads, (q, element) => q.not().isarIdEqualTo(element))
            .limit(20)
            .findAllSync();
        if (nextTasks.isEmpty || !_allowDownloads || FinampSettingsHelper.finampSettings.isOffline) {
          return;
        }
        for (var task in nextTasks) {
          if (task.file == null) {
            _enqueueLog.severe("Received ${task.name} with no valid file path.");
            _isar.writeTxnSync(() {
              _utils.updateItemState(task, DownloadItemState.failed);
            });
            continue;
          }
          while (_activeDownloads.length >= FinampSettingsHelper.finampSettings.maxConcurrentDownloads ||
              _finampUserHelper.currentUser == null) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
          await SchedulerBinding.instance.scheduleTask(() {
            _activeDownloads.add(task.isarId);
            try {
              // Base URL shouldn't be null at this point (user has to be logged in
              // to get to the point where they can add downloads).
              var url = switch (task.type) {
                DownloadItemType.track =>
                  _jellyfinApiData
                      .getTrackDownloadUrl(item: task.baseItem!, transcodingProfile: task.fileTranscodingProfile)
                      .toString(),
                DownloadItemType.image =>
                  _jellyfinApiData
                      .getImageUrl(
                        item: task.baseItem!,
                        // Download original file
                        quality: null,
                        format: null,
                      )
                      .toString(),
                _ => throw StateError("Invalid enqueue ${task.name} which is a ${task.type}"),
              };
              _enqueueLog.fine("Submitting download ${task.name} to background_downloader.");
              var downloadTask = DownloadTask(
                taskId: task.isarId.toString(),
                url: url,
                displayName: task.name,
                baseDirectory: task.fileDownloadLocation!.baseDirectory.baseDirectory,
                retries: 3,
                directory: path_helper.dirname(task.path!),
                headers: {"Authorization": _finampUserHelper.authorizationHeader},
                filename: path_helper.basename(task.path!),
              );
              return Future.sync(() async {
                //bool success = await FileDownloader().resume(downloadTask);
                //if (!success) {
                bool success = await FileDownloader().enqueue(downloadTask);
                //}
                if (!success) {
                  // We currently have no way to recover here.  The user must re-sync to clear
                  // the stuck download.
                  _enqueueLog.severe("Task ${task.name} failed to enqueue with background_downloader.");
                }
              });
            } catch (e) {
              _enqueueLog.severe("Error creating download task for ${task.name}: $e.", e);
              _isar.writeTxnSync(() {
                _utils.updateItemState(task, DownloadItemState.failed);
              });
            }
            // Set priority high to prevent stalling
          }, Priority.animation + 50);
          // This helps prevent choking the method channel, see MemoryTaskQueue
          await Future.delayed(const Duration(milliseconds: 20));
        }
      }
    } finally {
      _callbacksComplete?.complete();
    }
  }

  /// Returns true if the internal queue state and downloader state match
  /// the state of the given item.  Download state should be reset if false.
  Future<bool> validateQueued(DownloadItem item) async {
    if (item.state == DownloadItemState.downloading || _activeDownloads.contains(item.isarId)) {
      var activeTasks = await FileDownloader().allTasks(includeTasksWaitingToRetry: true);
      var activeItemIds = activeTasks.map((e) => int.parse(e.taskId)).toList();
      if (!activeItemIds.contains(item.isarId)) {
        return false;
      }
    }
    return true;
  }

  /// Remove a download task from this queue and cancel any active download.
  Future<void> remove(DownloadItem item) async {
    if (item.state == DownloadItemState.enqueued || item.state == DownloadItemState.downloading) {
      _isar.writeTxnSync(() {
        var canonItem = _isar.downloadItems.getSync(item.isarId);
        if (canonItem != null) {
          _utils.updateItemState(canonItem, DownloadItemState.notDownloaded);
        }
      });
    }
    if (_activeDownloads.contains(item.isarId)) {
      _activeDownloads.remove(item.isarId);
      await FileDownloader().cancelTaskWithId(item.isarId.toString());
    }
  }

  /// Called by FileDownloader whenever a download completes.
  /// Remove the completed task and allow the queue to advance.
  @override
  void taskFinished(Task task) {
    _activeDownloads.remove(int.parse(task.taskId));
  }

  // We do not currently pause or resume the downloads
  @override
  Future<void> pauseAll({Iterable<DownloadTask>? tasks, String? group}) async {}
  @override
  Future<void> resumeAll({Iterable<DownloadTask>? tasks, String? group}) async {}
}

class DownloadMigrationSteps {
  final _isar = GetIt.instance<Isar>();
  final _downloadsLogger = Logger("downloadsMigrationService");
  final DownloadStub _anchor;
  final DownloadOrchestrator _orchestrator;

  DownloadMigrationSteps(this._anchor, this._orchestrator);

  /// Substep 1 of [migrateFromHive].
  void migrateImages() {
    _downloadsLogger.info("Migrating images from Hive");
    // ignore: deprecated_member_use_from_same_package
    final downloadedItemsBox = Hive.box<DownloadedTrack>("DownloadedItems");
    final downloadedParentsBox =
        // ignore: deprecated_member_use_from_same_package
        Hive.box<DownloadedParent>("DownloadedParents");
    // ignore: deprecated_member_use_from_same_package
    final downloadedImagesBox = Hive.box<DownloadedImage>("DownloadedImages");

    List<DownloadItem> nodes = [];

    for (final image in downloadedImagesBox.values) {
      BaseItemDto baseItem;
      var hiveTrack = downloadedItemsBox.get(image.requiredBy.first);
      if (hiveTrack != null) {
        baseItem = hiveTrack.track;
      } else {
        var hiveParent = downloadedParentsBox.get(image.requiredBy.first);
        if (hiveParent != null) {
          baseItem = hiveParent.item;
        } else {
          _downloadsLogger.severe("Could not find item associated with image during migration to isar.");
          continue;
        }
      }

      var isarItem = DownloadStub.fromItem(
        type: DownloadItemType.image,
        item: baseItem,
      ).asItem(DownloadProfile(downloadLocationId: image.downloadLocationId));
      isarItem.path =
          (image.downloadLocationId ==
              FinampSettingsHelper.finampSettings.downloadLocationsMap.values
                  .where((element) => element.baseDirectory == DownloadLocationType.internalDocuments)
                  .first
                  .id)
          ? path_helper.join(FINAMP_BASE_DOWNLOAD_DIRECTORY, image.path)
          : image.path;
      isarItem.state = DownloadItemState.complete;
      isarItem.fileTranscodingProfile = DownloadProfile(downloadLocationId: image.downloadLocationId);
      nodes.add(isarItem);
      _orchestrator.updateDownloadStatuses(increment: DownloadItemState.complete);
    }

    _isar.writeTxnSync(() {
      _isar.downloadItems.putAllSync(nodes, saveLinks: false);
    });
  }

  /// Substep 2 of [migrateFromHive].
  void migrateTracks() {
    _downloadsLogger.info("Migrating tracks from Hive");
    // ignore: deprecated_member_use_from_same_package
    final downloadedItemsBox = Hive.box<DownloadedTrack>("DownloadedItems");

    List<DownloadItem> nodes = [];

    for (final track in downloadedItemsBox.values) {
      var baseItem = track.track;
      baseItem.mediaSources = [track.mediaSourceInfo];
      var isarItem = DownloadStub.fromItem(type: DownloadItemType.track, item: baseItem).asItem(
        DownloadProfile(transcodeCodec: FinampTranscodingCodec.original, downloadLocationId: track.downloadLocationId),
      );
      String? newPath;
      if (track.downloadLocationId == null) {
        for (MapEntry<String, DownloadLocation> entry
            in FinampSettingsHelper.finampSettings.downloadLocationsMap.entries) {
          if (track.path.contains(entry.value.currentPath)) {
            isarItem.fileTranscodingProfile = DownloadProfile(
              transcodeCodec: FinampTranscodingCodec.original,
              downloadLocationId: entry.key,
            );
            newPath = path_helper.relative(track.path, from: entry.value.currentPath);
            break;
          }
        }
        if (newPath == null) {
          _downloadsLogger.severe("Could not find ${track.path} during migration to isar.");
          continue;
        }
      } else {
        isarItem.fileTranscodingProfile = DownloadProfile(
          transcodeCodec: FinampTranscodingCodec.original,
          downloadLocationId: track.downloadLocationId,
        );
        if (track.downloadLocationId ==
            FinampSettingsHelper.finampSettings.downloadLocationsMap.values
                .where((element) => element.baseDirectory == DownloadLocationType.internalDocuments)
                .first
                .id) {
          newPath = path_helper.join(FINAMP_BASE_DOWNLOAD_DIRECTORY, track.path);
        } else {
          newPath = track.path;
        }
      }
      isarItem.path = newPath;
      isarItem.state = DownloadItemState.complete;
      isarItem.viewId = BaseItemId(track.viewId);
      nodes.add(isarItem);
      _orchestrator.updateDownloadStatuses(increment: DownloadItemState.complete);
    }

    _isar.writeTxnSync(() {
      _isar.downloadItems.putAllSync(nodes, saveLinks: false);
      for (var node in nodes) {
        if (node.baseItem?.blurHash != null) {
          var image = _isar.downloadItems.getSync(
            DownloadStub.getHash(node.baseItem!.blurHash!, DownloadItemType.image),
          );
          if (image != null) {
            node.requires.updateSync(link: [image]);
          }
        }
      }
    });
  }

  /// Substep 3 of [migrateFromHive].
  void migrateParents() {
    _downloadsLogger.info("Migrating parents from Hive");
    final downloadedParentsBox =
        // ignore: deprecated_member_use_from_same_package
        Hive.box<DownloadedParent>("DownloadedParents");
    // ignore: deprecated_member_use_from_same_package
    final downloadedItemsBox = Hive.box<DownloadedTrack>("DownloadedItems");

    for (final parent in downloadedParentsBox.values) {
      var trackId = parent.downloadedChildren.values.firstOrNull?.id;
      if (trackId == null) {
        _downloadsLogger.severe("Could not find item associated with parent during migration to isar.");
        continue;
      }
      var track = downloadedItemsBox.get(trackId);
      if (track == null) {
        _downloadsLogger.severe("Could not find item associated with parent during migration to isar.");
        continue;
      }
      var isarItem = DownloadStub.fromItem(type: DownloadItemType.collection, item: parent.item).asItem(
        DownloadProfile(transcodeCodec: FinampTranscodingCodec.original, downloadLocationId: track.downloadLocationId),
      );
      isarItem.userTranscodingProfile = DownloadProfile(
        transcodeCodec: FinampTranscodingCodec.original,
        downloadLocationId: track.downloadLocationId,
      );
      // This should only be used for IDs/links and does not need real download items.
      List<DownloadItem> required = parent.downloadedChildren.values
          .map((e) => DownloadStub.fromItem(type: DownloadItemType.track, item: e).asItem(null))
          .toList();
      isarItem.orderedChildren = required.map((e) => e.isarId).toList();

      if (parent.item.blurHash != null || parent.item.imageId != null) {
        required.add(DownloadStub.fromItem(type: DownloadItemType.image, item: parent.item).asItem(null));
      }

      isarItem.state = DownloadItemState.complete;
      if (isarItem.baseItemType != BaseItemDtoType.playlist) {
        isarItem.viewId = BaseItemId(parent.viewId);
      }

      _isar.writeTxnSync(() {
        _isar.downloadItems.putSync(isarItem, saveLinks: false);
        var anchorItem = _anchor.asItem(null);
        _isar.downloadItems.putSync(anchorItem, saveLinks: false);
        anchorItem.requires.updateSync(link: [isarItem]);
        var existing = _isar.downloadItems.getAllSync(required.map((e) => e.isarId).toList());
        _isar.downloadItems.putAllSync(required.toSet().difference(existing.toSet()).toList(), saveLinks: false);
        isarItem.requires.addAll(required);
        isarItem.requires.saveSync();
        isarItem.info.addAll(required);
        isarItem.info.saveSync();
      });
    }
  }
}

class IsarPersistentStorage implements PersistentStorage {
  final _isar = GetIt.instance<Isar>();

  @override
  Future<void> storeTaskRecord(TaskRecord record) => _store(IsarTaskDataType.taskRecord, record.taskId, record);

  @override
  Future<TaskRecord?> retrieveTaskRecord(String taskId) => _get(IsarTaskDataType.taskRecord, taskId);

  @override
  Future<List<TaskRecord>> retrieveAllTaskRecords() => _getAll(IsarTaskDataType.taskRecord);

  @override
  Future<void> removeTaskRecord(String? taskId) => _remove(IsarTaskDataType.taskRecord, taskId);

  @override
  Future<void> storePausedTask(Task task) => _store(IsarTaskDataType.pausedTask, task.taskId, task);

  @override
  Future<Task?> retrievePausedTask(String taskId) => _get(IsarTaskDataType.pausedTask, taskId);

  @override
  Future<List<Task>> retrieveAllPausedTasks() => _getAll(IsarTaskDataType.pausedTask);

  @override
  Future<void> removePausedTask(String? taskId) => _remove(IsarTaskDataType.pausedTask, taskId);

  @override
  Future<void> storeResumeData(ResumeData resumeData) =>
      _store(IsarTaskDataType.resumeData, resumeData.taskId, resumeData);

  @override
  Future<ResumeData?> retrieveResumeData(String taskId) => _get(IsarTaskDataType.resumeData, taskId);

  @override
  Future<List<ResumeData>> retrieveAllResumeData() => _getAll(IsarTaskDataType.resumeData);

  @override
  Future<void> removeResumeData(String? taskId) => _remove(IsarTaskDataType.resumeData, taskId);

  @override
  (String, int) get currentDatabaseVersion => ("FinampIsar", 1);

  @override
  // This should come from finamp settings if migration needed
  Future<(String, int)> get storedDatabaseVersion => Future.value(("FinampIsar", 1));

  @override
  Future<void> initialize() async {
    // Isar database gets opened by main
  }

  Future<void> _store(IsarTaskDataType type, String id, dynamic data) async {
    type.check(data); // Verify the data object has the correct type
    String json = jsonEncode(data.toJson());
    _isar.writeTxnSync(() {
      _isar.isarTaskDatas.putSync(IsarTaskData(IsarTaskData.getHash(type, id), type, json, 0), saveLinks: false);
    });
  }

  Future<T?> _get<T>(IsarTaskDataType<T> type, String id) async {
    var item = _isar.isarTaskDatas.getSync(IsarTaskData.getHash(type, id));
    return (item == null) ? null : type.fromJson(jsonDecode(item.jsonData) as Map<String, dynamic>);
  }

  Future<List<T>> _getAll<T>(IsarTaskDataType<T> type) async {
    var items = _isar.isarTaskDatas.where().typeEqualTo(type).findAllSync();
    return items.map((e) => type.fromJson(jsonDecode(e.jsonData) as Map<String, dynamic>)).toList();
  }

  Future<void> _remove(IsarTaskDataType type, String? id) async {
    _isar.writeTxnSync(() {
      if (id != null) {
        _isar.isarTaskDatas.deleteSync(IsarTaskData.getHash(type, id));
      } else {
        _isar.isarTaskDatas.where().typeEqualTo(type).deleteAllSync();
      }
    });
  }
}
