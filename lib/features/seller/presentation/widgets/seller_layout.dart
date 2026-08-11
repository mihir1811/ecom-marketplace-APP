import 'package:flutter/material.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import 'seller_drawer.dart';

/// Shared scaffold key so any seller-section screen can open the drawer.
final GlobalKey<ScaffoldState> sellerScaffoldKey = GlobalKey<ScaffoldState>();

/// Opens the side drawer from seller (or buyer-hosted shared) screens.
void openSellerDrawer([BuildContext? context]) {
  final sellerState = sellerScaffoldKey.currentState;
  if (sellerState != null) {
    sellerState.openDrawer();
    return;
  }
  if (context != null) {
    Scaffold.maybeOf(context)?.openDrawer();
  }
}

/// Authenticated seller shell (drawer available on all seller routes).
///
/// Non-sellers are redirected home — dashboard and seller chat stay seller-only.
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

    if (!authState.isSeller) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.go(AppRouteNames.home);
      });
      return const AppScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AppScaffold(
      scaffoldKey: sellerScaffoldKey,
      drawer: SellerDrawer(selectedRoute: selectedRoute),
      body: child,
    );
  }
}
