import 'package:go_router/go_router.dart';
import '../../core/router/route_names.dart';
import 'presentation/screens/home_screen.dart';

/// Modular routes list for the Home feature.
/// Spreads easily into the central root GoRouter configuration.
final List<RouteBase> homeRoutes = [
  GoRoute(
    path: AppRouteNames.home,
    builder: (context, state) => const HomeScreen(),
  ),
];
