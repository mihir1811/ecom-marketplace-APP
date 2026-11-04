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
import '../spotlight/presentation/screens/seller_spotlight_book_screen.dart';
import '../spotlight/presentation/screens/seller_spotlight_detail_screen.dart';
import '../spotlight/presentation/screens/seller_spotlight_screen.dart';

/// Modular routes for the authenticated seller workspace.
///
/// All seller pages share one [SellerLayout] shell so the drawer stays global.
final List<RouteBase> sellerRoutes = [
  ShellRoute(
    // go_router 17 started reporting shell navigation to the root
    // observers; keep the earlier behaviour.
    notifyRootObserver: false,
    builder: (context, state, child) {
      return SellerLayout(selectedRoute: state.uri.path, child: child);
    },
    routes: [
      GoRoute(
        caseSensitive: false,
        path: AppRouteNames.sellerDashboard,
        builder: (context, state) => const SellerDashboardScreen(),
      ),
      GoRoute(
        caseSensitive: false,
        path: AppRouteNames.sellerProducts,
        builder: (context, state) => const SellerProductsScreen(),
      ),
      GoRoute(
        caseSensitive: false,
        path: '/seller/products/:productId/edit',
        builder: (context, state) => SellerProductEditScreen(
          productId: state.pathParameters['productId']!,
        ),
      ),
      GoRoute(
        caseSensitive: false,
        path: AppRouteNames.sellerOrders,
        builder: (context, state) => SellerOrdersScreen(
          preset: SellerOrdersPreset.fromQuery(state.uri.queryParameters),
        ),
      ),
      GoRoute(
        caseSensitive: false,
        path: AppRouteNames.sellerWallet,
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        caseSensitive: false,
        path: '/seller/orders/:orderId',
        builder: (context, state) =>
            SellerOrderDetailScreen(orderId: state.pathParameters['orderId']!),
      ),
      GoRoute(
        caseSensitive: false,
        path: AppRouteNames.sellerInquiries,
        builder: (context, state) => const SellerInquiriesScreen(),
      ),
      GoRoute(
        caseSensitive: false,
        path: AppRouteNames.sellerInquiryNew,
        builder: (context, state) => const SellerInquiryFormScreen(),
      ),
      GoRoute(
        caseSensitive: false,
        path: '/seller/inquiries/:category/:inquiryId',
        builder: (context, state) => SellerInquiryDetailScreen(
          categoryName: state.pathParameters['category']!,
          inquiryId: state.pathParameters['inquiryId']!,
        ),
      ),
      GoRoute(
        caseSensitive: false,
        path: AppRouteNames.sellerOffers,
        builder: (context, state) => SellerOffersScreen(
          initialStatus: state.uri.queryParameters['status'],
        ),
      ),
      GoRoute(
        caseSensitive: false,
        path: AppRouteNames.sellerAuctions,
        builder: (context, state) =>
            SellerAuctionsScreen(initialTab: state.uri.queryParameters['tab']),
      ),
      GoRoute(
        caseSensitive: false,
        path: AppRouteNames.sellerAnalytics,
        builder: (context, state) => const SellerAnalyticsScreen(),
      ),
      GoRoute(
        caseSensitive: false,
        path: AppRouteNames.sellerChat,
        builder: (context, state) => const SellerChatListScreen(),
      ),
      GoRoute(
        caseSensitive: false,
        path: '/seller/chat/:chatId',
        builder: (context, state) =>
            SellerChatDetailScreen(chatId: state.pathParameters['chatId']!),
      ),
      GoRoute(
        caseSensitive: false,
        path: AppRouteNames.sellerHelpCenter,
        builder: (context, state) => const HelpCenterScreen(),
      ),
      GoRoute(
        caseSensitive: false,
        path: AppRouteNames.sellerNotifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        caseSensitive: false,
        path: AppRouteNames.sellerReferences,
        builder: (context, state) => const SellerReferencesScreen(),
      ),
      GoRoute(
        caseSensitive: false,
        path: AppRouteNames.sellerPromotions,
        builder: (context, state) => const SellerPromotionsScreen(),
      ),
      // Advertising studio (paid spotlight placements).
      GoRoute(
        caseSensitive: false,
        path: AppRouteNames.sellerSpotlight,
        builder: (context, state) => const SellerSpotlightScreen(),
      ),
      GoRoute(
        caseSensitive: false,
        path: AppRouteNames.sellerSpotlightNew,
        builder: (context, state) => const SellerSpotlightBookScreen(),
      ),
      GoRoute(
        caseSensitive: false,
        path: AppRouteNames.sellerSpotlightDetail,
        builder: (context, state) => SellerSpotlightDetailScreen(
          adId: state.pathParameters['adId'] ?? '',
        ),
      ),
      GoRoute(
        caseSensitive: false,
        path: AppRouteNames.sellerProfile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        caseSensitive: false,
        path: AppRouteNames.sellerApiKeys,
        builder: (context, state) => const SellerApiKeysScreen(),
      ),
      GoRoute(
        caseSensitive: false,
        path: AppRouteNames.sellerSettings,
        builder: (context, state) => const BuyerSettingsScreen(seller: true),
      ),
      GoRoute(
        caseSensitive: false,
        path: AppRouteNames.sellerAbout,
        builder: (context, state) => const SellerAboutScreen(),
      ),
      GoRoute(
        caseSensitive: false,
        path: AppRouteNames.sellerPrivacy,
        builder: (context, state) => const SellerPrivacyScreen(),
      ),
      GoRoute(
        caseSensitive: false,
        path: AppRouteNames.sellerTerms,
        builder: (context, state) => const SellerTermsScreen(),
      ),
      GoRoute(
        caseSensitive: false,
        path: AppRouteNames.sellerPolicies,
        builder: (context, state) => const SellerPoliciesHubScreen(),
      ),
      GoRoute(
        caseSensitive: false,
        path: AppRouteNames.sellerPolicyDetail,
        builder: (context, state) => SellerPolicyDetailScreen(
          policyId: state.pathParameters['policyId'] ?? '',
        ),
      ),
    ],
  ),
];
