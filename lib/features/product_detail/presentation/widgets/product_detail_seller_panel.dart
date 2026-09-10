import 'package:flutter/material.dart';
import '../../../../core/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/listing_seller_info.dart';

/// Listing seller identity.
///
/// Individual (non-business) viewers always see name only. Business viewers
/// see contact fields only when the listing seller is also a business account.
class ProductDetailSellerPanel extends StatelessWidget {
  const ProductDetailSellerPanel({
    required this.seller,
    this.showContactDetails = false,
    super.key,
  });

  final ListingSellerInfo seller;

  /// When false (individual viewer), only [seller.displayName] is shown.
  final bool showContactDetails;

  @override
  Widget build(BuildContext context) {
    if (!seller.hasAnyData) return const SizedBox.shrink();

    final showContact = showContactDetails && !seller.isIndividual;

    final rows = <({String label, String value, IconData icon})>[
      (
        label: context.tr(CatalogL10n.seller),
        value: seller.displayName,
        icon: Icons.storefront_outlined,
      ),
      if (showContact && seller.email != null)
        (
          label: context.tr(CatalogL10n.email),
          value: seller.email!,
          icon: Icons.email_outlined,
        ),
      if (showContact && seller.phone != null)
        (
          label: context.tr(CatalogL10n.phone),
          value: seller.phone!,
          icon: Icons.phone_outlined,
        ),
      if (showContact && seller.location != null)
        (
          label: context.tr(CatalogL10n.location),
          value: seller.location!,
          icon: Icons.location_on_outlined,
        ),
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
            context.tr(CatalogL10n.sellerInformation),
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
