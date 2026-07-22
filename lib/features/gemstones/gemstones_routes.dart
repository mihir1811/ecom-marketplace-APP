import 'package:go_router/go_router.dart';
import '../../core/router/route_names.dart';
import 'presentation/screens/gemstone_listings_screen.dart';
import 'presentation/screens/gemstone_search_screen.dart';

final List<RouteBase> gemstonesRoutes = [
  GoRoute(
    path: AppRouteNames.gemstones,
    builder: (context, state) => const GemstoneSearchScreen(),
  ),
  GoRoute(
    path: AppRouteNames.gemstoneResults,
    builder: (context, state) => const GemstoneListingsScreen(),
  ),
];
