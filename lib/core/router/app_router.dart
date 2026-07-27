import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';
import '../../features/home/home_routes.dart';
import '../../features/diamonds/diamonds_routes.dart';
import '../../features/gemstones/gemstones_routes.dart';
import '../../features/watches/watches_routes.dart';
import '../../features/bullions/bullions_routes.dart';
import '../../features/jewelry/jewelry_routes.dart';
import '../../features/auth/auth_routes.dart';
import '../../features/buyer/buyer_routes.dart';
import '../../features/seller/seller_routes.dart';
import '../../features/comparison/comparison_routes.dart';
import '../../features/cart/cart_routes.dart';
import '../../features/info/info_routes.dart';

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

/// Root GoRouter configuration compiling routes from all feature modules.
/// When adding a new feature, import its routes and append them to the routes list below.
final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRouteNames.home,
  routes: [
    ...homeRoutes,
    ...infoRoutes,
    ...authRoutes,
    ...buyerRoutes,
    ...sellerRoutes,
    ...diamondsRoutes,
    ...gemstonesRoutes,
    ...watchesRoutes,
    ...bullionsRoutes,
    ...jewelryRoutes,
    ...comparisonRoutes,
    ...cartRoutes,
  ],
);
