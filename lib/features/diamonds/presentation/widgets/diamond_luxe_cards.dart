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
import '../../../spotlight/presentation/widgets/spotlight_tag.dart';
import '../../application/diamond_search_provider.dart';
import '../../domain/melee_lot_figures.dart';
import '../../domain/models/diamond.dart';
import '../../domain/models/diamond_display.dart';
import 'diamond_cards.dart' show diamondGradesLine;
import 'diamond_svg_data.dart';

/// Melee lots follow the finder's Pieces / Carat toggle; single stones
/// always read in carats. Null for single stones.
MeleeLotFigures? _melee(Diamond d) => d.isMelee ? MeleeLotFigures.of(d) : null;

bool _meleeInPcs(WidgetRef ref, MeleeLotFigures? m) =>
    m != null &&
    (m.totalPcs ?? 0) > 0 &&
    ref.watch(diamondSearchProvider.select((s) => s.meleeInPcs));

/// Melee values worked out from the sieve chart, not sent by the seller.
bool _approx(MeleeLotFigures? m, {required bool inPcs}) =>
    m != null && (inPcs ? m.pcsApprox : m.caratApprox);

/// "$8,191/ct" or, for melee in pieces mode, "$37.50/pc"; "≈" when the
/// value comes from the sieve chart.
String? _unitPrice(Diamond d, MeleeLotFigures? m, {required bool inPcs}) {
  final mark = _approx(m, inPcs: inPcs) ? '≈' : '';
  if (inPcs) {
    final ppp = m?.pricePerPcs;
    if (ppp == null || ppp <= 0) return null;
    return '$mark${AppCurrency.format(formatGroupedWhole(ppp))}/pc';
  }
  final ppc =
      m?.pricePerCarat ??
      d.pricePerCarat ??
      (d.carat > 0 && d.price > 0 ? d.price / d.carat : null);
  if (ppc == null || ppc <= 0) return null;
  return '$mark${AppCurrency.format(formatGroupedWhole(ppc.roundToDouble()))}/ct';
}

String? _measure(Diamond d) => DiamondDisplay.optional(
  d.measurement,
)?.replaceAll(RegExp(r'\s*[xX]\s*'), ' × ');

/// "$8,191/ct · 7.21 × 5.10 × 3.18" — rounded, grouped, typographic ×.
/// Estimated melee figures end with "approx.".
String? _metaLine(Diamond d, MeleeLotFigures? m, {required bool inPcs}) {
  final parts = [
    ?_unitPrice(d, m, inPcs: inPcs),
    ?_measure(d),
    if (_approx(m, inPcs: inPcs)) 'approx.',
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

/// "1.20 ct Round", or "120 pcs Round" for melee in pieces mode.
String _title(Diamond d, MeleeLotFigures? m, {required bool inPcs}) {
  final shape = DiamondDisplay.shape(d.shape);
  final mark = _approx(m, inPcs: inPcs) ? '≈' : '';
  final String size;
  if (inPcs) {
    final pcs = m!.totalPcs!;
    size =
        '$mark${formatGroupedWhole(pcs.toDouble())} ${pcs == 1 ? 'pc' : 'pcs'}';
  } else {
    final carat = m?.totalCarat ?? d.carat;
    size = '$mark${carat.toStringAsFixed(2)} ct';
  }
  return shape == DiamondDisplay.missing ? size : '$size $shape';
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
/// Status sits top-left, the one select control top-right (for sellers it
/// picks for compare and project at once) and save bottom-right.
class DiamondLuxeGridCard extends ConsumerWidget {
  const DiamondLuxeGridCard({
    required this.diamond,
    required this.onTap,
    super.key,
    this.sponsored = false,
  });

  final Diamond diamond;
  final VoidCallback onTap;

  /// Paid placement: blue Sponsored pill beside the stock number and a
  /// blue outline.
  final bool sponsored;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = diamond;
    final stock = d.stockNumber?.trim();
    final m = _melee(d);
    final inPcs = _meleeInPcs(ref, m);
    return LuxeProductGridCard(
      onTap: onTap,
      highlighted: ref.watch(isRecentlyViewedProvider(d.id)),
      outlineColor: sponsored ? SpotlightColors.blue(context) : null,
      media: _thumb(context, d),
      title: _title(d, m, inPcs: inPcs),
      subtitle: diamondGradesLine(d) ?? DiamondDisplay.missing,
      metaLeading: sponsored ? const SpotlightTag(pill: true) : null,
      meta: sponsored && stock != null && stock.isNotEmpty
          ? '#$stock'
          : _metaLine(d, m, inPcs: inPcs),
      price: _price(d),
      overlays: LuxeMediaOverlays(
        topLeft: AvailabilityStatusBadge(status: d.available),
        topRight: DiamondSelectionToggle(diamond: d),
        bottomRight: _save(d),
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
    this.sponsored = false,
  });

  final Diamond diamond;
  final VoidCallback onTap;

  /// Paid placement: blue Sponsored pill beside the stock number and a
  /// blue outline.
  final bool sponsored;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = diamond;
    final lab = DiamondDisplay.labBadge(d.lab ?? d.certificate);
    final stock = d.stockNumber?.trim();
    final m = _melee(d);
    final inPcs = _meleeInPcs(ref, m);
    final detail = [
      // Sponsored cards lead with the stock number, right after the pill.
      if (sponsored && stock != null && stock.isNotEmpty) '#$stock',
      // Melee rows price per piece or per carat to match the finder mode.
      if (m != null) ?_unitPrice(d, m, inPcs: inPcs),
      ?lab,
      ?_measure(d),
      if (_approx(m, inPcs: inPcs)) 'approx.',
      if (!sponsored && stock != null && stock.isNotEmpty) '#$stock',
    ].join(' · ');

    return LuxeProductListCard(
      onTap: onTap,
      highlighted: ref.watch(isRecentlyViewedProvider(d.id)),
      outlineColor: sponsored ? SpotlightColors.blue(context) : null,
      detailLeading: sponsored ? const SpotlightTag(pill: true) : null,
      media: _thumb(context, d),
      title: _title(d, m, inPcs: inPcs),
      subtitle: diamondGradesLine(d) ?? DiamondDisplay.missing,
      detail: detail,
      price: _price(d, showList: true),
      titleAction: DiamondSelectionToggle(diamond: d, onLight: true),
      priceAction: _save(d, onLight: true),
      thumbTopLeft: AvailabilityStatusBadge(status: d.available),
    );
  }
}
