import 'package:flutter/material.dart';

/// Which finder owns the Single/Melee screen background palette.
enum MeleeBgFamily {
  labGrown,
  natural,
  gemstone,
}

/// Raw color palette definition for GemWorld.
/// Exposes static constants for styling light and dark modes.
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

  /// Catalog-specific Single/Melee screen background families.
  static const labGrownSingleBg = Color(0xFFEEF8F3);
  static const labGrownMeleeBg = Color(0xFFEDF7FB);
  static const naturalSingleBg = Color(0xFFF0F1F6);
  static const gemstoneBg = Color(0xFFF5F6FA);

  /// Soft melee tint of the screen background (same family as [creamBg]/[obsidianBg]).
  ///
  /// Light mode by [family]:
  /// - [MeleeBgFamily.labGrown]: #eef8f3 → #edf7fb
  /// - [MeleeBgFamily.natural]: #f0f1f6 → [creamBg] (theme default / `--background`)
  /// - [MeleeBgFamily.gemstone]: always #f5f6fa (no melee shift)
  static Color screenBg({
    required bool isDark,
    bool melee = false,
    MeleeBgFamily family = MeleeBgFamily.natural,
  }) {
    if (isDark) {
      return melee ? const Color(0xFF151C24) : obsidianBg;
    }
    switch (family) {
      case MeleeBgFamily.labGrown:
        return melee ? labGrownMeleeBg : labGrownSingleBg;
      case MeleeBgFamily.natural:
        return melee ? creamBg : naturalSingleBg;
      case MeleeBgFamily.gemstone:
        return gemstoneBg;
    }
  }

  /// Soft melee tint for sticky surfaces (nav / bottom bar).
  /// Matches [screenBg] light-mode families so sticky chrome tracks the page.
  static Color surfaceBg({
    required bool isDark,
    bool melee = false,
    MeleeBgFamily family = MeleeBgFamily.natural,
  }) {
    if (isDark) {
      return melee ? const Color(0xFF1B242E) : charcoalDark;
    }
    return screenBg(isDark: false, melee: melee, family: family);
  }

  /// Shared duration for melee background color transitions.
  static const Duration meleeBgDuration = Duration(milliseconds: 1200);

  // Text colors (Light mode)
  static const textPrimaryLight = Color(0xFF111827);
  static const textSecondaryLight = Color(0xFF4B5563);
  static const textMutedLight = Color(0xFF9CA3AF);

  // Text colors (Dark mode)
  static const textPrimaryDark = Color(0xFFF9FAFB);
  static const textSecondaryDark = Color(0xFFD1D5DB);
  static const textMutedDark = Color(0xFF6B7280);

  // Semantic Statuses
  static const error = Color(0xFFDC2626);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFCA8A04);
  static const info = Color(0xFF2563EB);
}
