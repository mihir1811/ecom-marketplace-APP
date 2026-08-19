import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/product_detail.dart';
import '../screens/certificate_viewer_screen.dart';

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
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSpacing.r20),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          if (cert != null) _CertificationRow(certification: cert),
          if (cert != null && stock != null)
            Divider(height: 1, color: AppColors.border(context)),
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
    final hasLink = certification.hasCertificateLink;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                        color: AppColors.textPrimary(context),
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
                          color: AppColors.textMuted(context),
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
                  color: AppColors.textMuted(context),
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
          if (hasLink) ...[
            const SizedBox(height: AppSpacing.s12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => openCertificateViewer(
                  url: certification.certificateUrl!,
                  title: certification.certificateLabel ?? 'Certificate',
                ),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('View certification'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary(context),
                  side: BorderSide(color: AppColors.border(context)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s16,
                    vertical: AppSpacing.s12,
                  ),
                ),
              ),
            ),
          ],
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
