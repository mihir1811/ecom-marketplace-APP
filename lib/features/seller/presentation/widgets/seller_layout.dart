import 'package:flutter/material.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import 'seller_drawer.dart';

/// Shared scaffold key so any seller-section screen can open the drawer.
final GlobalKey<ScaffoldState> sellerScaffoldKey = GlobalKey<ScaffoldState>();

/// Opens the seller side drawer from anywhere inside the seller shell.
void openSellerDrawer([BuildContext? context]) {
  final state = sellerScaffoldKey.currentState;
  if (state != null) {
    state.openDrawer();
    return;
  }
  if (context != null) {
    Scaffold.maybeOf(context)?.openDrawer();
  }
}

/// Authenticated seller/user shell (drawer available on all seller routes).
class SellerLayout extends ConsumerWidget {
  const SellerLayout({
    super.key,
    required this.child,
    required this.selectedRoute,
  });

  final Widget child;
  final String selectedRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (!authState.isAuthenticated) {
      return const LoginScreen();
    }

    return AppScaffold(
      scaffoldKey: sellerScaffoldKey,
      drawer: SellerDrawer(selectedRoute: selectedRoute),
      body: child,
    );
  }
}
