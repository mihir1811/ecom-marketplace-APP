import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/core/theme/app_fonts.dart';
import 'package:gemstone/core/theme/bundled_fonts.dart';

void main() {
  final declared = RegExp(r'^    - family: (\S+)$', multiLine: true)
      .allMatches(File('pubspec.yaml').readAsStringSync())
      .map((m) => m.group(1)!)
      .toSet();

  test('family names match what google_fonts registered', () {
    expect(AppFonts.primary().fontFamily, 'Outfit_regular');
    expect(AppFonts.secondaryFontFamily, 'PlusJakartaSans_regular');
    expect(
      AppFonts.display(fontWeight: FontWeight.w600).fontFamily,
      'CormorantGaramond_600',
    );
    expect(AppFonts.monoFontFamily, 'JetBrainsMono_regular');
    expect(
      BundledFonts.style('Instrument Serif', fontStyle: FontStyle.italic)
          .fontFamily,
      'InstrumentSerif_italic',
    );
    expect(AppFonts.primary().fontFamilyFallback, ['Outfit']);
  });

  test('closest-match ties resolve like google_fonts', () {
    // Outfit has no italics: the same-weight upright file wins (score 2).
    expect(
      AppFonts.primary(
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
      ).fontFamily,
      'Outfit_500',
    );
    // Manrope 900 italic: 800 upright scores 3, nothing closer.
    expect(
      BundledFonts.style(
        'Manrope',
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
      ).fontFamily,
      'Manrope_800',
    );
    // Out of range weights clamp to the nearest file.
    expect(
      AppFonts.secondary(fontWeight: FontWeight.w900).fontFamily,
      'PlusJakartaSans_800',
    );
    expect(
      AppFonts.display(fontWeight: FontWeight.w100).fontFamily,
      'CormorantGaramond_300',
    );
  });

  test('every variant the app can request is bundled', () {
    final requested = <String?>{
      for (final w in FontWeight.values) ...[
        AppFonts.primary(fontWeight: w).fontFamily,
        AppFonts.primary(fontWeight: w, fontStyle: FontStyle.italic).fontFamily,
        AppFonts.secondary(fontWeight: w).fontFamily,
        AppFonts.display(fontWeight: w).fontFamily,
        BundledFonts.style('Manrope', fontWeight: w).fontFamily,
      ],
      AppFonts.monoFontFamily,
      BundledFonts.style('Instrument Serif').fontFamily,
      BundledFonts.style('Instrument Serif', fontStyle: FontStyle.italic)
          .fontFamily,
      for (final base in [
        ThemeData.light().textTheme,
        ThemeData.dark().textTheme,
      ])
        for (final s in [
          AppFonts.secondaryTextTheme(base).displayLarge,
          AppFonts.secondaryTextTheme(base).titleMedium,
          AppFonts.secondaryTextTheme(base).bodyMedium,
          AppFonts.secondaryTextTheme(base).labelLarge,
          AppFonts.secondaryTextTheme(base).labelSmall,
        ])
          s?.fontFamily,
    };
    for (final family in requested) {
      expect(declared, contains(family), reason: '$family not in pubspec');
    }
    for (final family in declared) {
      final file = RegExp(
        '- family: $family\\n      fonts:\\n        - asset: (\\S+)',
      ).firstMatch(File('pubspec.yaml').readAsStringSync())!.group(1)!;
      expect(File(file).existsSync(), isTrue, reason: file);
    }
  });
}
