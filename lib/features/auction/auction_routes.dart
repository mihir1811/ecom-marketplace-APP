import 'package:go_router/go_router.dart';

import '../../core/auth/verified_account_gate.dart';
import '../../core/router/route_names.dart';
import '../../core/widgets/app_system_back_scope.dart';
import 'application/auction_providers.dart';
import 'presentation/screens/auction_detail_screen.dart';
import 'presentation/screens/auctions_list_screen.dart';

// Drawer items and notification taps open these with `go`, leaving the
// screen alone on the stack. [AppSystemBackScope] keeps Android back from
// popping the root route (which closes the app) and routes it through
// [AppNavigation.back] instead.
final List<RouteBase> auctionRoutes = [
  GoRoute(
    path: AppRouteNames.auctions,
    builder: (context, state) => const AppSystemBackScope(
      child: AuctionsListScreen(kind: AuctionFeedKind.live, title: 'Auctions'),
    ),
  ),
  GoRoute(
    path: AppRouteNames.auctionActivity,
    builder: (context, state) => const AppSystemBackScope(
      child: VerifiedAccountGate(
        child: AuctionsListScreen(
          kind: AuctionFeedKind.activity,
          title: 'My bids',
          outcomes: ['all', 'participating', 'won', 'lost'],
        ),
      ),
    ),
  ),
  GoRoute(
    path: AppRouteNames.auctionWins,
    builder: (context, state) => const AppSystemBackScope(
      child: VerifiedAccountGate(
        child: AuctionsListScreen(kind: AuctionFeedKind.wins, title: 'My wins'),
      ),
    ),
  ),
  GoRoute(
    path: AppRouteNames.auctionDetail,
    builder: (context, state) => AppSystemBackScope(
      child: AuctionDetailScreen(auctionId: state.pathParameters['auctionId']!),
    ),
  ),
];
