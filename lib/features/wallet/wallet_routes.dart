import 'package:go_router/go_router.dart';

import '../../core/auth/verified_account_gate.dart';
import '../../core/router/route_names.dart';
import '../buyer/presentation/maison/maison_layout.dart';
import 'presentation/screens/wallet_screen.dart';

/// Buyer wallet route; the seller route puts the same [WalletScreen] in
/// the seller shell.
final List<RouteBase> walletRoutes = [
  GoRoute(
    path: AppRouteNames.buyerWallet,
    builder: (context, state) =>
        const MaisonLayout(child: VerifiedAccountGate(child: WalletScreen())),
  ),
];
