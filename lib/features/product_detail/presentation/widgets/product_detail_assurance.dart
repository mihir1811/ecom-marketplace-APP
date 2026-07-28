import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    final cert = certification;
    final stock = availability;
    if (cert == null && stock == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(AppSpacing.r20),
        border: Border.all(color: AppColors.warmBorder),
      ),
      child: Column(
        children: [
          if (cert != null) _CertificationRow(certification: cert),
          if (cert != null && stock != null)
            const Divider(height: 1, color: AppColors.warmBorder),
          if (stock != null) _AvailabilityRow(availability: stock),
        ],
      ),
    );
  }
}

class _CertificationRow extends StatelessWidget {
  const _CertificationRow({required this.certification});

  final ProductCertification certification;

  @override
  Widget build(BuildContext context) {
    final reference = certification.referenceValue;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Row(
        children: [
          const Icon(
            Icons.verified_outlined,
            size: 18,
            color: AppColors.success,
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  certification.authority,
                  style: AppTypography.label.copyWith(
                    color: AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (reference != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${certification.referenceLabel ?? 'Reference'} · $reference',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMutedLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (reference != null)
            IconButton(
              tooltip: 'Copy reference',
              visualDensity: VisualDensity.compact,
              iconSize: 16,
              color: AppColors.textMutedLight,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: reference));
                final messenger = ScaffoldMessenger.maybeOf(context);
                messenger?.hideCurrentSnackBar();
                messenger?.showSnackBar(
                  const SnackBar(
                    content: Text('Reference copied'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded),
            ),
        ],
      ),
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
                color: AppColors.textPrimaryLight,
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
                color: AppColors.textSecondaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}
