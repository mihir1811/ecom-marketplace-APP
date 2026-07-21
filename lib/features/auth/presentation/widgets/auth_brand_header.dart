import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';

/// Shared auth header (diamond icon + small eyebrow + subtitle).
class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({
    super.key,
    required this.eyebrow,
    required this.subtitle,
  });

  final String eyebrow;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.sandSurface,
            borderRadius: BorderRadius.circular(AppSpacing.r12),
            border: Border.all(color: AppColors.warmBorder, width: 1),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.diamond_outlined,
            color: AppColors.charcoal,
          ),
        ),
        SizedBox(width: AppSpacing.s16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryLight,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(height: AppSpacing.s8),
            Text(
              subtitle,
              style: AppTypography.body.copyWith(
                color: AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

