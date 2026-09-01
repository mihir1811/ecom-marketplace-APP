import 'package:go_router/go_router.dart';

import '../../core/auth/seller_only_gate.dart';
import '../../core/auth/verified_account_gate.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/router/route_names.dart';
import '../seller/presentation/screens/seller_chat_detail_screen.dart';
import '../seller/presentation/screens/seller_chat_list_screen.dart';
import '../seller/presentation/screens/seller_help_center_screen.dart';
import '../seller/presentation/screens/seller_inquiry_detail_screen.dart';
import '../seller/presentation/screens/seller_inquiry_form_screen.dart';
import '../seller/presentation/screens/seller_inquiry_inbox_screen.dart';
import 'presentation/screens/buyer_order_detail_screen.dart';
import 'presentation/screens/buyer_orders_screen.dart';
import 'presentation/screens/buyer_profile_screen.dart';
import 'presentation/screens/buyer_refunds_screen.dart';
import 'presentation/screens/buyer_reviews_screen.dart';
import 'presentation/screens/buyer_settings_screen.dart';
import 'presentation/screens/buyer_wishlist_screen.dart';
import '../recently_viewed/presentation/screens/buyer_recently_viewed_screen.dart';
import 'presentation/widgets/buyer_layout.dart';
import '../reference/presentation/screens/buyer_references_screen.dart';

/// Buyer account routes. Shared screens reuse seller widgets under `/buyer/...`.
final List<RouteBase> buyerRoutes = [
  GoRoute(
    path: AppRouteNames.buyerProfile,
    builder: (context, state) => const BuyerProfileScreen(),
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
    path: AppRouteNames.buyerReferences,
    builder: (context, state) => const BuyerReferencesScreen(),
  ),
  GoRoute(
    path: AppRouteNames.buyerInquiries,
    builder: (context, state) => BuyerLayout(
      title: context.tr(AccountCommerceL10n.inquiries),
      child: const SellerInquiryInboxScreen(showHeader: false),
    ),
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
    builder: (context, state) => BuyerLayout(
      title: context.tr(AccountCommerceL10n.helpCenter),
      child: const SellerHelpCenterScreen(showHeader: false),
    ),
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
    builder: (context, state) => BuyerLayout(
      title: context.tr(CoreL10n.messages),
      child: const VerifiedAccountGate(
        fallbackRoute: AppRouteNames.buyerProfile,
        child: SellerOnlyGate(
          fallbackRoute: AppRouteNames.buyerProfile,
          child: SellerChatListScreen(),
        ),
      ),
    ),
  ),
  GoRoute(
    path: '/buyer/messages/:chatId',
    builder: (context, state) => BuyerLayout(
      title: context.tr(AccountCommerceL10n.chat),
      child: VerifiedAccountGate(
        fallbackRoute: AppRouteNames.buyerProfile,
        child: SellerOnlyGate(
          fallbackRoute: AppRouteNames.buyerProfile,
          child: SellerChatDetailScreen(
            chatId: state.pathParameters['chatId']!,
          ),
        ),
      ),
    ),
  ),
  GoRoute(
    path: AppRouteNames.buyerSettings,
    builder: (context, state) => const BuyerSettingsScreen(),
  ),
];
