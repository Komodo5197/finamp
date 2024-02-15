import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../components/LayoutSettingsScreen/content_grid_view_cross_axis_count_list_tile.dart';
import '../components/LayoutSettingsScreen/content_view_type_dropdown_list_tile.dart';
import '../components/LayoutSettingsScreen/hide_song_artists_if_same_as_album_artists_selector.dart';
import '../components/LayoutSettingsScreen/show_cover_as_player_background_selector.dart';
import '../components/LayoutSettingsScreen/show_text_on_grid_view_selector.dart';
import '../components/LayoutSettingsScreen/theme_selector.dart';
import '../models/finamp_models.dart';
import '../services/finamp_settings_helper.dart';
import 'tabs_settings_screen.dart';

class LayoutSettingsScreen extends StatelessWidget {
  const LayoutSettingsScreen({Key? key}) : super(key: key);

  static const routeName = "/settings/layout";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.layoutAndTheme),
      ),
      body: ListView(
        children: [
          const ContentViewTypeDropdownListTile(),
          for (final type in ContentGridViewCrossAxisCountType.values)
            ContentGridViewCrossAxisCountListTile(type: type),
          const ShowTextOnGridViewSelector(),
          const ShowCoverAsPlayerBackgroundSelector(),
          const HideSongArtistsIfSameAsAlbumArtistsSelector(),
          const ThemeSelector(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.tab),
            title: Text(AppLocalizations.of(context)!.tabs),
            onTap: () =>
                Navigator.of(context).pushNamed(TabsSettingsScreen.routeName),
          ),
          const FloatNowPlayingSwitch(),
        ],
      ),
    );
  }
}

class FloatNowPlayingSwitch extends ConsumerWidget {
  const FloatNowPlayingSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool? floatBar = ref.watch(FinampSettingsHelper.finampSettingsProvider
        .select((value) => value.valueOrNull?.floatNowPlaying));

    return SwitchListTile.adaptive(
      title: Text(AppLocalizations.of(context)!.floatNowPlayingTitle),
      subtitle: Text(AppLocalizations.of(context)!.floatNowPlayingSubtitle),
      value: floatBar ?? true,
      onChanged: floatBar == null
          ? null
          : (value) async {
              FinampSettings finampSettingsTemp =
                  FinampSettingsHelper.finampSettings;
              finampSettingsTemp.floatNowPlaying = value;
              await Hive.box<FinampSettings>("FinampSettings")
                  .put("FinampSettings", finampSettingsTemp);
            },
    );
  }
}
