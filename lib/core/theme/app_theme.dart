import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_palette.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Centralized Material 3 Theme Configuration for GemWorld.
/// Assembles [ThemeData] from an [AppPalette]; the palette also rides on the
/// theme as an [AppPaletteTheme] extension for token lookups.
class AppTheme {
  const AppTheme._();

  /// Original light look ([AppPalette.ivory]).
  static ThemeData get light => build(AppPalette.ivory);

  /// Original dark look ([AppPalette.onyx]).
  static ThemeData get dark => build(AppPalette.onyx);

  static final _cache = <AppPaletteId, ThemeData>{};

  /// Theme for [palette] (built once per palette).
  static ThemeData build(AppPalette palette) => _cache.putIfAbsent(
    palette.id,
    () => palette.isDark
        ? _dark(palette.chrome, palette)
        : _light(palette.chrome, palette),
  );

  static ThemeData _light(AppChromeColors c, AppPalette palette) {
    final defaultTextTheme = AppTypography.buildTextTheme(c.textPrimaryLight);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppTypography.fontFamily,
      extensions: [AppPaletteTheme(palette)],
      colorScheme: ColorScheme.light(
        primary: c.charcoal,
        onPrimary: c.warmWhite,
        secondary: c.bronze,
        onSecondary: c.warmWhite,
        error: AppColors.error,
        onError: c.warmWhite,
        // White page and sheets; neutral grey tiers for filled controls.
        surface: c.warmWhite,
        onSurface: c.textPrimaryLight,
        surfaceContainerLowest: c.warmWhite,
        surfaceContainerLow: const Color(0xFFFAFAFA),
        surfaceContainer: c.sandSurface,
        surfaceContainerHigh: const Color(0xFFEFEFF1),
        surfaceContainerHighest: const Color(0xFFE9E9EC),
        surfaceTint: Colors.transparent,
        outline: c.warmBorder,
        outlineVariant: c.warmBorder,
        shadow: c.shadowTint,
      ),
      scaffoldBackgroundColor: c.creamBg,
      canvasColor: c.creamBg,

      // Typography
      textTheme: defaultTextTheme,

      // AppBar configuration
      appBarTheme: AppBarTheme(
        backgroundColor: c.creamBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.title.copyWith(color: c.textPrimaryLight),
        iconTheme: IconThemeData(color: c.textPrimaryLight),
      ),

      // Floating surfaces stay white and lift off the page with a shadow.
      dialogTheme: DialogThemeData(
        backgroundColor: c.warmWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shadowColor: c.shadowTint.withValues(alpha: 0.35),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.warmWhite,
        modalBackgroundColor: c.warmWhite,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.warmWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shadowColor: c.shadowTint.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(AppSpacing.r12)),
          side: BorderSide(color: c.warmBorder),
        ),
      ),

      // Compact list rows for phone screens.
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.s16),
        minVerticalPadding: AppSpacing.s8,
        horizontalTitleGap: AppSpacing.s16,
        minLeadingWidth: 28,
      ),

      // Card Design: white card, hairline edge and a soft lift.
      cardTheme: CardThemeData(
        color: c.warmWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shadowColor: c.shadowTint.withValues(alpha: 0.25),
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(AppSpacing.r12)),
          side: BorderSide(color: c.warmBorder, width: 1.0),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // Input Decoration (Text Fields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.warmWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s12,
        ),
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(AppSpacing.r8)),
          borderSide: BorderSide(color: c.warmBorder, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(AppSpacing.r8)),
          borderSide: BorderSide(color: c.warmBorder, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(AppSpacing.r8)),
          borderSide: BorderSide(color: c.charcoal, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.r8)),
          borderSide: BorderSide(color: AppColors.error, width: 1.0),
        ),
        labelStyle: AppTypography.label.copyWith(color: c.textSecondaryLight),
        hintStyle: AppTypography.body.copyWith(color: c.textMutedLight),
        // Keep prefix/suffix icons readable when the field is in error state.
        prefixIconColor: c.textSecondaryLight,
        suffixIconColor: c.textSecondaryLight,
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.charcoal,
          foregroundColor: c.warmWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s24,
            vertical: AppSpacing.s16,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppSpacing.r8)),
          ),
          textStyle: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.charcoal,
          side: BorderSide(color: c.charcoal, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s24,
            vertical: AppSpacing.s16,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppSpacing.r8)),
          ),
          textStyle: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.charcoal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12,
            vertical: AppSpacing.s8,
          ),
          textStyle: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: c.warmWhite,
        disabledColor: c.sandSurface,
        selectedColor: c.charcoal,
        secondarySelectedColor: c.charcoal,
        checkmarkColor: c.warmWhite,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(
            Radius.circular(AppSpacing.circular),
          ),
          side: BorderSide(color: c.warmBorder, width: 1.0),
        ),
        labelStyle: AppTypography.caption.copyWith(
          color: c.textPrimaryLight,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: AppTypography.caption.copyWith(
          color: c.warmWhite,
          fontWeight: FontWeight.w600,
        ),
        color: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return c.charcoal;
          }
          return c.warmWhite;
        }),
        brightness: Brightness.light,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: c.warmBorder,
        thickness: 1.0,
        space: 1.0,
      ),
    );
  }

  static ThemeData _dark(AppChromeColors c, AppPalette palette) {
    final defaultTextTheme = AppTypography.buildTextTheme(c.textPrimaryDark);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppTypography.fontFamily,
      extensions: [AppPaletteTheme(palette)],
      colorScheme: ColorScheme.dark(
        primary: c.bronzeLight,
        onPrimary: c.charcoalDark,
        secondary: c.bronze,
        onSecondary: c.warmWhite,
        error: AppColors.error,
        onError: c.warmWhite,
        surface: c.slateSurface,
        onSurface: c.textPrimaryDark,
        outline: c.slateBorder,
      ),
      scaffoldBackgroundColor: c.obsidianBg,

      // Typography
      textTheme: defaultTextTheme,

      // AppBar configuration
      appBarTheme: AppBarTheme(
        backgroundColor: c.obsidianBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.title.copyWith(color: c.textPrimaryDark),
        iconTheme: IconThemeData(color: c.textPrimaryDark),
      ),

      // Compact list rows for phone screens.
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.s16),
        minVerticalPadding: AppSpacing.s8,
        horizontalTitleGap: AppSpacing.s16,
        minLeadingWidth: 28,
      ),

      // Card Design
      cardTheme: CardThemeData(
        color: c.slateSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(AppSpacing.r12)),
          side: BorderSide(color: c.slateBorder, width: 1.0),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // Input Decoration (Text Fields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.slateSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s12,
        ),
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(AppSpacing.r8)),
          borderSide: BorderSide(color: c.slateBorder, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(AppSpacing.r8)),
          borderSide: BorderSide(color: c.slateBorder, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(AppSpacing.r8)),
          borderSide: BorderSide(color: c.bronzeLight, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.r8)),
          borderSide: BorderSide(color: AppColors.error, width: 1.0),
        ),
        labelStyle: AppTypography.label.copyWith(color: c.textSecondaryDark),
        hintStyle: AppTypography.body.copyWith(color: c.textMutedDark),
        prefixIconColor: c.textSecondaryDark,
        suffixIconColor: c.textSecondaryDark,
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.bronze,
          foregroundColor: c.warmWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s24,
            vertical: AppSpacing.s16,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppSpacing.r8)),
          ),
          textStyle: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.bronzeLight,
          side: BorderSide(color: c.bronzeLight, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s24,
            vertical: AppSpacing.s16,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppSpacing.r8)),
          ),
          textStyle: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.bronzeLight,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12,
            vertical: AppSpacing.s8,
          ),
          textStyle: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: c.slateSurface,
        disabledColor: c.slateSurface,
        selectedColor: c.warmWhite,
        secondarySelectedColor: c.warmWhite,
        checkmarkColor: c.charcoal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(
            Radius.circular(AppSpacing.circular),
          ),
          side: BorderSide(color: c.slateBorder, width: 1.0),
        ),
        labelStyle: AppTypography.caption.copyWith(
          color: c.textPrimaryDark,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: AppTypography.caption.copyWith(
          color: c.charcoal,
          fontWeight: FontWeight.w600,
        ),
        color: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return c.warmWhite;
          }
          return c.slateSurface;
        }),
        brightness: Brightness.dark,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: c.slateBorder,
        thickness: 1.0,
        space: 1.0,
      ),
    );
  }
}
