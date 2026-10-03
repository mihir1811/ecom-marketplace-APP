import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../../core/widgets/catalog_card_image_pager.dart';
import '../../../../core/widgets/luxe/luxe_product_card.dart';
import '../../../buyer/domain/models/wishlist_item.dart';
import '../../../catalog_flow/presentation/widgets/catalog_card_actions.dart';
import '../../../comparison/domain/models/compare_item.dart';
import '../../../product_detail/domain/adapters/watch_product_detail.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../../recently_viewed/application/recently_viewed_providers.dart';
import '../../../recently_viewed/presentation/widgets/recently_viewed_badge.dart';
import '../../domain/models/watch.dart';

String _join(Iterable<String> parts) =>
    parts.where((p) => p.trim().isNotEmpty).join(' · ');

/// "40mm · Steel · Black dial".
String _specs(Watch w) => _join([
  if (w.caseSizeMm > 0) '${w.caseSizeMm}mm',
  w.caseMaterial,
  if (w.dialColor.trim().isNotEmpty) '${w.dialColor} dial',
]);

/// "Submariner · 2021 · Excellent".
String _detail(Watch w) =>
    _join([w.collection, if (w.year > 0) '${w.year}', w.condition]);

Widget _thumb(BuildContext context, Watch w) {
  final p = LuxePalette.of(context);
  final url = w.renderableImageUrl;
  final fallback = ColoredBox(
    color: p.surfaceRaised,
    child: Center(child: Icon(Icons.watch_outlined, size: 46, color: p.accent)),
  );
  return CatalogCardImagePager(
    imageUrls: url == null ? const [] : [url],
    fallback: fallback,
    memCacheWidth: 480,
  );
}

Widget _price(Watch w, {bool showList = false}) {
  final markdown = catalogMarkdownPercent(w.discount);
  return LuxePriceRow(
    price: w.price,
    listPrice: markdown == null ? null : catalogListFromNet(w.price, markdown),
    discountPercent: markdown,
    showList: showList,
  );
}

CatalogSaveButton _save(Watch w, {bool onLight = false}) => CatalogSaveButton(
  item: WishlistItem.fromWatch(w),
  onAdded: () => rememberProductDetail(watchProductDetail(w)),
  onLight: onLight,
);

CatalogCompareButton _compare(Watch w, {bool onLight = false}) =>
    CatalogCompareButton(item: CompareItem.fromWatch(w), onLight: onLight);

/// Two-column watch result card: brand as the serif title, model beneath.
class WatchLuxeGridCard extends ConsumerWidget {
  const WatchLuxeGridCard({
    required this.watch,
    required this.onTap,
    super.key,
  });

  final Watch watch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = watch;
    return LuxeProductGridCard(
      onTap: onTap,
      highlighted: ref.watch(isRecentlyViewedProvider(w.id)),
      media: _thumb(context, w),
      title: w.brand,
      subtitle: w.model,
      meta: _specs(w),
      price: _price(w),
      overlays: LuxeMediaOverlays(
        topLeft: AvailabilityStatusBadge(status: w.availabilityStatus),
        topRight: _save(w),
        bottomRight: _compare(w),
      ),
    );
  }
}

/// Full-width watch result row.
class WatchLuxeListCard extends ConsumerWidget {
  const WatchLuxeListCard({
    required this.watch,
    required this.onTap,
    super.key,
  });

  final Watch watch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = watch;
    return LuxeProductListCard(
      onTap: onTap,
      highlighted: ref.watch(isRecentlyViewedProvider(w.id)),
      media: _thumb(context, w),
      title: w.brand,
      subtitle: w.model,
      detail: _join([_detail(w), _specs(w)]),
      price: _price(w, showList: true),
      titleAction: _save(w, onLight: true),
      priceAction: _compare(w, onLight: true),
      thumbTopLeft: AvailabilityStatusBadge(status: w.availabilityStatus),
    );
  }
}
