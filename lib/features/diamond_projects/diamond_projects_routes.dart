import 'package:go_router/go_router.dart';

import '../../core/auth/seller_only_gate.dart';
import '../../core/router/route_names.dart';
import 'presentation/screens/diamond_project_stats_screen.dart';
import 'presentation/screens/saved_diamond_projects_screen.dart';

final List<RouteBase> diamondProjectsRoutes = [
  GoRoute(
    path: AppRouteNames.diamondProject,
    builder: (context, state) =>
        const SellerOnlyGate(child: DiamondProjectStatsScreen()),
  ),
  GoRoute(
    path: AppRouteNames.savedDiamondProjects,
    builder: (context, state) =>
        const SellerOnlyGate(child: SavedDiamondProjectsScreen()),
  ),
];
