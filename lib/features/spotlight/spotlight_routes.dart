import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import '../product_detail/domain/models/product_detail.dart';
import 'domain/spotlight_models.dart';
import 'presentation/screens/spotlight_shop_screen.dart';
import 'presentation/screens/spotlight_shop_section_screen.dart';

/// Public spotlight routes. The seller's Advertising studio lives in the
/// seller shell (see `seller_routes.dart`).
final List<RouteBase> spotlightRoutes = [
  GoRoute(
    caseSensitive: false,
    path: AppRouteNames.sellerShop,
    builder: (context, state) {
      final extra = state.extra;
      return SpotlightShopScreen(
        sellerId: state.pathParameters['sellerId'] ?? '',
        profile: extra is SpotlightSellerProfile ? extra : null,
      );
    },
  ),
  // Shop "View all": one section of the seller's pieces.
  GoRoute(
    caseSensitive: false,
    path: AppRouteNames.sellerShopSection,
    redirect: (context, state) {
      final slug = state.pathParameters['segment'];
      final known = ProductSegment.values.any((s) => s.slug == slug);
      return known
          ? null
          : AppRouteNames.sellerShopPath(
              state.pathParameters['sellerId'] ?? '',
            );
    },
    builder: (context, state) {
      final slug = state.pathParameters['segment'];
      final extra = state.extra;
      return SpotlightShopSectionScreen(
        sellerId: state.pathParameters['sellerId'] ?? '',
        segment: ProductSegment.values.firstWhere((s) => s.slug == slug),
        sellerName: extra is String ? extra : null,
      );
    },
  ),
];
