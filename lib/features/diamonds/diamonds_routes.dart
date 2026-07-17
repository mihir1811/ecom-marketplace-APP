import 'package:go_router/go_router.dart';
import '../../core/router/route_names.dart';
import 'presentation/screens/diamond_search_screen.dart';
import 'presentation/screens/diamond_listings_screen.dart';

final List<RouteBase> diamondsRoutes = [
  GoRoute(
    path: AppRouteNames.diamonds,
    builder: (context, state) => const DiamondSearchScreen(),
  ),
  GoRoute(
    path: AppRouteNames.diamondResults,
    builder: (context, state) => const DiamondListingsScreen(),
  ),
];
