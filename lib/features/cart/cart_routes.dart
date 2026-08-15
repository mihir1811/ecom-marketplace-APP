import 'package:go_router/go_router.dart';

import '../../core/auth/verified_account_gate.dart';
import '../../core/router/route_names.dart';
import 'presentation/screens/cart_screen.dart';

final List<RouteBase> cartRoutes = [
  GoRoute(
    path: AppRouteNames.cart,
    builder: (context, state) => const VerifiedAccountGate(
      child: CartScreen(),
    ),
  ),
];
