import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import 'presentation/screens/brand_watch_screen.dart';
import 'presentation/screens/watches_screen.dart';
import 'presentation/widgets/watch_filter_drawer.dart';

final List<RouteBase> watchesRoutes = [
  GoRoute(
    caseSensitive: false,
    path: AppRouteNames.watches,
    builder: (context, state) => const WatchesScreen(),
  ),
  GoRoute(
    caseSensitive: false,
    path: AppRouteNames.watchesFilters,
    builder: (context, state) => const WatchFilterDrawer(),
  ),
  GoRoute(
    caseSensitive: false,
    path: AppRouteNames.brandWatchFilters,
    builder: (context, state) {
      final brandName = state.pathParameters['brandName']!;
      return WatchFilterDrawer(lockedBrand: Uri.decodeComponent(brandName));
    },
  ),
  GoRoute(
    caseSensitive: false,
    path: AppRouteNames.brandWatch,
    builder: (context, state) {
      final brandName = state.pathParameters['brandName']!;
      return BrandWatchScreen(brandName: Uri.decodeComponent(brandName));
    },
  ),
];
