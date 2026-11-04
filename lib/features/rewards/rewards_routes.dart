import 'package:go_router/go_router.dart';

import '../../core/auth/verified_account_gate.dart';
import '../../core/router/route_names.dart';
import '../buyer/presentation/maison/maison_layout.dart';
import 'presentation/screens/rewards_screen.dart';

/// Buyer reward points route.
final List<RouteBase> rewardsRoutes = [
  GoRoute(
    caseSensitive: false,
    path: AppRouteNames.buyerRewards,
    builder: (context, state) =>
        const MaisonLayout(child: VerifiedAccountGate(child: RewardsScreen())),
  ),
];
