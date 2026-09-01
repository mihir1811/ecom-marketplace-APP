import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Compact bubble shown above a selected chart element.
class ChartValueTooltip extends StatelessWidget {
  const ChartValueTooltip({
    required this.label,
    required this.value,
    super.key,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(AppSpacing.r8),
      color: AppColors.charcoal,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.warmWhite.withValues(alpha: 0.8),
                fontSize: 10,
              ),
            ),
            Text(
              value,
              style: AppTypography.label.copyWith(
                color: AppColors.warmWhite,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
