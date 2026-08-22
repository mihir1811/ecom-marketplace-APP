import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/product_detail.dart';

/// Certification and stock status — the two facts a buyer checks immediately
/// after the price, before reading any specification.
class ProductDetailAssurance extends StatelessWidget {
  const ProductDetailAssurance({
    required this.certification,
    required this.availability,
    super.key,
  });

  final ProductCertification? certification;
  final ProductAvailability? availability;

  @override
  Widget build(BuildContext context) {
    final stock = availability;
    if (stock == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSpacing.r20),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: _AvailabilityRow(availability: stock),
    );
  }
}

class _AvailabilityRow extends StatelessWidget {
  const _AvailabilityRow({required this.availability});

  final ProductAvailability availability;

  @override
  Widget build(BuildContext context) {
    final tint = switch (availability.tone) {
      ProductStockTone.available => AppColors.success,
      ProductStockTone.limited => AppColors.warning,
      ProductStockTone.unavailable => AppColors.error,
    };

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Text(
              availability.label,
              style: AppTypography.label.copyWith(
                color: AppColors.textPrimary(context),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (availability.detail != null)
            Text(
              availability.detail!,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary(context),
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}
