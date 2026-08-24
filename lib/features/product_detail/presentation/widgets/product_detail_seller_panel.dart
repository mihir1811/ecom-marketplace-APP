import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/listing_seller_info.dart';

/// Listing seller identity — visible only to signed-in seller accounts.
class ProductDetailSellerPanel extends StatelessWidget {
  const ProductDetailSellerPanel({required this.seller, super.key});

  final ListingSellerInfo seller;

  @override
  Widget build(BuildContext context) {
    if (!seller.hasAnyData) return const SizedBox.shrink();

    final rows = <({String label, String value, IconData icon})>[
      (label: 'Seller', value: seller.displayName, icon: Icons.storefront_outlined),
      if (!seller.isIndividual && seller.email != null)
        (label: 'Email', value: seller.email!, icon: Icons.email_outlined),
      if (!seller.isIndividual && seller.phone != null)
        (label: 'Phone', value: seller.phone!, icon: Icons.phone_outlined),
      if (!seller.isIndividual && seller.location != null)
        (label: 'Location', value: seller.location!, icon: Icons.location_on_outlined),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.s4,
            bottom: AppSpacing.s12,
          ),
          child: Text(
            'Seller information',
            style: AppTypography.label.copyWith(
              color: AppColors.textSecondary(context),
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(AppSpacing.r20),
            border: Border.all(color: AppColors.border(context)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) Divider(height: 1, color: AppColors.border(context)),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s16,
                    vertical: AppSpacing.s12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(rows[i].icon, size: 18, color: AppColors.bronze),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rows[i].label,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textMuted(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              rows[i].value,
                              style: AppTypography.label.copyWith(
                                color: AppColors.textPrimary(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
