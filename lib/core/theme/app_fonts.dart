import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Single source of truth for every typeface in the app.
///
/// Change a family name below and it applies everywhere. Names must match
/// the Google Fonts catalogue exactly (https://fonts.google.com).
///
/// Roles:
/// - [primary]   — headings, titles, prices, figures, buttons.
/// - [secondary] — body copy, labels, captions, form fields, eyebrows.
/// - [display]   — large hero/display statements and headline values.
/// - [mono]      — keys, ids and other code-like values.
abstract final class AppFonts {
  static const String primaryFamily = 'Outfit';
  static const String secondaryFamily = 'Plus Jakarta Sans';
  static const String displayFamily = 'Cormorant Garamond';
  static const String monoFamily = 'JetBrains Mono';

  /// Resolved family names (registers the font with google_fonts on access).
  static String get primaryFontFamily => primary().fontFamily!;
  static String get secondaryFontFamily => secondary().fontFamily!;
  static String get displayFontFamily => display().fontFamily!;
  static String get monoFontFamily => mono().fontFamily!;

  static TextStyle primary({
    TextStyle? textStyle,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? height,
    List<FontFeature>? fontFeatures,
  }) => _font(
    primaryFamily,
    textStyle: textStyle,
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    letterSpacing: letterSpacing,
    height: height,
    fontFeatures: fontFeatures,
  );

  static TextStyle secondary({
    TextStyle? textStyle,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? height,
    List<FontFeature>? fontFeatures,
  }) => _font(
    secondaryFamily,
    textStyle: textStyle,
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    letterSpacing: letterSpacing,
    height: height,
    fontFeatures: fontFeatures,
  );

  static TextStyle display({
    TextStyle? textStyle,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? height,
    List<FontFeature>? fontFeatures,
  }) => _font(
    displayFamily,
    textStyle: textStyle,
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    letterSpacing: letterSpacing,
    height: height,
    fontFeatures: fontFeatures,
  );

  static TextStyle mono({
    TextStyle? textStyle,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? height,
    List<FontFeature>? fontFeatures,
  }) => _font(
    monoFamily,
    textStyle: textStyle,
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    letterSpacing: letterSpacing,
    height: height,
    fontFeatures: fontFeatures,
  );

  /// [base] restyled with the secondary family (body/UI default).
  static TextTheme secondaryTextTheme([TextTheme? base]) =>
      GoogleFonts.getTextTheme(secondaryFamily, base);

  static TextStyle _font(
    String family, {
    TextStyle? textStyle,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? height,
    List<FontFeature>? fontFeatures,
  }) => GoogleFonts.getFont(
    family,
    textStyle: textStyle,
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    letterSpacing: letterSpacing,
    height: height,
    fontFeatures: fontFeatures,
  );
}
