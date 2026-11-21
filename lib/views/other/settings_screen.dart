import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/core/theme/theme_settings.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';

/// Theme preferences, backed by [themeModeProvider]. Pure Riverpod: the
/// notifier persists through ThemeSettings, no service locator involved.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.auSettingsTitle),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(l.auSettingsThemeTitle),
            subtitle: Text(l.auSettingsThemeSubtitle),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              onChanged: (ThemeMode? newThemeMode) {
                if (newThemeMode != null) {
                  ref.read(themeModeProvider.notifier).set(newThemeMode);
                }
              },
              items: [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text(l.auThemeSystem),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text(l.auThemeLight),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text(l.auThemeDark),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: colorScheme.secondaryContainer,
          ),
          ListTile(
            title: Text(l.auSettingsQuickToggleTitle),
            subtitle: Text(l.auSettingsQuickToggleSubtitle),
            trailing: IconButton(
              icon: Icon(
                themeMode == ThemeMode.light
                    ? Icons.dark_mode
                    : Icons.light_mode,
              ),
              onPressed: () {
                final next = themeMode == ThemeMode.light
                    ? ThemeMode.dark
                    : ThemeMode.light;
                ref.read(themeModeProvider.notifier).set(next);
              },
            ),
          ),
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: colorScheme.secondaryContainer,
          ),
        ],
      ),
    );
  }
}
