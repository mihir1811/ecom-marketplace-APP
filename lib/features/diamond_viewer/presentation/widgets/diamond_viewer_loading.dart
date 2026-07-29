import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class DiamondViewerLoadingView extends StatelessWidget {
  const DiamondViewerLoadingView({super.key, this.progress = 0});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return ColoredBox(
      color: AppColors.charcoal,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.warmWhite,
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              Text(
                'Loading 360° viewer…',
                style: AppTypography.label.copyWith(
                  color: AppColors.warmWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (clamped > 0) ...[
                const SizedBox(height: AppSpacing.s16),
                SizedBox(
                  width: 180,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.circular),
                    child: LinearProgressIndicator(
                      value: clamped,
                      minHeight: 4,
                      backgroundColor: AppColors.charcoalLight,
                      color: AppColors.bronze,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
