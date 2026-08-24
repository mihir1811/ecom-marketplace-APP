import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../recently_viewed/presentation/widgets/recently_viewed_badge.dart';
import '../../../recently_viewed/presentation/widgets/recently_viewed_card_shell.dart';
import '../../../buyer/domain/models/wishlist_item.dart';
import '../../../buyer/presentation/widgets/wishlist_toggle_button.dart';
import '../../../comparison/application/comparison_provider.dart';
import '../../../comparison/domain/models/compare_item.dart';
import '../../../comparison/presentation/widgets/compare_add_button.dart';
import '../../../comparison/presentation/widgets/compare_toggle_helper.dart';
import '../../../product_detail/domain/adapters/diamond_product_detail.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../domain/models/diamond.dart';
import '../../domain/models/diamond_display.dart';
import 'diamond_svg_data.dart';

/// Horizontal list card matching [WatchCardList] layout with diamond data.
class DiamondCardList extends ConsumerWidget {
  const DiamondCardList({required this.diamond, super.key, this.onTap});

  final Diamond diamond;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = AppColors.textPrimary(context);
    final secondaryColor = AppColors.textSecondary(context);
    final inCompare = ref.watch(isInComparisonProvider(diamond.id));
    final title = _listTitle(diamond);
    final detail = _listDetailLine(diamond);
    final meta = _listMetaLine(diamond);

    return RecentlyViewedCardShell(
      productId: diamond.id,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(child: _DiamondListThumb(diamond: diamond)),
                Positioned(
                  top: AppSpacing.s8,
                  left: AppSpacing.s8,
                  child: AvailabilityStatusBadge(
                    status: diamond.available,
                  ),
                ),
                Positioned(
                  top: AppSpacing.s8,
                  right: AppSpacing.s8,
                  child: WishlistToggleButton(
                    item: WishlistItem.fromDiamond(diamond),
                    onAdded: () =>
                        rememberProductDetail(diamondProductDetail(diamond)),
                    size: 18,
                  ),
                ),
                Positioned(
                  bottom: AppSpacing.s8,
                  right: AppSpacing.s8,
                  child: CompareAddButton(
                    size: 32,
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
            child: SizedBox(
              height: 140,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16,
                  AppSpacing.s16,
                  AppSpacing.s16,
                  AppSpacing.s16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.label.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.cardLineGap),
                    Text(
                      detail,
                      style: AppTypography.caption.copyWith(
                        color: secondaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (meta != null) ...[
                      const SizedBox(height: AppSpacing.cardLineGap),
                      Text(
                        meta,
                        style: AppTypography.caption.copyWith(
                          color: secondaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
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
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ).copyWith(color: textColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (diamond.discount != null && diamond.discount! > 0)
                          Padding(
                            padding:
                                const EdgeInsets.only(left: AppSpacing.s4),
                            child: Text(
                              '-${formatDiscountPercent(diamond.discount!)}%',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.terracotta,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        const Icon(
                          Icons.arrow_forward,
                          size: 18,
                          color: AppColors.bronze,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiamondListThumb extends StatelessWidget {
  const _DiamondListThumb({required this.diamond});

  final Diamond diamond;

  @override
  Widget build(BuildContext context) {
    final photoUrl = diamond.imageUrl?.trim();
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    final fallback = _ShapeFallback(shape: diamond.shape, size: 52);

    if (!hasPhoto) return fallback;

    return ColoredBox(
      color: AppColors.surface(context),
      child: AppNetworkImage(
        url: photoUrl,
        fit: BoxFit.cover,
        memCacheWidth: 480,
        error: fallback,
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
      color: AppColors.surface(context),
      child: Center(
        child: renderShapeSvg(shape, size: size, color: AppColors.bronze),
      ),
    );
  }
}

String _listTitle(Diamond diamond) {
  final carat = '${diamond.carat.toStringAsFixed(2)}ct';
  final shape = DiamondDisplay.shape(diamond.shape);
  if (shape == DiamondDisplay.missing) return carat;
  return '$carat $shape';
}

String _listDetailLine(Diamond diamond) {
  final parts = <String>[];
  final color = DiamondDisplay.primaryColorLabel(
    color: diamond.color,
    fancyColor: diamond.fancyColor,
    fancyIntensity: diamond.fancyIntensity,
    uppercase: true,
  );
  final clarity = DiamondDisplay.gradeChip(diamond.clarity);
  final cut = DiamondDisplay.gradeChip(diamond.cut);
  if (color != null) parts.add('Col $color');
  if (clarity != 'N/A') parts.add(clarity);
  if (cut != 'N/A') parts.add('Cut $cut');
  if (parts.isEmpty) {
    final polish = DiamondDisplay.gradeChip(diamond.polish);
    final symmetry = DiamondDisplay.gradeChip(diamond.symmetry);
    if (polish != 'N/A') parts.add('Pol $polish');
    if (symmetry != 'N/A') parts.add('Sym $symmetry');
  }
  if (parts.isEmpty) return 'Grades unavailable';
  return parts.join(' · ');
}

String? _listMetaLine(Diamond diamond) {
  final parts = <String>[];
  final lab = DiamondDisplay.labBadge(diamond.lab ?? diamond.certificate);
  if (lab != null) parts.add(lab);
  final ppc = diamond.pricePerCarat;
  if (ppc != null && ppc > 0) {
    parts.add('${AppCurrency.format(formatCatalogPrice(ppc))}/ct');
  }
  final measure = DiamondDisplay.optional(diamond.measurement);
  if (measure != null) {
    parts.add(measure);
  } else {
    final stock = DiamondDisplay.optional(diamond.stockNumber);
    if (stock != null) parts.add('Stock $stock');
  }
  if (parts.isEmpty) return null;
  return parts.join(' · ');
}
