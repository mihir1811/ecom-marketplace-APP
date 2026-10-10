import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Colour roles for the "Atelier" workspace (seller + shared buyer pages).
///
/// The workspace is deliberately quiet: calm canvas / surfaces, one accent
/// ("gold" role) for focus and value, and muted gem tones that are only used
/// to carry status. Concrete values come from the active [AppPalette].
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
    required this.floatShadowColor,
    required this.goldGradientColors,
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

  /// Accent role (champagne gold, soft gold, ice blue… per palette).
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
  final Color floatShadowColor;
  final List<Color> goldGradientColors;
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
    floatShadowColor: Color(0x262B2116),
    goldGradientColors: [Color(0xFFC6A16A), Color(0xFF9A7442)],
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
    floatShadowColor: Color(0x99000000),
    goldGradientColors: [Color(0xFFE6C995), Color(0xFFB98F52)],
    isDark: true,
  );

  /// Palette for [context]: the active [AppPalette] when its brightness
  /// matches the ambient theme, otherwise the neutral light / dark set.
  static AtelierPalette of(BuildContext context) =>
      AppPalette.resolve(context).atelier;

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
      color: floatShadowColor,
      blurRadius: 32,
      spreadRadius: -6,
      offset: const Offset(0, 16),
    ),
  ];

  /// Accent gradient used sparingly for primary emphasis.
  LinearGradient get goldGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: goldGradientColors,
  );
}

/// Semantic status tones.
enum AtelierTone { neutral, gold, emerald, ruby, sapphire, amber }
