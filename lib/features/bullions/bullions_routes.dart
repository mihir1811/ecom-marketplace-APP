import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import 'presentation/screens/bullions_screen.dart';

final List<RouteBase> bullionsRoutes = [
  GoRoute(
    path: AppRouteNames.bullions,
    builder: (context, state) => const BullionsScreen(),
  ),
];

