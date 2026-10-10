import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_palette.dart';

/// Stored palette choice, read before the first frame.
typedef PaletteSnapshot = ({AppPaletteId palette, AppPaletteId lastLight});

/// Persists the user's colour palette across launches and keeps
/// [AppPalette.current] in step with it.
class PalettePreference extends StateNotifier<AppPaletteId> {
  PalettePreference([
    AppPaletteId initial = AppPaletteId.ivory,
    AppPaletteId? lastLight,
  ]) : _lastLight = lastLight ?? _lightOf(initial),
       super(initial) {
    AppPalette.activate(initial);
  }

  static const _key = 'gw.theme.palette';
  static const _lastLightKey = 'gw.theme.lastLightPalette';

  /// Pre-palette builds stored only a dark-mode flag.
  static const _legacyDarkKey = 'gw.theme.darkMode';

  /// Light palette to return to when dark mode is switched off.
  AppPaletteId _lastLight;

  @override
  set state(AppPaletteId value) {
    AppPalette.activate(value);
    if (!AppPalette.byId(value).isDark) _lastLight = value;
    super.state = value;
  }

  static AppPaletteId _lightOf(AppPaletteId id) {
    final palette = AppPalette.byId(id);
    return palette.isDark ? palette.dayId : id;
  }

  static AppPaletteId? _parse(String? name) {
    for (final palette in AppPalette.selectable) {
      if (palette.id.name == name) return palette.id;
    }
    return null;
  }

  /// Reads the stored palette (migrating the legacy dark flag).
  static Future<PaletteSnapshot> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored =
          _parse(prefs.getString(_key)) ??
          (prefs.getBool(_legacyDarkKey) == true
              ? AppPaletteId.onyx
              : AppPaletteId.ivory);
      final lastLight =
          _parse(prefs.getString(_lastLightKey)) ?? _lightOf(stored);
      return (palette: stored, lastLight: lastLight);
    } catch (_) {
      // Non-fatal — fall back to the default palette.
      return (palette: AppPaletteId.ivory, lastLight: AppPaletteId.ivory);
    }
  }

  /// Loads the persisted preference (if any) into the current state.
  Future<void> hydrate() async {
    final stored = await load();
    _lastLight = stored.lastLight;
    if (mounted && stored.palette != state) state = stored.palette;
  }

  Future<void> setPalette(AppPaletteId id) async {
    if (id == state) return;
    state = id;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, id.name);
      await prefs.setString(_lastLightKey, _lastLight.name);
      await prefs.setBool(_legacyDarkKey, AppPalette.byId(id).isDark);
    } catch (_) {
      // Persistence failure is non-fatal; in-memory state is already updated.
    }
  }

  /// Quick light / dark toggle: dark goes to Onyx, light returns to the
  /// last light palette the user picked.
  Future<void> setDarkMode(bool enabled) =>
      setPalette(enabled ? AppPaletteId.onyx : _lastLight);
}

/// App-wide palette preference.
final palettePreferenceProvider =
    StateNotifierProvider<PalettePreference, AppPaletteId>(
      (ref) => PalettePreference(),
    );

/// True when the active palette is dark.
final themePreferenceProvider = Provider<bool>(
  (ref) => AppPalette.byId(ref.watch(palettePreferenceProvider)).isDark,
);
