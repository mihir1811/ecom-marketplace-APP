import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/catalog_card_image_pager.dart';
import '../../../../core/widgets/luxe/luxe_metal_swatch.dart';
import '../../../../core/widgets/luxe/luxe_product_card.dart';
import '../../../buyer/domain/models/wishlist_item.dart';
import '../../../catalog_flow/presentation/widgets/catalog_card_actions.dart';
import '../../../comparison/domain/models/compare_item.dart';
import '../../../product_detail/domain/adapters/jewelry_product_detail.dart';
import '../../../product_detail/domain/models/jewelry_unit_pricing.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../../recently_viewed/application/recently_viewed_providers.dart';
import '../../../recently_viewed/presentation/widgets/recently_viewed_badge.dart';
import '../../domain/models/jewelry.dart';

String _join(Iterable<String> parts) =>
    parts.where((p) => p.trim().isNotEmpty).join(' · ');

String _weight(double v, String unit) =>
    '${v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2)}$unit';

/// Card title: the product name before any " — " descriptor.
String jewelryCardTitle(Jewelry j) {
  final dash = j.name.split(' — ');
  return dash.length > 1 ? dash.first.trim() : j.name;
}

/// "18K · Yellow Gold".
String _metal(Jewelry j) => _join([j.metalPurity, j.metalColor]);

/// "Diamond · Round · 0.50ct · 12 pcs".
String _stones(Jewelry j) => _join([
  j.stoneType,
  j.stoneShape,
  if (j.stoneWeightCt > 0) _weight(j.stoneWeightCt, 'ct'),
  if (j.stoneCount > 1) '${j.stoneCount} pcs',
]);

/// "Rings · Solitaire · ★ 4.8 (120)".
String _category(Jewelry j) => _join([
  j.category,
  if (j.subCategory != null) j.subCategory!,
  if (j.rating != null)
    '★ ${j.rating}${j.reviewCount == null ? '' : ' (${j.reviewCount})'}',
]);

Widget _thumb(BuildContext context, Jewelry j) {
  final p = LuxePalette.of(context);
  final url = j.displayImageUrl;
  final fallback = ColoredBox(
    color: p.surfaceRaised,
    child: Center(
      child: Icon(Icons.diamond_outlined, size: 42, color: p.accent),
    ),
  );
  return CatalogCardImagePager(
    imageUrls: url == null ? const [] : [url],
    fallback: fallback,
    memCacheWidth: 480,
  );
}

Widget _price(Jewelry j, {bool showList = false}) {
  final pricing = JewelryUnitPricing.from(
    metalPrice: j.metalPrice,
    stonePrice: j.stonePrice,
    makingCharge: j.makingCharge,
    discountAmount: j.discountAmount,
    totalPrice: j.price,
  );
  return LuxePriceRow(
    price: pricing.netPrice,
    listPrice: pricing.hasDiscount ? pricing.listPrice : null,
    discountPercent: pricing.hasDiscount ? pricing.discountPercent : null,
    showList: showList,
  );
}

/// Availability dot plus the listing badge (e.g. "Auction").
Widget _status(BuildContext context, Jewelry j) {
  final p = LuxePalette.of(context);
  final badge = j.badge?.trim();
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      AvailabilityStatusBadge(status: j.availability),
      if (badge != null && badge.isNotEmpty) ...[
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: ShapeDecoration(
            color: p.ink.withValues(alpha: 0.82),
            shape: const StadiumBorder(),
          ),
          child: Text(
            badge.toUpperCase(),
            style: LuxeType.eyebrow(p.canvas).copyWith(fontSize: 9),
          ),
        ),
      ],
    ],
  );
}

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
  });

  final Jewelry jewelry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final j = jewelry;
    return LuxeProductGridCard(
      onTap: onTap,
      highlighted: ref.watch(isRecentlyViewedProvider(j.id)),
      media: _thumb(context, j),
      title: jewelryCardTitle(j),
      subtitle: _metal(j).isEmpty ? j.category : _metal(j),
      meta: _stones(j).isEmpty ? _category(j) : _stones(j),
      price: _price(j),
      overlays: LuxeMediaOverlays(
        topLeft: _status(context, j),
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
  });

  final Jewelry jewelry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final j = jewelry;
    return LuxeProductListCard(
      onTap: onTap,
      highlighted: ref.watch(isRecentlyViewedProvider(j.id)),
      media: _thumb(context, j),
      title: jewelryCardTitle(j),
      subtitle: _join([
        _metal(j),
        if (j.metalWeightG > 0) _weight(j.metalWeightG, 'g'),
      ]),
      detail: _join([_stones(j), _category(j)]),
      price: _price(j, showList: true),
      titleAction: _save(j, onLight: true),
      priceAction: _compare(j, onLight: true),
      thumbTopLeft: _status(context, j),
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
