import 'package:go_router/go_router.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/router/route_names.dart';
import 'presentation/screens/diamond_listings_screen.dart';
import 'presentation/screens/diamond_search_screen.dart';
import 'presentation/screens/lab_grown_diamond_search_screen.dart';
import 'presentation/widgets/lab_grown_diamond_scope.dart';

final List<RouteBase> diamondsRoutes = [
  GoRoute(
    path: AppRouteNames.diamonds,
    builder: (context, state) => const DiamondSearchScreen(),
  ),
  GoRoute(
    path: AppRouteNames.diamondResults,
    builder: (context, state) => const DiamondListingsScreen(),
  ),
  ShellRoute(
    builder: (context, state, child) => LabGrownDiamondScope(child: child),
    routes: [
      GoRoute(
        path: AppRouteNames.labGrownDiamonds,
        builder: (context, state) => const LabGrownDiamondSearchScreen(),
      ),
      GoRoute(
        path: AppRouteNames.labGrownDiamondResults,
        builder: (context, state) => DiamondListingsScreen(
          title: context.tr(CatalogL10n.labGrownResults),
          searchRoute: AppRouteNames.labGrownDiamonds,
        ),
      ),
    ],
  ),
];
