import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class DiamondViewerErrorView extends StatelessWidget {
  const DiamondViewerErrorView({
    required this.message,
    super.key,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.charcoal,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.threed_rotation,
                size: 48,
                color: AppColors.bronzeLight,
              ),
              const SizedBox(height: AppSpacing.s16),
              Text(
                'Unable to open 360° view',
                style: AppTypography.title.copyWith(
                  color: AppColors.warmWhite,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                message,
                style: AppTypography.body.copyWith(
                  color: AppColors.bronzeLight,
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.s24),
                FilledButton(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.bronze,
                    foregroundColor: AppColors.warmWhite,
                  ),
                  child: const Text('Try again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
