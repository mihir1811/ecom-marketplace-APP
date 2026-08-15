import 'package:go_router/go_router.dart';
import 'navigator_keys.dart';
import 'route_names.dart';
import '../../features/home/home_routes.dart';
import '../../features/diamonds/diamonds_routes.dart';
import '../../features/diamond_projects/diamond_projects_routes.dart';
import '../../features/gemstones/gemstones_routes.dart';
import '../../features/watches/watches_routes.dart';
import '../../features/bullions/bullions_routes.dart';
import '../../features/jewelry/jewelry_routes.dart';
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
import '../../features/info/info_routes.dart';

export 'navigator_keys.dart';

/// Root GoRouter configuration compiling routes from all feature modules.
/// When adding a new feature, import its routes and append them to the routes list below.
final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRouteNames.home,
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
    ...productDetailRoutes,
    ...productShareRoutes,
    ...diamondViewerRoutes,
    ...comparisonRoutes,
    ...cartRoutes,
    ...paymentRoutes,
    ...walletRoutes,
  ],
);
