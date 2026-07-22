import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class GlobalSearchBar extends StatelessWidget {
  const GlobalSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final textColor = AppColors.textPrimaryLight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.warmWhite,
          borderRadius: BorderRadius.circular(AppSpacing.r20),
          border: Border.all(
            color: AppColors.warmBorder,
          ),
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search by shape, carat, certificate...',
            hintStyle: AppTypography.body.copyWith(
              color: AppColors.textMutedLight,
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
                color: AppColors.textMutedLight,
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
