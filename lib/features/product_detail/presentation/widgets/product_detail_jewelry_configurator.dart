import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../application/jewelry_config_draft_provider.dart';
import '../../domain/models/jewelry_unit_pricing.dart';
import '../../domain/models/product_jewelry_detail.dart';

/// "Choose your details" + price / quantity cards.
class ProductDetailJewelryConfigurator extends ConsumerWidget {
  const ProductDetailJewelryConfigurator({
    required this.productId,
    required this.jewelry,
    required this.draft,
    this.priceOnRequest = false,
    super.key,
  });

  final String productId;
  final ProductJewelryDetail jewelry;
  final JewelryConfigDraft? draft;
  final bool priceOnRequest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(jewelryConfigDraftProvider(productId).notifier);
    final purity = draft?.purity ??
        (jewelry.metalPurity.trim().isEmpty ? null : jewelry.metalPurity);
    final size = draft?.size;
    final stoneLabel = draft?.stoneWeightLabel;
    final qty = draft?.quantity ?? 1;
    final sku = draft?.sku ?? jewelry.styleNo;
    final symbol = jewelry.currencySymbol;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose your details',
                style: AppTypography.title.copyWith(
                  color: AppColors.textPrimary(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Select metal, purity, size, and stone weight to preview the matching piece.',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted(context),
                  height: 1.45,
                ),
              ),
              if (jewelry.purityOptions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s24),
                const _SectionLabel('PURITY'),
                const SizedBox(height: AppSpacing.s12),
                Wrap(
                  spacing: AppSpacing.s8,
                  runSpacing: AppSpacing.s8,
                  children: [
                    for (final option in jewelry.purityOptions)
                      _PillChip(
                        label: option,
                        selected: purity == option,
                        onTap: () => notifier.selectPurity(option, jewelry),
                      ),
                  ],
                ),
              ],
              if (jewelry.sizeOptions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s24),
                const _SectionLabel('SIZE'),
                const SizedBox(height: AppSpacing.s12),
                _SizeDropdown(
                  value: size,
                  options: jewelry.sizeOptions,
                  onChanged: (v) => notifier.selectSize(v, jewelry),
                ),
              ],
              if (jewelry.stoneWeightOptions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s24),
                const _SectionLabel('STONE WEIGHT'),
                const SizedBox(height: AppSpacing.s12),
                Wrap(
                  spacing: AppSpacing.s8,
                  runSpacing: AppSpacing.s8,
                  children: [
                    for (final option in jewelry.stoneWeightOptions)
                      _PillChip(
                        label: option,
                        selected: stoneLabel == option,
                        onTap: () =>
                            notifier.selectStoneWeight(option, jewelry),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        _Card(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _UnitPriceBlock(
                      symbol: symbol,
                      pricing: JewelryUnitPricing.from(
                        metalPrice: draft?.metalPrice ?? jewelry.metalPrice,
                        stonePrice: draft?.stonePrice ?? jewelry.stonePrice,
                        makingCharge:
                            draft?.makingCharge ?? jewelry.makingCharge,
                        discountAmount:
                            draft?.discountAmount ?? jewelry.discountAmount,
                        totalPrice: draft?.price ?? jewelry.price,
                      ),
                      priceOnRequest: priceOnRequest,
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      'Including all taxes and charges',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted(context),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      'SKU: $sku',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted(context),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Quantity',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textPrimary(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  _QuantityStepper(
                    quantity: qty,
                    onChanged: notifier.setQuantity,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UnitPriceBlock extends StatelessWidget {
  const _UnitPriceBlock({
    required this.symbol,
    required this.pricing,
    this.priceOnRequest = false,
  });

  final String symbol;
  final JewelryUnitPricing pricing;
  final bool priceOnRequest;

  @override
  Widget build(BuildContext context) {
    if (priceOnRequest) {
      return Text(
        'Price on request',
        style: AppTypography.headline.copyWith(
          color: AppColors.textPrimary(context),
          fontWeight: FontWeight.w700,
          fontSize: 28,
          height: 1.1,
        ),
      );
    }
    final netLabel = '$symbol${formatGroupedWhole(pricing.netPrice)}';
    if (!pricing.hasDiscount) {
      return Text(
        netLabel,
        style: AppTypography.headline.copyWith(
          color: AppColors.textPrimary(context),
          fontWeight: FontWeight.w700,
          fontSize: 28,
          height: 1.1,
        ),
      );
    }

    final listLabel = '$symbol${formatGroupedWhole(pricing.listPrice)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.s12,
          runSpacing: AppSpacing.s8,
          children: [
            Text(
              listLabel,
              style: AppTypography.body.copyWith(
                color: AppColors.textMuted(context),
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.lineThrough,
                decorationColor: AppColors.textMuted(context),
              ),
            ),
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
                '${formatDiscountPercent(pricing.discountPercent)}% off',
                style: AppTypography.caption.copyWith(
                  color: AppColors.warmWhite,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          netLabel,
          style: AppTypography.headline.copyWith(
            color: AppColors.success,
            fontWeight: FontWeight.w700,
            fontSize: 28,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s20),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSpacing.r20),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.caption.copyWith(
        color: AppColors.textMuted(context),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        fontSize: 11,
      ),
    );
  }
}

class _PillChip extends StatelessWidget {
  const _PillChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.selectedFill(context)
          : AppColors.surface(context),
      borderRadius: BorderRadius.circular(AppSpacing.r32),
      child: InkWell(
        onTap: () {
          if (!selected) AppHaptics.selection();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppSpacing.r32),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s20,
            vertical: AppSpacing.s12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.r32),
            border: Border.all(
              color: selected
                  ? AppColors.selectedFill(context)
                  : AppColors.border(context),
            ),
          ),
          child: Text(
            label,
            style: AppTypography.label.copyWith(
              color: selected
                  ? AppColors.onSelected(context)
                  : AppColors.textPrimary(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _SizeDropdown extends StatelessWidget {
  const _SizeDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppSpacing.r16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value != null && options.contains(value) ? value : null,
          isExpanded: true,
          hint: Text(
            'Select',
            style: AppTypography.body.copyWith(
              color: AppColors.textMuted(context),
            ),
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary(context),
          ),
          items: [
            for (final option in options)
              DropdownMenuItem(
                value: option,
                child: Text(
                  option,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onChanged,
  });

  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppSpacing.r32),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyButton(
            icon: Icons.remove,
            onTap: quantity > 1 ? () => onChanged(quantity - 1) : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
            child: Text(
              '$quantity',
              style: AppTypography.label.copyWith(
                color: AppColors.textPrimary(context),
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          _QtyButton(
            icon: Icons.add,
            onTap: () => onChanged(quantity + 1),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.r32),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(
          icon,
          size: 18,
          color: onTap == null
              ? AppColors.textMuted(context)
              : AppColors.textPrimary(context),
        ),
      ),
    );
  }
}
