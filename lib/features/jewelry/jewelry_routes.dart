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
    caseSensitive: false,
    path: AppRouteNames.jewelry,
    builder: (context, state) => const JewelryCategoriesScreen(),
  ),
  GoRoute(
    caseSensitive: false,
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
    caseSensitive: false,
    path: AppRouteNames.jewelryFilters,
    builder: (context, state) => JewelryFilterScreen(
      scope: state.extra is JewelryFilterScope
          ? state.extra! as JewelryFilterScope
          : null,
    ),
  ),
  GoRoute(
    caseSensitive: false,
    path: AppRouteNames.jewelryPremium,
    builder: (context, state) => const JewelryPremiumScreen(),
  ),
  GoRoute(
    caseSensitive: false,
    path: AppRouteNames.jewelryHouses,
    builder: (context, state) => const JewelryHousesScreen(),
  ),
  GoRoute(
    caseSensitive: false,
    path: AppRouteNames.jewelryHouseCollection,
    builder: (context, state) => JewelryHouseCollectionScreen(
      shop: state.pathParameters['slug'] ?? '',
      category: state.pathParameters['category'] ?? '',
    ),
  ),
  GoRoute(
    caseSensitive: false,
    path: AppRouteNames.jewelryHouse,
    builder: (context, state) => JewelryHouseScreen(
      slug: state.pathParameters['slug'] ?? '',
      preview: state.extra is MarketplaceShop
          ? state.extra! as MarketplaceShop
          : null,
    ),
  ),
];
