import 'package:flutter/material.dart';

/// Which finder owns the Single/Melee screen background palette.
enum MeleeBgFamily {
  labGrown,
  natural,

  /// Gemstone finder — Natural stone type.
  gemstoneNatural,

  /// Gemstone finder — Lab Grown stone type.
  gemstoneLabGrown,
}

/// Raw color palette definition for GemWorld.
/// Exposes static constants for styling light mode.
class AppColors {
  const AppColors._();

  // Primary Palette (Luxury Charcoal & Navy)
  static const charcoal = Color(0xFF111827);
  static const charcoalLight = Color(0xFF1F2937);
  static const charcoalDark = Color(0xFF030712);

  // Accent / Luxury Metal (Bronze / Gold)
  static const bronze = Color(0xFF9E7753);
  static const bronzeLight = Color(0xFFBCA38B);
  static const bronzeDark = Color(0xFF805A37);

  // Terracotta / Alert Coral (Vibrant Accent seen in notifications & badges)
  static const terracotta = Color(0xFFD9463E);
  static const terracottaLight = Color(0xFFE5736E);

  // Light Mode Surfaces (Warm Cream and Soft Sands)
  static const creamBg = Color(0xFFFCFCFA);
  static const sandSurface = Color(0xFFF4F4F0);
  static const warmWhite = Color(0xFFFFFFFF);
  static const warmBorder = Color(0xFFE2E2DC);

  // Dark Mode Surfaces (Sleek Obsidian and Charcoal)
  static const obsidianBg = Color(0xFF0B0C0E);
  static const slateSurface = Color(0xFF16181B);
  static const slateBorder = Color(0xFF2E3035);

  /// Catalog Single/Melee screen backgrounds — light contrasting pairs
  /// (cool ↔ warm opposites; never pure white/black).
  /// Natural diamond finder — cool mist ↔ warm peach
  static const naturalSingleBg = Color.fromARGB(
    255,
    190,
    217,
    248,
  ); // cool mist (default)
  static const naturalMeleeBg = Color.fromARGB(255, 248, 213, 182); // peach

  /// Lab-grown diamond finder — warm blush ↔ cool mint
  static const labGrownSingleBg = Color.fromARGB(
    255,
    242,
    248,
    190,
  ); // warm blush (default)
  static const labGrownMeleeBg = Color(0xFFC8DED6); // cool mint

  /// Gemstone — Natural stone type — cool lilac ↔ warm apricot
  static const gemstoneNaturalSingleBg = Color.fromARGB(
    255,
    224,
    205,
    255,
  ); // cool lilac (default)
  static const gemstoneNaturalMeleeBg = Color.fromARGB(
    255,
    202,
    247,
    199,
  ); // warm apricot

  /// Gemstone — Lab Grown stone type — warm sand ↔ cool steel
  static const gemstoneLabSingleBg = Color.fromARGB(
    255,
    248,
    199,
    250,
  ); // warm sand (default)
  static const gemstoneLabMeleeBg = Color.fromARGB(
    255,
    248,
    196,
    196,
  ); // cool steel

  /// Dark-mode tinted bands — unused; dark mode uses neutral surfaces only.
  static const naturalSingleBgDark = Color(0xFF4A4036);
  static const naturalMeleeBgDark = Color(0xFF5E5144);
  static const labGrownSingleBgDark = Color(0xFF2A3832);
  static const labGrownMeleeBgDark = Color(0xFF344840);
  static const gemstoneNaturalSingleBgDark = Color(0xFF4A3E34);
  static const gemstoneNaturalMeleeBgDark = Color(0xFF5C4C3E);
  static const gemstoneLabSingleBgDark = Color(0xFF2C3440);
  static const gemstoneLabMeleeBgDark = Color(0xFF364050);

  /// Soft highlight used by melee water-reveal rings (lighter than bronze).
  static const meleeRevealAccentLight = Color(0xFFD4B896);
  static const meleeRevealAccentDark = Color(0xFFE8D4B0);

  /// Natural melee accent — cool slate (contrasts peach melee bg).
  static const naturalMeleeAccent = Color(0xFF5C6B7A);
  static const naturalMeleeAccentLight = Color(0xFF8A98A6);

  /// Brand / finder accent. Natural melee uses cool slate; everything else stays bronze.
  static Color finderAccent(
    BuildContext context, {
    MeleeBgFamily family = MeleeBgFamily.natural,
    bool melee = false,
  }) {
    if (family == MeleeBgFamily.natural && melee) {
      return naturalMeleeAccent;
    }
    return isDark(context) ? bronzeLight : bronze;
  }

  /// Softer companion to [finderAccent] (unselected / glow).
  static Color finderAccentSoft(
    BuildContext context, {
    MeleeBgFamily family = MeleeBgFamily.natural,
    bool melee = false,
  }) {
    if (family == MeleeBgFamily.natural && melee) {
      return naturalMeleeAccentLight;
    }
    return bronzeLight;
  }

  /// Resolves gemstone finder palette from Natural / Lab Grown stone type.
  /// Defaults to Natural when unset so Single/Melee still have a stable tint.
  static MeleeBgFamily gemstoneFamily({required String? stoneType}) {
    if (stoneType == 'Lab Grown') return MeleeBgFamily.gemstoneLabGrown;
    return MeleeBgFamily.gemstoneNatural;
  }

  /// Soft melee tint of the screen background (light-mode pastels).
  static Color screenBg({
    bool melee = false,
    MeleeBgFamily family = MeleeBgFamily.natural,
  }) {
    switch (family) {
      case MeleeBgFamily.labGrown:
        return melee ? labGrownMeleeBg : labGrownSingleBg;
      case MeleeBgFamily.natural:
        return melee ? naturalMeleeBg : naturalSingleBg;
      case MeleeBgFamily.gemstoneNatural:
        return melee ? gemstoneNaturalMeleeBg : gemstoneNaturalSingleBg;
      case MeleeBgFamily.gemstoneLabGrown:
        return melee ? gemstoneLabMeleeBg : gemstoneLabSingleBg;
    }
  }

  /// Soft melee tint for sticky surfaces (nav / bottom bar).
  /// Matches [screenBg] light-mode families so sticky chrome tracks the page.
  static Color surfaceBg({
    bool melee = false,
    MeleeBgFamily family = MeleeBgFamily.natural,
  }) {
    return screenBg(melee: melee, family: family);
  }

  /// Melee-family screen tint. Light mode uses pastels; dark mode stays neutral
  /// (no family color shift — looks muddy on dark surfaces).
  static Color screenBgFor(
    BuildContext context, {
    bool melee = false,
    MeleeBgFamily family = MeleeBgFamily.natural,
  }) {
    if (isDark(context)) return slateSurface;
    return screenBg(melee: melee, family: family);
  }

  /// Shared duration for melee background color transitions.
  static const Duration meleeBgDuration = Duration(milliseconds: 900);

  // Text colors (Light mode)
  static const textPrimaryLight = Color(0xFF111827);
  static const textSecondaryLight = Color(0xFF4B5563);
  static const textMutedLight = Color(0xFF9CA3AF);

  // Text colors (Dark mode)
  static const textPrimaryDark = Color(0xFFF9FAFB);
  static const textSecondaryDark = Color(0xFFD1D5DB);
  static const textMutedDark = Color(0xFF6B7280);

  /// True when the ambient theme is dark.
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Screen background that adapts to the active theme.
  static Color bg(BuildContext context) =>
      isDark(context) ? obsidianBg : creamBg;

  /// Card / container surface that adapts to the active theme.
  static Color surface(BuildContext context) =>
      isDark(context) ? slateSurface : sandSurface;

  /// Elevated card surface (white card on light, slate card on dark).
  static Color card(BuildContext context) =>
      isDark(context) ? slateSurface : warmWhite;

  /// Border color that adapts to the active theme.
  static Color border(BuildContext context) =>
      isDark(context) ? slateBorder : warmBorder;

  /// Input field fill that adapts to the active theme.
  static Color field(BuildContext context) =>
      isDark(context) ? slateSurface : warmWhite;

  /// Primary text color that adapts to the active theme.
  static Color textPrimary(BuildContext context) =>
      isDark(context) ? textPrimaryDark : textPrimaryLight;

  /// Secondary text color that adapts to the active theme.
  static Color textSecondary(BuildContext context) =>
      isDark(context) ? textSecondaryDark : textSecondaryLight;

  /// Muted text color that adapts to the active theme.
  static Color textMuted(BuildContext context) =>
      isDark(context) ? textMutedDark : textMutedLight;

  /// Selected chip / segment fill. Inverts against the surface so the
  /// chosen item stays obvious in both themes.
  static Color selectedFill(BuildContext context) =>
      isDark(context) ? warmWhite : charcoal;

  /// Text / icon color on [selectedFill].
  static Color onSelected(BuildContext context) =>
      isDark(context) ? charcoal : warmWhite;

  /// Drawer / nav-row selected fill — soft elevate in dark, solid charcoal in light.
  static Color navSelectedFill(BuildContext context) =>
      isDark(context) ? charcoalLight : charcoal;

  /// Text / icon color on [navSelectedFill].
  static Color navOnSelected(BuildContext context) =>
      isDark(context) ? textPrimaryDark : warmWhite;

  // Semantic Statuses
  static const error = Color(0xFFDC2626);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFCA8A04);
  static const info = Color(0xFF2563EB);
}
