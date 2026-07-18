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

    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
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
              horizontal: AppSpacing.s16,
              vertical: AppSpacing.s8,
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
          ),
          style: AppTypography.body.copyWith(color: textColor),
          textInputAction: TextInputAction.search,
          onSubmitted: (value) {},
        ),
      ),
    );
  }
}
