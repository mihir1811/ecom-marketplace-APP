import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'application/catalog_product_detail_loader.dart';
import 'product_detail_navigation.dart';

/// Opens the product detail page for a catalog piece known only by its
/// cart / API `productType` and id (chat threads, offers, …).
///
/// Uses the detail cached this session when there is one, otherwise loads
/// it. Resolves to false when the piece could not be loaded (callers show
/// their own message).
Future<bool> openCatalogProductDetail(
  BuildContext context,
  WidgetRef ref, {
  required String productType,
  required String productId,
}) async {
  final id = productId.trim();
  if (id.isEmpty) return false;
  if (openRememberedProductDetail(context, id)) return true;
  final detail = await CatalogProductDetailLoader.load(
    ref.read,
    productType: productType,
    productId: id,
  );
  if (detail == null || !context.mounted) return false;
  openProductDetail(context, detail);
  return true;
}
