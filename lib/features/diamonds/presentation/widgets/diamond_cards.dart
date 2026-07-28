import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../../core/widgets/marketplace_product_card_shell.dart';
import '../../../buyer/domain/models/wishlist_item.dart';
import '../../../buyer/presentation/widgets/wishlist_toggle_button.dart';
import '../../../comparison/application/comparison_provider.dart';
import '../../../comparison/domain/models/compare_item.dart';
import '../../../comparison/presentation/widgets/compare_add_button.dart';
import '../../../comparison/presentation/widgets/compare_toggle_helper.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../domain/models/diamond.dart';
import 'diamond_svg_data.dart';

class DiamondCardGrid extends ConsumerWidget {
  final Diamond diamond;
  final VoidCallback? onTap;

  const DiamondCardGrid({
    super.key,
    required this.diamond,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor =
        AppColors.textPrimaryLight;
    final mutedColor =
        AppColors.textMutedLight;
    final inCompare = ref.watch(isInComparisonProvider(diamond.id));

    return MarketplaceProductCardShell(
      onTap: onTap,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.15,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      color: AppColors.sandSurface,
                      child: Center(
                        child: renderShapeSvg(
                          diamond.shape,
                          size: 48,
                          color: AppColors.bronze,
                        ),
                      ),
                    ),
                  ),
                  if (diamond.discount != null && diamond.discount! > 0)
                    Positioned(
                      top: AppSpacing.s8,
                      right: AppSpacing.s8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s8,
                          vertical: AppSpacing.s4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.terracotta,
                          borderRadius: BorderRadius.circular(AppSpacing.r4),
                        ),
                        child: Text(
                          '-${diamond.discount!.round()}%',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.warmWhite,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  if (diamond.hasVideo)
                    const Positioned(
                      top: AppSpacing.s8,
                      left: AppSpacing.s8,
                      child: Icon(
                        Icons.play_circle_fill,
                        color: AppColors.bronze,
                        size: 18,
                      ),
                    ),
                  Positioned(
                    bottom: AppSpacing.s8,
                    left: AppSpacing.s4,
                    child: WishlistToggleButton(
                      item: WishlistItem.fromDiamond(diamond),
                      size: 18,
                    ),
                  ),
                  Positioned(
                    bottom: AppSpacing.s8,
                    right: AppSpacing.s8,
                    child: CompareAddButton(
                      isSelected: inCompare,
                      onPressed: () => handleCompareToggle(
                        context,
                        ref,
                        CompareItem.fromDiamond(diamond),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s12,
                  AppSpacing.s8,
                  AppSpacing.s12,
                  AppSpacing.s8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$${formatCatalogPrice(diamond.price)}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ).copyWith(color: textColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${diamond.carat}ct ${diamond.shape}',
                      style: AppTypography.caption.copyWith(
                        color: mutedColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Flexible(child: _specChip(diamond.cut, context)),
                        const SizedBox(width: AppSpacing.s4),
                        Flexible(child: _specChip(diamond.color, context)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            diamond.clarity,
                            style: AppTypography.caption.copyWith(
                              color: mutedColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s8),
                        Flexible(
                          child: Text(
                            diamond.certificate,
                            style: AppTypography.caption.copyWith(
                              color: mutedColor,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }

  Widget _specChip(String label, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.r4),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

}


class DiamondCardList extends ConsumerWidget {
  final Diamond diamond;
  final VoidCallback? onTap;

  const DiamondCardList({
    super.key,
    required this.diamond,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bgColor = AppColors.warmWhite;
    final borderColor = AppColors.warmBorder;
    final textColor = AppColors.textPrimaryLight;
    final mutedColor = AppColors.textMutedLight;
    final inCompare = ref.watch(isInComparisonProvider(diamond.id));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppSpacing.r12),
          border: Border.all(color: borderColor),
          boxShadow: AppShadows.cardLight,
        ),
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          height: 148,
          child: Row(
            children: [
              _buildImageSection(context, ref, inCompare),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildPriceRow(textColor, mutedColor),
                      const SizedBox(height: AppSpacing.s4),
                      _buildDetailsRow(mutedColor),
                      const SizedBox(height: AppSpacing.s4),
                      _buildSpecRow(textColor, mutedColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(
    BuildContext context,
    WidgetRef ref,
    bool inCompare,
  ) {
    return SizedBox(
      width: 100,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: AppColors.sandSurface,
              child: Center(
                child: renderShapeSvg(
                  diamond.shape,
                  size: 48,
                  color: AppColors.bronze,
                ),
              ),
            ),
          ),
          if (diamond.discount != null && diamond.discount! > 0)
            Positioned(
              top: AppSpacing.s4,
              right: AppSpacing.s4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.terracotta,
                  borderRadius: BorderRadius.circular(AppSpacing.r4),
                ),
                child: Text(
                  '-${diamond.discount!.round()}%',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.warmWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: AppSpacing.s8,
            left: AppSpacing.s4,
            child: WishlistToggleButton(
              item: WishlistItem.fromDiamond(diamond),
              size: 16,
            ),
          ),
          Positioned(
            bottom: AppSpacing.s8,
            right: AppSpacing.s8,
            child: CompareAddButton(
              size: 28,
              isSelected: inCompare,
              onPressed: () => handleCompareToggle(
                context,
                ref,
                CompareItem.fromDiamond(diamond),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(Color textColor, Color mutedColor) {
    return Row(
      children: [
        Flexible(
          child: Text(
            '\$${formatCatalogPrice(diamond.price)}',
            style: AppTypography.title.copyWith(
              fontWeight: FontWeight.bold,
              color: textColor,
              fontSize: 18,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (diamond.pricePerCarat != null) ...[
          const SizedBox(width: AppSpacing.s8),
          Flexible(
            child: Text(
              '\$${diamond.pricePerCarat!.round()}/ct',
              style: AppTypography.caption.copyWith(
                color: mutedColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        const Spacer(),
        if (diamond.hasVideo)
          const Icon(
            Icons.play_circle_fill,
            color: AppColors.bronze,
            size: 16,
          ),
      ],
    );
  }

  Widget _buildDetailsRow(Color mutedColor) {
    return Text(
      '${diamond.carat}ct ${diamond.shape} • ${diamond.cut}',
      style: AppTypography.body.copyWith(
        color: mutedColor,
        fontWeight: FontWeight.w500,
        fontSize: 13,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSpecRow(Color textColor, Color mutedColor) {
    return Row(
      children: [
        Flexible(
          child: Text(
            '${diamond.color} • ${diamond.clarity}',
            style: AppTypography.label.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.s8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s8,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.sandSurface,
              borderRadius: BorderRadius.circular(AppSpacing.r4),
            ),
            child: Text(
              diamond.certificate,
              style: AppTypography.caption.copyWith(
                color: mutedColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

}


class DiamondGridView extends StatelessWidget {
  final List<Diamond> diamonds;
  final ScrollController scrollController;
  final bool isLoadingMore;

  const DiamondGridView({
    super.key,
    required this.diamonds,
    required this.scrollController,
    this.isLoadingMore = false,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.only(
        left: AppSpacing.s16,
        right: AppSpacing.s16,
        top: AppSpacing.s8,
        bottom: AppSpacing.s24,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.s12,
        mainAxisSpacing: AppSpacing.s12,
        childAspectRatio: 0.72,
      ),
      itemCount: diamonds.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= diamonds.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.s16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final diamond = diamonds[index];
        return DiamondCardGrid(
          key: ValueKey(diamond.id),
          diamond: diamond,
          onTap: () => openDiamondDetail(context, diamond),
        );
      },
    );
  }
}


class DiamondListView extends StatelessWidget {
  final List<Diamond> diamonds;
  final ScrollController scrollController;
  final bool isLoadingMore;

  const DiamondListView({
    super.key,
    required this.diamonds,
    required this.scrollController,
    this.isLoadingMore = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.only(
        left: AppSpacing.s16,
        right: AppSpacing.s16,
        top: AppSpacing.s8,
        bottom: AppSpacing.s24,
      ),
      itemCount: diamonds.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= diamonds.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Text(
                  'Loading more...',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
          );
        }
        final diamond = diamonds[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s12),
          child: DiamondCardList(
            key: ValueKey(diamond.id),
            diamond: diamond,
            onTap: () => openDiamondDetail(context, diamond),
          ),
        );
      },
    );
  }
}
