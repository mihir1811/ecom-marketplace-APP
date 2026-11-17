import 'package:flutter/material.dart';

import 'atelier_palette.dart';
import 'luxe_tokens.dart';

/// Every colour palette the app can render. The first four are offered in
/// Settings; the `*Night` entries are dark companions used for always-dark
/// chrome (drawer menu) while a light palette is active.
enum AppPaletteId {
  ivory,
  onyx,
  emeraldPearl,
  midnightIce,
  emeraldNight,
  midnightNight,
}

/// Brand-level colours behind the legacy [AppColors] API. Light / dark
/// variants live side by side; [AppColors] picks by ambient brightness.
@immutable
class AppChromeColors {
  const AppChromeColors({
    required this.charcoal,
    required this.charcoalLight,
    required this.charcoalDark,
    required this.bronze,
    required this.bronzeLight,
    required this.bronzeDark,
    required this.creamBg,
    required this.sandSurface,
    required this.warmWhite,
    required this.warmBorder,
    required this.obsidianBg,
    required this.slateSurface,
    required this.slateBorder,
    required this.textPrimaryLight,
    required this.textSecondaryLight,
    required this.textMutedLight,
    required this.textPrimaryDark,
    required this.textSecondaryDark,
    required this.textMutedDark,
    required this.meleeRevealAccentLight,
    required this.meleeRevealAccentDark,
    required this.naturalMeleeAccent,
    required this.naturalMeleeAccentLight,
    required this.shadowTint,
    required this.classicTints,
  });

  /// Primary (deep brand) colour and its lighter / darker companions.
  final Color charcoal;
  final Color charcoalLight;
  final Color charcoalDark;

  /// Accent (text-safe) with its lighter / darker companions.
  final Color bronze;
  final Color bronzeLight;
  final Color bronzeDark;

  // Light surfaces.
  final Color creamBg;
  final Color sandSurface;
  final Color warmWhite;
  final Color warmBorder;

  // Dark surfaces.
  final Color obsidianBg;
  final Color slateSurface;
  final Color slateBorder;

  final Color textPrimaryLight;
  final Color textSecondaryLight;
  final Color textMutedLight;
  final Color textPrimaryDark;
  final Color textSecondaryDark;
  final Color textMutedDark;

  final Color meleeRevealAccentLight;
  final Color meleeRevealAccentDark;
  final Color naturalMeleeAccent;
  final Color naturalMeleeAccentLight;

  /// Base colour for elevation shadows.
  final Color shadowTint;

  /// Whether decorative classic tints (finder pastels, copper auction band)
  /// are used. Brand palettes derive those tints from their own tones.
  final bool classicTints;
}

/// One complete colour palette: every token set the app reads from.
///
/// This is the single source of truth for colour. [AtelierPalette.of],
/// [LuxePalette.of], [LuxeStage], [AppColors] and [AppTheme] all resolve
/// from the active palette, so switching it re-skins every surface.
@immutable
class AppPalette {
  const AppPalette._({
    required this.id,
    required this.label,
    required this.caption,
    required this.brightness,
    required this.dayId,
    required this.nightId,
    required this.atelier,
    required this.luxe,
    required this.stage,
    required this.chrome,
  });

  final AppPaletteId id;

  /// Display name and short descriptor for the Settings chooser.
  final String label;
  final String caption;
  final Brightness brightness;

  /// Light / dark companions (self when already that brightness).
  final AppPaletteId dayId;
  final AppPaletteId nightId;

  final AtelierPalette atelier;
  final LuxePalette luxe;
  final LuxeStagePalette stage;
  final AppChromeColors chrome;

  bool get isDark => brightness == Brightness.dark;
  AppPalette get day => byId(dayId);
  AppPalette get night => byId(nightId);

  /// Palettes offered in Settings, in display order.
  static const selectable = [ivory, onyx, emeraldPearl, midnightIce];

  static const _all = {
    AppPaletteId.ivory: ivory,
    AppPaletteId.onyx: onyx,
    AppPaletteId.emeraldPearl: emeraldPearl,
    AppPaletteId.midnightIce: midnightIce,
    AppPaletteId.emeraldNight: emeraldNight,
    AppPaletteId.midnightNight: midnightNight,
  };

  static AppPalette byId(AppPaletteId id) => _all[id]!;

  static AppPalette _current = ivory;

  /// The palette the app is currently rendering. Read by context-free
  /// token getters ([AppColors] statics, [LuxeStage]).
  static AppPalette get current => _current;

  /// Makes [id] the active palette. Called by the palette preference.
  static void activate(AppPaletteId id) => _current = byId(id);

  /// Palette for [context]: the theme's palette when its brightness matches
  /// the ambient theme, otherwise that palette's day / night companion.
  static AppPalette resolve(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPaletteTheme>()?.palette ?? _current;
    if (palette.brightness == theme.brightness) return palette;
    return theme.brightness == Brightness.dark ? palette.night : palette.day;
  }

  // ── Stage sets ────────────────────────────────────────────────────────

  static const _classicStage = LuxeStagePalette(
    obsidian: Color(0xFF070709),
    raised: Color(0xFF24232A),
    glow: Color(0xFF101A26),
    vaultTop: Color(0xFF2A2318),
    vault: Color(0xFF14110D),
    vaultBottom: Color(0xFF0B0A08),
    ink: Color(0xFFF5F1EA),
    inkMuted: Color(0xFFA8A196),
    gold: Color(0xFFDDBF88),
    goldDeep: Color(0xFF9C7A45),
    goldLight: Color(0xFFF1DDB5),
  );

  static const _emeraldStage = LuxeStagePalette(
    obsidian: Color(0xFF042C27),
    raised: Color(0xFF0B5147),
    glow: Color(0xFF0A4A41),
    vaultTop: Color(0xFF0E5A4F),
    vault: Color(0xFF063C35),
    vaultBottom: Color(0xFF03221E),
    ink: Color(0xFFFAF9F5),
    inkMuted: Color(0xFFA9BDB5),
    gold: Color(0xFFC8A86B),
    goldDeep: Color(0xFF9A7B3F),
    goldLight: Color(0xFFE9D8B0),
  );

  static const _midnightStage = LuxeStagePalette(
    obsidian: Color(0xFF07111F),
    raised: Color(0xFF15263F),
    glow: Color(0xFF12294A),
    vaultTop: Color(0xFF16294A),
    vault: Color(0xFF0B1729),
    vaultBottom: Color(0xFF050C17),
    ink: Color(0xFFFFFFFF),
    inkMuted: Color(0xFF9FB3C8),
    gold: Color(0xFF8FD8FF),
    goldDeep: Color(0xFF4FAEE0),
    goldLight: Color(0xFFD6F1FF),
  );

  // ── Chrome sets ───────────────────────────────────────────────────────

  static const _classicChrome = AppChromeColors(
    charcoal: Color(0xFF111827),
    charcoalLight: Color(0xFF1F2937),
    charcoalDark: Color(0xFF030712),
    bronze: Color(0xFF9E7753),
    bronzeLight: Color(0xFFBCA38B),
    bronzeDark: Color(0xFF805A37),
    creamBg: Color(0xFFFFFFFF),
    sandSurface: Color(0xFFF4F4F5),
    warmWhite: Color(0xFFFFFFFF),
    warmBorder: Color(0xFFE4E4E7),
    obsidianBg: Color(0xFF0B0C0E),
    slateSurface: Color(0xFF16181B),
    slateBorder: Color(0xFF2E3035),
    textPrimaryLight: Color(0xFF111827),
    textSecondaryLight: Color(0xFF4B5563),
    textMutedLight: Color(0xFF9CA3AF),
    textPrimaryDark: Color(0xFFF9FAFB),
    textSecondaryDark: Color(0xFFD1D5DB),
    textMutedDark: Color(0xFF6B7280),
    meleeRevealAccentLight: Color(0xFFD4B896),
    meleeRevealAccentDark: Color(0xFFE8D4B0),
    naturalMeleeAccent: Color(0xFF5C6B7A),
    naturalMeleeAccentLight: Color(0xFF8A98A6),
    shadowTint: Color(0xFF111827),
    classicTints: true,
  );

  static const _emeraldChrome = AppChromeColors(
    charcoal: Color(0xFF063C35),
    charcoalLight: Color(0xFF0B5147),
    charcoalDark: Color(0xFF03221E),
    bronze: Color(0xFF9A7B3F),
    bronzeLight: Color(0xFFC8A86B),
    bronzeDark: Color(0xFF7A5F2C),
    creamBg: Color(0xFFFFFFFF),
    sandSurface: Color(0xFFF4F4F5),
    warmWhite: Color(0xFFFFFFFF),
    warmBorder: Color(0xFFDDE5E1),
    obsidianBg: Color(0xFF031F1B),
    slateSurface: Color(0xFF062B26),
    slateBorder: Color(0xFF15443C),
    textPrimaryLight: Color(0xFF063C35),
    textSecondaryLight: Color(0xFF3E5F57),
    textMutedLight: Color(0xFF8AA199),
    textPrimaryDark: Color(0xFFF4F2EA),
    textSecondaryDark: Color(0xFFC9D8D1),
    textMutedDark: Color(0xFF7C948C),
    meleeRevealAccentLight: Color(0xFFDCC796),
    meleeRevealAccentDark: Color(0xFFE9D8B0),
    naturalMeleeAccent: Color(0xFF0B5147),
    naturalMeleeAccentLight: Color(0xFF6F9188),
    shadowTint: Color(0xFF063C35),
    classicTints: false,
  );

  static const _midnightChrome = AppChromeColors(
    charcoal: Color(0xFF07111F),
    charcoalLight: Color(0xFF0E1C30),
    charcoalDark: Color(0xFF040A13),
    bronze: Color(0xFF1F7FB4),
    bronzeLight: Color(0xFF8FD8FF),
    bronzeDark: Color(0xFF16618A),
    creamBg: Color(0xFFFFFFFF),
    sandSurface: Color(0xFFF4F4F5),
    warmWhite: Color(0xFFFFFFFF),
    warmBorder: Color(0xFFDDE4EA),
    obsidianBg: Color(0xFF050C17),
    slateSurface: Color(0xFF0B1626),
    slateBorder: Color(0xFF1A2A40),
    textPrimaryLight: Color(0xFF07111F),
    textSecondaryLight: Color(0xFF3B4C63),
    textMutedLight: Color(0xFF8A9AAD),
    textPrimaryDark: Color(0xFFF2F7FB),
    textSecondaryDark: Color(0xFFCBD9E3),
    textMutedDark: Color(0xFF7D8DA1),
    meleeRevealAccentLight: Color(0xFFB5E6FF),
    meleeRevealAccentDark: Color(0xFFD6F1FF),
    naturalMeleeAccent: Color(0xFF0E1C30),
    naturalMeleeAccentLight: Color(0xFF6F8299),
    shadowTint: Color(0xFF07111F),
    classicTints: false,
  );

  // ── Palettes ──────────────────────────────────────────────────────────

  /// Plain white light theme (original light look).
  static const ivory = AppPalette._(
    id: AppPaletteId.ivory,
    label: 'White',
    caption: 'Light',
    brightness: Brightness.light,
    dayId: AppPaletteId.ivory,
    nightId: AppPaletteId.onyx,
    atelier: AtelierPalette.light,
    luxe: LuxePalette.light,
    stage: _classicStage,
    chrome: _classicChrome,
  );

  /// Obsidian / onyx dark theme (original dark look).
  static const onyx = AppPalette._(
    id: AppPaletteId.onyx,
    label: 'Onyx',
    caption: 'Dark',
    brightness: Brightness.dark,
    dayId: AppPaletteId.ivory,
    nightId: AppPaletteId.onyx,
    atelier: AtelierPalette.dark,
    luxe: LuxePalette.dark,
    stage: _classicStage,
    chrome: _classicChrome,
  );

  /// Deep emerald, forest green, soft gold and pearl.
  static const emeraldPearl = AppPalette._(
    id: AppPaletteId.emeraldPearl,
    label: 'Emerald × Pearl',
    caption: 'Distinctive luxury',
    brightness: Brightness.light,
    dayId: AppPaletteId.emeraldPearl,
    nightId: AppPaletteId.emeraldNight,
    atelier: AtelierPalette(
      canvas: Color(0xFFFFFFFF),
      surface: Color(0xFFFFFFFF),
      raised: Color(0xFFFFFFFF),
      sunken: Color(0xFFF4F4F5),
      lifted: Color(0xFFFFFFFF),
      ink: Color(0xFF063C35),
      inkSoft: Color(0xFF3E5F57),
      muted: Color(0xFF7C948C),
      hairline: Color(0xFFDDE5E1),
      gold: Color(0xFF9A7B3F),
      goldSoft: Color(0xFFEFE7D4),
      onGold: Color(0xFF063C35),
      onyx: Color(0xFF063C35),
      onOnyx: Color(0xFFFAF9F5),
      emerald: Color(0xFF1E7A52),
      ruby: Color(0xFFB2433A),
      sapphire: Color(0xFF3E6690),
      amber: Color(0xFFB7801F),
      shadow: Color(0x1F052A25),
      floatShadowColor: Color(0x29052A25),
      goldGradientColors: [Color(0xFFD8BC85), Color(0xFFB08F52)],
      isDark: false,
    ),
    luxe: LuxePalette(
      canvas: Color(0xFFFFFFFF),
      surface: Color(0xFFFFFFFF),
      surfaceRaised: Color(0xFFF4F4F5),
      ink: Color(0xFF063C35),
      inkMuted: Color(0xFF4E6B63),
      inkFaint: Color(0xFF8AA199),
      hairline: Color(0xFFDDE5E1),
      accent: Color(0xFF9A7B3F),
      accentSoft: Color(0xFFEFE7D4),
      onAccent: Color(0xFFFAF9F5),
      isDark: false,
    ),
    stage: _emeraldStage,
    chrome: _emeraldChrome,
  );

  /// Midnight navy, ice blue, diamond white and mist blue.
  static const midnightIce = AppPalette._(
    id: AppPaletteId.midnightIce,
    label: 'Midnight × Ice',
    caption: 'Modern B2B',
    brightness: Brightness.light,
    dayId: AppPaletteId.midnightIce,
    nightId: AppPaletteId.midnightNight,
    atelier: AtelierPalette(
      canvas: Color(0xFFFFFFFF),
      surface: Color(0xFFFFFFFF),
      raised: Color(0xFFFFFFFF),
      sunken: Color(0xFFF4F4F5),
      lifted: Color(0xFFFFFFFF),
      ink: Color(0xFF07111F),
      inkSoft: Color(0xFF3B4C63),
      muted: Color(0xFF7D8DA1),
      hairline: Color(0xFFDDE4EA),
      gold: Color(0xFF1F7FB4),
      goldSoft: Color(0xFFDDF1FB),
      onGold: Color(0xFF07111F),
      onyx: Color(0xFF07111F),
      onOnyx: Color(0xFFFFFFFF),
      emerald: Color(0xFF2F7A57),
      ruby: Color(0xFFB2433A),
      sapphire: Color(0xFF2F5F9E),
      amber: Color(0xFFB7801F),
      shadow: Color(0x1F07111F),
      floatShadowColor: Color(0x2907111F),
      goldGradientColors: [Color(0xFFA6E0FF), Color(0xFF5BB8EA)],
      isDark: false,
    ),
    luxe: LuxePalette(
      canvas: Color(0xFFFFFFFF),
      surface: Color(0xFFFFFFFF),
      surfaceRaised: Color(0xFFF4F4F5),
      ink: Color(0xFF07111F),
      inkMuted: Color(0xFF4A5A70),
      inkFaint: Color(0xFF8A9AAD),
      hairline: Color(0xFFDDE4EA),
      accent: Color(0xFF1F7FB4),
      accentSoft: Color(0xFFDDF1FB),
      onAccent: Color(0xFFFFFFFF),
      isDark: false,
    ),
    stage: _midnightStage,
    chrome: _midnightChrome,
  );

  /// Dark companion of [emeraldPearl].
  static const emeraldNight = AppPalette._(
    id: AppPaletteId.emeraldNight,
    label: 'Emerald Night',
    caption: 'Dark',
    brightness: Brightness.dark,
    dayId: AppPaletteId.emeraldPearl,
    nightId: AppPaletteId.emeraldNight,
    atelier: AtelierPalette(
      canvas: Color(0xFF031F1B),
      surface: Color(0xFF062B26),
      raised: Color(0xFF08322C),
      sunken: Color(0xFF0A3630),
      lifted: Color(0xFF124A41),
      ink: Color(0xFFF4F2EA),
      inkSoft: Color(0xFFBFD0C8),
      muted: Color(0xFF7F988F),
      hairline: Color(0xFF15443C),
      gold: Color(0xFFC8A86B),
      goldSoft: Color(0xFF26372A),
      onGold: Color(0xFF063C35),
      onyx: Color(0xFF0A3A33),
      onOnyx: Color(0xFFFAF9F5),
      emerald: Color(0xFF6CC79A),
      ruby: Color(0xFFE07A6E),
      sapphire: Color(0xFF7FA6D1),
      amber: Color(0xFFE3B05A),
      shadow: Color(0x66000000),
      floatShadowColor: Color(0x99000000),
      goldGradientColors: [Color(0xFFDCC08A), Color(0xFFB0904F)],
      isDark: true,
    ),
    luxe: LuxePalette(
      canvas: Color(0xFF031F1B),
      surface: Color(0xFF062B26),
      surfaceRaised: Color(0xFF0A3630),
      ink: Color(0xFFF4F2EA),
      inkMuted: Color(0xFFA3B8AF),
      inkFaint: Color(0xFF5F7D74),
      hairline: Color(0xFF15443C),
      accent: Color(0xFFC8A86B),
      accentSoft: Color(0xFF26372A),
      onAccent: Color(0xFF063C35),
      isDark: true,
    ),
    stage: _emeraldStage,
    chrome: _emeraldChrome,
  );

  /// Dark companion of [midnightIce].
  static const midnightNight = AppPalette._(
    id: AppPaletteId.midnightNight,
    label: 'Midnight Night',
    caption: 'Dark',
    brightness: Brightness.dark,
    dayId: AppPaletteId.midnightIce,
    nightId: AppPaletteId.midnightNight,
    atelier: AtelierPalette(
      canvas: Color(0xFF050C17),
      surface: Color(0xFF0B1626),
      raised: Color(0xFF0F1C2F),
      sunken: Color(0xFF111F33),
      lifted: Color(0xFF1B2E48),
      ink: Color(0xFFF2F7FB),
      inkSoft: Color(0xFFBCCBD8),
      muted: Color(0xFF7D8DA1),
      hairline: Color(0xFF1A2A40),
      gold: Color(0xFF8FD8FF),
      goldSoft: Color(0xFF132D42),
      onGold: Color(0xFF07111F),
      onyx: Color(0xFF0E1C30),
      onOnyx: Color(0xFFFFFFFF),
      emerald: Color(0xFF5DB88B),
      ruby: Color(0xFFE07A6E),
      sapphire: Color(0xFF8FB6E0),
      amber: Color(0xFFE3B05A),
      shadow: Color(0x66000000),
      floatShadowColor: Color(0x99000000),
      goldGradientColors: [Color(0xFFB5E6FF), Color(0xFF6CC4F0)],
      isDark: true,
    ),
    luxe: LuxePalette(
      canvas: Color(0xFF050C17),
      surface: Color(0xFF0B1626),
      surfaceRaised: Color(0xFF111F33),
      ink: Color(0xFFF2F7FB),
      inkMuted: Color(0xFF9FB0C2),
      inkFaint: Color(0xFF5C6E84),
      hairline: Color(0xFF1A2A40),
      accent: Color(0xFF8FD8FF),
      accentSoft: Color(0xFF132D42),
      onAccent: Color(0xFF07111F),
      isDark: true,
    ),
    stage: _midnightStage,
    chrome: _midnightChrome,
  );
}

/// Carries the active [AppPalette] on [ThemeData] so context lookups
/// ([AtelierPalette.of], [LuxePalette.of], [AppColors]) register a theme
/// dependency and rebuild when the palette changes.
@immutable
class AppPaletteTheme extends ThemeExtension<AppPaletteTheme> {
  const AppPaletteTheme(this.palette);

  final AppPalette palette;

  @override
  AppPaletteTheme copyWith({AppPalette? palette}) =>
      AppPaletteTheme(palette ?? this.palette);

  /// Palettes are discrete; swap halfway through a theme animation.
  @override
  AppPaletteTheme lerp(AppPaletteTheme? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

extension AppPaletteContext on BuildContext {
  /// Active palette for this subtree.
  AppPalette get appPalette => AppPalette.resolve(this);
}
