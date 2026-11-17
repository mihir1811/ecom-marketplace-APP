import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'luxe_scope.dart';

/// Which finder a Single/Melee control belongs to (picks its accent).
enum MeleeBgFamily {
  labGrown,
  natural,

  /// Gemstone finder — Natural stone type.
  gemstoneNatural,

  /// Gemstone finder — Lab Grown stone type.
  gemstoneLabGrown,
}

/// Legacy colour API for GemWorld.
///
/// Every brand colour resolves from the active [AppPalette]: static getters
/// read [AppPalette.current]; `(context)` helpers read the theme's palette.
/// Only semantic status colours stay fixed.
class AppColors {
  const AppColors._();

  static AppChromeColors get _chrome => AppPalette.current.chrome;

  static AppChromeColors _of(BuildContext context) =>
      AppPalette.resolve(context).chrome;

  // Primary Palette (Luxury Charcoal & Navy)
  static Color get charcoal => _chrome.charcoal;
  static Color get charcoalLight => _chrome.charcoalLight;
  static Color get charcoalDark => _chrome.charcoalDark;

  // Accent / Luxury Metal (Bronze / Gold)
  static Color get bronze => _chrome.bronze;
  static Color get bronzeLight => _chrome.bronzeLight;
  static Color get bronzeDark => _chrome.bronzeDark;

  // Terracotta / Alert Coral (Vibrant Accent seen in notifications & badges)
  static const terracotta = Color(0xFFD9463E);
  static const terracottaLight = Color(0xFFE5736E);

  // Light Mode Surfaces (white page, neutral grey fills and hairlines)
  static Color get creamBg => _chrome.creamBg;
  static Color get sandSurface => _chrome.sandSurface;
  static Color get warmWhite => _chrome.warmWhite;
  static Color get warmBorder => _chrome.warmBorder;

  // Dark Mode Surfaces (Sleek Obsidian and Charcoal)
  static Color get obsidianBg => _chrome.obsidianBg;
  static Color get slateSurface => _chrome.slateSurface;
  static Color get slateBorder => _chrome.slateBorder;

  /// Soft highlight used by melee water-reveal rings (lighter than bronze).
  static Color get meleeRevealAccentLight => _chrome.meleeRevealAccentLight;
  static Color get meleeRevealAccentDark => _chrome.meleeRevealAccentDark;

  /// Natural melee accent — cool slate (contrasts peach melee bg).
  static Color get naturalMeleeAccent => _chrome.naturalMeleeAccent;
  static Color get naturalMeleeAccentLight => _chrome.naturalMeleeAccentLight;

  /// Brand / finder accent. Natural melee uses cool slate; everything else stays bronze.
  static Color finderAccent(
    BuildContext context, {
    MeleeBgFamily family = MeleeBgFamily.natural,
    bool melee = false,
  }) {
    final luxe = LuxeScope.paletteOf(context);
    if (luxe != null) return luxe.accent;
    final c = _of(context);
    if (family == MeleeBgFamily.natural && melee) {
      return c.naturalMeleeAccent;
    }
    return isDark(context) ? c.bronzeLight : c.bronze;
  }

  /// Softer companion to [finderAccent] (unselected / glow).
  static Color finderAccentSoft(
    BuildContext context, {
    MeleeBgFamily family = MeleeBgFamily.natural,
    bool melee = false,
  }) {
    final luxe = LuxeScope.paletteOf(context);
    if (luxe != null) return luxe.accent.withValues(alpha: 0.45);
    final c = _of(context);
    if (family == MeleeBgFamily.natural && melee) {
      return c.naturalMeleeAccentLight;
    }
    return c.bronzeLight;
  }

  /// Resolves gemstone finder palette from Natural / Lab Grown stone type.
  /// Defaults to Natural when unset so Single/Melee still have a stable tint.
  static MeleeBgFamily gemstoneFamily({required String? stoneType}) {
    if (stoneType == 'Lab Grown') return MeleeBgFamily.gemstoneLabGrown;
    return MeleeBgFamily.gemstoneNatural;
  }

  /// Finder screen background. Every family and mode uses the plain page
  /// colour; the finders no longer tint the page.
  static Color screenBg({
    bool melee = false,
    MeleeBgFamily family = MeleeBgFamily.natural,
  }) => creamBg;

  /// Background for sticky finder chrome (nav / bottom bar); tracks
  /// [screenBg].
  static Color surfaceBg({
    bool melee = false,
    MeleeBgFamily family = MeleeBgFamily.natural,
  }) => screenBg(melee: melee, family: family);

  /// Finder screen background for [context]: the plain page colour of the
  /// active theme, whatever the family or mode.
  static Color screenBgFor(
    BuildContext context, {
    bool melee = false,
    MeleeBgFamily family = MeleeBgFamily.natural,
  }) => bg(context);

  // Text colors (Light mode)
  static Color get textPrimaryLight => _chrome.textPrimaryLight;
  static Color get textSecondaryLight => _chrome.textSecondaryLight;
  static Color get textMutedLight => _chrome.textMutedLight;

  // Text colors (Dark mode)
  static Color get textPrimaryDark => _chrome.textPrimaryDark;
  static Color get textSecondaryDark => _chrome.textSecondaryDark;
  static Color get textMutedDark => _chrome.textMutedDark;

  /// True when the ambient theme is dark.
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Screen background that adapts to the active theme.
  static Color bg(BuildContext context) =>
      LuxeScope.paletteOf(context)?.canvas ??
      (isDark(context) ? _of(context).obsidianBg : _of(context).creamBg);

  /// Card / container surface that adapts to the active theme.
  static Color surface(BuildContext context) =>
      LuxeScope.paletteOf(context)?.surfaceRaised ??
      (isDark(context) ? _of(context).slateSurface : _of(context).sandSurface);

  /// Elevated card surface (white card on light, slate card on dark).
  static Color card(BuildContext context) =>
      LuxeScope.paletteOf(context)?.surface ??
      (isDark(context) ? _of(context).slateSurface : _of(context).warmWhite);

  /// Border color that adapts to the active theme.
  static Color border(BuildContext context) =>
      LuxeScope.paletteOf(context)?.hairline ??
      (isDark(context) ? _of(context).slateBorder : _of(context).warmBorder);

  /// Input field fill that adapts to the active theme.
  static Color field(BuildContext context) =>
      LuxeScope.paletteOf(context)?.surface ??
      (isDark(context) ? _of(context).slateSurface : _of(context).warmWhite);

  /// Primary text color that adapts to the active theme.
  static Color textPrimary(BuildContext context) =>
      LuxeScope.paletteOf(context)?.ink ??
      (isDark(context)
          ? _of(context).textPrimaryDark
          : _of(context).textPrimaryLight);

  /// Secondary text color that adapts to the active theme.
  static Color textSecondary(BuildContext context) =>
      LuxeScope.paletteOf(context)?.inkMuted ??
      (isDark(context)
          ? _of(context).textSecondaryDark
          : _of(context).textSecondaryLight);

  /// Muted text color that adapts to the active theme.
  static Color textMuted(BuildContext context) =>
      LuxeScope.paletteOf(context)?.inkFaint ??
      (isDark(context)
          ? _of(context).textMutedDark
          : _of(context).textMutedLight);

  /// Selected chip / segment fill. Inverts against the surface so the
  /// chosen item stays obvious in both themes.
  static Color selectedFill(BuildContext context) =>
      LuxeScope.paletteOf(context)?.ink ??
      (isDark(context) ? _of(context).warmWhite : _of(context).charcoal);

  /// Text / icon color on [selectedFill].
  static Color onSelected(BuildContext context) =>
      LuxeScope.paletteOf(context)?.canvas ??
      (isDark(context) ? _of(context).charcoal : _of(context).warmWhite);

  /// Accent that adapts to the active palette (bronze in the classic look).
  static Color accent(BuildContext context) => _of(context).bronze;

  /// Drawer / nav-row selected fill — soft elevate in dark, solid charcoal in light.
  static Color navSelectedFill(BuildContext context) =>
      isDark(context) ? _of(context).charcoalLight : _of(context).charcoal;

  /// Text / icon color on [navSelectedFill].
  static Color navOnSelected(BuildContext context) =>
      isDark(context) ? _of(context).textPrimaryDark : _of(context).warmWhite;

  // Semantic Statuses
  static const error = Color(0xFFDC2626);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFCA8A04);
  static const info = Color(0xFF2563EB);
}
