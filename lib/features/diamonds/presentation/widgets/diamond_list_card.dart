import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/marketplace_product_card_shell.dart';
import '../../../buyer/domain/models/wishlist_item.dart';
import '../../../buyer/presentation/widgets/wishlist_toggle_button.dart';
import '../../../comparison/application/comparison_provider.dart';
import '../../../comparison/domain/models/compare_item.dart';
import '../../../comparison/presentation/widgets/compare_add_button.dart';
import '../../../comparison/presentation/widgets/compare_toggle_helper.dart';
import '../../domain/models/diamond.dart';
import '../../domain/models/diamond_display.dart';
import 'diamond_svg_data.dart';

/// Horizontal list card with specs and compare action.
class DiamondCardList extends ConsumerWidget {
  const DiamondCardList({
    required this.diamond,
    super.key,
    this.onTap,
  });

  final Diamond diamond;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title =
        '${diamond.carat.toStringAsFixed(2)}ct ${DiamondDisplay.shape(diamond.shape)}';
    final price = AppCurrency.format(formatCatalogPrice(diamond.price));
    final inCompare = ref.watch(isInComparisonProvider(diamond.id));

    return MarketplaceProductCardShell(
      borderRadius: AppSpacing.r12,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          AppSpacing.s20,
          AppSpacing.s16,
          AppSpacing.s20,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ListMedia(
                diamond: diamond,
                inCompare: inCompare,
                onCompare: () => handleCompareToggle(
                  context,
                  ref,
                  CompareItem.fromDiamond(diamond),
                ),
              ),
              const SizedBox(width: AppSpacing.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTypography.title.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              height: 1.3,
                              color: AppColors.textPrimaryLight,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s12),
                        Text(
                          price,
                          style: AppTypography.title.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            height: 1.3,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s20),
                    _SpecGrid(diamond: diamond),
                    const SizedBox(height: AppSpacing.s16),
                    _MetaRow(diamond: diamond),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListMedia extends StatelessWidget {
  const _ListMedia({
    required this.diamond,
    required this.inCompare,
    required this.onCompare,
  });

  final Diamond diamond;
  final bool inCompare;
  final VoidCallback onCompare;

  static const double _width = 116;
  static const double _minHeight = 132;

  @override
  Widget build(BuildContext context) {
    final photoUrl = diamond.imageUrl?.trim();
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    final certLab =
        DiamondDisplay.labBadge(diamond.lab ?? diamond.certificate);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _minHeight),
      child: SizedBox(
        width: _width,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.sandSurface,
                  borderRadius: BorderRadius.circular(AppSpacing.r8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.r8),
                  child: hasPhoto
                      ? AppNetworkImage(
                          url: photoUrl,
                          fit: BoxFit.cover,
                          width: _width,
                          memCacheWidth: 300,
                          error: _ShapeFallback(shape: diamond.shape, size: 52),
                        )
                      : _ShapeFallback(shape: diamond.shape, size: 52),
                ),
              ),
            ),
            if (certLab != null)
              Positioned(
                top: AppSpacing.s8,
                left: AppSpacing.s8,
                child: _CertificateLabBadge(label: certLab),
              ),
            Positioned(
              top: AppSpacing.s4,
              right: AppSpacing.s4,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.warmWhite,
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: AppColors.warmBorder),
                  ),
                ),
                child: WishlistToggleButton(
                  item: WishlistItem.fromDiamond(diamond),
                  size: 13,
                  padded: true,
                ),
              ),
            ),
            Positioned(
              bottom: AppSpacing.s4,
              right: AppSpacing.s4,
              child: CompareAddButton(
                size: 30,
                isSelected: inCompare,
                onPressed: onCompare,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShapeFallback extends StatelessWidget {
  const _ShapeFallback({required this.shape, required this.size});

  final String shape;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.sandSurface,
      child: Center(
        child: renderShapeSvg(
          shape,
          size: size,
          color: AppColors.bronze,
        ),
      ),
    );
  }
}

class _CertificateLabBadge extends StatelessWidget {
  const _CertificateLabBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: AppColors.bronze,
        borderRadius: BorderRadius.circular(AppSpacing.r4),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: AppColors.warmWhite,
          fontWeight: FontWeight.w700,
          fontSize: 9,
          height: 1.1,
          letterSpacing: 0.2,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _SpecGrid extends StatelessWidget {
  const _SpecGrid({required this.diamond});

  final Diamond diamond;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SpecItem(
                label: 'Cut',
                value: DiamondDisplay.gradeChip(diamond.cut),
              ),
            ),
            const SizedBox(width: AppSpacing.s16),
            Expanded(
              child: _SpecItem(
                label: 'Color',
                value: DiamondDisplay.gradeChip(diamond.color),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s16),
        Row(
          children: [
            Expanded(
              child: _SpecItem(
                label: 'Clarity',
                value: DiamondDisplay.gradeChip(diamond.clarity),
              ),
            ),
            const SizedBox(width: AppSpacing.s16),
            Expanded(
              child: _SpecItem(
                label: 'Polish',
                value: DiamondDisplay.gradeChip(diamond.polish),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.diamond});

  final Diamond diamond;

  @override
  Widget build(BuildContext context) {
    final ppc = diamond.pricePerCarat;
    final ppcLabel = ppc == null
        ? 'N/A'
        : AppCurrency.format(formatCatalogPrice(ppc));
    final hasMeasure = DiamondDisplay.optional(diamond.measurement) != null;
    final measure = DiamondDisplay.optional(diamond.measurement) ??
        DiamondDisplay.optional(diamond.stockNumber) ??
        'N/A';

    return Row(
      children: [
        Expanded(child: _SpecItem(label: '\$/ct', value: ppcLabel)),
        const SizedBox(width: AppSpacing.s16),
        Expanded(
          child: _SpecItem(
            label: hasMeasure ? 'Size' : 'Stock',
            value: measure,
          ),
        ),
      ],
    );
  }
}

class _SpecItem extends StatelessWidget {
  const _SpecItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isMissing = value == 'N/A';
    return Row(
      children: [
        Text(
          '$label: ',
          style: AppTypography.body.copyWith(
            fontSize: 12,
            height: 1.35,
            color: AppColors.textSecondaryLight,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body.copyWith(
              fontSize: 12,
              height: 1.35,
              color: isMissing
                  ? AppColors.textMutedLight
                  : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
