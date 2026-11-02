import 'package:flutter/material.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/account_access.dart';
import '../../../../core/auth/auth_providers.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/app_drawer_button.dart';
import '../../../../core/widgets/navigation/top_bar/section_top_bar.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../atelier/atelier_shell.dart';
import '../atelier/atelier_theme.dart';
import 'seller_drawer.dart';

/// Opens the side drawer from seller (or buyer-hosted shared) screens.
void openSellerDrawer([BuildContext? context]) {
  if (context != null) {
    openAppDrawer(context);
  }
}

/// Authenticated seller shell (drawer + shared section top bar).
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

  static const _pendingAllowedExact = <String>{
    AppRouteNames.sellerHelpCenter,
    AppRouteNames.sellerReferences,
    AppRouteNames.sellerInquiries,
    AppRouteNames.sellerNotifications,
    AppRouteNames.sellerSettings,
    AppRouteNames.sellerAbout,
    AppRouteNames.sellerPrivacy,
    AppRouteNames.sellerTerms,
    AppRouteNames.sellerPolicies,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (!authState.isAuthenticated) {
      return const LoginScreen();
    }

    if (!authState.isSeller) {
      _redirectHome(context);
      return AppScaffold(
        backgroundColor: context.atelier.canvas,
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (authState.isVerificationPending &&
        !_isAllowedWhilePending(selectedRoute)) {
      _redirectHome(context);
      final p = context.atelier;
      return AppScaffold(
        backgroundColor: p.canvas,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AtelierSpace.s24),
            child: Text(
              AccountAccess.pendingMessage,
              textAlign: TextAlign.center,
              style: AtelierType.body(p.inkSoft),
            ),
          ),
        ),
      );
    }

    // Product edit uses its own AppScaffold + AppTopBar.
    final ownsOwnAppBar = _ownsOwnAppBar(selectedRoute);
    final isDetail = _isDetailRoute(selectedRoute);
    final router = GoRouter.of(context);
    final canPop = router.canPop();
    final p = context.atelier;
    final width = MediaQuery.sizeOf(context).width;
    final destinations = sellerPrimaryDestinations(
      context,
      pending: authState.isVerificationPending,
    );
    // Compact widths reach every destination through the drawer.
    final useRail = width >= 1024 && !ownsOwnAppBar;

    Widget body = child;
    if (useRail) {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SellerRail(
            destinations: destinations,
            location: selectedRoute,
            extended: width >= 1320,
          ),
          Expanded(child: child),
        ],
      );
    }

    final backFallback = _backFallback(
      selectedRoute,
      pending: authState.isVerificationPending,
    );

    return PopScope(
      // Drawer / rail peers use `go` (no stack). With nothing to pop, back
      // goes one level up: detail → its list, any tool → dashboard,
      // dashboard → home. It never exits the app silently.
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (!context.mounted) return;
        context.goBack(fallbackLocation: backFallback);
      },
      child: AppScaffold(
        drawer: SellerDrawer(selectedRoute: selectedRoute),
        backgroundColor: p.canvas,
        appBar: ownsOwnAppBar
            ? null
            : SectionTopBar(
                location: selectedRoute,
                showBack: isDetail,
                onBack: () => context.goBack(fallbackLocation: backFallback),
                backgroundColor: p.canvas,
              ),
        body: body,
      ),
    );
  }

  static void _redirectHome(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      context.resetTo(AppRouteNames.home);
    });
  }

  /// Where back leads when there is no history to pop.
  static String _backFallback(String route, {required bool pending}) {
    final parent = AppNavigation.logicalParentOf(route);
    if (parent == null) return AppRouteNames.home;
    if (parent == AppRouteNames.sellerDashboard && pending) {
      return AppRouteNames.home;
    }
    return parent;
  }

  static bool _isAllowedWhilePending(String route) {
    if (route == AppRouteNames.sellerProfile ||
        route.startsWith('${AppRouteNames.sellerProfile}/')) {
      return true;
    }
    if (_pendingAllowedExact.contains(route)) return true;
    if (route.startsWith('${AppRouteNames.sellerPolicies}/')) return true;
    return route.startsWith('${AppRouteNames.sellerInquiries}/');
  }

  /// Nested screens that render their own [AppScaffold] app bar.
  static bool _ownsOwnAppBar(String route) => _isProductEditRoute(route);

  /// Stacked detail/flow routes (back button instead of drawer menu).
  static bool _isDetailRoute(String route) {
    if (route == AppRouteNames.sellerInquiryNew) return true;
    if (route == AppRouteNames.sellerAbout ||
        route == AppRouteNames.sellerPrivacy ||
        route == AppRouteNames.sellerTerms ||
        route == AppRouteNames.sellerPolicies ||
        route.startsWith('${AppRouteNames.sellerPolicies}/')) {
      return true;
    }
    if (_isProductEditRoute(route)) return true;
    return _isNestedUnder(route, AppRouteNames.sellerOrders) ||
        _isNestedUnder(route, AppRouteNames.sellerChat) ||
        (_isNestedUnder(route, AppRouteNames.sellerInquiries) &&
            route != AppRouteNames.sellerInquiryNew);
  }

  static bool _isProductEditRoute(String route) {
    return route.contains('/products/') && route.endsWith('/edit');
  }

  static bool _isNestedUnder(String route, String parent) {
    return route.startsWith('$parent/') && route != parent;
  }
}
