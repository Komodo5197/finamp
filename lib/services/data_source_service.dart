import 'dart:core';

import 'package:finamp/components/global_snackbar.dart';
import 'package:finamp/components/MusicScreen/music_screen_tab_view.dart';
import 'package:finamp/l10n/app_localizations.dart';
import 'package:finamp/services/finamp_user_helper.dart';
import 'package:finamp/services/queue_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';

import 'finamp_settings_helper.dart';

Logger _dataSourceServiceLogger = Logger("Data Source Service");

enum SourceChangeGenericType { network, transcoding }

enum SourceChangeType { toLocalUrl, toRemoteUrl, toOffline, toOnline, toDirectPlay, toTranscoding }

class DataSourceService {
  // Android can briefly report no transport between Wi-Fi and mobile data.
  // Keep an automatic queue reload pending through that gap so it runs only
  // once a usable transport has returned.
  static bool _networkAvailable = true;
  static bool _networkQueueReloadPending = false;
  static bool _networkContentRefreshPending = false;

  /// A source change is emitted by a provider and can arrive while Flutter is
  /// building a frame.  Reloading the queue may fetch items from Jellyfin, so
  /// postpone that work until the frame has completed.
  static Future<void> _reloadQueueAfterFrame(QueueService queueService) async {
    await SchedulerBinding.instance.endOfFrame;
    await queueService.reloadQueue();
  }

  /// Refreshes failed Home/search providers only after the new background HTTP
  /// client is ready.  Existing requests may have failed in Android's short
  /// no-transport interval and Riverpod otherwise keeps that error displayed.
  static Future<void> _refreshOnlineContentAfterFrame() async {
    await SchedulerBinding.instance.endOfFrame;
    musicScreenRefreshStream.add(null);
  }

  /// Called by the network manager after every connectivity event. Source
  /// changes may happen while Android is between transports; in that case a
  /// queue reload would inevitably fail and otherwise would not be retried
  /// when the public route comes up.
  static Future<void> setNetworkAvailable(bool networkAvailable, {bool sourceChanged = false}) async {
    final networkRecovered = !_networkAvailable && networkAvailable;
    _networkAvailable = networkAvailable;

    if (!networkRecovered) return;

    // When the endpoint itself changed, its provider notification will reload
    // the queue and refresh the UI shortly. Keep pending markers until that
    // notification so the same handoff cannot trigger duplicate work.
    if (sourceChanged) return;

    final reloadQueue = _networkQueueReloadPending;
    final refreshContent = _networkContentRefreshPending;
    _networkQueueReloadPending = false;
    _networkContentRefreshPending = false;

    if (reloadQueue &&
        FinampSettingsHelper.finampSettings.autoReloadQueue &&
        GetIt.instance.isRegistered<QueueService>()) {
      final queueService = GetIt.instance<QueueService>();
      final queueInfo = queueService.getQueue();
      if (queueInfo.trackCount > 0 && queueInfo.undownloadedTracks > 0) {
        _dataSourceServiceLogger.info("Retrying queued reload after network recovery");
        await _reloadQueueAfterFrame(queueService);
      }
    }

    if (refreshContent) {
      _dataSourceServiceLogger.info("Refreshing Home and search after network recovery");
      await _refreshOnlineContentAfterFrame();
    }
  }

  static void create() {
    final FinampUserHelper finampUserHelper = GetIt.instance<FinampUserHelper>();
    final ref = GetIt.instance<ProviderContainer>();

    ref.listen(finampSettingsProvider.isOffline, (_, isOffline) {
      if (isOffline) {
        _dataSourceServiceLogger.info("Offline Mode Enabled");
      } else {
        _dataSourceServiceLogger.info("Offline Mode Disabled");
      }
      _onDataSourceChange(isOffline ? SourceChangeType.toOffline : SourceChangeType.toOnline);
    });

    ref.listen(finampSettingsProvider.shouldTranscode, (_, shouldTranscode) {
      if (shouldTranscode) {
        _dataSourceServiceLogger.info("Transcoding Enabled");
      } else {
        _dataSourceServiceLogger.info("Transcoding Disabled");
      }
      _onDataSourceChange(shouldTranscode ? SourceChangeType.toTranscoding : SourceChangeType.toDirectPlay);
    });

    ref.listen(finampSettingsProvider.transcodingStreamingFormat, (_, transcodingStreamingFormat) {
      if (FinampSettingsHelper.finampSettings.shouldTranscode) {
        _dataSourceServiceLogger.info("Transcoding Streaming Format Changed: $transcodingStreamingFormat");
        _onDataSourceChange(SourceChangeType.toTranscoding);
      }
    });

    ref.listen(finampSettingsProvider.transcodeBitrate, (_, transcodeBitrate) {
      if (FinampSettingsHelper.finampSettings.shouldTranscode) {
        _dataSourceServiceLogger.info("Transcoding Bitrate Changed: $transcodeBitrate");
        _onDataSourceChange(SourceChangeType.toTranscoding);
      }
    });

    ref.listen(FinampUserHelper.finampCurrentUserProvider.select((user) => user?.baseURL), (_, newUrl) {
      _dataSourceServiceLogger.info("Base URL Changed: $newUrl");
      bool isLocalUrl = finampUserHelper.currentUser?.isLocal ?? false;
      _onDataSourceChange(isLocalUrl ? SourceChangeType.toLocalUrl : SourceChangeType.toRemoteUrl);
    });
  }

  static Future<void> _onDataSourceChange(SourceChangeType event) async {
    if (!GetIt.instance.isRegistered<QueueService>()) return;
    final QueueService queueService = GetIt.instance<QueueService>();
    _dataSourceServiceLogger.finest("Connectivity Change Triggered, event is '$event'");

    final queueInfo = queueService.getQueue();

    Future<void> handleNetworkQueueReload() async {
      if (queueInfo.undownloadedTracks == 0) return;
      if (FinampSettingsHelper.finampSettings.autoReloadQueue) {
        if (_networkAvailable) {
          _networkQueueReloadPending = false;
          await _reloadQueueAfterFrame(queueService);
        } else {
          _networkQueueReloadPending = true;
          _dataSourceServiceLogger.info("Deferring queue reload until network recovery");
        }
        return;
      }

      GlobalSnackbar.message(
        (context) {
          final reloadPrompt = AppLocalizations.of(context)!.autoReloadPrompt(SourceChangeGenericType.network.name);
          final reloadPromptMissingTracks = AppLocalizations.of(
            context,
          )!.autoReloadPromptMissingTracks(queueInfo.undownloadedTracks);
          if (event == SourceChangeType.toOffline) {
            // Warn about tracks unavailable after an offline reload, before it happens.
            return "$reloadPrompt. $reloadPromptMissingTracks";
          }
          return reloadPrompt;
        },
        action: (context) => SnackBarAction(
          label: AppLocalizations.of(context)!.autoReloadPromptReloadButton,
          onPressed: () {
            // Archived queues are not overwritten and can always be restored.
            queueService.reloadQueue(archiveQueue: event == SourceChangeType.toOffline);
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
        isConfirmation: false,
      );
    }

    if (queueInfo.trackCount > 0) {
      switch (event) {
        case SourceChangeType.toLocalUrl:
        case SourceChangeType.toRemoteUrl:
          if (_networkAvailable) {
            _networkContentRefreshPending = false;
            await _refreshOnlineContentAfterFrame();
          } else {
            _networkContentRefreshPending = true;
            _dataSourceServiceLogger.info("Deferring Home and search refresh until network recovery");
          }
          await handleNetworkQueueReload();
          break;
        case SourceChangeType.toOffline:
          await handleNetworkQueueReload();
          break;
        case SourceChangeType.toOnline:
          // nop, queue won't change since Finamp prefers downloaded data anyway
          break;
        case SourceChangeType.toDirectPlay:
        case SourceChangeType.toTranscoding:
          final queueInfo = queueService.getQueue();
          final transcodingItemsExist = queueInfo.fullQueue.any((item) => item.item.extras?["shouldTranscode"] == true);
          if (event == SourceChangeType.toTranscoding || transcodingItemsExist) {
            if (FinampSettingsHelper.finampSettings.autoReloadQueue) {
              await _reloadQueueAfterFrame(queueService);
            } else {
              GlobalSnackbar.message(
                (context) => AppLocalizations.of(context)!.autoReloadPrompt(SourceChangeGenericType.transcoding.name),
                action: (context) => SnackBarAction(
                  label: AppLocalizations.of(context)!.autoReloadPromptReloadButton,
                  onPressed: () {
                    queueService.reloadQueue(archiveQueue: false);
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
                isConfirmation: false,
              );
            }
          }
          break;
      }
    }
  }
}
