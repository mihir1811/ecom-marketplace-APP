import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colour roles for the seller "Atelier" workspace, resolved per brightness.
///
/// The workspace is deliberately quiet: warm ivory / onyx surfaces, one
/// champagne-gold accent for focus and value, and muted gem tones that are
/// only used to carry status.
@immutable
class AtelierPalette {
  const AtelierPalette({
    required this.canvas,
    required this.surface,
    required this.raised,
    required this.sunken,
    required this.lifted,
    required this.ink,
    required this.inkSoft,
    required this.muted,
    required this.hairline,
    required this.gold,
    required this.goldSoft,
    required this.onGold,
    required this.onyx,
    required this.onOnyx,
    required this.emerald,
    required this.ruby,
    required this.sapphire,
    required this.amber,
    required this.shadow,
    required this.isDark,
  });

  final Color canvas;
  final Color surface;
  final Color raised;
  final Color sunken;

  /// Selected fill that sits on a [sunken] track (segments, toggles).
  final Color lifted;
  final Color ink;
  final Color inkSoft;
  final Color muted;
  final Color hairline;
  final Color gold;
  final Color goldSoft;
  final Color onGold;

  /// Deep hero surface (balance card, primary buttons) in both themes.
  final Color onyx;
  final Color onOnyx;
  final Color emerald;
  final Color ruby;
  final Color sapphire;
  final Color amber;
  final Color shadow;
  final bool isDark;

  static const light = AtelierPalette(
    canvas: Color(0xFFF6F3ED),
    surface: Color(0xFFFFFFFF),
    raised: Color(0xFFFFFDF9),
    sunken: Color(0xFFEFEAE1),
    lifted: Color(0xFFFFFFFF),
    ink: Color(0xFF17140F),
    inkSoft: Color(0xFF574F44),
    muted: Color(0xFF948A7C),
    hairline: Color(0xFFE5DED2),
    gold: Color(0xFFA9844F),
    goldSoft: Color(0xFFF1E7D6),
    onGold: Color(0xFFFFFFFF),
    onyx: Color(0xFF15130F),
    onOnyx: Color(0xFFF6F0E4),
    emerald: Color(0xFF2F7A57),
    ruby: Color(0xFFB2433A),
    sapphire: Color(0xFF3E6690),
    amber: Color(0xFFB7801F),
    shadow: Color(0x1A2B2116),
    isDark: false,
  );

  static const dark = AtelierPalette(
    canvas: Color(0xFF0D0C0A),
    surface: Color(0xFF161411),
    raised: Color(0xFF1C1915),
    sunken: Color(0xFF1F1C18),
    lifted: Color(0xFF332D25),
    ink: Color(0xFFF3EDE2),
    inkSoft: Color(0xFFC2B8A8),
    muted: Color(0xFF857B6D),
    hairline: Color(0xFF2A2621),
    gold: Color(0xFFD5B27A),
    goldSoft: Color(0xFF2B2418),
    onGold: Color(0xFF1A140B),
    onyx: Color(0xFF1E1B16),
    onOnyx: Color(0xFFF6F0E4),
    emerald: Color(0xFF5DB88B),
    ruby: Color(0xFFE07A6E),
    sapphire: Color(0xFF7FA6D1),
    amber: Color(0xFFE3B05A),
    shadow: Color(0x66000000),
    isDark: true,
  );

  static AtelierPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  /// Status colour for a [AtelierTone].
  Color tone(AtelierTone tone) => switch (tone) {
    AtelierTone.neutral => inkSoft,
    AtelierTone.gold => gold,
    AtelierTone.emerald => emerald,
    AtelierTone.ruby => ruby,
    AtelierTone.sapphire => sapphire,
    AtelierTone.amber => amber,
  };

  /// Soft, low-contrast card shadow (none in dark mode, hairlines do the work).
  List<BoxShadow> get softShadow => isDark
      ? const []
      : [
          BoxShadow(
            color: shadow,
            blurRadius: 18,
            spreadRadius: -8,
            offset: const Offset(0, 8),
          ),
        ];

  /// Lifted shadow for floating chrome (dock, sheets, toasts).
  List<BoxShadow> get floatShadow => [
    BoxShadow(
      color: isDark ? const Color(0x99000000) : const Color(0x262B2116),
      blurRadius: 32,
      spreadRadius: -6,
      offset: const Offset(0, 16),
    ),
  ];

  /// Champagne-gold gradient used sparingly for primary emphasis.
  LinearGradient get goldGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: isDark
        ? const [Color(0xFFE6C995), Color(0xFFB98F52)]
        : const [Color(0xFFC6A16A), Color(0xFF9A7442)],
  );
}

/// Semantic status tones.
enum AtelierTone { neutral, gold, emerald, ruby, sapphire, amber }

extension AtelierContext on BuildContext {
  AtelierPalette get atelier => AtelierPalette.of(this);

  bool get reduceMotion => MediaQuery.maybeDisableAnimationsOf(this) ?? false;
}

/// Spacing scale (4pt grid).
abstract final class AtelierSpace {
  static const s2 = 2.0;
  static const s4 = 4.0;
  static const s6 = 6.0;
  static const s8 = 8.0;
  static const s10 = 10.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s20 = 20.0;
  static const s24 = 24.0;
  static const s32 = 32.0;
  static const s40 = 40.0;
  static const s48 = 48.0;

  /// Horizontal page gutter that grows with the viewport.
  static double gutter(double width) => width >= 1200
      ? 40
      : width >= 720
      ? 28
      : 18;
}

/// Corner radii.
abstract final class AtelierRadius {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 22.0;
  static const xl = 28.0;
  static const pill = 999.0;
}

/// Motion tokens.
abstract final class AtelierMotion {
  static const quick = Duration(milliseconds: 180);
  static const base = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 560);
  static const lazy = Duration(milliseconds: 900);

  /// Material 3 "emphasized" — fast start, long soft landing.
  static const emphasized = Cubic(0.2, 0, 0, 1);

  /// Gentle overshoot for selection indicators.
  static const settle = Cubic(0.34, 1.36, 0.64, 1);

  /// Per-item stagger for list reveals.
  static const stagger = Duration(milliseconds: 45);
}

/// Typography: a high-contrast serif for display numerals and titles, a
/// neutral grotesk for everything functional.
abstract final class AtelierType {
  static const _tabular = [FontFeature.tabularFigures()];

  /// Lining, tabular numerals: the serif's old-style digits read "1" as "I".
  static const _display = [
    FontFeature.tabularFigures(),
    FontFeature.liningFigures(),
  ];

  /// Large editorial serif — page titles, hero values.
  static TextStyle display(
    Color color, {
    double size = 34,
    FontWeight? weight,
  }) => GoogleFonts.cormorantGaramond(
    fontSize: size,
    fontWeight: weight ?? FontWeight.w600,
    height: 1.05,
    letterSpacing: -0.4,
    color: color,
    fontFeatures: _display,
  );

  /// Section / card titles.
  static TextStyle title(Color color, {double size = 16}) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: -0.2,
    color: color,
  );

  static TextStyle body(Color color, {double size = 14}) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: color,
  );

  static TextStyle label(Color color, {double size = 13, FontWeight? weight}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w600,
        height: 1.2,
        letterSpacing: -0.05,
        color: color,
      );

  static TextStyle caption(Color color, {double size = 12}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w500,
        height: 1.35,
        color: color,
      );

  /// Spaced small caps used as quiet section markers.
  static TextStyle overline(Color color) => GoogleFonts.inter(
    fontSize: 10.5,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 1.6,
    color: color,
  );

  /// Functional numbers (amounts in rows, counts) — tabular so they align.
  static TextStyle figure(
    Color color, {
    double size = 15,
    FontWeight? weight,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: weight ?? FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.2,
    color: color,
    fontFeatures: _tabular,
  );
}
