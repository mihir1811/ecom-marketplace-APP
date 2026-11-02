import 'package:flutter/material.dart';
import 'package:gemstone/core/theme/app_fonts.dart';

import 'app_palette.dart';

/// Luxe colour tokens, resolved from the active [AppPalette]. Shared by the
/// home experience and the redesigned catalog flows.
@immutable
class LuxePalette {
  const LuxePalette({
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

  static const light = LuxePalette(
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

  static const dark = LuxePalette(
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

  static LuxePalette of(BuildContext context) =>
      AppPalette.resolve(context).luxe;

  /// Positive (in stock, success) and caution (discount, alerts) tones.
  Color get positive =>
      isDark ? const Color(0xFF7BC8A0) : const Color(0xFF2F7A55);
  Color get caution =>
      isDark ? const Color(0xFFE59A7E) : const Color(0xFFB4532F);
}

/// Tokens for the always-dark hero stage, dark feature cards and the
/// drawer "vault". Values are set per [AppPalette].
@immutable
class LuxeStagePalette {
  const LuxeStagePalette({
    required this.obsidian,
    required this.raised,
    required this.glow,
    required this.vaultTop,
    required this.vault,
    required this.vaultBottom,
    required this.ink,
    required this.inkMuted,
    required this.gold,
    required this.goldDeep,
    required this.goldLight,
  });

  /// Stage base.
  final Color obsidian;

  /// Lighter top stop for stage gradients.
  final Color raised;

  /// Tinted centre of the stage's radial glow.
  final Color glow;

  /// Three-stop warm "vault" gradient (drawer, wallet, profile heroes).
  final Color vaultTop;
  final Color vault;
  final Color vaultBottom;
  final Color ink;
  final Color inkMuted;

  /// Stage accent and its deeper / lighter companions.
  final Color gold;
  final Color goldDeep;
  final Color goldLight;
}

/// Always-dark hero stage tokens for the active palette.
abstract final class LuxeStage {
  static LuxeStagePalette get _s => AppPalette.current.stage;

  static Color get obsidian => _s.obsidian;
  static Color get raised => _s.raised;
  static Color get glow => _s.glow;
  static Color get vaultTop => _s.vaultTop;
  static Color get vault => _s.vault;
  static Color get vaultBottom => _s.vaultBottom;
  static Color get ink => _s.ink;
  static Color get inkMuted => _s.inkMuted;
  static Color get gold => _s.gold;
  static Color get goldDeep => _s.goldDeep;
  static Color get goldLight => _s.goldLight;
  static const glass = Color(0x14FFFFFF);
  static const glassBorder = Color(0x29FFFFFF);
}

/// Editorial type scale: [AppFonts.display] display, [AppFonts.secondary] for interface.
abstract final class LuxeType {
  static TextStyle display(double size, Color color) => AppFonts.display(
    fontSize: size,
    height: 1.02,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.4,
    color: color,
  );

  static TextStyle displayItalic(double size, Color color) =>
      display(size, color).copyWith(fontStyle: FontStyle.italic);

  static TextStyle eyebrow(Color color) => AppFonts.secondary(
    fontSize: 11,
    height: 1.2,
    fontWeight: FontWeight.w500,
    letterSpacing: 2.6,
    color: color,
  );

  static TextStyle body(Color color, {double size = 15}) => AppFonts.secondary(
    fontSize: size,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: color,
  );

  static TextStyle label(Color color, {double size = 13}) => AppFonts.secondary(
    fontSize: size,
    height: 1.25,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
    color: color,
  );

  static TextStyle figure(Color color, {double size = 15}) => AppFonts.primary(
    fontSize: size,
    height: 1.2,
    fontWeight: FontWeight.w500,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

/// Motion tokens shared by every luxe surface.
abstract final class LuxeMotion {
  static const reveal = Duration(milliseconds: 900);
  static const fast = Duration(milliseconds: 220);
  static const medium = Duration(milliseconds: 420);
  static const stagger = Duration(milliseconds: 90);

  /// Expo-out: fast start, long luxurious settle.
  static const Curve settle = Cubic(0.16, 1, 0.3, 1);
  static const Curve press = Cubic(0.2, 0, 0, 1);
}

/// Spacing scale for luxe layouts.
abstract final class LuxeSpace {
  static const gutter = 14.0;
  static const section = 40.0;
  static const radius = 22.0;
  static const radiusSmall = 14.0;
}
