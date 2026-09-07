import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../application/jewelry_config_draft_provider.dart';
import '../../domain/models/jewelry_unit_pricing.dart';
import '../../domain/models/product_detail.dart';
import '../../domain/models/product_jewelry_detail.dart';

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
        Row(
          children: [
            for (var i = 0; i < _tabs.length; i++)
              Padding(
                padding: EdgeInsets.only(
                  right: i < _tabs.length - 1 ? AppSpacing.s24 : 0,
                ),
                child: _TabLabel(
                  title: _tabs[i],
                  selected: i == _tabIndex,
                  onTap: () => setState(() => _tabIndex = i),
                ),
              ),
          ],
        ),
        Divider(height: 1, thickness: 1, color: AppColors.border(context)),
        const SizedBox(height: AppSpacing.s24),
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

class _TabLabel extends StatelessWidget {
  const _TabLabel({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s12),
            child: Text(
              title,
              style: AppTypography.label.copyWith(
                color: selected
                    ? AppColors.textPrimary(context)
                    : AppColors.textMuted(context),
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          ColoredBox(
            color: selected
                ? AppColors.textPrimary(context)
                : Colors.transparent,
            child: const SizedBox(height: 2, width: 88),
          ),
        ],
      ),
    );
  }
}

class _DetailsTab extends StatelessWidget {
  const _DetailsTab({required this.jewelry});

  final ProductJewelryDetail jewelry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About this piece',
          style: AppTypography.title.copyWith(
            color: AppColors.textPrimary(context),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        Text(
          jewelry.description,
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary(context),
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.s32),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 560;
            final material = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Material',
                  style: AppTypography.label.copyWith(
                    color: AppColors.textPrimary(context),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                if (jewelry.materialLabel != null) ...[
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    jewelry.materialLabel!,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ],
            );
            final style = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Style',
                  style: AppTypography.label.copyWith(
                    color: AppColors.textPrimary(context),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                if (jewelry.category.trim().isNotEmpty)
                  _MetaLine('Category: ${jewelry.category}'),
                if (jewelry.gender.trim().isNotEmpty)
                  _MetaLine('Gender: ${jewelry.gender}'),
                if (jewelry.occasion.trim().isNotEmpty)
                  _MetaLine('Occasion: ${jewelry.occasion}'),
              ],
            );
            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  material,
                  const SizedBox(height: AppSpacing.s24),
                  style,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: material),
                const SizedBox(width: AppSpacing.s32),
                Expanded(child: style),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: Text(
        text,
        style: AppTypography.body.copyWith(
          color: AppColors.textSecondary(context),
        ),
      ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        final left = _ProductSummaryColumn(
          jewelry: jewelry,
          draft: draft,
        );
        final right = _SpecCardsColumn(
          jewelry: jewelry,
          draft: draft,
          priceOnRequest: priceOnRequest,
        );
        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              left,
              const SizedBox(height: AppSpacing.s24),
              right,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 4, child: left),
            const SizedBox(width: AppSpacing.s32),
            Expanded(flex: 6, child: right),
          ],
        );
      },
    );
  }
}

class _ProductSummaryColumn extends StatelessWidget {
  const _ProductSummaryColumn({
    required this.jewelry,
    required this.draft,
  });

  final ProductJewelryDetail jewelry;
  final JewelryConfigDraft? draft;

  @override
  Widget build(BuildContext context) {
    final sku = draft?.sku ?? jewelry.styleNo;
    final metalW = draft?.metalWeightG ?? jewelry.metalWeightG;
    final totalW = draft?.totalWeightG ?? jewelry.totalWeightG;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Product Summary',
          style: AppTypography.title.copyWith(
            color: AppColors.textPrimary(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        _KvRow('Style No.', sku),
        if (metalW > 0)
          _KvRow('Metal Weight', '${_fmtWeight(metalW)}g'),
        if (totalW != null && totalW > 0)
          _KvRow('Total Weight', '${_fmtWeight(totalW)}g'),
      ],
    );
  }
}

class _SpecCardsColumn extends StatelessWidget {
  const _SpecCardsColumn({
    required this.jewelry,
    required this.draft,
    this.priceOnRequest = false,
  });

  final ProductJewelryDetail jewelry;
  final JewelryConfigDraft? draft;
  final bool priceOnRequest;

  @override
  Widget build(BuildContext context) {
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
    final metalW = draft?.metalWeightG ?? jewelry.metalWeightG;
    final totalW = draft?.totalWeightG ?? jewelry.totalWeightG;
    final size = draft?.braceletSize ??
        draft?.ringSize ??
        draft?.chainLength ??
        jewelry.sizeLabel;
    final stones = (draft?.stones.isNotEmpty ?? false)
        ? draft!.stones
        : jewelry.stones;

    return Column(
      children: [
        _ExpandableSpecCard(
          title: 'Price Breakup',
          initiallyExpanded: true,
          child: priceOnRequest
              ? const _KvRow('Grand Total', 'Price on request', bold: true)
              : Column(
                  children: [
                    if (pricing.metal > 0)
                      _KvRow(
                        'Metal',
                        '$symbol${formatGroupedWhole(pricing.metal)}',
                      ),
                    if (pricing.stone > 0)
                      _KvRow(
                        'Diamond',
                        '$symbol${formatGroupedWhole(pricing.stone)}',
                      ),
                    if (pricing.making > 0)
                      _KvRow(
                        'Making Charges',
                        '$symbol${formatGroupedWhole(pricing.making)}',
                      ),
                    if (pricing.hasDiscount)
                      _KvRow(
                        'Discount',
                        '-$symbol${formatGroupedWhole(pricing.discount)}',
                        valueColor: AppColors.success,
                      ),
                    const Divider(height: AppSpacing.s24),
                    _KvRow(
                      'Grand Total',
                      '$symbol${formatGroupedWhole(pricing.netPrice)}',
                      bold: true,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '(MRP Incl. of all taxes)',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted(context),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.s16),
        _ExpandableSpecCard(
          title: 'Metal Details',
          initiallyExpanded: true,
          child: Column(
            children: [
              if (metalType.trim().isNotEmpty)
                _KvRow('Metal Type', metalType),
              if (metalColor.trim().isNotEmpty)
                _KvRow('Metal Color', metalColor),
              if (purity.trim().isNotEmpty) _KvRow('Metal Purity', purity),
              if ((finish ?? '').trim().isNotEmpty)
                _KvRow('Metal Finish', finish!),
              if (metalW > 0)
                _KvRow('Metal Weight', '${_fmtWeight(metalW)}g'),
              if (size.trim().isNotEmpty) _KvRow(_sizeLabel(jewelry), size),
              if (totalW != null && totalW > 0)
                _KvRow('Total Weight', '${_fmtWeight(totalW)}g'),
            ],
          ),
        ),
        if (stones.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s16),
          _ExpandableSpecCard(
            title: 'Diamond Details',
            initiallyExpanded: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < stones.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.s16),
                  Text(
                    'Stone ${i + 1}',
                    style: AppTypography.label.copyWith(
                      color: AppColors.textPrimary(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  _StoneGrid(stone: stones[i]),
                ],
                const SizedBox(height: AppSpacing.s16),
                Text(
                  '*A differential amount will be applicable with difference in weight if any.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted(context),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _sizeLabel(ProductJewelryDetail jewelry) {
    if ((jewelry.braceletSize ?? '').isNotEmpty) return 'Bracelet Size';
    if ((jewelry.ringSize ?? '').isNotEmpty) return 'Ring Size';
    if ((jewelry.chainLength ?? '').isNotEmpty) return 'Chain Length';
    return 'Size';
  }
}

class _StoneGrid extends StatelessWidget {
  const _StoneGrid({required this.stone});

  final ProductJewelryStone stone;

  @override
  Widget build(BuildContext context) {
    final cells = <(String, String)>[
      if ((stone.type ?? '').isNotEmpty)
        ('Center Type', stone.type!.toUpperCase()),
      if ((stone.shape ?? '').isNotEmpty) ('Shape', stone.shape!),
      if (stone.weightCt != null && stone.weightCt! > 0)
        ('Carat', '${_fmtWeight(stone.weightCt!)}ct'),
      if ((stone.color ?? '').isNotEmpty) ('Color', stone.color!),
      if ((stone.clarity ?? '').isNotEmpty) ('Clarity', stone.clarity!),
      if (stone.pieces != null && stone.pieces! > 0)
        ('Pieces', '${stone.pieces}'),
      if ((stone.setting ?? '').isNotEmpty) ('Setting', stone.setting!),
    ];
    if (cells.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final colW = (constraints.maxWidth - AppSpacing.s16) / 2;
        return Wrap(
          spacing: AppSpacing.s16,
          runSpacing: AppSpacing.s12,
          children: [
            for (final cell in cells)
              SizedBox(
                width: colW,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cell.$1,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted(context),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cell.$2,
                      style: AppTypography.label.copyWith(
                        color: AppColors.textPrimary(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ExpandableSpecCard extends StatefulWidget {
  const _ExpandableSpecCard({
    required this.title,
    required this.child,
    this.initiallyExpanded = true,
  });

  final String title;
  final Widget child;
  final bool initiallyExpanded;

  @override
  State<_ExpandableSpecCard> createState() => _ExpandableSpecCardState();
}

class _ExpandableSpecCardState extends State<_ExpandableSpecCard> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSpacing.r20),
        border: Border.all(color: AppColors.border(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s20,
                vertical: AppSpacing.s16,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppTypography.label.copyWith(
                        color: AppColors.textPrimary(context),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary(context),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s20,
                0,
                AppSpacing.s20,
                AppSpacing.s20,
              ),
              child: widget.child,
            ),
        ],
      ),
    );
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Care Instructions',
          style: AppTypography.title.copyWith(
            color: AppColors.textPrimary(context),
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
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
        ],
        const SizedBox(height: AppSpacing.s16),
        Text(
          'Professional Service',
          style: AppTypography.label.copyWith(
            color: AppColors.textPrimary(context),
            fontWeight: FontWeight.w800,
            fontSize: 15,
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
          ),
        ),
      ],
    );
  }
}

class _KvRow extends StatelessWidget {
  const _KvRow(
    this.label,
    this.value, {
    this.bold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.body.copyWith(
                color: AppColors.textMuted(context),
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTypography.label.copyWith(
                color: valueColor ?? AppColors.textPrimary(context),
                fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
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
