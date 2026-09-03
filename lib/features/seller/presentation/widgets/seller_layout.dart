import 'package:flutter/material.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/account_access.dart';
import '../../../../core/auth/auth_providers.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_drawer_button.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../auth/presentation/screens/login_screen.dart';
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
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (!authState.isAuthenticated) {
      return const LoginScreen();
    }

    if (!authState.isSeller) {
      _redirectHome(context);
      return const AppScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (authState.isVerificationPending &&
        !_isAllowedWhilePending(selectedRoute)) {
      _redirectHome(context);
      return AppScaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Text(
              AccountAccess.pendingMessage,
              textAlign: TextAlign.center,
              style: AppTypography.body,
            ),
          ),
        ),
      );
    }

    // Product edit uses its own AppScaffold + AppTopBar (already includes theme).
    final ownsOwnAppBar = _ownsOwnAppBar(selectedRoute);
    final isDetail = _isDetailRoute(selectedRoute);

    return AppScaffold(
      drawer: SellerDrawer(selectedRoute: selectedRoute),
      backgroundColor: AppColors.bg(context),
      appBar: ownsOwnAppBar
          ? null
          : AppTopBar(
              title: _shellTitleFor(context, selectedRoute),
              leading: isDetail
                  ? BackButton(onPressed: () => context.goBack())
                  // AppDrawerButton uses its own context (under Scaffold).
                  // SellerLayout's context is an ancestor of the Scaffold and
                  // cannot open the drawer.
                  : const AppDrawerButton(),
              showDrawerButton: false,
              showCart: true,
              showWallet: true,
              showMessages: true,
              showThemeToggle: true,
              onSellerWalletTap: () =>
                  context.switchToRoute(AppRouteNames.sellerWallet),
              onSellerMessagesTap: () =>
                  context.switchToRoute(AppRouteNames.sellerChat),
            ),
      body: child,
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
