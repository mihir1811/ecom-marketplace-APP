import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/router/app_navigation.dart';
import '../../core/router/route_names.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../core/widgets/catalog_empty_state.dart';
import 'domain/models/product_detail.dart';
import 'product_detail_navigation.dart';
import 'presentation/screens/luxe_product_detail_screen.dart';
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
        if (LuxeProductDetailScreen.supports(detail)) {
          return LuxeProductDetailScreen(detail: detail);
        }
        return ProductDetailScreen(detail: detail);
      }
      return _ProductDetailUnavailable(productId: productId);
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
      appBar: SimpleAppTopBar(title: context.tr(CatalogL10n.product)),
      body: CatalogEmptyState(
        icon: Icons.search_off_outlined,
        title: context.tr(CatalogL10n.productUnavailable),
        message: productId.isEmpty
            ? context.tr(CatalogL10n.openFromCatalog)
            : context.tr(CatalogL10n.reopenFromCatalog, {
                'productId': productId,
              }),
        actionLabel: context.tr(CatalogL10n.browseCatalog),
        onAction: () => context.resetTo(AppRouteNames.home),
      ),
    );
  }
}
