import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import 'domain/seller_order_board.dart';
import 'presentation/screens/seller_analytics_screen.dart';
import 'presentation/screens/seller_auctions_screen.dart';
import 'presentation/screens/seller_chat_detail_screen.dart';
import 'presentation/screens/seller_chat_list_screen.dart';
import 'presentation/screens/seller_dashboard_screen.dart';
import 'presentation/screens/seller_inquiry_detail_screen.dart';
import 'presentation/screens/seller_inquiry_form_screen.dart';
import 'presentation/screens/seller_inquiries_screen.dart';
import 'presentation/screens/seller_offers_screen.dart';
import 'presentation/screens/seller_order_detail_screen.dart';
import 'presentation/screens/seller_orders_screen.dart';
import 'presentation/screens/seller_products_screen.dart';
import 'presentation/screens/seller_product_edit_screen.dart';
import 'presentation/screens/seller_api_keys_screen.dart';
import 'presentation/screens/seller_promotions_screen.dart';
import 'presentation/screens/seller_about_screen.dart';
import 'presentation/screens/seller_policies_hub_screen.dart';
import 'presentation/screens/seller_legal_document_screen.dart';
import 'presentation/widgets/seller_layout.dart';
import '../auth/presentation/screens/profile_screen.dart';
import '../buyer/presentation/screens/buyer_settings_screen.dart';
import '../help_center/presentation/screens/help_center_screen.dart';
import '../reference/presentation/screens/seller_references_screen.dart';
import '../notifications/presentation/screens/notifications_screen.dart';
import '../wallet/presentation/screens/wallet_screen.dart';

/// Modular routes for the authenticated seller workspace.
///
/// All seller pages share one [SellerLayout] shell so the drawer stays global.
final List<RouteBase> sellerRoutes = [
  ShellRoute(
    builder: (context, state, child) {
      return SellerLayout(selectedRoute: state.uri.path, child: child);
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
        path: '/seller/products/:productId/edit',
        builder: (context, state) => SellerProductEditScreen(
          productId: state.pathParameters['productId']!,
        ),
      ),
      GoRoute(
        path: AppRouteNames.sellerOrders,
        builder: (context, state) => SellerOrdersScreen(
          preset: SellerOrdersPreset.fromQuery(state.uri.queryParameters),
        ),
      ),
      GoRoute(
        path: AppRouteNames.sellerWallet,
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: '/seller/orders/:orderId',
        builder: (context, state) =>
            SellerOrderDetailScreen(orderId: state.pathParameters['orderId']!),
      ),
      GoRoute(
        path: AppRouteNames.sellerInquiries,
        builder: (context, state) => const SellerInquiriesScreen(),
      ),
      GoRoute(
        path: AppRouteNames.sellerInquiryNew,
        builder: (context, state) => const SellerInquiryFormScreen(),
      ),
      GoRoute(
        path: '/seller/inquiries/:category/:inquiryId',
        builder: (context, state) => SellerInquiryDetailScreen(
          categoryName: state.pathParameters['category']!,
          inquiryId: state.pathParameters['inquiryId']!,
        ),
      ),
      GoRoute(
        path: AppRouteNames.sellerOffers,
        builder: (context, state) => SellerOffersScreen(
          initialStatus: state.uri.queryParameters['status'],
        ),
      ),
      GoRoute(
        path: AppRouteNames.sellerAuctions,
        builder: (context, state) =>
            SellerAuctionsScreen(initialTab: state.uri.queryParameters['tab']),
      ),
      GoRoute(
        path: AppRouteNames.sellerAnalytics,
        builder: (context, state) => const SellerAnalyticsScreen(),
      ),
      GoRoute(
        path: AppRouteNames.sellerChat,
        builder: (context, state) => const SellerChatListScreen(),
      ),
      GoRoute(
        path: '/seller/chat/:chatId',
        builder: (context, state) =>
            SellerChatDetailScreen(chatId: state.pathParameters['chatId']!),
      ),
      GoRoute(
        path: AppRouteNames.sellerHelpCenter,
        builder: (context, state) => const HelpCenterScreen(),
      ),
      GoRoute(
        path: AppRouteNames.sellerNotifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRouteNames.sellerReferences,
        builder: (context, state) => const SellerReferencesScreen(),
      ),
      GoRoute(
        path: AppRouteNames.sellerPromotions,
        builder: (context, state) => const SellerPromotionsScreen(),
      ),
      GoRoute(
        path: AppRouteNames.sellerProfile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRouteNames.sellerApiKeys,
        builder: (context, state) => const SellerApiKeysScreen(),
      ),
      GoRoute(
        path: AppRouteNames.sellerSettings,
        builder: (context, state) => const BuyerSettingsScreen(seller: true),
      ),
      GoRoute(
        path: AppRouteNames.sellerAbout,
        builder: (context, state) => const SellerAboutScreen(),
      ),
      GoRoute(
        path: AppRouteNames.sellerPrivacy,
        builder: (context, state) => const SellerPrivacyScreen(),
      ),
      GoRoute(
        path: AppRouteNames.sellerTerms,
        builder: (context, state) => const SellerTermsScreen(),
      ),
      GoRoute(
        path: AppRouteNames.sellerPolicies,
        builder: (context, state) => const SellerPoliciesHubScreen(),
      ),
      GoRoute(
        path: AppRouteNames.sellerPolicyDetail,
        builder: (context, state) => SellerPolicyDetailScreen(
          policyId: state.pathParameters['policyId'] ?? '',
        ),
      ),
    ],
  ),
];
