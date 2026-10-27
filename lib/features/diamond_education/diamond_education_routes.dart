import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import 'presentation/screens/diamond_education_screen.dart';

/// Diamond education page.
final List<RouteBase> diamondEducationRoutes = [
  GoRoute(
    path: AppRouteNames.diamondEducation,
    builder: (context, state) => const DiamondEducationScreen(),
  ),
];
