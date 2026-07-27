import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import 'presentation/screens/about_us_screen.dart';
import 'presentation/screens/terms_and_conditions_screen.dart';

/// Static informational pages (About, legal, etc.).
final List<RouteBase> infoRoutes = [
  GoRoute(
    path: AppRouteNames.aboutUs,
    builder: (context, state) => const AboutUsScreen(),
  ),
  GoRoute(
    path: AppRouteNames.termsAndConditions,
    builder: (context, state) => const TermsAndConditionsScreen(),
  ),
];
