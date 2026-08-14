import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import 'presentation/screens/buyer_wallet_screen.dart';

final List<RouteBase> walletRoutes = [
  GoRoute(
    path: AppRouteNames.buyerWallet,
    builder: (context, state) => const BuyerWalletScreen(),
  ),
];
