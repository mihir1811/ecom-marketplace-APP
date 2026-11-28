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
import '../../../diamonds/presentation/widgets/diamond_svg_data.dart';
import '../../../product_detail/domain/adapters/rough_product_detail.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../../recently_viewed/application/recently_viewed_providers.dart';
import '../../../recently_viewed/presentation/widgets/recently_viewed_badge.dart';
import '../../domain/models/rough_parcel.dart';

/// "11.49 ct · 1 pc".
String _weightLine(RoughParcel r) =>
    '${roughCarat(r.totalCaratWeight)} · ${roughPieces(r.totalPcs)}';

/// Natural / lab · shape · quality, available values only.
String _grades(RoughParcel r) => [
  r.isLab ? 'Lab-grown' : 'Natural',
  ?_optional(r.isLab ? r.growthType : r.crystalShape),
  ?_optional(r.roughQuality),
].join(' · ');

String? _optional(String? v) {
  final t = v?.trim() ?? '';
  return t.isEmpty ? null : t;
}

String? _perCarat(RoughParcel r) =>
    r.pricePerCarat > 0 ? roughPerCarat(r.pricePerCarat) : null;

/// Rough crystal glyph on the card surface when a parcel has no photo.
class RoughCrystalPlaceholder extends StatelessWidget {
  const RoughCrystalPlaceholder({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return ColoredBox(
      color: p.surfaceRaised,
      child: Center(
        child: renderShapeSvg(roughShapeKey, size: size, color: p.accent),
      ),
    );
  }
}

Widget _thumb(RoughParcel r, {double glyph = 56}) => CatalogCardImagePager(
  imageUrls: r.images,
  fallback: RoughCrystalPlaceholder(size: glyph),
  memCacheWidth: 420,
);

Widget _price(RoughParcel r) => LuxePriceRow(price: r.totalPrice);

/// Hold / Memo tag; the status dot already covers sold and unavailable.
Widget? _tag(BuildContext context, RoughParcel r) {
  final tag = r.availabilityTag;
  if (tag == null) return null;
  final p = LuxePalette.of(context);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: ShapeDecoration(
      color: p.caution.withValues(alpha: 0.14),
      shape: const StadiumBorder(),
    ),
    child: Text(tag, style: LuxeType.label(p.caution, size: 11)),
  );
}

WishlistItem roughWishlistItem(RoughParcel r) => WishlistItem(
  id: r.id,
  category: WishlistCategory.roughDiamond,
  productType: FavoriteProductType.roughDiamond,
  title: r.displayName,
  subtitle: _weightLine(r),
  priceLabel: AppCurrency.format(formatGroupedWhole(r.totalPrice)),
  imageUrl: r.images.isEmpty ? null : r.images.first,
);

CatalogSaveButton _save(RoughParcel r, {bool onLight = false}) =>
    CatalogSaveButton(
      item: roughWishlistItem(r),
      onAdded: () => rememberProductDetail(roughProductDetail(r)),
      onLight: onLight,
    );

CatalogCompareButton _compare(RoughParcel r, {bool onLight = false}) =>
    CatalogCompareButton(
      item: CompareItem.fromRough(r),
      onAdded: () => rememberProductDetail(roughProductDetail(r)),
      onLight: onLight,
    );

/// Two-column rough parcel card on the shared [LuxeProductGridCard].
class RoughLuxeGridCard extends ConsumerWidget {
  const RoughLuxeGridCard({
    required this.parcel,
    required this.onTap,
    super.key,
  });

  final RoughParcel parcel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = parcel;
    final tag = _tag(context, r);
    return LuxeProductGridCard(
      onTap: onTap,
      highlighted: ref.watch(isRecentlyViewedProvider(r.id)),
      media: _thumb(r),
      title: r.displayName,
      subtitle: _weightLine(r),
      meta: [_grades(r), ?_perCarat(r)].join(' · '),
      price: _price(r),
      overlays: LuxeMediaOverlays(
        topLeft: AvailabilityStatusBadge(status: r.statusCode),
        topRight: _save(r),
        bottomLeft: tag,
        bottomRight: _compare(r),
      ),
    );
  }
}

/// Full-width rough parcel row on the shared [LuxeProductListCard].
class RoughLuxeListCard extends ConsumerWidget {
  const RoughLuxeListCard({
    required this.parcel,
    required this.onTap,
    super.key,
  });

  final RoughParcel parcel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = parcel;
    return LuxeProductListCard(
      onTap: onTap,
      highlighted: ref.watch(isRecentlyViewedProvider(r.id)),
      media: _thumb(r, glyph: 46),
      title: r.displayName,
      subtitle: _weightLine(r),
      detail: [_grades(r), ?_perCarat(r)].join(' · '),
      price: _price(r),
      titleAction: _save(r, onLight: true),
      priceAction: _compare(r, onLight: true),
      thumbTopLeft: AvailabilityStatusBadge(status: r.statusCode),
      thumbBottomLeft: _tag(context, r),
    );
  }
}
