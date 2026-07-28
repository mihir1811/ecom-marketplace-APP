import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/product_detail.dart';

/// Price block — the highest-priority number on the page.
class ProductDetailPrice extends StatelessWidget {
  const ProductDetailPrice({required this.price, super.key});

  final ProductPrice price;

  @override
  Widget build(BuildContext context) {
    final unit = price.unitDisplay;
    final discount = price.discountPercent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                price.display,
                style: AppTypography.label.copyWith(
                  color: AppColors.textPrimaryLight,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (discount != null && discount > 0) ...[
              const SizedBox(width: AppSpacing.s12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.terracotta,
                  borderRadius: BorderRadius.circular(AppSpacing.r8),
                ),
                child: Text(
                  '${discount.round()}% off',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.warmWhite,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (unit != null) ...[
          const SizedBox(height: AppSpacing.s8),
          Text(
            unit,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
