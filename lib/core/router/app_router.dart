import 'package:go_router/go_router.dart';
import '../deep_links/order_link.dart';
import '../deep_links/order_links.dart';
import 'navigator_keys.dart';
import '../widgets/navigation/bottom_nav/app_bottom_nav_host.dart';
import 'route_names.dart';
import '../../features/home/home_routes.dart';
import '../../features/diamonds/diamonds_routes.dart';
import '../../features/diamond_projects/diamond_projects_routes.dart';
import '../../features/gemstones/gemstones_routes.dart';
import '../../features/watches/watches_routes.dart';
import '../../features/bullions/bullions_routes.dart';
import '../../features/jewelry/jewelry_routes.dart';
import '../../features/jewelry_checkout/jewelry_checkout_routes.dart';
import '../../features/product_detail/product_detail_routes.dart';
import '../../features/product_share/product_share_routes.dart';
import '../../features/diamond_viewer/diamond_viewer_routes.dart';
import '../../features/auth/auth_routes.dart';
import '../../features/buyer/buyer_routes.dart';
import '../../features/seller/seller_routes.dart';
import '../../features/comparison/comparison_routes.dart';
import '../../features/cart/cart_routes.dart';
import '../../features/payment/payment_routes.dart';
import '../../features/wallet/wallet_routes.dart';
import '../../features/rewards/rewards_routes.dart';
import '../../features/info/info_routes.dart';
import '../../features/auction/auction_routes.dart';
import '../../features/live_shows/live_shows_routes.dart';
import '../../features/diamond_education/diamond_education_routes.dart';
import '../../features/jewelry_education/jewelry_education_routes.dart';
import '../../features/spotlight/spotlight_routes.dart';

export 'navigator_keys.dart';

/// Root GoRouter configuration compiling routes from all feature modules.
/// When adding a new feature, import its routes and append them to the routes list below.
// Every GoRoute sets `caseSensitive: false`: go_router 15 made paths case
// sensitive by default, and links like /Diamonds used to open.
final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRouteNames.home,
  observers: [appPopupRouteObserver],
  // WhatsApp order links that launch the app arrive as the first location
  // (`/orders/{id}`, `/seller/orders?o={id}`). Start on home and let
  // OrderLinkHost open the order on top once the session is known.
  redirect: (context, state) {
    final link = parseOrderLink(state.uri);
    if (link == null) return null;
    OrderLinks.instance.receive(link);
    return AppRouteNames.home;
  },
  routes: [
    ...homeRoutes,
    ...infoRoutes,
    ...authRoutes,
    ...buyerRoutes,
    ...sellerRoutes,
    ...diamondsRoutes,
    ...diamondProjectsRoutes,
    ...gemstonesRoutes,
    ...watchesRoutes,
    ...bullionsRoutes,
    ...jewelryRoutes,
    ...jewelryCheckoutRoutes,
    ...productDetailRoutes,
    ...spotlightRoutes,
    ...productShareRoutes,
    ...diamondViewerRoutes,
    ...comparisonRoutes,
    ...cartRoutes,
    ...paymentRoutes,
    ...walletRoutes,
    ...rewardsRoutes,
    ...auctionRoutes,
    ...liveShowsRoutes,
    ...diamondEducationRoutes,
    ...jewelryEducationRoutes,
  ],
);
