import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

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
import '../../../product_detail/product_detail_navigation.dart';
import '../../domain/models/diamond.dart';
import '../../domain/models/diamond_display.dart';
import 'diamond_svg_data.dart';
import 'diamond_list_card.dart';
export 'diamond_list_card.dart' show DiamondCardList;

Widget _diamondThumb(Diamond diamond, {double shapeSize = 48}) {
  final url = diamond.imageUrl?.trim();
  if (url != null && url.isNotEmpty) {
    return SizedBox.expand(
      child: AppNetworkImage(
        url: url,
        fit: BoxFit.cover,
        memCacheWidth: 400,
        error: ColoredBox(
          color: AppColors.sandSurface,
          child: Center(
            child: renderShapeSvg(
              diamond.shape,
              size: shapeSize,
              color: AppColors.bronze,
            ),
          ),
        ),
      ),
    );
  }
  return ColoredBox(
    color: AppColors.sandSurface,
    child: Center(
      child: renderShapeSvg(
        diamond.shape,
        size: shapeSize,
        color: AppColors.bronze,
      ),
    ),
  );
}

/// Grid card matching [WatchCardGrid] layout with diamond data.
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
    const textColor = AppColors.textPrimaryLight;
    const mutedColor = AppColors.textSecondaryLight;
    final inCompare = ref.watch(isInComparisonProvider(diamond.id));
    final title =
        '${diamond.carat.toStringAsFixed(2)}ct ${DiamondDisplay.shape(diamond.shape)}';
    final gradesLine = _gridGradesLine(diamond);
    final metaLine = _gridMetaLine(diamond);

    return MarketplaceProductCardShell(
      onTap: onTap,
      child: SizedBox.expand(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.05,
              child: Stack(
                children: [
                  Positioned.fill(child: _diamondThumb(diamond)),
                  Positioned(
                    top: AppSpacing.s4,
                    right: AppSpacing.s4,
                    child: WishlistToggleButton(
                      item: WishlistItem.fromDiamond(diamond),
                      size: 18,
                    ),
                  ),
                  if (diamond.discount != null && diamond.discount! > 0)
                    Positioned(
                      top: AppSpacing.s8,
                      left: AppSpacing.s8,
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
                  AppSpacing.s12,
                  AppSpacing.s12,
                  AppSpacing.s12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: AppTypography.label.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      softWrap: true,
                    ),
                    if (gradesLine != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        gradesLine,
                        style: AppTypography.caption.copyWith(
                          color: mutedColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        softWrap: true,
                      ),
                    ],
                    if (metaLine != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        metaLine,
                        style: AppTypography.caption.copyWith(
                          color: mutedColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        softWrap: true,
                      ),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppCurrency.format(
                              formatCatalogPrice(diamond.price),
                            ),
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ).copyWith(color: textColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: AppColors.bronze,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Color · Clarity · Cut — only values that exist (never N/A).
String? _gridGradesLine(Diamond diamond) {
  final parts = <String>[];
  final color = DiamondDisplay.gradeChip(diamond.color);
  final clarity = DiamondDisplay.gradeChip(diamond.clarity);
  final cut = DiamondDisplay.gradeChip(diamond.cut);
  if (color != 'N/A') parts.add(color);
  if (clarity != 'N/A') parts.add(clarity);
  if (cut != 'N/A') parts.add(cut);
  if (parts.isEmpty) return null;
  return parts.join(' · ');
}

/// $/ct · measurement — raw values only (no Pol/Sym/labels).
String? _gridMetaLine(Diamond diamond) {
  final parts = <String>[];
  final ppc = diamond.pricePerCarat;
  if (ppc != null && ppc > 0) {
    parts.add('${AppCurrency.format(formatCatalogPrice(ppc))}/ct');
  }
  final measure = DiamondDisplay.optional(diamond.measurement);
  if (measure != null) parts.add(measure);
  if (parts.isEmpty) return null;
  return parts.join(' · ');
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
      cacheExtent: 600,
      addAutomaticKeepAlives: false,
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
        childAspectRatio: 0.68,
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
        return RepaintBoundary(
          child: DiamondCardGrid(
            key: ValueKey(diamond.id),
            diamond: diamond,
            onTap: () => openDiamondDetail(context, diamond),
          ),
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
      cacheExtent: 600,
      addAutomaticKeepAlives: false,
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
        return RepaintBoundary(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s12),
            child: DiamondCardList(
              key: ValueKey(diamond.id),
              diamond: diamond,
              onTap: () => openDiamondDetail(context, diamond),
            ),
          ),
        );
      },
    );
  }
}
