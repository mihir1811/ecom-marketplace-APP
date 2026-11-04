import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import 'presentation/screens/bullions_screen.dart';
import 'presentation/widgets/bullions_filter_drawer.dart';

final List<RouteBase> bullionsRoutes = [
  GoRoute(
    caseSensitive: false,
    path: AppRouteNames.bullions,
    builder: (context, state) => const BullionsScreen(),
  ),
  GoRoute(
    caseSensitive: false,
    path: AppRouteNames.bullionsFilters,
    builder: (context, state) => const BullionsFilterDrawer(),
  ),
];
