import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import 'domain/models/rough_parcel.dart';
import 'presentation/screens/rough_diamonds_screen.dart';
import 'presentation/screens/rough_filters_screen.dart';

final List<RouteBase> roughDiamondsRoutes = [
  GoRoute(
    caseSensitive: false,
    path: AppRouteNames.roughDiamonds,
    builder: (context, state) {
      final type = state.uri.queryParameters['type'];
      return RoughDiamondsScreen(
        initialType: type == null ? null : RoughDiamondType.fromQuery(type),
      );
    },
  ),
  GoRoute(
    caseSensitive: false,
    path: AppRouteNames.roughDiamondsFilters,
    builder: (context, state) => const RoughFiltersScreen(),
  ),
];
