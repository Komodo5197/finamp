import 'dart:isolate';

import 'package:finamp/services/downloads_service/downloads_service_background_orchestrator.dart';
import 'package:isolate_channel/isolate_channel.dart';

enum DownloadsMethods {
  // TODO make this a class?
  // Takes SyncOptions
  executeSyncs,
  // Args TBD - need relevent settings passed back?
  repair,
  // Called from background, takes isarId?
  // TODO do isar work in background, only do downloader removal in foreground?
  removeQueuedDownload,
  // takes bool resetFilesystemFull
  resetConnectionErrors,
  showConnectionError,
  // Takes TaskStatusUpdate
  processDownloadProgress,
  // Takes int
  // TODO maybe increment to get around ordering issues?
  setRepairProgress,
  markOutdatedTranscodes,
}

class DownloadsMethodChannel {
  Future<void> openChannel() async {
    final connection = await spawnIsolate(_startIsolate);
  }

  Future<dynamic> callMethod(DownloadsMethods method, dynamic args) {
    return Future.value(null);
  }

  static void _startIsolate(SendPort port) {
    final connection = setupIsolate(port);
  }

  Future<void> _callMethod(String methodName, dynamic args) {
    DownloadsServiceBackgroundOrchestrator _orcestrator;
    final method = DownloadsMethods.values.firstWhere((value) => value.name == methodName);
    switch (method) {
      case DownloadsMethods.executeSyncs:
        // TODO: Handle this case.
        throw UnimplementedError();
      case DownloadsMethods.repair:
        // TODO: Handle this case.
        throw UnimplementedError();
      case DownloadsMethods.removeQueuedDownload:
        // TODO: Handle this case.
        throw UnimplementedError();
      case DownloadsMethods.resetConnectionErrors:
        // TODO: Handle this case.
        throw UnimplementedError();
      case DownloadsMethods.showConnectionError:
        // TODO: Handle this case.
        throw UnimplementedError();
      case DownloadsMethods.processDownloadProgress:
        // TODO: Handle this case.
        throw UnimplementedError();
      case DownloadsMethods.setRepairProgress:
        // TODO: Handle this case.
        throw UnimplementedError();
      case DownloadsMethods.markOutdatedTranscodes:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }
}
