import 'package:flutter/material.dart';
import 'package:gemstone/core/theme/app_fonts.dart';

/// Typography tokens for the GemWorld design system.
/// Headings use [AppFonts.primary]; body/UI text uses [AppFonts.secondary].
class AppTypography {
  const AppTypography._();

  static String get fontFamily => AppFonts.secondary().fontFamily!;

  static TextStyle get display =>
      AppFonts.primary(fontSize: 28, fontWeight: FontWeight.w700, height: 1.2);

  static TextStyle get headline =>
      AppFonts.primary(fontSize: 24, fontWeight: FontWeight.w700, height: 1.25);

  static TextStyle get title =>
      AppFonts.primary(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3);

  static TextStyle get body => AppFonts.secondary(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get label => AppFonts.secondary(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static TextStyle get caption => AppFonts.secondary(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  /// Assembles the complete [TextTheme] based on this design system.
  static TextTheme buildTextTheme(Color textColor) {
    return TextTheme(
      displayLarge: display.copyWith(color: textColor),
      displayMedium: display.copyWith(color: textColor, fontSize: 26),
      displaySmall: display.copyWith(color: textColor, fontSize: 24),
      headlineLarge: headline.copyWith(color: textColor),
      headlineMedium: headline.copyWith(color: textColor, fontSize: 22),
      headlineSmall: headline.copyWith(color: textColor, fontSize: 20),
      titleLarge: title.copyWith(color: textColor),
      titleMedium: title.copyWith(color: textColor, fontSize: 16),
      titleSmall: title.copyWith(color: textColor, fontSize: 15),
      bodyLarge: body.copyWith(color: textColor),
      bodyMedium: body.copyWith(color: textColor, fontSize: 14),
      bodySmall: body.copyWith(color: textColor, fontSize: 13),
      labelLarge: label.copyWith(color: textColor),
      labelMedium: label.copyWith(color: textColor, fontSize: 12),
      labelSmall: label.copyWith(color: textColor, fontSize: 11),
    );
  }
}
