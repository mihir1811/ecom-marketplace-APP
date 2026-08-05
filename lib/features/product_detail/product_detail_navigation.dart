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
void openProductDetail(BuildContext context, ProductDetail detail) {
  rememberProductDetail(detail);
  context.push(
    AppRouteNames.productDetailPath(detail.segment.slug, detail.id),
    extra: detail,
  );
}

void openDiamondDetail(BuildContext context, Diamond diamond) =>
    openProductDetail(context, diamondProductDetail(diamond));

void openGemstoneDetail(BuildContext context, Gemstone gemstone) =>
    openProductDetail(context, gemstoneProductDetail(gemstone));

void openJewelryDetail(BuildContext context, Jewelry jewelry) =>
    openProductDetail(context, jewelryProductDetail(jewelry));

void openWatchDetail(BuildContext context, Watch watch) =>
    openProductDetail(context, watchProductDetail(watch));

void openBullionDetail(BuildContext context, Bullion bullion) =>
    openProductDetail(context, bullionProductDetail(bullion));
