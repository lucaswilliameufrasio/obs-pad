import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(l.settingsTheme),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(l.themeSystem),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(l.themeLight),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(l.themeDark),
                  ),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (value) =>
                    notifier.update((s) => s.copyWith(themeMode: value.first)),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l.settingsLanguage),
            trailing: DropdownButton<String?>(
              value: settings.localeCode,
              onChanged: (value) =>
                  notifier.update((s) => s.copyWith(localeCode: () => value)),
              items: [
                DropdownMenuItem(child: Text(l.languageSystem)),
                const DropdownMenuItem(value: 'pt', child: Text('Português')),
                const DropdownMenuItem(value: 'en', child: Text('English')),
              ],
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.light_mode_outlined),
            title: Text(l.settingsKeepScreenOn),
            subtitle: Text(l.settingsKeepScreenOnHint),
            value: settings.keepScreenOn,
            onChanged: (v) =>
                notifier.update((s) => s.copyWith(keepScreenOn: v)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.vibration),
            title: Text(l.settingsHaptics),
            value: settings.haptics,
            onChanged: (v) => notifier.update((s) => s.copyWith(haptics: v)),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.school_outlined),
            title: Text(l.settingsGuide),
            onTap: () => context.push('/onboarding'),
          ),
          ListTile(
            leading: const Icon(Icons.public),
            title: Text(l.menuRemote),
            onTap: () => context.push('/remote'),
          ),
        ],
      ),
    );
  }
}
