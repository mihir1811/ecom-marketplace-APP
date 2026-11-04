import 'package:flutter/material.dart';

/// Bundled replacement for the `google_fonts` package.
///
/// The font files in `assets/fonts/` are the exact files google_fonts used to
/// download at runtime (sha256-checked). Each weight/style is its own family,
/// named the way google_fonts registered it (`Outfit_600`,
/// `PlusJakartaSans_regular`, `InstrumentSerif_italic`, ...), and a style picks
/// its file with google_fonts' closest-match rule. Text therefore renders
/// exactly as before, without the network fetch or the fallback-font flash on
/// first launch.
abstract final class BundledFonts {
  /// [family] restyled like `GoogleFonts.getFont(family, ...)`.
  static TextStyle style(
    String family, {
    TextStyle? textStyle,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? height,
    List<FontFeature>? fontFeatures,
  }) {
    final spec = _families[family];
    assert(spec != null, 'Font family "$family" is not bundled');
    var style = (textStyle ?? const TextStyle()).copyWith(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      height: height,
      fontFeatures: fontFeatures,
    );
    if (spec == null) return style;
    final variant = spec.closest(
      style.fontWeight ?? FontWeight.w400,
      style.fontStyle ?? FontStyle.normal,
    );
    style = style.copyWith(
      fontFamily: '${spec.apiName}_${variant.name}',
      fontFamilyFallback: [spec.apiName],
    );
    return style;
  }

  /// [base] (default: light Material text theme) restyled with [family],
  /// like `GoogleFonts.getTextTheme(family, base)`.
  static TextTheme textTheme(String family, [TextTheme? base]) {
    final t = base ?? ThemeData.light().textTheme;
    TextStyle s(TextStyle? x) => style(family, textStyle: x);
    return TextTheme(
      displayLarge: s(t.displayLarge),
      displayMedium: s(t.displayMedium),
      displaySmall: s(t.displaySmall),
      headlineLarge: s(t.headlineLarge),
      headlineMedium: s(t.headlineMedium),
      headlineSmall: s(t.headlineSmall),
      titleLarge: s(t.titleLarge),
      titleMedium: s(t.titleMedium),
      titleSmall: s(t.titleSmall),
      bodyLarge: s(t.bodyLarge),
      bodyMedium: s(t.bodyMedium),
      bodySmall: s(t.bodySmall),
      labelLarge: s(t.labelLarge),
      labelMedium: s(t.labelMedium),
      labelSmall: s(t.labelSmall),
    );
  }

  /// Every variant the Google Fonts catalogue lists for each family (so the
  /// closest match is the one google_fonts picked). Only the variants this
  /// app can request are bundled; see `pubspec.yaml`.
  static final Map<String, _FamilySpec> _families = {
    'Outfit': _FamilySpec('Outfit', _upright(100, 900)),
    'Plus Jakarta Sans': _FamilySpec('PlusJakartaSans', [
      ..._upright(200, 800),
      ..._italic(200, 800),
    ]),
    'Cormorant Garamond': _FamilySpec('CormorantGaramond', [
      ..._upright(300, 700),
      ..._italic(300, 700),
    ]),
    'JetBrains Mono': _FamilySpec('JetBrainsMono', [
      ..._upright(100, 800),
      ..._italic(100, 800),
    ]),
    'Instrument Serif': _FamilySpec('InstrumentSerif', [
      ..._upright(400, 400),
      ..._italic(400, 400),
    ]),
    'Manrope': _FamilySpec('Manrope', _upright(200, 800)),
  };

  static List<_Variant> _upright(int from, int to) => [
    for (var w = from; w <= to; w += 100) _Variant(w, FontStyle.normal),
  ];

  static List<_Variant> _italic(int from, int to) => [
    for (var w = from; w <= to; w += 100) _Variant(w, FontStyle.italic),
  ];
}

class _FamilySpec {
  const _FamilySpec(this.apiName, this.variants);

  /// Family name without spaces, as google_fonts registered it.
  final String apiName;
  final List<_Variant> variants;

  /// google_fonts `_closestMatch`: |weight delta| / 100, +2 for a style
  /// mismatch; the first variant with the lowest score wins.
  _Variant closest(FontWeight weight, FontStyle style) {
    late _Variant best;
    int? bestScore;
    for (final v in variants) {
      var score = (weight.value - v.weight).abs() ~/ 100;
      if (v.style != style) score += 2;
      if (bestScore == null || score < bestScore) {
        bestScore = score;
        best = v;
      }
    }
    return best;
  }
}

class _Variant {
  const _Variant(this.weight, this.style);

  final int weight;
  final FontStyle style;

  /// google_fonts `GoogleFontsVariant.toString()`: `regular`, `italic`,
  /// `600`, `600italic`.
  String get name {
    final italic = style == FontStyle.italic;
    if (weight == 400) return italic ? 'italic' : 'regular';
    return italic ? '${weight}italic' : '$weight';
  }
}
