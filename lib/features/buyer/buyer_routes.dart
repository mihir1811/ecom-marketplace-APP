import 'package:go_router/go_router.dart';

import '../../core/auth/seller_only_gate.dart';
import '../../core/auth/verified_account_gate.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/router/route_names.dart';
import '../seller/presentation/screens/seller_inquiry_detail_screen.dart';
import '../seller/presentation/screens/seller_inquiry_form_screen.dart';
import 'presentation/screens/buyer_inquiries_screen.dart';
import 'presentation/screens/buyer_offers_screen.dart';
import 'presentation/screens/buyer_order_detail_screen.dart';
import 'presentation/screens/buyer_chat_detail_screen.dart';
import 'presentation/screens/buyer_chat_list_screen.dart';
import 'presentation/screens/buyer_orders_screen.dart';
import 'presentation/screens/buyer_refunds_screen.dart';
import 'presentation/screens/buyer_reviews_screen.dart';
import 'presentation/screens/buyer_settings_screen.dart';
import 'presentation/screens/buyer_wishlist_screen.dart';
import 'presentation/screens/buyer_about_screen.dart';
import 'presentation/screens/buyer_policies_hub_screen.dart';
import 'presentation/screens/buyer_legal_document_screen.dart';
import '../recently_viewed/presentation/screens/buyer_recently_viewed_screen.dart';
import '../notifications/presentation/screens/notifications_screen.dart';
import '../auth/presentation/screens/profile_screen.dart';
import '../help_center/presentation/screens/help_center_screen.dart';
import 'presentation/maison/maison_layout.dart';
import 'presentation/widgets/buyer_layout.dart';
import '../reference/presentation/screens/buyer_references_screen.dart';

/// Buyer account routes. Profile, Help center, Wallet and Notifications are
/// common screens wrapped in the buyer shell; everything else is buyer-only.
final List<RouteBase> buyerRoutes = [
  GoRoute(
    path: AppRouteNames.buyerProfile,
    builder: (context, state) =>
        const MaisonLayout(scrollsBehindDock: true, child: ProfileScreen()),
  ),
  GoRoute(
    path: AppRouteNames.buyerOrders,
    builder: (context, state) =>
        const VerifiedAccountGate(child: BuyerOrdersScreen()),
  ),
  GoRoute(
    path: '/buyer/orders/:orderId',
    builder: (context, state) => VerifiedAccountGate(
      child: BuyerOrderDetailScreen(orderId: state.pathParameters['orderId']!),
    ),
  ),
  GoRoute(
    path: AppRouteNames.buyerRefunds,
    builder: (context, state) =>
        const VerifiedAccountGate(child: BuyerRefundsScreen()),
  ),
  GoRoute(
    path: AppRouteNames.buyerOffers,
    builder: (context, state) => VerifiedAccountGate(
      child: BuyerOffersScreen(payOfferId: state.uri.queryParameters['pay']),
    ),
  ),
  GoRoute(
    path: AppRouteNames.buyerReferences,
    builder: (context, state) => const BuyerReferencesScreen(),
  ),
  GoRoute(
    path: AppRouteNames.buyerInquiries,
    builder: (context, state) => const BuyerInquiriesScreen(),
  ),
  GoRoute(
    path: AppRouteNames.buyerInquiryNew,
    builder: (context, state) => BuyerLayout(
      title: context.tr(AccountCommerceL10n.newInquiry),
      child: const SellerInquiryFormScreen(),
    ),
  ),
  GoRoute(
    path: '/buyer/inquiries/:category/:inquiryId',
    builder: (context, state) => BuyerLayout(
      title: context.tr(AccountCommerceL10n.inquiry),
      child: SellerInquiryDetailScreen(
        categoryName: state.pathParameters['category']!,
        inquiryId: state.pathParameters['inquiryId']!,
      ),
    ),
  ),
  GoRoute(
    path: AppRouteNames.buyerHelpCenter,
    builder: (context, state) =>
        const MaisonLayout(detail: true, child: HelpCenterScreen()),
  ),
  GoRoute(
    path: AppRouteNames.buyerWishlist,
    builder: (context, state) => const BuyerWishlistScreen(),
  ),
  GoRoute(
    path: AppRouteNames.buyerRecentlyViewed,
    builder: (context, state) => const BuyerRecentlyViewedScreen(),
  ),
  GoRoute(
    path: AppRouteNames.buyerReviews,
    builder: (context, state) => const BuyerReviewsScreen(),
  ),
  GoRoute(
    path: AppRouteNames.buyerMessages,
    builder: (context, state) => const MaisonLayout(
      detail: true,
      child: VerifiedAccountGate(
        fallbackRoute: AppRouteNames.buyerProfile,
        child: SellerOnlyGate(
          fallbackRoute: AppRouteNames.buyerProfile,
          child: BuyerChatListScreen(),
        ),
      ),
    ),
  ),
  GoRoute(
    path: '/buyer/messages/:chatId',
    builder: (context, state) => MaisonLayout(
      detail: true,
      child: VerifiedAccountGate(
        fallbackRoute: AppRouteNames.buyerProfile,
        child: SellerOnlyGate(
          fallbackRoute: AppRouteNames.buyerProfile,
          child: BuyerChatDetailScreen(chatId: state.pathParameters['chatId']!),
        ),
      ),
    ),
  ),
  GoRoute(
    path: AppRouteNames.buyerSettings,
    builder: (context, state) => const BuyerSettingsScreen(),
  ),
  GoRoute(
    path: AppRouteNames.buyerNotifications,
    builder: (context, state) =>
        const MaisonLayout(detail: true, child: NotificationsScreen()),
  ),
  GoRoute(
    path: AppRouteNames.buyerAbout,
    builder: (context, state) => const BuyerAboutScreen(),
  ),
  GoRoute(
    path: AppRouteNames.buyerPrivacy,
    builder: (context, state) => const BuyerPrivacyScreen(),
  ),
  GoRoute(
    path: AppRouteNames.buyerTerms,
    builder: (context, state) => const BuyerTermsScreen(),
  ),
  GoRoute(
    path: AppRouteNames.buyerPolicies,
    builder: (context, state) => const BuyerPoliciesHubScreen(),
  ),
  GoRoute(
    path: AppRouteNames.buyerPolicyDetail,
    builder: (context, state) => BuyerPolicyDetailScreen(
      policyId: state.pathParameters['policyId'] ?? '',
    ),
  ),
];
