import 'dart:ui';

import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Locales supported by the application.
abstract final class AppLocale {
  static const english = Locale('en');
  static const hindi = Locale('hi');
  static const gujarati = Locale('gu');

  static const supported = <Locale>[english, hindi, gujarati];

  static Locale fromLanguageCode(String? languageCode) {
    return supported.firstWhere(
      (locale) => locale.languageCode == languageCode,
      orElse: () => english,
    );
  }
}

/// Persists and exposes the user's app-language preference.
class LocalePreference extends StateNotifier<Locale> {
  LocalePreference() : super(AppLocale.english);

  static const _key = 'gw.locale.languageCode';

  /// Loads the persisted locale, falling back to English.
  Future<void> hydrate() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final locale = AppLocale.fromLanguageCode(preferences.getString(_key));
      if (locale != state) state = locale;
    } catch (_) {
      // Persistence is non-critical; English remains the safe default.
    }
  }

  /// Updates the app immediately and persists the selection.
  Future<void> setLocale(Locale locale) async {
    final supported = AppLocale.fromLanguageCode(locale.languageCode);
    state = supported;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_key, supported.languageCode);
    } catch (_) {
      // The in-memory selection still applies for the current session.
    }
  }
}

/// App-wide locale preference.
final localePreferenceProvider =
    StateNotifierProvider<LocalePreference, Locale>(
      (ref) => LocalePreference(),
    );
