import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import 'presentation/screens/jewelry_education_screen.dart';

/// Jewelry education page.
final List<RouteBase> jewelryEducationRoutes = [
  GoRoute(
    caseSensitive: false,
    path: AppRouteNames.jewelryEducation,
    builder: (context, state) => const JewelryEducationScreen(),
  ),
];
