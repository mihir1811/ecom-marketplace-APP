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
import 'presentation/transition/product_sheet_launch.dart';
import 'presentation/transition/product_sheet_screen.dart';

final List<RouteBase> productDetailRoutes = [
  GoRoute(
    path: AppRouteNames.productDetail,
    pageBuilder: (context, state) {
      final extra = state.extra;
      final segment = state.pathParameters['segment'] ?? '';
      final productId = state.pathParameters['productId'] ?? '';
      final detail = switch (extra) {
        final ProductDetail product => product,
        _ => restoreProductDetail(segment, productId),
      };
      if (detail is! ProductDetail) {
        return MaterialPage<void>(
          key: state.pageKey,
          child: _ProductDetailUnavailable(productId: productId),
        );
      }
      rememberProductDetail(detail);
      if (!LuxeProductDetailScreen.supports(detail)) {
        return MaterialPage<void>(
          key: state.pageKey,
          child: ProductDetailScreen(detail: detail),
        );
      }
      // A pop-up that grows out of the tapped card; the sheet drives its own
      // motion from the route animation, so the transition adds nothing.
      return CustomTransitionPage<void>(
        key: state.pageKey,
        opaque: false,
        transitionDuration: const Duration(milliseconds: 680),
        reverseTransitionDuration: const Duration(milliseconds: 520),
        child: ProductSheetScreen(
          detail: detail,
          launch: ProductSheetLaunch.forPage(state.pageKey.value),
        ),
        transitionsBuilder: (context, animation, secondary, child) => child,
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
