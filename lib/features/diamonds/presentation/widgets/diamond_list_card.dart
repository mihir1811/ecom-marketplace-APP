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
import '../../../cart/application/cart_provider.dart';
import '../../../comparison/application/comparison_provider.dart';
import '../../../comparison/domain/models/compare_item.dart';
import '../../../comparison/presentation/widgets/compare_add_button.dart';
import '../../../comparison/presentation/widgets/compare_toggle_helper.dart';
import '../../../product_detail/domain/adapters/diamond_product_detail.dart';
import '../../domain/models/diamond.dart';
import '../../domain/models/diamond_display.dart';
import 'diamond_svg_data.dart';

/// Horizontal list card with specs and footer actions.
class DiamondCardList extends ConsumerWidget {
  const DiamondCardList({
    required this.diamond,
    super.key,
    this.onTap,
  });

  final Diamond diamond;
  final VoidCallback? onTap;

  void _notify(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title =
        '${diamond.carat.toStringAsFixed(2)}ct ${DiamondDisplay.shape(diamond.shape)}';
    final price = AppCurrency.format(formatCatalogPrice(diamond.price));
    final inCompare = ref.watch(isInComparisonProvider(diamond.id));
    final canPurchase = !diamond.isSold;

    return MarketplaceProductCardShell(
      borderRadius: AppSpacing.r12,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ListMedia(diamond: diamond),
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
                            fontSize: 16,
                            height: 1.25,
                            color: AppColors.textPrimaryLight,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Text(
                        price,
                        style: AppTypography.title.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          height: 1.25,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  _SpecGrid(diamond: diamond),
                  const SizedBox(height: AppSpacing.s12),
                  Row(
                    children: [
                      CompareAddButton(
                        size: 36,
                        isSelected: inCompare,
                        onPressed: () => handleCompareToggle(
                          context,
                          ref,
                          CompareItem.fromDiamond(diamond),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onTap,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.charcoal,
                            side: const BorderSide(color: AppColors.warmBorder),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s8,
                              vertical: AppSpacing.s8,
                            ),
                            minimumSize: const Size(0, 36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text('Details'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: canPurchase
                              ? () {
                                  final added = ref
                                      .read(cartProvider.notifier)
                                      .addItem(
                                        diamondProductDetail(diamond)
                                            .toCartItem(),
                                      );
                                  _notify(
                                    context,
                                    added
                                        ? 'Added to cart'
                                        : 'Already in your cart',
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s8,
                              vertical: AppSpacing.s8,
                            ),
                            minimumSize: const Size(0, 36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: Text(
                            canPurchase ? 'Add to cart' : 'Sold',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListMedia extends StatelessWidget {
  const _ListMedia({required this.diamond});

  final Diamond diamond;

  static const double _size = 128;

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        diamond.imageUrl != null && diamond.imageUrl!.trim().isNotEmpty;
    final certLab =
        DiamondDisplay.labBadge(diamond.lab ?? diamond.certificate);

    return SizedBox(
      width: _size,
      height: _size,
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
                        url: diamond.imageUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: 320,
                      )
                    : ColoredBox(
                        color: AppColors.sandSurface,
                        child: Center(
                          child: renderShapeSvg(
                            diamond.shape,
                            size: 64,
                            color: AppColors.bronze,
                          ),
                        ),
                      ),
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
            top: 4,
            right: 4,
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
                size: 14,
                padded: true,
              ),
            ),
          ),
        ],
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
          fontSize: 10,
          height: 1.1,
          letterSpacing: 0.3,
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
    final specs = <(String, String)>[
      ('Cut', DiamondDisplay.gradeChip(diamond.cut)),
      ('Color', DiamondDisplay.gradeChip(diamond.color)),
      ('Clarity', DiamondDisplay.gradeChip(diamond.clarity)),
      ('Certificate', DiamondDisplay.gradeChip(diamond.certificate)),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SpecItem(label: specs[0].$1, value: specs[0].$2),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: _SpecItem(label: specs[1].$1, value: specs[1].$2),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s8),
        Row(
          children: [
            Expanded(
              child: _SpecItem(label: specs[2].$1, value: specs[2].$2),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: _SpecItem(label: specs[3].$1, value: specs[3].$2),
            ),
          ],
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
            fontSize: 13,
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
              fontSize: 13,
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
