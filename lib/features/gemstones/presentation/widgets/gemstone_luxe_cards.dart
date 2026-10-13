import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../../core/widgets/catalog_card_image_pager.dart';
import '../../../../core/widgets/luxe/luxe_product_card.dart';
import '../../../buyer/domain/models/wishlist_item.dart';
import '../../../catalog_flow/presentation/widgets/catalog_card_actions.dart';
import '../../../comparison/domain/models/compare_item.dart';
import '../../../product_detail/domain/adapters/gemstone_product_detail.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../../recently_viewed/application/recently_viewed_providers.dart';
import '../../../recently_viewed/presentation/widgets/recently_viewed_badge.dart';
import '../../domain/gemstone_assets.dart';
import '../../domain/models/gemstone.dart';
import 'gemstone_finder_filters.dart' show GemstoneHueOrb;

String? _optional(String? value) {
  final t = value?.trim() ?? '';
  if (t.isEmpty || t == '-' || t == '—' || t == '–') return null;
  if (t.toLowerCase() == 'n/a') return null;
  return t;
}

/// "1.20 ct Ruby" — the gem is what buyers scan for first.
String _title(Gemstone g) {
  final carat = '${g.carat.toStringAsFixed(2)} ct';
  final type = _optional(g.type) ?? _optional(g.shape);
  return type == null ? carat : '$carat $type';
}

/// Shape · colour · clarity, available values only.
String _grades(Gemstone g) {
  final parts = [
    ?_optional(g.shape),
    ?_optional(g.color),
    ?_optional(g.clarity),
  ];
  return parts.isEmpty ? '—' : parts.join(' · ');
}

String? _perCarat(Gemstone g) {
  final ppc = g.pricePerCarat;
  if (ppc == null || ppc <= 0) return null;
  return '${AppCurrency.format(formatGroupedWhole(ppc.roundToDouble()))}/ct';
}

/// Origin · treatment · $/ct for the grid's quiet line.
String? _gridMeta(Gemstone g) {
  final parts = [?_optional(g.origin), ?_optional(g.treatment), ?_perCarat(g)];
  return parts.isEmpty ? null : parts.join(' · ');
}

/// Origin · treatment · lab · dimensions for list rows.
String _listDetail(Gemstone g) {
  final dims = _optional(
    g.dimensions,
  )?.replaceAll(RegExp(r'\s*[xX*]\s*'), ' × ');
  return [
    ?_optional(g.origin),
    ?_optional(g.treatment),
    ?_optional(g.lab)?.toUpperCase(),
    ?dims,
  ].join(' · ');
}

Widget _thumb(BuildContext context, Gemstone g, {double orb = 56}) {
  final p = LuxePalette.of(context);
  final fallback = ColoredBox(
    color: p.surfaceRaised,
    child: Center(
      child: GemstoneHueOrb(hue: gemstoneHue(g.type), size: orb),
    ),
  );
  return CatalogCardImagePager(
    imageUrls: catalogListingImageUrls(
      imageUrl: g.imageUrl,
      imageUrls: g.imageUrls,
    ),
    fallback: fallback,
    memCacheWidth: 420,
  );
}

Widget _price(Gemstone g, {bool showList = false}) {
  final markdown = catalogMarkdownPercent(g.discount);
  return LuxePriceRow(
    price: g.price,
    listPrice: markdown == null ? null : catalogListFromNet(g.price, markdown),
    discountPercent: markdown,
    showList: showList,
  );
}

String? _status(Gemstone g) => g.isSold ? 'sold' : g.availability;

CatalogSaveButton _save(Gemstone g, {bool onLight = false}) =>
    CatalogSaveButton(
      item: WishlistItem.fromGemstone(g),
      onAdded: () => rememberProductDetail(gemstoneProductDetail(g)),
      onLight: onLight,
    );

CatalogCompareButton _compare(Gemstone g, {bool onLight = false}) =>
    CatalogCompareButton(
      item: CompareItem.fromGemstone(g),
      onAdded: () => rememberProductDetail(gemstoneProductDetail(g)),
      onLight: onLight,
    );

/// Two-column gemstone result card on the shared [LuxeProductGridCard].
class GemstoneLuxeGridCard extends ConsumerWidget {
  const GemstoneLuxeGridCard({
    required this.gemstone,
    required this.onTap,
    super.key,
  });

  final Gemstone gemstone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = gemstone;
    return LuxeProductGridCard(
      onTap: onTap,
      highlighted: ref.watch(isRecentlyViewedProvider(g.id)),
      media: _thumb(context, g),
      title: _title(g),
      subtitle: _grades(g),
      meta: _gridMeta(g),
      price: _price(g),
      overlays: LuxeMediaOverlays(
        topLeft: AvailabilityStatusBadge(status: _status(g)),
        topRight: _save(g),
        bottomRight: _compare(g),
      ),
    );
  }
}

/// Full-width gemstone result row on the shared [LuxeProductListCard].
class GemstoneLuxeListCard extends ConsumerWidget {
  const GemstoneLuxeListCard({
    required this.gemstone,
    required this.onTap,
    super.key,
  });

  final Gemstone gemstone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = gemstone;
    return LuxeProductListCard(
      onTap: onTap,
      highlighted: ref.watch(isRecentlyViewedProvider(g.id)),
      media: _thumb(context, g, orb: 46),
      title: _title(g),
      subtitle: _grades(g),
      detail: _listDetail(g),
      price: _price(g, showList: true),
      titleAction: _save(g, onLight: true),
      priceAction: _compare(g, onLight: true),
      thumbTopLeft: AvailabilityStatusBadge(status: _status(g)),
    );
  }
}
