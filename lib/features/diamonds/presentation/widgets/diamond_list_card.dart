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
import '../../domain/models/diamond.dart';
import '../../domain/models/diamond_display.dart';
import 'diamond_svg_data.dart';

/// Compact horizontal list card — square media, specs only (no footer actions).
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
                  _SpecWrap(diamond: diamond),
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

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        diamond.imageUrl != null && diamond.imageUrl!.trim().isNotEmpty;

    return SizedBox(
      width: 96,
      height: 96,
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
                        memCacheWidth: 240,
                      )
                    : Center(
                        child: renderShapeSvg(
                          diamond.shape,
                          size: 52,
                          color: AppColors.bronze,
                        ),
                      ),
              ),
            ),
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

class _SpecWrap extends StatelessWidget {
  const _SpecWrap({required this.diamond});

  final Diamond diamond;

  @override
  Widget build(BuildContext context) {
    final specs = <(String, String, Widget?)>[
      (
        'Stock',
        DiamondDisplay.optional(diamond.stockNumber) ??
            DiamondDisplay.optional(diamond.id) ??
            '—',
        null,
      ),
      (
        'Color',
        DiamondDisplay.gradeChip(diamond.color),
        null,
      ),
      (
        'Clarity',
        DiamondDisplay.gradeChip(diamond.clarity),
        null,
      ),
      (
        'Shape',
        DiamondDisplay.shape(diamond.shape),
        renderShapeSvg(
          diamond.shape,
          size: 14,
          color: AppColors.charcoal,
        ),
      ),
      (
        'Carat',
        diamond.carat.toStringAsFixed(2),
        null,
      ),
    ];

    return Wrap(
      spacing: AppSpacing.s16,
      runSpacing: AppSpacing.s8,
      children: [
        for (final spec in specs)
          _SpecItem(label: spec.$1, value: spec.$2, leading: spec.$3),
      ],
    );
  }
}

class _SpecItem extends StatelessWidget {
  const _SpecItem({
    required this.label,
    required this.value,
    this.leading,
  });

  final String label;
  final String value;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 180),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: AppTypography.body.copyWith(
              fontSize: 13,
              color: AppColors.textSecondaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body.copyWith(
                fontSize: 13,
                color: AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
