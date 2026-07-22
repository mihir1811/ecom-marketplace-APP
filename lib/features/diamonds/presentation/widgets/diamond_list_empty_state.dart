import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class DiamondListEmptyState extends StatelessWidget {
  final VoidCallback? onResetFilters;

  const DiamondListEmptyState({super.key, this.onResetFilters});

  @override
  Widget build(BuildContext context) {
    final mutedColor = AppColors.textMutedLight;
    final textColor = AppColors.textPrimaryLight;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.diamond_outlined,
              size: 72,
              color: mutedColor.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppSpacing.s24),
            Text(
              'No Diamonds Found',
              style: AppTypography.headline.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(
              'Try adjusting your filters or search criteria to find matching diamonds.',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                color: mutedColor,
              ),
            ),
            if (onResetFilters != null) ...[
              const SizedBox(height: AppSpacing.s24),
              OutlinedButton.icon(
                onPressed: onResetFilters,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reset Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
