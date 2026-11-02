import 'package:flutter/material.dart';
import 'package:gemstone/core/theme/app_fonts.dart';

/// Colour tokens for the authentication experience.
///
/// Two moods share one structure: [noir] (obsidian + champagne) for dark
/// mode and [ivory] (warm paper + ink) for light mode.
@immutable
class AuthPalette {
  const AuthPalette({
    required this.isDark,
    required this.bg,
    required this.surface,
    required this.surfaceFocus,
    required this.hairline,
    required this.hairlineStrong,
    required this.ink,
    required this.inkSoft,
    required this.inkMuted,
    required this.accent,
    required this.accentSoft,
    required this.ctaTop,
    required this.ctaBottom,
    required this.onCta,
    required this.danger,
    required this.dangerSoft,
    required this.success,
    required this.successSoft,
    required this.scrim,
  });

  final bool isDark;
  final Color bg;
  final Color surface;
  final Color surfaceFocus;
  final Color hairline;
  final Color hairlineStrong;
  final Color ink;
  final Color inkSoft;
  final Color inkMuted;
  final Color accent;
  final Color accentSoft;
  final Color ctaTop;
  final Color ctaBottom;
  final Color onCta;
  final Color danger;
  final Color dangerSoft;
  final Color success;
  final Color successSoft;
  final Color scrim;

  static const noir = AuthPalette(
    isDark: true,
    bg: Color(0xFF08080A),
    surface: Color(0x0DFFFFFF),
    surfaceFocus: Color(0x17FFFFFF),
    hairline: Color(0x1CFFFFFF),
    hairlineStrong: Color(0x38FFFFFF),
    ink: Color(0xFFF5EFE4),
    inkSoft: Color(0xC7F5EFE4),
    inkMuted: Color(0x8CF5EFE4),
    accent: Color(0xFFD9BC8C),
    accentSoft: Color(0x24D9BC8C),
    ctaTop: Color(0xFFEBD6AE),
    ctaBottom: Color(0xFFC29E66),
    onCta: Color(0xFF15110B),
    danger: Color(0xFFEE9283),
    dangerSoft: Color(0x24EE9283),
    success: Color(0xFFA5D6B1),
    successSoft: Color(0x21A5D6B1),
    scrim: Color(0xB3000000),
  );

  static const ivory = AuthPalette(
    isDark: false,
    bg: Color(0xFFF6F2EA),
    surface: Color(0x99FFFFFF),
    surfaceFocus: Color(0xFFFFFFFF),
    hairline: Color(0x241A1610),
    hairlineStrong: Color(0x421A1610),
    ink: Color(0xFF15120D),
    inkSoft: Color(0xC715120D),
    inkMuted: Color(0x9415120D),
    accent: Color(0xFF8A6633),
    accentSoft: Color(0x1F8A6633),
    ctaTop: Color(0xFF2A241B),
    ctaBottom: Color(0xFF0E0C09),
    onCta: Color(0xFFF8F2E6),
    danger: Color(0xFFB0402E),
    dangerSoft: Color(0x1AB0402E),
    success: Color(0xFF2E7A4D),
    successSoft: Color(0x1A2E7A4D),
    scrim: Color(0x66000000),
  );

  static AuthPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? noir : ivory;

  LinearGradient get ctaGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [ctaTop, ctaBottom],
  );
}

/// Type scale: [AppFonts.display] for statements, [AppFonts.secondary] for UI.
abstract final class AuthType {
  static TextStyle display(AuthPalette p) => AppFonts.display(
    fontSize: 38,
    fontWeight: FontWeight.w500,
    height: 1.05,
    letterSpacing: -0.4,
    color: p.ink,
  );

  static TextStyle title(AuthPalette p) => AppFonts.display(
    fontSize: 26,
    fontWeight: FontWeight.w600,
    height: 1.15,
    color: p.ink,
  );

  static TextStyle eyebrow(AuthPalette p) => AppFonts.secondary(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 2.6,
    height: 1.3,
    color: p.accent,
  );

  static TextStyle body(AuthPalette p) => AppFonts.secondary(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: p.inkSoft,
  );

  static TextStyle field(AuthPalette p) => AppFonts.secondary(
    fontSize: 15.5,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: p.ink,
  );

  static TextStyle label(AuthPalette p) => AppFonts.secondary(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    height: 1.35,
    color: p.ink,
  );

  static TextStyle caption(AuthPalette p) => AppFonts.secondary(
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: p.inkMuted,
  );

  static TextStyle button(AuthPalette p) => AppFonts.primary(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    height: 1.2,
    color: p.onCta,
  );
}

/// Spacing and radius scale for the auth kit.
abstract final class AuthSpace {
  static const s4 = 4.0;
  static const s6 = 6.0;
  static const s8 = 6.0;
  static const s12 = 8.0;
  static const s16 = 12.0;
  static const s20 = 14.0;
  static const s24 = 16.0;
  static const s32 = 20.0;
  static const s40 = 24.0;
  static const s48 = 28.0;

  static const rField = 16.0;
  static const rCard = 22.0;
  static const rPill = 999.0;

  static const fieldHeight = 52.0;
  static const buttonHeight = 52.0;
  static const contentMaxWidth = 440.0;
}

/// Shared timings and curves so every motion feels like one system.
abstract final class AuthMotion {
  static const quick = Duration(milliseconds: 180);
  static const base = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 560);
  static const entrance = Duration(milliseconds: 760);

  /// Expo-out: fast start, long silky settle.
  static const ease = Cubic(0.16, 1, 0.3, 1);
  static const easeInOut = Cubic(0.65, 0, 0.35, 1);

  static Duration stagger(int index) =>
      Duration(milliseconds: 120 + index * 70);

  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);
}
