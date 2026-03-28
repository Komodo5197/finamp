import 'dart:async';
import 'dart:isolate';

import 'package:background_downloader/background_downloader.dart' as downloader;
import 'package:finamp/services/downloads_service/downloads_service.dart';
import 'package:finamp/services/downloads_service/downloads_service_background_orchestrator.dart';
import 'package:finamp/services/downloads_service/downloads_service_utils.dart';
import 'package:isolate_channel/isolate_channel.dart';
import 'package:logging/logging.dart';

enum DownloadsMethods {
  // TODO make this a class?
  // Takes SyncOptions
  executeSyncs(false, SyncOptions),
  // TODO Args TBD - need relevent settings passed back?
  repair(false, Null),
  // takes isarId?
  // TODO do isar work in background, only do downloader removal in foreground?
  removeQueuedDownload(true, int),
  resetConnectionErrors(false, bool),
  showConnectionError(true, Null),
  processDownloadProgress(false, downloader.TaskStatusUpdate),
  // TODO maybe increment to get around ordering issues?  Use stream or something?
  setRepairProgress(true, int),
  markOutdatedTranscodes(false, Null);

  const DownloadsMethods(this.calledFromBackground, this.argument);

  final bool calledFromBackground;
  final Type argument;
}

class DownloadsMethodChannel {
  DownloadsMethodChannel.foreground(DownloadsService service) {
    _orcestrator = null;
    _service = service;
  }

  DownloadsMethodChannel.background(IsolateMethodChannel channel) {
    _orcestrator = DownloadsServiceBackgroundOrchestrator(this);
    _service = null;
    _channel = channel;
  }

  IsolateMethodChannel? _channel;

  late final DownloadsServiceBackgroundOrchestrator? _orcestrator;

  late final DownloadsService? _service;

  Future<void> openChannel() async {
    assert(_channel == null);

    final connection = await spawnIsolate(_startIsolate);
    _channel = IsolateMethodChannel('downloader_isolate', connection);
    _channel!.setMethodCallHandler((request) {
      final method = DownloadsMethods.values.firstWhere((value) => value.name == request.method);
      return _callMethod(method, request.arguments);
    });
    final eventStream = IsolateEventChannel('logging', connection);
    eventStream.receiveBroadcastStream().listen((event) {
      print("3ZZZZZZZZZZZZZZZZZZZZZZ");
      print(event);
    });
    print("2ZZZZZZZZZZZZZZZZZZZZZZZZ");
  }

  Future<dynamic> callMethod(DownloadsMethods method, dynamic args) {
    assert(_channel != null);
    assert(method.calledFromBackground ? _orcestrator != null : _service != null);
    assert(args.runtimeType == method.argument);
    return _channel!.invokeMethod(method.name, args);
  }

  static void _startIsolate(SendPort port) {
    print("wassssuppp!!!");
    try {
      final connection = setupIsolate(port);
      final methodChannel = IsolateMethodChannel('downloader_isolate', connection);
      final logging = IsolateEventChannel('logging', connection);
      // TODO get logging working on jellyfin isolate?
      Logger.root.level = Level.ALL;
      Logger.root.onRecord.listen((event) {
        print(event);
      });
      logging.setStreamHandler(
        IsolateStreamHandler.inline(
          onListen: (_, sink) {
            sink.success("ZZZZZZZZZZZZZZZZZZZZZZZZZ");
            Logger.root.onRecord.listen((event) {
              sink.success(event);
            });
          },
        ),
      );

      // TODO complete all isolate setup

      final channel = DownloadsMethodChannel.background(methodChannel);
      methodChannel.setMethodCallHandler((request) {
        print("CCCC called ${request}");
        final method = DownloadsMethods.values.firstWhere((value) => value.name == request.method);
        return channel._callMethod(method, request.arguments);
      });
    } catch (e, trace) {
      print(e);
      print(trace);
    }
    print("finalized!");
  }

  // TODO add args to methods passing relevent data to background
  Future<void> _callMethod(DownloadsMethods method, dynamic args) {
    switch (method) {
      case DownloadsMethods.executeSyncs:
        final options = args as SyncOptions;
        return Future.sync(() async {
          try {
            if (options.isUserDelete) {
              _orcestrator!.userDeleteRunning = true;
            }
            if (options.forceFullSync) {
              _orcestrator!.forceFullSync = true;
            }
            _orcestrator!.fullSpeedSync = options.useFullSpeed;
            if (!options.deletesOnly) {
              await _orcestrator.syncBuffer.executeSyncs();
            }
            await _orcestrator.deleteBuffer.executeDeletes();
            if (options.waitFowDownloads) {
              // TODO how do we wait for downloads?  Isn't this tracked in foreground?
            }
          } finally {
            if (options.isUserDelete) {
              _orcestrator!.userDeleteRunning = false;
            }
            if (options.forceFullSync) {
              _orcestrator!.forceFullSync = false;
            }
          }
        });
      case DownloadsMethods.repair:
        return _orcestrator!.repairAllDownloads();
      case DownloadsMethods.removeQueuedDownload:
        // TODO: Handle this case.
        throw UnimplementedError();
      case DownloadsMethods.resetConnectionErrors:
        final resetFilesystemFull = args as bool;
        if (resetFilesystemFull) {
          _orcestrator!.fileSystemFull = false;
        }
        _orcestrator!.resetConnectionErrors();
        return Future.value();
      case DownloadsMethods.showConnectionError:
        // TODO: Handle this case.
        throw UnimplementedError();
      case DownloadsMethods.processDownloadProgress:
        final update = args as downloader.TaskStatusUpdate;
        _orcestrator!.handleDownloadProgress(update);
        return Future.value();
      case DownloadsMethods.setRepairProgress:
        // TODO: Handle this case.
        throw UnimplementedError();
      case DownloadsMethods.markOutdatedTranscodes:
        _orcestrator!.markOutdatedTranscodes();
        return Future.value();
    }
  }
}
