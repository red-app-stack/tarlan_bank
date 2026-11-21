import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/services/secure_store.dart';
import 'package:tarlan_bank/views/shared/user_settings.dart';

/// Theme state with no GetX dependency. Loaded once during bootstrap; writes
/// go through SecureStore so the setting survives restarts.
class ThemeSettings {
  ThemeSettings(this._store);

  final SecureStore _store;
  final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.system);

  Future<void> load() async {
    final settings = await _store.loadSettings();
    mode.value = settings?.themeMode ?? ThemeMode.system;
  }

  void set(ThemeMode value) {
    mode.value = value;
    _persist();
  }

  void toggle() =>
      set(mode.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);

  Future<void> _persist() async {
    final current = await _store.loadSettings() ?? UserSettings.defaults();
    await _store.saveSettings(current.copyWith(themeMode: mode.value));
  }
}

final themeSettingsProvider = Provider<ThemeSettings>((ref) {
  throw UnimplementedError('Provide ThemeSettings via ProviderScope override');
});

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final settings = ref.watch(themeSettingsProvider);
    void onChanged() => state = settings.mode.value;
    settings.mode.addListener(onChanged);
    ref.onDispose(() => settings.mode.removeListener(onChanged));
    return settings.mode.value;
  }

  void set(ThemeMode value) => ref.read(themeSettingsProvider).set(value);
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
