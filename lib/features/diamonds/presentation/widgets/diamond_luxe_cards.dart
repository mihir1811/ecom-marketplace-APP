import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../../core/widgets/catalog_card_image_pager.dart';
import '../../../../core/widgets/luxe/luxe_product_card.dart';
import '../../../buyer/domain/models/wishlist_item.dart';
import '../../../catalog_flow/presentation/widgets/catalog_card_actions.dart';
import '../../../diamond_projects/presentation/widgets/diamond_selection_toggle.dart';
import '../../../product_detail/domain/adapters/diamond_product_detail.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../../recently_viewed/application/recently_viewed_providers.dart';
import '../../../recently_viewed/presentation/widgets/recently_viewed_badge.dart';
import '../../domain/models/diamond.dart';
import '../../domain/models/diamond_display.dart';
import 'diamond_cards.dart' show diamondGradesLine;
import 'diamond_svg_data.dart';

/// "$8,191/ct · 7.21 × 5.10 × 3.18" — rounded, grouped, typographic ×.
String? _metaLine(Diamond d) {
  final parts = <String>[];
  final ppc = d.pricePerCarat;
  if (ppc != null && ppc > 0) {
    parts.add(
      '${AppCurrency.format(formatGroupedWhole(ppc.roundToDouble()))}/ct',
    );
  }
  final measure = DiamondDisplay.optional(d.measurement);
  if (measure != null) {
    parts.add(measure.replaceAll(RegExp(r'\s*[xX]\s*'), ' × '));
  }
  return parts.isEmpty ? null : parts.join(' · ');
}

String _title(Diamond d) {
  final shape = DiamondDisplay.shape(d.shape);
  final carat = '${d.carat.toStringAsFixed(2)} ct';
  return shape == DiamondDisplay.missing ? carat : '$carat $shape';
}

Widget _thumb(BuildContext context, Diamond d) {
  final p = LuxePalette.of(context);
  final fallback = ColoredBox(
    color: p.surfaceRaised,
    child: Center(child: renderShapeSvg(d.shape, size: 52, color: p.accent)),
  );
  return CatalogCardImagePager(
    imageUrls: catalogListingImageUrls(
      imageUrl: d.imageUrl,
      imageUrls: d.imageUrls,
    ),
    fallback: fallback,
    memCacheWidth: 420,
  );
}

Widget _price(Diamond d, {bool showList = false}) {
  final belowList = catalogMarkdownPercent(d.discount);
  final rapList = (d.rap != null && d.rap! > 0 && d.carat > 0)
      ? d.rap! * d.carat
      : null;
  final inferred = belowList == null
      ? null
      : catalogListFromNet(d.price, belowList);
  return LuxePriceRow(
    price: d.price,
    listPrice: rapList != null && rapList > d.price ? rapList : inferred,
    discountPercent: belowList,
    showList: showList,
  );
}

CatalogSaveButton _save(Diamond d, {bool onLight = false}) => CatalogSaveButton(
  item: WishlistItem.fromDiamond(d),
  onAdded: () => rememberProductDetail(diamondProductDetail(d)),
  onLight: onLight,
);

/// Two-column diamond result card on the shared [LuxeProductGridCard].
///
/// Status sits top-left, save top-right and the one select control
/// bottom-right: for sellers it picks for compare and project at once.
class DiamondLuxeGridCard extends ConsumerWidget {
  const DiamondLuxeGridCard({
    required this.diamond,
    required this.onTap,
    super.key,
  });

  final Diamond diamond;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = diamond;
    return LuxeProductGridCard(
      onTap: onTap,
      highlighted: ref.watch(isRecentlyViewedProvider(d.id)),
      media: _thumb(context, d),
      title: _title(d),
      subtitle: diamondGradesLine(d) ?? DiamondDisplay.missing,
      meta: _metaLine(d),
      price: _price(d),
      overlays: LuxeMediaOverlays(
        topLeft: AvailabilityStatusBadge(status: d.available),
        topRight: _save(d),
        bottomRight: DiamondSelectionToggle(diamond: d),
      ),
    );
  }
}

/// Full-width diamond result row on the shared [LuxeProductListCard].
class DiamondLuxeListCard extends ConsumerWidget {
  const DiamondLuxeListCard({
    required this.diamond,
    required this.onTap,
    super.key,
  });

  final Diamond diamond;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = diamond;
    final lab = DiamondDisplay.labBadge(d.lab ?? d.certificate);
    final stock = d.stockNumber?.trim();
    final measure = DiamondDisplay.optional(d.measurement);
    final detail = [
      ?lab,
      if (measure != null) measure.replaceAll(RegExp(r'\s*[xX]\s*'), ' × '),
      if (stock != null && stock.isNotEmpty) '#$stock',
    ].join(' · ');

    return LuxeProductListCard(
      onTap: onTap,
      highlighted: ref.watch(isRecentlyViewedProvider(d.id)),
      media: _thumb(context, d),
      title: _title(d),
      subtitle: diamondGradesLine(d) ?? DiamondDisplay.missing,
      detail: detail,
      price: _price(d, showList: true),
      titleAction: _save(d, onLight: true),
      priceAction: DiamondSelectionToggle(diamond: d, onLight: true),
      thumbTopLeft: AvailabilityStatusBadge(status: d.available),
    );
  }
}
