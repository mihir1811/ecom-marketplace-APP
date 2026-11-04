import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/auth/verified_account_gate.dart';
import '../../core/router/route_names.dart';
import 'presentation/screens/jewelry_bag_screen.dart';
import 'presentation/screens/jewelry_checkout_screen.dart';
import 'presentation/screens/jewelry_order_detail_screen.dart';
import 'presentation/screens/jewelry_invoice_screen.dart';
import 'presentation/screens/jewelry_orders_screen.dart';
import 'presentation/screens/jewelry_shop_orders_screen.dart';
import '../jewelry_reviews/presentation/screens/jewelry_seller_reviews_screen.dart';

/// Sends guests to sign in: the bag, checkout and orders are for signed-in
/// buyers only.
String? _signedInOnly(BuildContext context, GoRouterState state) {
  final signedIn = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(authProvider).isAuthenticated;
  return signedIn ? null : AppRouteNames.login;
}

final List<RouteBase> jewelryCheckoutRoutes = [
  // Signed in only; checkout and orders also need a verified account.
  GoRoute(
    path: AppRouteNames.jewelryBag,
    redirect: _signedInOnly,
    builder: (context, state) => const JewelryBagScreen(),
  ),
  GoRoute(
    path: AppRouteNames.jewelryCheckout,
    redirect: _signedInOnly,
    builder: (context, state) =>
        const VerifiedAccountGate(child: JewelryCheckoutScreen()),
  ),
  GoRoute(
    path: AppRouteNames.jewelryOrders,
    redirect: _signedInOnly,
    builder: (context, state) =>
        const VerifiedAccountGate(child: JewelryOrdersScreen()),
  ),
  GoRoute(
    path: AppRouteNames.jewelryOrderDetail,
    redirect: _signedInOnly,
    builder: (context, state) => VerifiedAccountGate(
      child: JewelryOrderDetailScreen(
        orderId: state.pathParameters['orderId'] ?? '',
      ),
    ),
  ),
  GoRoute(
    path: AppRouteNames.jewelryOrderInvoice,
    redirect: _signedInOnly,
    builder: (context, state) => VerifiedAccountGate(
      child: JewelryInvoiceScreen(
        orderId: state.pathParameters['orderId'] ?? '',
      ),
    ),
  ),
  // Seller studio → orders for jewellery shops; the API rejects other
  // accounts with its own message, which the screen shows.
  GoRoute(
    path: AppRouteNames.jewelryShopOrders,
    redirect: _signedInOnly,
    builder: (context, state) =>
        JewelryShopOrdersScreen(openOrderId: state.uri.queryParameters['o']),
  ),
  // Seller studio → reviews; `r` is the review a push points at.
  GoRoute(
    path: AppRouteNames.jewelryShopReviews,
    redirect: _signedInOnly,
    builder: (context, state) => JewelrySellerReviewsScreen(
      focusReviewId: state.uri.queryParameters['r'],
      initialShow: state.uri.queryParameters['show'],
    ),
  ),
];
