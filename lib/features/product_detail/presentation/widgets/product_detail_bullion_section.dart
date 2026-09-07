import 'package:flutter/material.dart';
import '../../../../core/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/listing_seller_info.dart';
import '../../domain/models/product_bullion_detail.dart';
import '../../domain/models/product_detail.dart';

/// Bullion content: Overview / Specifications / Seller tabs.
class ProductDetailBullionSection extends StatefulWidget {
  const ProductDetailBullionSection({
    required this.detail,
    required this.bullion,
    super.key,
  });

  final ProductDetail detail;
  final ProductBullionDetail bullion;

  @override
  State<ProductDetailBullionSection> createState() =>
      _ProductDetailBullionSectionState();
}

class _ProductDetailBullionSectionState
    extends State<ProductDetailBullionSection> {
  int _tabIndex = 0;

  static const _tabs = <({String label, IconData icon})>[
    (label: 'Overview', icon: Icons.visibility_outlined),
    (label: 'Specifications', icon: Icons.bookmark_border_rounded),
    (label: 'Seller', icon: Icons.star_border_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < _tabs.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.s24),
              _TabChip(
                label: _tabs[i].label,
                icon: _tabs[i].icon,
                selected: i == _tabIndex,
                onTap: () => setState(() => _tabIndex = i),
              ),
            ],
          ],
        ),
        Divider(height: 1, thickness: 1, color: AppColors.border(context)),
        const SizedBox(height: AppSpacing.s24),
        switch (_tabIndex) {
          0 => _OverviewTab(text: widget.bullion.overview),
          1 => _SpecificationsTab(rows: widget.bullion.specRows),
          _ => _SellerTab(seller: widget.detail.listingSeller),
        },
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.textPrimary(context)
        : AppColors.textMuted(context);
    return InkWell(
      onTap: onTap,
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: AppSpacing.s8),
                  Text(
                    label,
                    style: AppTypography.label.copyWith(
                      color: color,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ColoredBox(
              color: selected
                  ? AppColors.textPrimary(context)
                  : Colors.transparent,
              child: const SizedBox(height: 2),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.body.copyWith(
        color: AppColors.textSecondary(context),
        height: 1.55,
        fontSize: 14,
      ),
    );
  }
}

class _SpecificationsTab extends StatelessWidget {
  const _SpecificationsTab({required this.rows});

  final List<ProductBullionSpecRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Text(
        'No specifications available.',
        style: AppTypography.body.copyWith(
          color: AppColors.textMuted(context),
        ),
      );
    }

    return Container(
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
                vertical: AppSpacing.s16,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      rows[i].label,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textMuted(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s16),
                  Flexible(
                    child: Text(
                      rows[i].value,
                      textAlign: TextAlign.right,
                      style: AppTypography.label.copyWith(
                        color: AppColors.textPrimary(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SellerTab extends StatelessWidget {
  const _SellerTab({required this.seller});

  final ListingSellerInfo? seller;

  @override
  Widget build(BuildContext context) {
    final info = seller;
    if (info == null || !info.hasAnyData) {
      return Text(
        'Seller information is not available for this listing.',
        style: AppTypography.body.copyWith(
          color: AppColors.textMuted(context),
        ),
      );
    }

    final rows = <({String label, String value, IconData icon})>[
      (
        label: context.tr(CatalogL10n.seller),
        value: info.displayName,
        icon: Icons.storefront_outlined,
      ),
      if (!info.isIndividual && info.email != null)
        (
          label: context.tr(CatalogL10n.email),
          value: info.email!,
          icon: Icons.email_outlined,
        ),
      if (!info.isIndividual && info.phone != null)
        (
          label: context.tr(CatalogL10n.phone),
          value: info.phone!,
          icon: Icons.phone_outlined,
        ),
      if (!info.isIndividual && info.location != null)
        (
          label: context.tr(CatalogL10n.location),
          value: info.location!,
          icon: Icons.location_on_outlined,
        ),
    ];

    return Container(
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
    );
  }
}
