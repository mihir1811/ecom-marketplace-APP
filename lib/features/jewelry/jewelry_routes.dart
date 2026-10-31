import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import 'presentation/screens/jewelry_categories_screen.dart';
import 'presentation/screens/jewelry_filter_screen.dart';
import 'domain/models/marketplace_listing.dart';
import 'presentation/screens/jewelry_house_collection_screen.dart';
import 'presentation/screens/jewelry_house_screen.dart';
import 'presentation/screens/jewelry_houses_screen.dart';
import 'presentation/screens/jewelry_listing_screen.dart';
import 'presentation/screens/jewelry_premium_screen.dart';

final List<RouteBase> jewelryRoutes = [
  GoRoute(
    path: AppRouteNames.jewelry,
    builder: (context, state) => const JewelryCategoriesScreen(),
  ),
  GoRoute(
    path: AppRouteNames.jewelryListing,
    builder: (context, state) {
      final params = state.uri.queryParameters;
      return JewelryListingScreen(
        initialCategory: params['category'],
        initialStyle: params['style'],
        initialMetal: params['metal'],
      );
    },
  ),
  GoRoute(
    path: AppRouteNames.jewelryFilters,
    builder: (context, state) => JewelryFilterScreen(
      scope: state.extra is JewelryFilterScope
          ? state.extra! as JewelryFilterScope
          : null,
    ),
  ),
  GoRoute(
    path: AppRouteNames.jewelryPremium,
    builder: (context, state) => const JewelryPremiumScreen(),
  ),
  GoRoute(
    path: AppRouteNames.jewelryHouses,
    builder: (context, state) => const JewelryHousesScreen(),
  ),
  GoRoute(
    path: AppRouteNames.jewelryHouseCollection,
    builder: (context, state) => JewelryHouseCollectionScreen(
      shop: state.pathParameters['slug'] ?? '',
      category: state.pathParameters['category'] ?? '',
      preview: state.extra is MarketplaceShop
          ? state.extra! as MarketplaceShop
          : null,
    ),
  ),
  GoRoute(
    path: AppRouteNames.jewelryHouse,
    builder: (context, state) => JewelryHouseScreen(
      slug: state.pathParameters['slug'] ?? '',
      preview: state.extra is MarketplaceShop
          ? state.extra! as MarketplaceShop
          : null,
    ),
  ),
];
