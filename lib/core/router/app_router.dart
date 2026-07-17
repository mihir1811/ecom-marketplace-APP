import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';
import '../../features/home/home_routes.dart';
import '../../features/diamonds/diamonds_routes.dart';

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

/// Root GoRouter configuration compiling routes from all feature modules.
/// When adding a new feature, import its routes and append them to the routes list below.
final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRouteNames.home,
  routes: [
    ...homeRoutes,
    ...diamondsRoutes,
  ],
);
