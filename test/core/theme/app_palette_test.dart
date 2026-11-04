import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/core/theme/app_colors.dart';
import 'package:gemstone/core/theme/app_palette.dart';
import 'package:gemstone/core/theme/app_theme.dart';
import 'package:gemstone/core/theme/atelier_palette.dart';
import 'package:gemstone/core/theme/luxe_tokens.dart';
import 'package:gemstone/core/theme/theme_preference_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() => AppPalette.activate(AppPaletteId.ivory));

  group('PalettePreference', () {
    test('restores the stored palette after a restart', () async {
      SharedPreferences.setMockInitialValues({});
      final first = PalettePreference();
      await first.setPalette(AppPaletteId.emeraldPearl);

      final stored = await PalettePreference.load();
      expect(stored.palette, AppPaletteId.emeraldPearl);
      expect(AppPalette.current.id, AppPaletteId.emeraldPearl);
    });

    test('migrates the legacy dark-mode flag to Onyx', () async {
      SharedPreferences.setMockInitialValues({'gw.theme.darkMode': true});
      final stored = await PalettePreference.load();
      expect(stored.palette, AppPaletteId.onyx);
      expect(stored.lastLight, AppPaletteId.ivory);
    });

    test('dark toggle returns to the last light palette', () async {
      SharedPreferences.setMockInitialValues({});
      final pref = PalettePreference(AppPaletteId.midnightIce);
      await pref.setDarkMode(true);
      expect(pref.state, AppPaletteId.onyx);
      await pref.setDarkMode(false);
      expect(pref.state, AppPaletteId.midnightIce);
    });
  });

  group('AppPalette', () {
    test('new palettes use the brand roles', () {
      const emerald = AppPalette.emeraldPearl;
      expect(emerald.atelier.ink, const Color(0xFF063C35));
      expect(emerald.atelier.canvas, const Color(0xFFEDF3EF));
      expect(emerald.atelier.hairline, const Color(0xFFC9D8D1));
      expect(emerald.stage.gold, const Color(0xFFC8A86B));

      const midnight = AppPalette.midnightIce;
      expect(midnight.atelier.ink, const Color(0xFF07111F));
      expect(midnight.atelier.canvas, const Color(0xFFEEF6FA));
      expect(midnight.atelier.hairline, const Color(0xFFCBD9E3));
      expect(midnight.stage.gold, const Color(0xFF8FD8FF));
    });

    testWidgets('every selectable palette builds a theme carrying itself', (
      tester,
    ) async {
      for (final palette in AppPalette.selectable) {
        final theme = AppTheme.build(palette);
        expect(theme.brightness, palette.brightness);
        expect(theme.extension<AppPaletteTheme>()?.palette, palette);
      }
    });

    test('static tokens follow the active palette', () {
      AppPalette.activate(AppPaletteId.midnightIce);
      expect(AppColors.charcoal, const Color(0xFF07111F));
      expect(LuxeStage.obsidian, AppPalette.midnightIce.stage.obsidian);
      AppPalette.activate(AppPaletteId.ivory);
      expect(AppColors.charcoal, const Color(0xFF111827));
    });

    testWidgets('context lookups resolve from the theme palette', (
      tester,
    ) async {
      late AtelierPalette atelier;
      late LuxePalette luxe;
      late Color bg;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(AppPalette.emeraldPearl),
          home: Builder(
            builder: (context) {
              atelier = AtelierPalette.of(context);
              luxe = LuxePalette.of(context);
              bg = AppColors.bg(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(atelier, AppPalette.emeraldPearl.atelier);
      expect(luxe, AppPalette.emeraldPearl.luxe);
      expect(bg, const Color(0xFFEDF3EF));
    });

    testWidgets('dark subtree under a light palette uses its night set', (
      tester,
    ) async {
      late AtelierPalette atelier;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(AppPalette.midnightIce.night),
          home: Builder(
            builder: (context) {
              atelier = AtelierPalette.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(atelier, AppPalette.midnightNight.atelier);
    });
  });
}
