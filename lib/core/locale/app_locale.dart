import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Locale state, copied from kitaphub (polished, reused verbatim in shape):
/// null = system locale, otherwise a persisted language code in prefs.
/// `ref.watch(localeProvider)` is passed straight to GetMaterialApp/MaterialApp.
final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);

class LocaleNotifier extends Notifier<Locale?> {
  final sys = PlatformDispatcher.instance.locale;

  @override
  Locale? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('locale');
    state = langCode != null ? Locale(langCode) : sys;
  }

  Future<void> setLocale(String? languageCode) async {
    final newLocale = languageCode != null && languageCode != 'system'
        ? Locale(languageCode)
        : sys;
    state = newLocale;
    final prefs = await SharedPreferences.getInstance();
    if (languageCode != null) {
      await prefs.setString('locale', languageCode);
    } else {
      await prefs.remove('locale');
    }
  }

  Future<void> resetToSystem() => setLocale(null);
}

extension LocaleExt on Locale? {
  String get languageCode => this?.languageCode ?? 'system';

  String get displayName {
    if (this == null) return 'System';
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'ru':
        return 'Русский';
      case 'kk':
        return 'Қазақша';
      default:
        return languageCode.toUpperCase();
    }
  }

  String localizeLang(AppLocalizations l) {
    switch (languageCode) {
      case 'ru':
        return l.labelRussian;
      case 'kk':
        return l.labelKazakh;
      case 'en':
        return l.labelEnglish;
      default:
        return languageCode.toUpperCase();
    }
  }

  String get flag {
    switch (languageCode) {
      case 'en':
        return '🇬🇧';
      case 'ru':
        return '🇷🇺';
      case 'kk':
        return '🇰🇿';
      default:
        return '🌐';
    }
  }
}
