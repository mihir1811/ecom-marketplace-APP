import 'package:go_router/go_router.dart';

import '../../core/auth/verified_account_gate.dart';
import '../../core/router/route_names.dart';
import 'presentation/screens/jewelry_bag_screen.dart';
import 'presentation/screens/jewelry_checkout_screen.dart';
import 'presentation/screens/jewelry_order_detail_screen.dart';
import 'presentation/screens/jewelry_orders_screen.dart';

final List<RouteBase> jewelryCheckoutRoutes = [
  // The bag works signed out; checkout and orders need a verified account.
  GoRoute(
    path: AppRouteNames.jewelryBag,
    builder: (context, state) => const JewelryBagScreen(),
  ),
  GoRoute(
    path: AppRouteNames.jewelryCheckout,
    builder: (context, state) =>
        const VerifiedAccountGate(child: JewelryCheckoutScreen()),
  ),
  GoRoute(
    path: AppRouteNames.jewelryOrders,
    builder: (context, state) =>
        const VerifiedAccountGate(child: JewelryOrdersScreen()),
  ),
  GoRoute(
    path: AppRouteNames.jewelryOrderDetail,
    builder: (context, state) => VerifiedAccountGate(
      child: JewelryOrderDetailScreen(
        orderId: state.pathParameters['orderId'] ?? '',
      ),
    ),
  ),
];
