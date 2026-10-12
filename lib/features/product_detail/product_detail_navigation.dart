import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import '../bullions/domain/models/billion.dart';
import '../diamonds/domain/models/diamond.dart';
import '../gemstones/domain/models/gemstone.dart';
import '../jewelry/domain/models/jewelry.dart';
import '../watches/domain/models/watch.dart';
import 'domain/adapters/bullion_product_detail.dart';
import 'domain/adapters/diamond_product_detail.dart';
import 'domain/adapters/gemstone_product_detail.dart';
import 'domain/adapters/jewelry_product_detail.dart';
import 'domain/adapters/watch_product_detail.dart';
import 'domain/models/product_detail.dart';
import 'presentation/transition/product_sheet_launch.dart';

final Map<String, ProductDetail> _productDetailCache = {};

String _productDetailCacheKey(String segment, String productId) =>
    '$segment::$productId';

void rememberProductDetail(ProductDetail detail) {
  _productDetailCache[_productDetailCacheKey(detail.segment.slug, detail.id)] =
      detail;
}

ProductDetail? restoreProductDetail(String segment, String productId) {
  return _productDetailCache[_productDetailCacheKey(segment, productId)];
}

/// Finds a previously viewed/wishlisted product by id across all segments.
ProductDetail? findRememberedProductDetail(String productId) {
  if (productId.isEmpty) return null;
  for (final detail in _productDetailCache.values) {
    if (detail.id == productId) return detail;
  }
  return null;
}

/// Opens a remembered product detail. Returns `false` when nothing is cached.
bool openRememberedProductDetail(BuildContext context, String productId) {
  final detail = findRememberedProductDetail(productId);
  if (detail == null) return false;
  openProductDetail(context, detail);
  return true;
}

/// Single entry point to the shared product detail page. The resolved view
/// model travels as route `extra` because the catalog is generated per session.
///
/// The page opens as a sheet that grows out of the card that was just tapped.
/// [switchSet] lets it offer the other products of the same list.
void openProductDetail(
  BuildContext context,
  ProductDetail detail, {
  ProductSwitchSet? switchSet,
}) {
  rememberProductDetail(detail);
  ProductTapTracker.attach();
  ProductSheetLaunch.stage(
    ProductSheetLaunch(
      origin: ProductTapTracker.capture(),
      switchSet: switchSet,
    ),
  );
  context.push(
    AppRouteNames.productDetailPath(detail.segment.slug, detail.id),
    extra: detail,
  );
}

/// Typed openers. Pass the list the row came from as [among] to let the
/// detail sheet switch between its products.
void openDiamondDetail(
  BuildContext context,
  Diamond diamond, {
  List<Diamond>? among,
}) {
  final detail = diamondProductDetail(diamond);
  openProductDetail(
    context,
    detail,
    switchSet: ProductSwitchSet.of(
      among,
      diamond,
      diamondProductDetail,
      detail,
    ),
  );
}

void openGemstoneDetail(
  BuildContext context,
  Gemstone gemstone, {
  List<Gemstone>? among,
}) {
  final detail = gemstoneProductDetail(gemstone);
  openProductDetail(
    context,
    detail,
    switchSet: ProductSwitchSet.of(
      among,
      gemstone,
      gemstoneProductDetail,
      detail,
    ),
  );
}

void openJewelryDetail(
  BuildContext context,
  Jewelry jewelry, {
  List<Jewelry>? among,
}) {
  final detail = jewelryProductDetail(jewelry);
  openProductDetail(
    context,
    detail,
    switchSet: ProductSwitchSet.of(
      among,
      jewelry,
      jewelryProductDetail,
      detail,
    ),
  );
}

void openWatchDetail(BuildContext context, Watch watch, {List<Watch>? among}) {
  final detail = watchProductDetail(watch);
  openProductDetail(
    context,
    detail,
    switchSet: ProductSwitchSet.of(among, watch, watchProductDetail, detail),
  );
}

void openBullionDetail(
  BuildContext context,
  Bullion bullion, {
  List<Bullion>? among,
}) {
  final detail = bullionProductDetail(bullion);
  openProductDetail(
    context,
    detail,
    switchSet: ProductSwitchSet.of(
      among,
      bullion,
      bullionProductDetail,
      detail,
    ),
  );
}
