import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colour tokens for the home experience, resolved per brightness.
///
/// The hero "stage" is a dark vitrine in both modes (jewellery reads best on
/// black); everything below it follows the app's light/dark preference.
@immutable
class HomePalette {
  const HomePalette._({
    required this.canvas,
    required this.surface,
    required this.surfaceRaised,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.hairline,
    required this.accent,
    required this.accentSoft,
    required this.onAccent,
    required this.isDark,
  });

  final Color canvas;
  final Color surface;
  final Color surfaceRaised;
  final Color ink;
  final Color inkMuted;
  final Color inkFaint;
  final Color hairline;
  final Color accent;
  final Color accentSoft;
  final Color onAccent;
  final bool isDark;

  static const light = HomePalette._(
    canvas: Color(0xFFF6F3EE),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFEFEAE2),
    ink: Color(0xFF16140F),
    inkMuted: Color(0xFF6A645A),
    inkFaint: Color(0xFFA39C90),
    hairline: Color(0xFFE2DBCF),
    accent: Color(0xFF9C7A45),
    accentSoft: Color(0xFFEDE3D1),
    onAccent: Color(0xFFFFFFFF),
    isDark: false,
  );

  static const dark = HomePalette._(
    canvas: Color(0xFF0A0A0C),
    surface: Color(0xFF131316),
    surfaceRaised: Color(0xFF1B1B1F),
    ink: Color(0xFFF3EEE6),
    inkMuted: Color(0xFF9D968B),
    inkFaint: Color(0xFF5E5951),
    hairline: Color(0xFF26252A),
    accent: Color(0xFFD9BB84),
    accentSoft: Color(0xFF2A241A),
    onAccent: Color(0xFF16140F),
    isDark: true,
  );

  static HomePalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// Fixed tokens for the always-dark hero stage and dark feature cards.
abstract final class HomeStage {
  static const obsidian = Color(0xFF070709);
  static const ink = Color(0xFFF5F1EA);
  static const inkMuted = Color(0xFFA8A196);
  static const gold = Color(0xFFDDBF88);
  static const goldDeep = Color(0xFF9C7A45);
  static const glass = Color(0x14FFFFFF);
  static const glassBorder = Color(0x29FFFFFF);
}

/// Editorial type scale: Cormorant Garamond display, Jost for interface.
abstract final class HomeType {
  static TextStyle display(double size, Color color) =>
      GoogleFonts.cormorantGaramond(
        fontSize: size,
        height: 1.02,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.4,
        color: color,
      );

  static TextStyle displayItalic(double size, Color color) =>
      display(size, color).copyWith(fontStyle: FontStyle.italic);

  static TextStyle eyebrow(Color color) => GoogleFonts.jost(
    fontSize: 11,
    height: 1.2,
    fontWeight: FontWeight.w500,
    letterSpacing: 2.6,
    color: color,
  );

  static TextStyle body(Color color, {double size = 15}) => GoogleFonts.jost(
    fontSize: size,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: color,
  );

  static TextStyle label(Color color, {double size = 13}) => GoogleFonts.jost(
    fontSize: size,
    height: 1.25,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
    color: color,
  );

  static TextStyle figure(Color color, {double size = 15}) => GoogleFonts.jost(
    fontSize: size,
    height: 1.2,
    fontWeight: FontWeight.w500,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

/// Motion tokens shared by every home section.
abstract final class HomeMotion {
  static const reveal = Duration(milliseconds: 900);
  static const fast = Duration(milliseconds: 220);
  static const medium = Duration(milliseconds: 420);
  static const stagger = Duration(milliseconds: 90);

  /// Expo-out: fast start, long luxurious settle.
  static const Curve settle = Cubic(0.16, 1, 0.3, 1);
  static const Curve press = Cubic(0.2, 0, 0, 1);
}

/// Spacing scale for the home layout.
abstract final class HomeSpace {
  static const gutter = 20.0;
  static const section = 72.0;
  static const radius = 22.0;
  static const radiusSmall = 14.0;
}
