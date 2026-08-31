import 'package:finamp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class AndroidAutoSettingsScreen extends StatelessWidget {
  const AndroidAutoSettingsScreen({super.key});
  static const routeName = "/settings/androidAuto";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.androidAutoSettings)),
      body: ListView(padding: const EdgeInsets.only(bottom: 200.0), children: const []),
    );
  }
}

/*class AndroidAutoBrowsingModeDropdown extends ConsumerWidget {
  const AndroidAutoBrowsingModeDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentMode = ref.watch(finampSettingsProvider.androidAutoBrowsingMode);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.androidAutoBrowsingModeLabel, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(l10n.androidAutoBrowsingModeSubtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          FinampSettingsDropdown<AndroidAutoBrowsingMode>(
            dropdownItems: [
              DropdownMenuEntry(value: AndroidAutoBrowsingMode.list, label: l10n.list),
              DropdownMenuEntry(value: AndroidAutoBrowsingMode.grid, label: l10n.grid),
              DropdownMenuEntry(value: AndroidAutoBrowsingMode.letters, label: l10n.androidAutoBrowsingModeLetterFirst),
            ],
            selectedValue: currentMode,
            onSelected: (value) {
              if (value != null) {
                FinampSetters.setAndroidAutoBrowsingMode(value);
              }
            },
          ),
        ],
      ),
    );
  }
}*/
