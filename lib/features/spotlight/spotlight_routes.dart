import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import 'domain/spotlight_models.dart';
import 'presentation/screens/spotlight_shop_screen.dart';

/// Public spotlight routes. The seller's Advertising studio lives in the
/// seller shell (see `seller_routes.dart`).
final List<RouteBase> spotlightRoutes = [
  GoRoute(
    path: AppRouteNames.sellerShop,
    builder: (context, state) {
      final extra = state.extra;
      return SpotlightShopScreen(
        sellerId: state.pathParameters['sellerId'] ?? '',
        profile: extra is SpotlightSellerProfile ? extra : null,
      );
    },
  ),
];
