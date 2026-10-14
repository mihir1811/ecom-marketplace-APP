import 'package:flutter/material.dart';
import 'package:gemstone/core/theme/app_fonts.dart';

/// Colour tokens for the comparison "vitrine": bone paper and champagne
/// gold by day, onyx and warm gold by night.
@immutable
class Vitrine {
  const Vitrine._({
    required this.paper,
    required this.card,
    required this.raised,
    required this.ink,
    required this.muted,
    required this.faint,
    required this.line,
    required this.gold,
    required this.goldSoft,
    required this.wash,
    required this.danger,
    required this.isDark,
  });

  final Color paper;
  final Color card;
  final Color raised;
  final Color ink;
  final Color muted;
  final Color faint;
  final Color line;
  final Color gold;
  final Color goldSoft;

  /// Tint behind a leading value.
  final Color wash;
  final Color danger;
  final bool isDark;

  static const _light = Vitrine._(
    paper: Color(0xFFF5F2ED),
    card: Color(0xFFFFFFFF),
    raised: Color(0xFFEDE8E0),
    ink: Color(0xFF121110),
    muted: Color(0xFF77716A),
    faint: Color(0xFFB4ADA3),
    line: Color(0xFFE5DFD5),
    gold: Color(0xFFA5803F),
    goldSoft: Color(0xFFF0E6D2),
    wash: Color(0xFFF7EEDC),
    danger: Color(0xFFB4532F),
    isDark: false,
  );

  static const _dark = Vitrine._(
    paper: Color(0xFF0B0B0D),
    card: Color(0xFF141417),
    raised: Color(0xFF1C1C20),
    ink: Color(0xFFF2EDE5),
    muted: Color(0xFF9A938A),
    faint: Color(0xFF57524C),
    line: Color(0xFF242328),
    gold: Color(0xFFD8B87B),
    goldSoft: Color(0xFF2A2318),
    wash: Color(0xFF1F1A12),
    danger: Color(0xFFE59A7E),
    isDark: true,
  );

  static Vitrine of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;

  /// Primary display, for names and numbers that should feel engraved.
  TextStyle display(double size, {Color? color, FontStyle? style}) =>
      AppFonts.primary(
        fontSize: size,
        height: 1.08,
        fontWeight: FontWeight.w500,
        fontStyle: style,
        letterSpacing: -0.2,
        color: color ?? ink,
      );

  /// Interface text ([AppFonts.secondary]).
  TextStyle text(
    double size, {
    Color? color,
    FontWeight weight = FontWeight.w500,
    double height = 1.3,
  }) => AppFonts.secondary(
    fontSize: size,
    height: height,
    fontWeight: weight,
    color: color ?? ink,
  );

  /// Tracked capitals for row and section labels.
  TextStyle eyebrow({Color? color, double size = 10}) => AppFonts.secondary(
    fontSize: size,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: 2.2,
    color: color ?? muted,
  );

  /// Tabular figures.
  TextStyle figure(double size, {Color? color, FontWeight? weight}) =>
      AppFonts.primary(
        fontSize: size,
        height: 1.2,
        fontWeight: weight ?? FontWeight.w700,
        color: color ?? ink,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}

/// Motion tokens.
abstract final class VitrineMotion {
  static const quick = Duration(milliseconds: 240);
  static const settle = Duration(milliseconds: 520);
  static const stagger = Duration(milliseconds: 70);

  /// Expo-out.
  static const Curve ease = Cubic(0.16, 1, 0.3, 1);
}

/// Roman numeral for a 0-based column (I–IV, then digits).
String vitrineNumeral(int index) =>
    const ['I', 'II', 'III', 'IV'].elementAtOrNull(index) ?? '${index + 1}';
