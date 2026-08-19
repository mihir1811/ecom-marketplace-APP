import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's dark theme choice across launches.
class ThemePreference extends StateNotifier<bool> {
  ThemePreference() : super(false);

  static const _key = 'gw.theme.darkMode';

  /// Loads the persisted preference (if any) into the current state.
  Future<void> hydrate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getBool(_key);
      if (stored != null && stored != state) {
        state = stored;
      }
    } catch (_) {
      // Non-fatal — fall back to light theme.
    }
  }

  Future<void> setDarkMode(bool enabled) async {
    state = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, enabled);
    } catch (_) {
      // Persistence failure is non-fatal; in-memory state is already updated.
    }
  }
}

/// App-wide dark mode preference provider.
final themePreferenceProvider =
    StateNotifierProvider<ThemePreference, bool>((ref) => ThemePreference());