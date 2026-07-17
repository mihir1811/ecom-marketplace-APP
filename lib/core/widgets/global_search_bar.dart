import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/app_shadows.dart';

class GlobalSearchBar extends StatelessWidget {
  final bool isDark;

  const GlobalSearchBar({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final containerColor = isDark ? AppColors.slateSurface : AppColors.warmWhite;
    final borderColor = isDark ? AppColors.slateBorder : AppColors.warmBorder;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: containerColor,
        border: Border(
          bottom: BorderSide(color: borderColor),
        ),
        boxShadow: AppShadows.cardLight,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s8,
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by shape, carat, certificate...',
          hintStyle: AppTypography.body.copyWith(
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
          filled: true,
          fillColor: isDark ? AppColors.charcoalLight : AppColors.sandSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.r8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.r8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.r8),
            borderSide: const BorderSide(color: AppColors.bronze),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            size: 20,
          ),
          suffixIcon: IconButton(
            icon: const Icon(
              Icons.tune,
              color: AppColors.bronze,
              size: 20,
            ),
            onPressed: () {},
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12,
            vertical: AppSpacing.s8,
          ),
        ),
        style: AppTypography.body.copyWith(color: textColor),
        textInputAction: TextInputAction.search,
        onSubmitted: (value) {},
      ),
    );
  }
}
