import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import '../seller/presentation/screens/seller_chat_detail_screen.dart';
import '../seller/presentation/screens/seller_chat_list_screen.dart';
import '../seller/presentation/screens/seller_help_center_screen.dart';
import '../seller/presentation/screens/seller_inquiry_detail_screen.dart';
import '../seller/presentation/screens/seller_inquiry_form_screen.dart';
import '../seller/presentation/screens/seller_inquiry_inbox_screen.dart';
import '../seller/presentation/screens/seller_profile_screen.dart';
import 'presentation/screens/buyer_order_detail_screen.dart';
import 'presentation/screens/buyer_orders_screen.dart';
import 'presentation/screens/buyer_reviews_screen.dart';
import 'presentation/screens/buyer_settings_screen.dart';
import 'presentation/screens/buyer_wishlist_screen.dart';
import 'presentation/widgets/buyer_layout.dart';

/// Buyer account routes. Shared screens reuse seller widgets under `/buyer/...`.
final List<RouteBase> buyerRoutes = [
  GoRoute(
    path: AppRouteNames.buyerProfile,
    builder: (context, state) => const BuyerLayout(
      child: SellerProfileScreen(),
    ),
  ),
  GoRoute(
    path: AppRouteNames.buyerOrders,
    builder: (context, state) => const BuyerOrdersScreen(),
  ),
  GoRoute(
    path: '/buyer/orders/:orderId',
    builder: (context, state) => BuyerOrderDetailScreen(
      orderId: state.pathParameters['orderId']!,
    ),
  ),
  GoRoute(
    path: AppRouteNames.buyerInquiries,
    builder: (context, state) => const BuyerLayout(
      child: SellerInquiryInboxScreen(),
    ),
  ),
  GoRoute(
    path: AppRouteNames.buyerInquiryNew,
    builder: (context, state) => const BuyerLayout(
      child: SellerInquiryFormScreen(),
    ),
  ),
  GoRoute(
    path: '/buyer/inquiries/:category/:inquiryId',
    builder: (context, state) => BuyerLayout(
      child: SellerInquiryDetailScreen(
        categoryName: state.pathParameters['category']!,
        inquiryId: state.pathParameters['inquiryId']!,
      ),
    ),
  ),
  GoRoute(
    path: AppRouteNames.buyerHelpCenter,
    builder: (context, state) => const BuyerLayout(
      child: SellerHelpCenterScreen(),
    ),
  ),
  GoRoute(
    path: AppRouteNames.buyerWishlist,
    builder: (context, state) => const BuyerWishlistScreen(),
  ),
  GoRoute(
    path: AppRouteNames.buyerReviews,
    builder: (context, state) => const BuyerReviewsScreen(),
  ),
  GoRoute(
    path: AppRouteNames.buyerMessages,
    builder: (context, state) => const BuyerLayout(
      child: SellerChatListScreen(),
    ),
  ),
  GoRoute(
    path: '/buyer/messages/:chatId',
    builder: (context, state) => BuyerLayout(
      child: SellerChatDetailScreen(
        chatId: state.pathParameters['chatId']!,
      ),
    ),
  ),
  GoRoute(
    path: AppRouteNames.buyerSettings,
    builder: (context, state) => const BuyerSettingsScreen(),
  ),
];
