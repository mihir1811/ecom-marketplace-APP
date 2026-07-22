import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Centralized Material 3 Theme Configuration for GemWorld.
/// Assembles Light ThemeData using design tokens.
class AppTheme {
  const AppTheme._();

  /// Light theme data representing the premium warm cream aesthetic of GemWorld.
  static ThemeData get light {
    final defaultTextTheme = AppTypography.buildTextTheme(AppColors.textPrimaryLight);
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.charcoal,
        onPrimary: AppColors.warmWhite,
        secondary: AppColors.bronze,
        onSecondary: AppColors.warmWhite,
        error: AppColors.error,
        onError: AppColors.warmWhite,
        surface: AppColors.sandSurface,
        onSurface: AppColors.textPrimaryLight,
        outline: AppColors.warmBorder,
      ),
      scaffoldBackgroundColor: AppColors.creamBg,
      
      // Typography
      textTheme: defaultTextTheme,
      
      // AppBar configuration
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.creamBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.title.copyWith(color: AppColors.textPrimaryLight),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
      ),

      // Card Design
      cardTheme: const CardThemeData(
        color: AppColors.sandSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.r12)),
          side: BorderSide(color: AppColors.warmBorder, width: 1.0),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // Input Decoration (Text Fields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.warmWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s12,
        ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.r8)),
          borderSide: BorderSide(color: AppColors.warmBorder, width: 1.0),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.r8)),
          borderSide: BorderSide(color: AppColors.warmBorder, width: 1.0),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.r8)),
          borderSide: BorderSide(color: AppColors.charcoal, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.r8)),
          borderSide: BorderSide(color: AppColors.error, width: 1.0),
        ),
        labelStyle: AppTypography.label.copyWith(color: AppColors.textSecondaryLight),
        hintStyle: AppTypography.body.copyWith(color: AppColors.textMutedLight),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.charcoal,
          foregroundColor: AppColors.warmWhite,
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
          foregroundColor: AppColors.charcoal,
          side: const BorderSide(color: AppColors.charcoal, width: 1.5),
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
          foregroundColor: AppColors.charcoal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12,
            vertical: AppSpacing.s8,
          ),
          textStyle: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.warmWhite,
        disabledColor: AppColors.sandSurface,
        selectedColor: AppColors.sandSurface,
        secondarySelectedColor: AppColors.sandSurface,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12, vertical: AppSpacing.s8),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.circular)),
          side: BorderSide(color: AppColors.warmBorder, width: 1.0),
        ),
        labelStyle: AppTypography.caption.copyWith(color: AppColors.textPrimaryLight, fontWeight: FontWeight.w500),
        brightness: Brightness.light,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.warmBorder,
        thickness: 1.0,
        space: 1.0,
      ),
    );
  }

}
