import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography hierarchy using Google Fonts.
/// Combines Playfair Display (Serif) for headlines/titles and Inter (Sans-Serif) for body/labels/captions.
class AppTypography {
  const AppTypography._();

  // Display hierarchy (Playfair Display)
  static TextStyle get display => GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
      );

  static TextStyle get headline => GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.25,
      );

  static TextStyle get title => GoogleFonts.playfairDisplay(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  // Body and helper hierarchy (Inter)
  static TextStyle get body => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  static TextStyle get caption => GoogleFonts.inter(
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
