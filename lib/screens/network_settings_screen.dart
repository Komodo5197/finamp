import 'package:finamp/components/Buttons/cta_medium.dart';
import 'package:finamp/components/finamp_app_bar_back_button.dart';
import 'package:finamp/components/NetworkSettingsScreen/active_network_display.dart';
import 'package:finamp/components/NetworkSettingsScreen/auto_offline_selector.dart';
import 'package:finamp/components/NetworkSettingsScreen/prefer_local_network_address_selector.dart';
import 'package:finamp/components/NetworkSettingsScreen/prefer_local_network_selector.dart';
import 'package:finamp/components/NetworkSettingsScreen/public_address_selector.dart';
import 'package:finamp/components/global_snackbar.dart';
import 'package:finamp/l10n/app_localizations.dart';
import 'package:finamp/services/jellyfin_api_helper.dart';
import 'package:finamp/services/finamp_settings_helper.dart';
import 'package:finamp/services/finamp_user_helper.dart';
import 'package:finamp/services/network_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';

class NetworkSettingsScreen extends StatefulWidget {
  const NetworkSettingsScreen({super.key});
  static const routeName = "/settings/network";

  @override
  State<NetworkSettingsScreen> createState() => _NetworkSettingsScreenState();
}

class _NetworkSettingsScreenState extends State<NetworkSettingsScreen> {
  final GlobalKey<LocalNetworkAddressSelectorState> localNetworkAddressKey = GlobalKey(
    debugLabel: "localNetworkAddressKey",
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.networkSettingsTitle),
        leading: FinampAppBarBackButton(),
        actions: [
          FinampSettingsHelper.makeSettingsResetButtonWithDialog(context, FinampSettingsHelper.resetNetworkSettings),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 200.0),
        children: [
          AutoOfflineSelector(),
          Divider(),
          ActiveNetworkDisplay(),
          PublicAddressSelector(),
          LocalNetworkSelector(),
          LocalNetworkAddressSelector(key: localNetworkAddressKey),
          SizedBox(height: 32.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CTAMedium(
                text: AppLocalizations.of(context)!.testConnectionButtonLabel,
                icon: TablerIcons.plug_connected,
                onPressed: () async {
                  // Ensure any pending edits in the local network address field are committed first
                  final widgetState = localNetworkAddressKey.currentState;
                  if (widgetState != null) {
                    await widgetState.commitIfChanged();
                  }
                  final [public, private] = await Future.wait([
                    GetIt.instance<JellyfinApiHelper>().pingPublicServer(),
                    GetIt.instance<JellyfinApiHelper>().pingLocalServer(),
                  ]);
                  // Testing the connections is also an explicit request to
                  // re-evaluate the active source.  This provides a reliable
                  // manual recovery path if Android delivered a network event
                  // while the app was suspended.
                  final preferLocalNetwork =
                      GetIt.instance<FinampUserHelper>().currentUser?.preferLocalNetwork ?? false;
                  await changeTargetUrl(isLocal: preferLocalNetwork && private);
                  GlobalSnackbar.message(
                    (context) => AppLocalizations.of(context)!.ping("${public.toString()}_${private.toString()}"),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
