import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/widgets/catalog_card_image_pager.dart';
import '../../../../core/widgets/luxe/luxe_metal_swatch.dart';
import '../../../../core/widgets/luxe/luxe_product_card.dart';
import '../../../buyer/domain/models/wishlist_item.dart';
import '../../../catalog_flow/presentation/widgets/catalog_card_actions.dart';
import '../../../comparison/domain/models/compare_item.dart';
import '../../../product_detail/domain/adapters/jewelry_product_detail.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../../recently_viewed/application/recently_viewed_providers.dart';
import '../../../recently_viewed/presentation/widgets/recently_viewed_badge.dart';
import '../../../jewelry_reviews/presentation/widgets/jewelry_review_stars.dart';
import '../../../spotlight/presentation/widgets/spotlight_tag.dart';
import '../../domain/models/jewelry.dart';

String _join(Iterable<String> parts) =>
    parts.where((p) => p.trim().isNotEmpty).join(' · ');

String _weight(double v, String unit) =>
    '${v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2)}$unit';

/// Card title: the product name before any " — " or " | " descriptor.
String jewelryCardTitle(Jewelry j) {
  for (final sep in const [' — ', ' | ']) {
    final parts = j.name.split(sep);
    if (parts.length > 1) return parts.first.trim();
  }
  return j.name;
}

/// "14K · Yellow Gold".
String _metal(Jewelry j) => _join([j.metalPurity, j.metalColor]);

/// "Lab-Grown · Diamond · Pear · 1.43ct".
String _stones(Jewelry j) => _join([
  j.stoneType,
  j.stoneCategory,
  j.stoneShape,
  if (j.stoneWeightCt > 0) _weight(j.stoneWeightCt, 'ct'),
]);

/// "Wedding Bands · Pureyou".
String _category(Jewelry j) =>
    _join([j.subCategory ?? j.category, j.shopName ?? '']);

Widget _thumb(BuildContext context, Jewelry j) {
  final p = LuxePalette.of(context);
  final fallback = ColoredBox(
    color: p.surfaceRaised,
    child: Center(
      child: Icon(Icons.diamond_outlined, size: 42, color: p.accent),
    ),
  );
  return CatalogCardImagePager(
    imageUrls: j.imageUrls.isNotEmpty ? j.imageUrls : [?j.displayImageUrl],
    fallback: fallback,
    memCacheWidth: 480,
  );
}

Widget _price(BuildContext context, Jewelry j) => LuxePriceRow(
  price: j.price,
  currencySymbol: j.isMarketplace ? AppCurrency.inrSymbol : null,
  prefix: j.hasPriceRange ? context.tr(JewelryMarketL10n.from) : null,
);

/// "★ 4.7 (12)" from the listing record; null without reviews.
Widget? _stars(Jewelry j) => j.rating == null || (j.reviewCount ?? 0) <= 0
    ? null
    : JewelryRatingChip(average: j.rating, count: j.reviewCount ?? 0);

/// Stock dot (sold out / made to order / in stock).
Widget _status(Jewelry j) => AvailabilityStatusBadge(status: j.availability);

/// Paid cards: the Sponsored pill above the stock dot.
Widget _badges(Jewelry j, {required bool sponsored}) => !sponsored
    ? _status(j)
    : Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SpotlightSponsoredPill(),
          const SizedBox(height: 4),
          _status(j),
        ],
      );

CatalogSaveButton _save(Jewelry j, {bool onLight = false}) => CatalogSaveButton(
  item: WishlistItem.fromJewelry(j),
  onAdded: () => rememberProductDetail(jewelryProductDetail(j)),
  onLight: onLight,
);

CatalogCompareButton _compare(Jewelry j, {bool onLight = false}) =>
    CatalogCompareButton(
      item: CompareItem.fromJewelry(j),
      onAdded: () => rememberProductDetail(jewelryProductDetail(j)),
      onLight: onLight,
    );

/// Two-column jewelry result card: serif piece name, metal line, stones
/// and the price, with the metal options floating over the photo.
class JewelryLuxeGridCard extends ConsumerWidget {
  const JewelryLuxeGridCard({
    required this.jewelry,
    required this.onTap,
    super.key,
    this.sponsored = false,
  });

  final Jewelry jewelry;
  final VoidCallback onTap;

  /// Paid placement: Sponsored pill on the photo and a blue outline.
  final bool sponsored;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final j = jewelry;
    return LuxeProductGridCard(
      onTap: onTap,
      highlighted: ref.watch(isRecentlyViewedProvider(j.id)),
      outlineColor: sponsored ? SpotlightColors.blueLight : null,
      media: _thumb(context, j),
      title: jewelryCardTitle(j),
      subtitle: _metal(j).isEmpty ? _category(j) : _metal(j),
      meta: _stones(j).isEmpty ? _category(j) : _stones(j),
      metaLeading: _stars(j),
      price: _price(context, j),
      overlays: LuxeMediaOverlays(
        topLeft: _badges(j, sponsored: sponsored),
        topRight: _save(j),
        bottomLeft: j.colorVariants.isEmpty
            ? null
            : LuxeMetalSwatchStack(labels: j.colorVariants, onImage: true),
        bottomRight: _compare(j),
      ),
    );
  }
}

/// Full-width jewelry result row.
class JewelryLuxeListCard extends ConsumerWidget {
  const JewelryLuxeListCard({
    required this.jewelry,
    required this.onTap,
    super.key,
    this.sponsored = false,
  });

  final Jewelry jewelry;
  final VoidCallback onTap;

  /// Paid placement: Sponsored pill on the photo and a blue outline.
  final bool sponsored;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final j = jewelry;
    return LuxeProductListCard(
      onTap: onTap,
      highlighted: ref.watch(isRecentlyViewedProvider(j.id)),
      outlineColor: sponsored ? SpotlightColors.blueLight : null,
      detailLeading: sponsored ? const SpotlightTag(pill: true) : _stars(j),
      media: _thumb(context, j),
      title: jewelryCardTitle(j),
      subtitle: _join([
        _metal(j),
        if (j.metalWeightG > 0) _weight(j.metalWeightG, 'g'),
      ]),
      detail: _join([_stones(j), _category(j)]),
      price: _price(context, j),
      titleAction: _save(j, onLight: true),
      priceAction: _compare(j, onLight: true),
      thumbTopLeft: _status(j),
      thumbBottomLeft: j.colorVariants.isEmpty
          ? null
          : LuxeMetalSwatchStack(
              labels: j.colorVariants,
              size: 12,
              onImage: true,
            ),
    );
  }
}
