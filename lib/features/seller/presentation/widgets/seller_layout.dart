import 'package:flutter/material.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/account_access.dart';
import '../../../../core/auth/auth_providers.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/app_drawer_button.dart';
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

/// Authenticated seller shell (drawer + theme toggle on every seller route).
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
    AppRouteNames.sellerLoginHistory,
    AppRouteNames.sellerInquiries,
    AppRouteNames.sellerNotifications,
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

    // Product edit uses its own AppScaffold + AppTopBar (already includes theme).
    final ownsOwnAppBar = _ownsOwnAppBar(selectedRoute);
    final isDetail = _isDetailRoute(selectedRoute);
    final router = GoRouter.of(context);
    final canPop = router.canPop();
    final p = context.atelier;
    final width = MediaQuery.sizeOf(context).width;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final destinations = sellerPrimaryDestinations(
      context,
      pending: authState.isVerificationPending,
    );
    final useRail = width >= 1024 && !ownsOwnAppBar;
    final useDock =
        !useRail && !isDetail && !keyboardOpen && destinations.length >= 3;

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

    return PopScope(
      // Drawer peers use `go` (no stack). Intercept system back so the app
      // returns home (or confirms exit on a terminal route) instead of
      // exiting silently.
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (!context.mounted) return;
        context.goBack();
      },
      child: AppScaffold(
        drawer: SellerDrawer(selectedRoute: selectedRoute),
        backgroundColor: p.canvas,
        appBar: ownsOwnAppBar
            ? null
            : AtelierTopBar(
                title: _shellTitleFor(context, selectedRoute),
                location: selectedRoute,
                showBack: isDetail,
                onBack: () => context.goBack(),
                // Wallet is a dock / rail destination; keep it reachable
                // from the bar wherever neither is shown.
                showWalletAction:
                    !useRail && !useDock && !authState.isVerificationPending,
              ),
        bottomNavigationBar: useDock
            ? SellerDock(destinations: destinations, location: selectedRoute)
            : null,
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

  static bool _isAllowedWhilePending(String route) {
    if (route == AppRouteNames.sellerProfile ||
        route.startsWith('${AppRouteNames.sellerProfile}/')) {
      return true;
    }
    if (_pendingAllowedExact.contains(route)) return true;
    return route.startsWith('${AppRouteNames.sellerInquiries}/');
  }

  /// Nested screens that render their own [AppScaffold] app bar.
  static bool _ownsOwnAppBar(String route) => _isProductEditRoute(route);

  /// Stacked detail/flow routes (back button instead of drawer menu).
  static bool _isDetailRoute(String route) {
    if (route == AppRouteNames.sellerInquiryNew) return true;
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

  static String _shellTitleFor(BuildContext context, String route) {
    const exactTitles = <String, String>{
      AppRouteNames.sellerDashboard: RemainingL10n.dashboard,
      AppRouteNames.sellerProducts: RemainingL10n.products,
      AppRouteNames.sellerOrders: RemainingL10n.orders,
      AppRouteNames.sellerWallet: RemainingL10n.wallet,
      AppRouteNames.sellerInquiries: RemainingL10n.inquiries,
      AppRouteNames.sellerInquiryNew: RemainingL10n.productInquiry,
      AppRouteNames.sellerOffers: RemainingL10n.offers,
      AppRouteNames.sellerAuctions: RemainingL10n.myAuctions,
      AppRouteNames.sellerAnalytics: RemainingL10n.analytics,
      AppRouteNames.sellerChat: CoreL10n.messages,
      AppRouteNames.sellerHelpCenter: RemainingL10n.helpCenter,
      AppRouteNames.sellerReferences: RemainingL10n.references,
      AppRouteNames.sellerPromotions: RemainingL10n.promotions,
      AppRouteNames.sellerProfile: RemainingL10n.profile,
      AppRouteNames.sellerLoginHistory: RemainingL10n.loginHistory,
      AppRouteNames.sellerApiKeys: RemainingL10n.apiKeys,
    };

    final exactKey = exactTitles[route];
    if (exactKey != null) return context.tr(exactKey);

    if (_isNestedUnder(route, AppRouteNames.sellerInquiries)) {
      return context.tr(RemainingL10n.inquiryDetails);
    }
    if (_isNestedUnder(route, AppRouteNames.sellerChat)) {
      return context.tr(RemainingL10n.chat);
    }
    if (_isNestedUnder(route, AppRouteNames.sellerOrders)) {
      return context.tr(AccountCommerceL10n.orderDetails);
    }
    if (_isProductEditRoute(route)) {
      return context.tr(RemainingL10n.editProduct);
    }
    return context.tr(CatalogL10n.seller);
  }
}
