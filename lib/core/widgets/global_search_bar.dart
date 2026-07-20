import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class GlobalSearchBar extends StatelessWidget {
  final bool isDark;

  const GlobalSearchBar({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.charcoalLight : AppColors.warmWhite,
          borderRadius: BorderRadius.circular(AppSpacing.r20),
          border: Border.all(
            color: isDark ? AppColors.slateBorder : AppColors.warmBorder,
          ),
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search by shape, carat, certificate...',
            hintStyle: AppTypography.body.copyWith(
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s12,
              vertical: AppSpacing.s8,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: AppSpacing.s12, right: AppSpacing.s8),
              child: Icon(
                Icons.search,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                size: 20,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
          ),
          style: AppTypography.body.copyWith(color: textColor),
          textInputAction: TextInputAction.search,
          onSubmitted: (value) {},
        ),
      ),
    );
  }
}
