import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../application/jewelry_config_draft_provider.dart';
import '../../domain/models/jewelry_unit_pricing.dart';
import '../../domain/models/product_detail.dart';
import '../../domain/models/product_jewelry_detail.dart';
import 'product_detail_spec_chrome.dart';

/// Details / Specifications / Care tabs for jewelry PDP.
class ProductDetailJewelryTabs extends StatefulWidget {
  const ProductDetailJewelryTabs({
    required this.detail,
    required this.jewelry,
    required this.draft,
    super.key,
  });

  final ProductDetail detail;
  final ProductJewelryDetail jewelry;
  final JewelryConfigDraft? draft;

  @override
  State<ProductDetailJewelryTabs> createState() =>
      _ProductDetailJewelryTabsState();
}

class _ProductDetailJewelryTabsState extends State<ProductDetailJewelryTabs> {
  int _tabIndex = 0;

  static const _tabs = ['Details', 'Specifications', 'Care'];

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
          0 => _DetailsTab(jewelry: widget.jewelry),
          1 => _SpecificationsTab(
              jewelry: widget.jewelry,
              draft: widget.draft,
              priceOnRequest: widget.detail.price.isOnRequest,
            ),
          _ => const _CareTab(),
        },
      ],
    );
  }
}

class _DetailsTab extends StatelessWidget {
  const _DetailsTab({required this.jewelry});

  final ProductJewelryDetail jewelry;

  @override
  Widget build(BuildContext context) {
    final metaRows = <ProductDetailSpecKv>[
      if (jewelry.materialLabel != null)
        ProductDetailSpecKv(
          'Material',
          productDetailSpecDash(jewelry.materialLabel),
        ),
      if (jewelry.category.trim().isNotEmpty)
        ProductDetailSpecKv('Category', jewelry.category),
      if (jewelry.gender.trim().isNotEmpty)
        ProductDetailSpecKv('Gender', jewelry.gender),
      if (jewelry.occasion.trim().isNotEmpty)
        ProductDetailSpecKv('Occasion', jewelry.occasion),
      if ((jewelry.style ?? '').trim().isNotEmpty)
        ProductDetailSpecKv('Style', jewelry.style!),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProductDetailSpecPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About this piece',
                style: AppTypography.label.copyWith(
                  color: AppColors.textPrimary(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              Text(
                jewelry.description,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary(context),
                  height: 1.5,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        if (metaRows.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s24),
          ProductDetailSpecSection(title: 'Product info', rows: metaRows),
        ],
      ],
    );
  }
}

class _SpecificationsTab extends StatelessWidget {
  const _SpecificationsTab({
    required this.jewelry,
    required this.draft,
    this.priceOnRequest = false,
  });

  final ProductJewelryDetail jewelry;
  final JewelryConfigDraft? draft;
  final bool priceOnRequest;

  @override
  Widget build(BuildContext context) {
    final sku = draft?.sku ?? jewelry.styleNo;
    final metalW = draft?.metalWeightG ?? jewelry.metalWeightG;
    final totalW = draft?.totalWeightG ?? jewelry.totalWeightG;
    final symbol = jewelry.currencySymbol;
    final pricing = JewelryUnitPricing.from(
      metalPrice: draft?.metalPrice ?? jewelry.metalPrice,
      stonePrice: draft?.stonePrice ?? jewelry.stonePrice,
      makingCharge: draft?.makingCharge ?? jewelry.makingCharge,
      discountAmount: draft?.discountAmount ?? jewelry.discountAmount,
      totalPrice: draft?.price ?? jewelry.price,
    );
    final metalType = draft?.metalType ?? jewelry.metalType;
    final metalColor = draft?.metalColor ?? jewelry.metalColor;
    final purity = draft?.purity ?? jewelry.metalPurity;
    final finish = draft?.metalFinish ?? jewelry.metalFinish;
    final size = draft?.braceletSize ??
        draft?.ringSize ??
        draft?.chainLength ??
        jewelry.sizeLabel;
    final stones = (draft?.stones.isNotEmpty ?? false)
        ? draft!.stones
        : jewelry.stones;

    final summaryRows = <ProductDetailSpecKv>[
      ProductDetailSpecKv('Style No.', productDetailSpecDash(sku)),
      ProductDetailSpecKv(
        'Metal Weight',
        metalW > 0 ? '${_fmtWeight(metalW)}g' : '—',
      ),
      ProductDetailSpecKv(
        'Total Weight',
        totalW != null && totalW > 0 ? '${_fmtWeight(totalW)}g' : '—',
      ),
    ];

    final priceRows = <ProductDetailSpecKv>[
      if (priceOnRequest)
        const ProductDetailSpecKv('Grand Total', 'Price on request', bold: true)
      else ...[
        if (pricing.metal > 0)
          ProductDetailSpecKv(
            'Metal',
            '$symbol${formatGroupedWhole(pricing.metal)}',
          ),
        if (pricing.stone > 0)
          ProductDetailSpecKv(
            'Diamond',
            '$symbol${formatGroupedWhole(pricing.stone)}',
          ),
        if (pricing.making > 0)
          ProductDetailSpecKv(
            'Making Charges',
            '$symbol${formatGroupedWhole(pricing.making)}',
          ),
        if (pricing.hasDiscount)
          ProductDetailSpecKv(
            'Discount',
            '-$symbol${formatGroupedWhole(pricing.discount)}',
            valueColor: AppColors.success,
          ),
        ProductDetailSpecKv(
          'Grand Total',
          '$symbol${formatGroupedWhole(pricing.netPrice)}',
          bold: true,
        ),
        const ProductDetailSpecKv(
          'MRP',
          'Incl. of all taxes',
        ),
      ],
    ];

    final metalRows = <ProductDetailSpecKv>[
      ProductDetailSpecKv('Metal Type', productDetailSpecDash(metalType)),
      ProductDetailSpecKv('Metal Color', productDetailSpecDash(metalColor)),
      ProductDetailSpecKv('Metal Purity', productDetailSpecDash(purity)),
      ProductDetailSpecKv('Metal Finish', productDetailSpecDash(finish)),
      ProductDetailSpecKv(
        'Metal Weight',
        metalW > 0 ? '${_fmtWeight(metalW)}g' : '—',
      ),
      ProductDetailSpecKv(_sizeLabel(jewelry), productDetailSpecDash(size)),
      ProductDetailSpecKv(
        'Total Weight',
        totalW != null && totalW > 0 ? '${_fmtWeight(totalW)}g' : '—',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProductDetailSpecSection(title: 'Product Summary', rows: summaryRows),
        const SizedBox(height: AppSpacing.s24),
        ProductDetailSpecSection(title: 'Price Breakup', rows: priceRows),
        const SizedBox(height: AppSpacing.s24),
        ProductDetailSpecSection(title: 'Metal Details', rows: metalRows),
        for (var i = 0; i < stones.length; i++) ...[
          const SizedBox(height: AppSpacing.s24),
          ProductDetailSpecSection(
            title: stones.length == 1 ? 'Diamond Details' : 'Stone ${i + 1}',
            rows: _stoneRows(stones[i]),
          ),
        ],
      ],
    );
  }

  List<ProductDetailSpecKv> _stoneRows(ProductJewelryStone stone) {
    return [
      ProductDetailSpecKv(
        'Center Type',
        productDetailSpecDash(stone.type?.toUpperCase()),
      ),
      ProductDetailSpecKv('Shape', productDetailSpecDash(stone.shape)),
      ProductDetailSpecKv(
        'Carat',
        stone.weightCt != null && stone.weightCt! > 0
            ? '${_fmtWeight(stone.weightCt!)}ct'
            : '—',
      ),
      ProductDetailSpecKv('Color', productDetailSpecDash(stone.color)),
      ProductDetailSpecKv('Clarity', productDetailSpecDash(stone.clarity)),
      ProductDetailSpecKv(
        'Pieces',
        stone.pieces != null && stone.pieces! > 0 ? '${stone.pieces}' : '—',
      ),
      ProductDetailSpecKv('Setting', productDetailSpecDash(stone.setting)),
    ];
  }

  String _sizeLabel(ProductJewelryDetail jewelry) {
    if ((jewelry.braceletSize ?? '').isNotEmpty) return 'Bracelet Size';
    if ((jewelry.ringSize ?? '').isNotEmpty) return 'Ring Size';
    if ((jewelry.chainLength ?? '').isNotEmpty) return 'Chain Length';
    return 'Size';
  }
}

class _CareTab extends StatelessWidget {
  const _CareTab();

  static const _tips = [
    'Store in a soft cloth pouch or jewelry box to prevent scratches',
    'Clean with a soft, dry cloth after each wear',
    'Avoid contact with perfumes, lotions, and cleaning agents',
    'Remove before swimming, exercising, or showering',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProductDetailSpecPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Care Instructions',
                style: AppTypography.label.copyWith(
                  color: AppColors.textPrimary(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              for (final tip in _tips) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check, size: 18, color: AppColors.success),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Text(
                        tip,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary(context),
                          height: 1.45,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s12),
              ],
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Professional Service',
                style: AppTypography.label.copyWith(
                  color: AppColors.textPrimary(context),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              Text(
                'For deep cleaning and maintenance, visit our store or contact '
                'customer service to schedule professional jewelry cleaning and '
                'inspection.',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary(context),
                  height: 1.5,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _fmtWeight(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
