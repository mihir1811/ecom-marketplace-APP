import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import 'presentation/screens/seller_auctions_screen.dart';
import 'presentation/screens/seller_dashboard_screen.dart';
import 'presentation/screens/seller_order_detail_screen.dart';
import 'presentation/screens/seller_orders_screen.dart';
import 'presentation/screens/seller_products_screen.dart';
import 'presentation/screens/seller_refunds_screen.dart';
import 'presentation/screens/seller_section_screen.dart';
import 'presentation/widgets/seller_layout.dart';

/// Modular routes for the authenticated seller/user side.
///
/// All seller pages share one [SellerLayout] shell so the drawer stays global.
final List<RouteBase> sellerRoutes = [
  ShellRoute(
    builder: (context, state, child) {
      return SellerLayout(
        selectedRoute: state.uri.path,
        child: child,
      );
    },
    routes: [
      GoRoute(
        path: AppRouteNames.sellerDashboard,
        builder: (context, state) => const SellerDashboardScreen(),
      ),
      GoRoute(
        path: AppRouteNames.sellerProducts,
        builder: (context, state) => const SellerProductsScreen(),
      ),
      GoRoute(
        path: AppRouteNames.sellerOrders,
        builder: (context, state) => const SellerOrdersScreen(),
      ),
      GoRoute(
        path: '/seller/orders/:orderId',
        builder: (context, state) => SellerOrderDetailScreen(
          orderId: state.pathParameters['orderId']!,
        ),
      ),
      GoRoute(
        path: AppRouteNames.sellerRefunds,
        builder: (context, state) => const SellerRefundsScreen(),
      ),
      GoRoute(
        path: AppRouteNames.sellerInquiries,
        builder: (context, state) =>
            const SellerSectionScreen(title: 'Inquiries'),
      ),
      GoRoute(
        path: AppRouteNames.sellerOffers,
        builder: (context, state) => const SellerSectionScreen(title: 'Offers'),
      ),
      GoRoute(
        path: AppRouteNames.sellerAuctions,
        builder: (context, state) => const SellerAuctionsScreen(),
      ),
      GoRoute(
        path: AppRouteNames.sellerAnalytics,
        builder: (context, state) =>
            const SellerSectionScreen(title: 'Analytics'),
      ),
      GoRoute(
        path: AppRouteNames.sellerInventory,
        builder: (context, state) =>
            const SellerSectionScreen(title: 'Inventory'),
      ),
      GoRoute(
        path: AppRouteNames.sellerChat,
        builder: (context, state) => const SellerSectionScreen(title: 'Chat'),
      ),
      GoRoute(
        path: AppRouteNames.sellerHelpCenter,
        builder: (context, state) =>
            const SellerSectionScreen(title: 'Help center'),
      ),
      GoRoute(
        path: AppRouteNames.sellerPromotions,
        builder: (context, state) =>
            const SellerSectionScreen(title: 'Promotions'),
      ),
      GoRoute(
        path: AppRouteNames.sellerProfile,
        builder: (context, state) => const SellerSectionScreen(title: 'Profile'),
      ),
    ],
  ),
];
