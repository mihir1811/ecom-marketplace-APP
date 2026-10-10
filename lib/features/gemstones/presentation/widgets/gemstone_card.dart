import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../../core/widgets/catalog_card_image_pager.dart';
import '../../../../core/widgets/catalog_missing_image.dart';
import '../../../../core/widgets/catalog_discount_price.dart';
import '../../../recently_viewed/presentation/widgets/recently_viewed_badge.dart';
import '../../../recently_viewed/presentation/widgets/recently_viewed_card_shell.dart';
import '../../../buyer/domain/models/wishlist_item.dart';
import '../../../buyer/presentation/widgets/wishlist_toggle_button.dart';
import '../../../comparison/application/comparison_provider.dart';
import '../../../comparison/domain/models/compare_item.dart';
import '../../../comparison/presentation/widgets/compare_add_button.dart';
import '../../../comparison/presentation/widgets/compare_toggle_helper.dart';
import '../../../product_detail/domain/adapters/gemstone_product_detail.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../domain/models/gemstone.dart';

class GemstoneCardGrid extends ConsumerWidget {
  const GemstoneCardGrid({required this.gemstone, this.onTap, super.key});

  final Gemstone gemstone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = AppColors.textPrimary(context);
    final mutedColor = AppColors.textSecondary(context);
    final inCompare = ref.watch(isInComparisonProvider(gemstone.id));
    final title = _gridTitle(gemstone);
    final gradesLine = _gridGradesLine(gemstone);
    final metaLine = _gridMetaLine(gemstone);
    final markdown = catalogMarkdownPercent(gemstone.discount);

    return RecentlyViewedCardShell(
      productId: gemstone.id,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1.05,
            child: Stack(
              children: [
                Positioned.fill(
                  child: _GemstoneThumb(
                    gemstone: gemstone,
                    padding: AppSpacing.s24,
                  ),
                ),
                Positioned(
                  top: AppSpacing.s4,
                  right: AppSpacing.s4,
                  child: WishlistToggleButton(
                    item: WishlistItem.fromGemstone(gemstone),
                    onAdded: () =>
                        rememberProductDetail(gemstoneProductDetail(gemstone)),
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
                      CompareItem.fromGemstone(gemstone),
                    ),
                  ),
                ),
                Positioned(
                  top: AppSpacing.s8,
                  left: AppSpacing.s8,
                  child: AvailabilityStatusBadge(status: gemstone.availability),
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
                  Text(
                    title,
                    style: AppTypography.label.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (gradesLine != null) ...[
                    const SizedBox(height: AppSpacing.cardLineGap),
                    Text(
                      gradesLine,
                      style: AppTypography.caption.copyWith(
                        color: mutedColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (metaLine != null) ...[
                    const SizedBox(height: AppSpacing.cardLineGap),
                    Text(
                      metaLine,
                      style: AppTypography.caption.copyWith(
                        color: mutedColor,
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
                  const SizedBox(height: AppSpacing.cardPriceGap),
                  Row(
                    children: [
                      Expanded(
                        child: CatalogDiscountPrice(
                          net: gemstone.price,
                          discount: gemstone.discount,
                          textColor: textColor,
                          fontSize: 14,
                        ),
                      ),
                      if (markdown != null)
                        Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.s4),
                          child: Text(
                            '-${formatDiscountPercent(markdown)}%',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.terracotta,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      Icon(
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
    );
  }
}

/// Horizontal list card matching [WatchCardList] layout with gemstone data.
class GemstoneCardList extends ConsumerWidget {
  const GemstoneCardList({required this.gemstone, this.onTap, super.key});

  final Gemstone gemstone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = AppColors.textPrimary(context);
    final secondaryColor = AppColors.textSecondary(context);
    final inCompare = ref.watch(isInComparisonProvider(gemstone.id));
    final title = _listTitle(gemstone);
    final detail = _listDetailLine(gemstone);
    final meta = _listMetaLine(gemstone);
    final markdown = catalogMarkdownPercent(gemstone.discount);

    return RecentlyViewedCardShell(
      productId: gemstone.id,
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
                Positioned.fill(
                  child: _GemstoneThumb(
                    gemstone: gemstone,
                    padding: AppSpacing.s16,
                    cover: true,
                  ),
                ),
                Positioned(
                  top: AppSpacing.s8,
                  left: AppSpacing.s8,
                  child: AvailabilityStatusBadge(status: gemstone.availability),
                ),
                Positioned(
                  top: AppSpacing.s8,
                  right: AppSpacing.s8,
                  child: WishlistToggleButton(
                    item: WishlistItem.fromGemstone(gemstone),
                    onAdded: () =>
                        rememberProductDetail(gemstoneProductDetail(gemstone)),
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
                      CompareItem.fromGemstone(gemstone),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s16,
                AppSpacing.s16,
                AppSpacing.s16,
                AppSpacing.s16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                  const SizedBox(height: AppSpacing.cardPriceGap),
                  Row(
                    children: [
                      Expanded(
                        child: CatalogDiscountPrice(
                          net: gemstone.price,
                          discount: gemstone.discount,
                          textColor: textColor,
                          fontSize: 17,
                        ),
                      ),
                      if (markdown != null)
                        Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.s4),
                          child: Text(
                            '-${formatDiscountPercent(markdown)}%',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.terracotta,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      Icon(
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
        ],
      ),
    );
  }
}

class _GemstoneThumb extends StatelessWidget {
  const _GemstoneThumb({
    required this.gemstone,
    required this.padding,
    this.cover = false,
  });

  final Gemstone gemstone;
  final double padding;
  final bool cover;

  @override
  Widget build(BuildContext context) {
    final fallback = CatalogMissingImage(padding: padding);
    final urls = catalogListingImageUrls(
      imageUrl: gemstone.imageUrl,
      imageUrls: gemstone.imageUrls,
    );
    if (urls.isEmpty) return fallback;

    return CatalogCardImagePager(
      imageUrls: urls,
      fallback: fallback,
      fit: cover ? BoxFit.cover : BoxFit.contain,
      memCacheWidth: cover ? 280 : 400,
      backgroundColor: AppColors.sandSurface,
    );
  }
}

String _gridTitle(Gemstone gemstone) {
  final carat = '${gemstone.carat.toStringAsFixed(2)}ct';
  final shape = _optionalText(gemstone.shape);
  if (shape != null) return '$carat $shape';
  final type = _optionalText(gemstone.type);
  return type == null ? carat : '$carat $type';
}

/// Color · Clarity · Cut — available values only (never N/A).
String? _gridGradesLine(Gemstone gemstone) {
  final parts = <String>[];
  final color = _optionalText(gemstone.color);
  final clarity = _optionalText(gemstone.clarity);
  final cut = _optionalText(gemstone.cut);
  if (color != null) parts.add(color);
  if (clarity != null) parts.add(clarity);
  if (cut != null) parts.add(cut);
  if (parts.isEmpty) return null;
  return parts.join(' · ');
}

/// $/ct · dimensions — raw values only (no labels).
String? _gridMetaLine(Gemstone gemstone) {
  final parts = <String>[];
  final ppc = gemstone.pricePerCarat;
  if (ppc != null && ppc > 0) {
    parts.add('${AppCurrency.format(formatCatalogPrice(ppc))}/ct');
  }
  final dims = _optionalText(gemstone.dimensions);
  if (dims != null) parts.add(dims);
  if (parts.isEmpty) {
    final origin = _optionalText(gemstone.origin);
    if (origin != null) parts.add(origin);
  }
  if (parts.isEmpty) return null;
  return parts.join(' · ');
}

String _listTitle(Gemstone gemstone) {
  final carat = '${gemstone.carat.toStringAsFixed(2)}ct';
  final shape = _optionalText(gemstone.shape);
  final cut = _optionalText(gemstone.cut);
  if (shape != null && cut != null && !_equalsIgnoreCase(shape, cut)) {
    return '$carat $shape $cut';
  }
  if (shape != null) return '$carat $shape';
  if (cut != null) return '$carat $cut';
  final type = _optionalText(gemstone.type);
  return type == null ? carat : '$carat $type';
}

String _listDetailLine(Gemstone gemstone) {
  final parts = <String>[];
  final color = _optionalText(gemstone.color);
  final clarity = _optionalText(gemstone.clarity);
  final cut = _optionalText(gemstone.cut);
  if (color != null) parts.add(color);
  if (clarity != null) parts.add(clarity);
  if (cut != null) parts.add(cut);
  if (parts.isEmpty) {
    final shape = _optionalText(gemstone.shape);
    if (shape != null) parts.add(shape);
  }
  if (parts.isEmpty) return 'Specs unavailable';
  return parts.join(' · ');
}

String? _listMetaLine(Gemstone gemstone) {
  final parts = <String>[];
  final origin = _optionalText(gemstone.origin);
  if (origin != null) parts.add(origin);
  final treatment = _optionalText(gemstone.treatment);
  if (treatment != null) parts.add(treatment);
  final lab = _optionalText(gemstone.lab);
  if (lab != null) parts.add(lab);
  final ppc = gemstone.pricePerCarat;
  if (ppc != null && ppc > 0) {
    parts.add('${AppCurrency.format(formatCatalogPrice(ppc))}/ct');
  }
  final dims = _optionalText(gemstone.dimensions);
  if (dims != null && parts.length < 3) parts.add(dims);
  if (parts.isEmpty) return null;
  return parts.join(' · ');
}

String? _optionalText(String? value) {
  if (value == null) return null;
  final t = value.trim();
  if (t.isEmpty ||
      t == '-' ||
      t == '—' ||
      t == '–' ||
      t.toLowerCase() == 'n/a') {
    return null;
  }
  return t;
}

bool _equalsIgnoreCase(String a, String b) =>
    a.toLowerCase() == b.toLowerCase();
