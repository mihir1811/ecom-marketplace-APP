import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_providers.dart';
import '../../../../core/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/listing_seller_info.dart';
import '../../domain/models/product_bullion_detail.dart';
import '../../domain/models/product_detail.dart';
import 'product_detail_spec_chrome.dart';

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

  static const _tabs = ['Overview', 'Specifications', 'Seller'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProductDetailSpecTabBar(
          titles: _tabs,
          selectedIndex: _tabIndex,
          onSelected: (i) => setState(() => _tabIndex = i),
        ),
        const SizedBox(height: AppSpacing.s12),
        switch (_tabIndex) {
          0 => _OverviewTab(text: widget.bullion.overview),
          1 => _SpecificationsTab(rows: widget.bullion.specRows),
          _ => _SellerTab(seller: widget.detail.listingSeller),
        },
      ],
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final body = text.trim().isEmpty ? 'No overview available' : text;
    return ProductDetailSpecPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s32,
      ),
      child: Text(
        body,
        textAlign: text.trim().isEmpty ? TextAlign.center : TextAlign.start,
        style: AppTypography.body.copyWith(
          color: AppColors.textMuted(context),
          height: 1.55,
          fontSize: 14,
        ),
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
      return ProductDetailSpecPanel(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s32,
        ),
        child: Text(
          'No specifications available.',
          textAlign: TextAlign.center,
          style: AppTypography.body.copyWith(
            color: AppColors.textMuted(context),
            fontSize: 14,
          ),
        ),
      );
    }

    return ProductDetailSpecTable(
      rows: [
        for (final row in rows)
          ProductDetailSpecKv(row.label, productDetailSpecDash(row.value)),
      ],
    );
  }
}

class _SellerTab extends ConsumerWidget {
  const _SellerTab({required this.seller});

  final ListingSellerInfo? seller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = seller;
    if (info == null || !info.hasAnyData) {
      return ProductDetailSpecPanel(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s32,
        ),
        child: Text(
          'Seller information is not available for this listing.',
          textAlign: TextAlign.center,
          style: AppTypography.body.copyWith(
            color: AppColors.textMuted(context),
            fontSize: 14,
          ),
        ),
      );
    }

    final viewerIsSeller = ref.watch(authProvider.select((s) => s.isSeller));
    final showContact = viewerIsSeller && !info.isIndividual;

    final rows = <ProductDetailSpecKv>[
      ProductDetailSpecKv(
        context.tr(CatalogL10n.seller),
        productDetailSpecDash(info.displayName),
      ),
      if (showContact && info.email != null)
        ProductDetailSpecKv(
          context.tr(CatalogL10n.email),
          productDetailSpecDash(info.email),
        ),
      if (showContact && info.phone != null)
        ProductDetailSpecKv(
          context.tr(CatalogL10n.phone),
          productDetailSpecDash(info.phone),
        ),
      if (showContact && info.location != null)
        ProductDetailSpecKv(
          context.tr(CatalogL10n.location),
          productDetailSpecDash(info.location),
        ),
    ];

    return ProductDetailSpecTable(rows: rows);
  }
}
