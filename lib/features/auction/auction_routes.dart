import 'package:go_router/go_router.dart';

import '../../core/auth/verified_account_gate.dart';
import '../../core/router/route_names.dart';
import 'application/auction_providers.dart';
import 'presentation/screens/auction_detail_screen.dart';
import 'presentation/screens/auctions_list_screen.dart';

final List<RouteBase> auctionRoutes = [
  GoRoute(
    path: AppRouteNames.auctions,
    builder: (context, state) => const AuctionsListScreen(
      kind: AuctionFeedKind.live,
      title: 'Auctions',
    ),
  ),
  GoRoute(
    path: AppRouteNames.auctionActivity,
    builder: (context, state) => const VerifiedAccountGate(
      child: AuctionsListScreen(
        kind: AuctionFeedKind.activity,
        title: 'My bids',
        outcomes: ['all', 'participating', 'won', 'lost'],
      ),
    ),
  ),
  GoRoute(
    path: AppRouteNames.auctionWins,
    builder: (context, state) => const VerifiedAccountGate(
      child: AuctionsListScreen(
        kind: AuctionFeedKind.wins,
        title: 'My wins',
      ),
    ),
  ),
  GoRoute(
    path: AppRouteNames.auctionDetail,
    builder: (context, state) => AuctionDetailScreen(
      auctionId: state.pathParameters['auctionId']!,
    ),
  ),
];
