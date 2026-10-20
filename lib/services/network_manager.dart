import 'dart:async';
import 'dart:core';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:finamp/components/global_snackbar.dart';
import 'package:finamp/l10n/app_localizations.dart';
import 'package:finamp/services/downloads_service.dart';
import 'package:finamp/services/data_source_service.dart';
import 'package:finamp/services/finamp_user_helper.dart';
import 'package:finamp/services/jellyfin_api_helper.dart';
import 'package:finamp/services/playon_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/finamp_models.dart';
import 'finamp_settings_helper.dart';

part 'network_manager.g.dart';

Logger _networkAutomationLogger = Logger("Network Automation");
Logger _autoOfflineLogger = Logger("Auto Offline");
Logger _networKSwitcherLogger = Logger("Network Switcher");

int activeDelayCounter = 0;
Future<void> _networkChangeQueue = Future.value();
Timer? _preferredLocalUrlRetryTimer;
int _networkChangeGeneration = 0;

const _preferredLocalUrlRetryDelay = Duration(seconds: 3);

/// This stream receives update when autoOffline enters/exists the 7 second confirmation/validation timeout
final autoOfflineStatusStream = StreamController<int>.broadcast();
final autoOfflineStatusProvider = StreamProvider((ref) {
  return autoOfflineStatusStream.stream;
}).select((v) => v.valueOrNull ?? 0);

final StreamSubscription<List<ConnectivityResult>> _listener = Connectivity().onConnectivityChanged.listen(
  _onConnectivityChange,
);

@riverpod
class AutoOffline extends _$AutoOffline {
  static void startWatching() {
    ProviderContainer container = GetIt.instance<ProviderContainer>();

    container.listen(autoOfflineProvider, (_, automationState) {
      bool automationEnabled = automationState > 0;
      _networkAutomationLogger.info("${automationEnabled ? "Enabled" : "Paused"} Automation");

      if (automationEnabled) {
        _listener.resume();
        // instantly check if offline mode should be on
        _onConnectivityChange(null);
      } else {
        _listener.pause();
      }
    }, fireImmediately: true);
  }

  @override
  int build() {
    bool autoOfflineEnabled = ref.watch(finampSettingsProvider.autoOffline) != AutoOfflineOption.disabled;

    // false = user overwrote offline mode
    bool autoOfflineActive = ref.watch(finampSettingsProvider.autoOfflineListenerActive);

    bool preferLocalNetwork =
        ref.watch(FinampUserHelper.finampCurrentUserProvider)?.preferLocalNetwork ?? DefaultSettings.preferLocalNetwork;

    // Why this integer magic?
    // If the function would return a bool aka. `(autoOfflineEnabled && autoOfflineActive) || autoServerSwitch`
    // The container.listen would only trigger when the value actually changes (doesn't stay the same).
    // This means when preferLocalNetwork is true, the method will always return `true`. Thus not firing the listener.
    // Why does the listener need to trigger?
    // When the user paused automation by manually changing offline mode, and then reengages automation
    // The listener wouldn't fire (since the value doesn't actually change, it stays `true`), this results in _onConnectivityChange
    // not being called which means autoOffline wont reevaluate the offline-state immediately, meaning offlineMode stays where the
    // user last changed it to and wont update until a network change happens
    int state = 0;
    if (autoOfflineEnabled && autoOfflineActive) state += 1;
    if (preferLocalNetwork) state += 2;

    return state;
  }
}

Future<void> _onConnectivityChange(List<ConnectivityResult>? connections) async {
  final generation = ++_networkChangeGeneration;
  _preferredLocalUrlRetryTimer?.cancel();

  // Android commonly emits several states while moving between Wi-Fi and
  // mobile data.  Handle them in order so an earlier reachability check cannot
  // restore clients that a later event has just invalidated.
  _networkChangeQueue = _networkChangeQueue.then((_) => _handleConnectivityChange(connections, generation)).catchError((
    Object error,
    StackTrace stack,
  ) {
    _networkAutomationLogger.severe("Error handling network change: $error", error, stack);
  });
  return _networkChangeQueue;
}

Future<void> _handleConnectivityChange(List<ConnectivityResult>? connections, int generation) async {
  _networkAutomationLogger.info(
    "Network Change: ${connections?.map((element) => element.toString()).join(", ") ?? "None (likely a manual function call)"}",
  );
  connections ??= await Connectivity().checkConnectivity();

  final networkAvailable = connections.any((connection) => connection != ConnectivityResult.none);
  if (!networkAvailable) {
    await DataSourceService.setNetworkAvailable(false);
  }

  // A local address is only meaningful on a local transport.  In particular,
  // after Wi-Fi is disabled Android may retain a short-lived route while the
  // phone is already using mobile data; probing that route can incorrectly
  // leave the LAN URL selected.  On mobile-only (or no) connectivity, select
  // the public URL directly.  With Wi-Fi/Ethernet available, keep the normal
  // reachability probe because it may be a Wi-Fi network away from home.
  final hasPotentialLocalTransport =
      connections.contains(ConnectivityResult.wifi) || connections.contains(ConnectivityResult.ethernet);
  final sourceChanged = await changeTargetUrl(isLocal: hasPotentialLocalTransport ? null : false);

  // Android may publish Wi-Fi before DHCP/routing has made the LAN reachable.
  // The first probe then correctly keeps the public address, but there may be
  // no second connectivity callback once the local server becomes reachable.
  // Recheck once after that short settling period so "prefer local" is
  // honoured when the user comes back home.
  if (hasPotentialLocalTransport && !sourceChanged) {
    _schedulePreferredLocalUrlRetry(generation);
  } else {
    _preferredLocalUrlRetryTimer?.cancel();
  }

  // Do this only after persisting the selected address.  Recreating a client
  // is a best-effort cleanup; it must never prevent the source selection from
  // reaching the user state.
  await GetIt.instance<JellyfinApiHelper>().resetNetworkConnections();
  if (networkAvailable) {
    await DataSourceService.setNetworkAvailable(true, sourceChanged: sourceChanged);
  }
  final offlineModeActive = await _setOfflineMode(connections);
  if (!offlineModeActive) await _reconnectPlayOnService(connections);
  _notifyOfPausedDownloads(connections);
}

void _schedulePreferredLocalUrlRetry(int generation) {
  _preferredLocalUrlRetryTimer?.cancel();
  _preferredLocalUrlRetryTimer = Timer(_preferredLocalUrlRetryDelay, () {
    if (generation != _networkChangeGeneration) return;

    _networkChangeQueue = _networkChangeQueue.then((_) => _retryPreferredLocalUrl(generation)).catchError((
      Object error,
      StackTrace stack,
    ) {
      _networkAutomationLogger.severe("Error retrying preferred local URL: $error", error, stack);
    });
  });
}

Future<void> _retryPreferredLocalUrl(int generation) async {
  if (generation != _networkChangeGeneration) return;

  final connections = await Connectivity().checkConnectivity();
  if (generation != _networkChangeGeneration) return;

  final hasPotentialLocalTransport =
      connections.contains(ConnectivityResult.wifi) || connections.contains(ConnectivityResult.ethernet);
  final user = GetIt.instance<FinampUserHelper>().currentUser;

  if (!hasPotentialLocalTransport || user == null || !user.preferLocalNetwork || user.isLocal) return;

  if (!await GetIt.instance<JellyfinApiHelper>().pingLocalServer() || generation != _networkChangeGeneration) {
    _networkAutomationLogger.fine("Preferred local server is still unreachable after network recovery");
    return;
  }

  _networkAutomationLogger.info("Local server became reachable after network recovery; restoring local address");
  final sourceChanged = await changeTargetUrl(isLocal: true);
  if (!sourceChanged) return;

  await GetIt.instance<JellyfinApiHelper>().resetNetworkConnections();
  await DataSourceService.setNetworkAvailable(true, sourceChanged: true);
  await _reconnectPlayOnService(connections);
}

bool featureEnabled() {
  return FinampSettingsHelper.finampSettings.autoOffline != AutoOfflineOption.disabled &&
      FinampSettingsHelper.finampSettings.autoOfflineListenerActive;
}

/// Sets the offline mode based on the current connectivity and user settings
Future<bool> _setOfflineMode(List<ConnectivityResult> connections) async {
  if (!featureEnabled()) {
    return FinampSettingsHelper.finampSettings.isOffline;
  }

  bool state1 = await _shouldBeOffline(connections);

  // this prevents an issue on ios (and mac?) where the
  // listener gets called even though it shouldn't.
  // The wait also acts as an timeout so offline mode is less
  // likely to engage when it doesn't need to and this helps
  // with queue reloading
  autoOfflineStatusStream.add(++activeDelayCounter);
  await Future.delayed(Duration(seconds: 7), () => {});
  autoOfflineStatusStream.add(--activeDelayCounter);

  // Return Early to prevent another Connectivity check
  if (!featureEnabled()) {
    return FinampSettingsHelper.finampSettings.isOffline;
  }
  connections = await Connectivity().checkConnectivity();
  bool state2 = await _shouldBeOffline(connections);

  // skip if state changed during the delay because the function should be triggered by the change again
  // skip if target state is already the active offline-mode state to prevent unessesary snackbar messages
  // check if feature is enabled was already done after the delay
  if (state1 != state2 || FinampSettingsHelper.finampSettings.isOffline == state2) {
    return FinampSettingsHelper.finampSettings.isOffline;
  }

  GlobalSnackbar.message(
    (context) => AppLocalizations.of(context)!.autoOfflineNotification(state2 ? "enabled" : "disabled"),
  );

  _autoOfflineLogger.info("Automatically ${state2 ? "Enabled" : "Disabled"} Offline Mode");

  FinampSetters.setIsOffline(state2);
  return state2;
}

Future<bool> _shouldBeOffline(List<ConnectivityResult> connections) async {
  switch (FinampSettingsHelper.finampSettings.autoOffline) {
    case AutoOfflineOption.disconnected:
      return !connections.contains(ConnectivityResult.mobile) &&
          !connections.contains(ConnectivityResult.ethernet) &&
          !connections.contains(ConnectivityResult.wifi);
    case AutoOfflineOption.network:
      return !connections.contains(ConnectivityResult.ethernet) && !connections.contains(ConnectivityResult.wifi);
    case AutoOfflineOption.unreachable:
      final api = GetIt.instance<JellyfinApiHelper>();
      if (await api.pingActiveServer()) return false;

      // A missed or stale Android connectivity callback must not strand the
      // user on a dead LAN address. When the local endpoint has failed but the
      // configured public endpoint is alive, fail over before enabling offline
      // mode. This also stops PlayOn and playback-history retries from keeping
      // the unreachable local URL.
      final user = GetIt.instance<FinampUserHelper>().currentUser;
      if ((user?.isLocal ?? false) && await api.pingPublicServer()) {
        _networkAutomationLogger.warning("Local server is unreachable; failing over to the public address");
        final sourceChanged = await changeTargetUrl(isLocal: false);
        if (sourceChanged) {
          await api.resetNetworkConnections();
          await DataSourceService.setNetworkAvailable(true, sourceChanged: true);
          await _reconnectPlayOnService(connections);
        }
        return false;
      }

      return true;
    default:
      return false;
  }
}

Future<bool> changeTargetUrl({bool? isLocal}) async {
  FinampUser? user = GetIt.instance<FinampUserHelper>().currentUser;
  if (user == null) return false;

  if (isLocal != null && isLocal != user.isLocal) {
    _networKSwitcherLogger.info("Changed active network to ${isLocal ? "local" : "public"} address");
    GetIt.instance<FinampUserHelper>().currentUser?.update(newIsLocal: isLocal);
    return true;
  }

  // this avoids an infinite loop... again :)
  if (isLocal != null) {
    return false;
  }

  // Disable this feature
  if (!user.preferLocalNetwork) return changeTargetUrl(isLocal: false);

  bool reachable = await GetIt.instance<JellyfinApiHelper>().pingLocalServer();
  return await changeTargetUrl(isLocal: reachable);
}

int _getDownloads() {
  final downloadsService = GetIt.instance<DownloadsService>();
  downloadsService.updateDownloadCounts();

  final nodesSyncing = downloadsService.downloadCounts["sync"]!;
  final downloadingEnqueued = downloadsService.downloadStatuses[DownloadItemState.enqueued]!;
  final downloadingRunning = downloadsService.downloadStatuses[DownloadItemState.downloading]!;

  final activeDownloads = nodesSyncing + downloadingEnqueued + downloadingRunning;
  return activeDownloads;
}

void _notifyOfPausedDownloads(List<ConnectivityResult> connections) async {
  if (!FinampSettingsHelper.finampSettings.isOffline) return;

  if (connections.contains(ConnectivityResult.none)) {
    if (_getDownloads() == 0) return;
    GlobalSnackbar.message((context) => AppLocalizations.of(context)!.downloadPaused);
    return;
  }

  // desktop doesn't have this setting
  if (!(Platform.isAndroid || Platform.isIOS)) return;

  if (FinampSettingsHelper.finampSettings.requireWifiForDownloads) {
    final connectedToWifi = connections.contains(ConnectivityResult.wifi);
    if (connectedToWifi) return;

    if (_getDownloads() == 0) return;

    GlobalSnackbar.message((context) => AppLocalizations.of(context)!.downloadPaused);
  }
}

Future<void> _reconnectPlayOnService(List<ConnectivityResult> connections) async {
  final playOnService = GetIt.instance<PlayOnService>();

  if (connections.contains(ConnectivityResult.none)) {
    playOnService.closeListener();
    return;
  }
  await playOnService.reconnectAfterNetworkChange();
}
