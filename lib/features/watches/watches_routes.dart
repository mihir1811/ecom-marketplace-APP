import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import 'presentation/screens/brand_watch_screen.dart';
import 'presentation/screens/watches_screen.dart';

final List<RouteBase> watchesRoutes = [
  GoRoute(
    path: AppRouteNames.watches,
    builder: (context, state) => const WatchesScreen(),
  ),
  GoRoute(
    path: AppRouteNames.brandWatch,
    builder: (context, state) {
      final brandName = state.pathParameters['brandName']!;
      return BrandWatchScreen(brandName: brandName);
    },
  ),
];
