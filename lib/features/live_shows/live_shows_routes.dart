import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import '../../core/widgets/app_system_back_scope.dart';
import 'presentation/screens/live_show_screen.dart';
import 'presentation/screens/live_shows_screen.dart';

// Watching and reading are public; sign-in is asked for only to act.
final List<RouteBase> liveShowsRoutes = [
  GoRoute(
    path: AppRouteNames.liveShows,
    builder: (context, state) =>
        const AppSystemBackScope(child: LiveShowsScreen()),
  ),
  GoRoute(
    path: AppRouteNames.liveShow,
    builder: (context, state) => AppSystemBackScope(
      child: LiveShowScreen(showId: state.pathParameters['showId']!),
    ),
  ),
];
