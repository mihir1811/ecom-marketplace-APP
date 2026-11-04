import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import 'presentation/screens/comparison_screen.dart';

final List<RouteBase> comparisonRoutes = [
  GoRoute(
    caseSensitive: false,
    path: AppRouteNames.comparison,
    builder: (context, state) => const ComparisonScreen(),
  ),
];
