import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import 'presentation/screens/jewelry_categories_screen.dart';
import 'presentation/screens/jewelry_filter_screen.dart';
import 'presentation/screens/jewelry_houses_screen.dart';
import 'presentation/screens/jewelry_listing_screen.dart';

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
    builder: (context, state) => const JewelryFilterScreen(),
  ),
  GoRoute(
    path: AppRouteNames.jewelryHouses,
    builder: (context, state) => const JewelryHousesScreen(),
  ),
];
