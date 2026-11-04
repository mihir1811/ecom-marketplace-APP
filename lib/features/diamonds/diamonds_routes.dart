import 'package:go_router/go_router.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/router/route_names.dart';
import 'presentation/screens/diamond_listings_screen.dart';
import 'presentation/screens/diamond_search_screen.dart';
import 'presentation/screens/lab_grown_diamond_search_screen.dart';
import 'presentation/widgets/lab_grown_diamond_scope.dart';

final List<RouteBase> diamondsRoutes = [
  GoRoute(
    caseSensitive: false,
    path: AppRouteNames.diamonds,
    builder: (context, state) => const DiamondSearchScreen(),
  ),
  GoRoute(
    caseSensitive: false,
    path: AppRouteNames.diamondResults,
    builder: (context, state) => const DiamondListingsScreen(),
  ),
  ShellRoute(
    // go_router 17 started reporting shell navigation to the root
    // observers; keep the earlier behaviour.
    notifyRootObserver: false,
    builder: (context, state, child) => LabGrownDiamondScope(child: child),
    routes: [
      GoRoute(
        caseSensitive: false,
        path: AppRouteNames.labGrownDiamonds,
        builder: (context, state) => const LabGrownDiamondSearchScreen(),
      ),
      GoRoute(
        caseSensitive: false,
        path: AppRouteNames.labGrownDiamondResults,
        builder: (context, state) => DiamondListingsScreen(
          title: context.tr(CatalogL10n.labGrownResults),
          searchRoute: AppRouteNames.labGrownDiamonds,
        ),
      ),
    ],
  ),
];
