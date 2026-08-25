import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Primary filled-button style for authentication screens.
ButtonStyle authFilledButtonStyle(BuildContext context) {
  return FilledButton.styleFrom(
    backgroundColor: AppColors.selectedFill(context),
    foregroundColor: AppColors.onSelected(context),
    padding: const EdgeInsets.symmetric(
      vertical: AppSpacing.s16,
      horizontal: AppSpacing.s24,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.r8),
    ),
  );
}

/// Spinner color that stays readable on [authFilledButtonStyle].
Widget authButtonSpinner(BuildContext context) {
  return SizedBox(
    height: 18,
    width: 18,
    child: CircularProgressIndicator(
      strokeWidth: 2,
      color: AppColors.onSelected(context),
    ),
  );
}
