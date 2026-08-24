import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../core/widgets/catalog_empty_state.dart';
import 'domain/models/product_detail.dart';
import 'product_detail_navigation.dart';
import 'presentation/screens/product_detail_screen.dart';

final List<RouteBase> productDetailRoutes = [
  GoRoute(
    path: AppRouteNames.productDetail,
    builder: (context, state) {
      final extra = state.extra;
      final segment = state.pathParameters['segment'] ?? '';
      final productId = state.pathParameters['productId'] ?? '';
      final detail = switch (extra) {
        final ProductDetail product => product,
        _ => restoreProductDetail(segment, productId),
      };
      if (detail is ProductDetail) {
        rememberProductDetail(detail);
        return ProductDetailScreen(detail: detail);
      }
      return _ProductDetailUnavailable(
        productId: productId,
      );
    },
  ),
];

/// Shown when the page is reached without a resolved product, e.g. a cold
/// deep link. The catalog is generated per session, so the buyer is sent back
/// to search rather than seeing a stale record.
class _ProductDetailUnavailable extends StatelessWidget {
  const _ProductDetailUnavailable({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const SimpleAppTopBar(
        title: 'Product',
      ),
      body: CatalogEmptyState(
        icon: Icons.search_off_outlined,
        title: 'This product is no longer loaded',
        message: productId.isEmpty
            ? 'Open the product from a catalog listing to see its details.'
            : 'Reopen $productId from a catalog listing to see its details.',
        actionLabel: 'Browse catalog',
        onAction: () => context.go(AppRouteNames.home),
      ),
    );
  }
}
