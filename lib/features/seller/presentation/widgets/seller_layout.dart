import 'package:flutter/material.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/account_access.dart';
import '../../../../core/auth/auth_providers.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (!authState.isAuthenticated) {
      return const LoginScreen();
    }

    if (!authState.isSeller) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.resetTo(AppRouteNames.home);
      });
      return const AppScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final onOwnProfile =
        selectedRoute == AppRouteNames.sellerProfile ||
        selectedRoute.startsWith('${AppRouteNames.sellerProfile}/');
    final allowedWhenPending =
        onOwnProfile ||
        selectedRoute == AppRouteNames.sellerHelpCenter ||
        selectedRoute == AppRouteNames.sellerReferences ||
        selectedRoute == AppRouteNames.sellerLoginHistory ||
        selectedRoute == AppRouteNames.sellerInquiries ||
        selectedRoute.startsWith('${AppRouteNames.sellerInquiries}/');
    if (authState.isVerificationPending && !allowedWhenPending) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.resetTo(AppRouteNames.home);
      });
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
    final title = _shellTitleFor(selectedRoute);

    return AppScaffold(
      drawer: SellerDrawer(selectedRoute: selectedRoute),
      backgroundColor: AppColors.bg(context),
      appBar: ownsOwnAppBar
          ? null
          : AppTopBar(
              title: title,
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

  /// Nested screens that render their own [AppScaffold] app bar.
  static bool _ownsOwnAppBar(String route) {
    return route.contains('/products/') && route.endsWith('/edit');
  }

  /// Stacked detail/flow routes (back button instead of drawer menu).
  static bool _isDetailRoute(String route) {
    if (route == AppRouteNames.sellerInquiryNew) return true;
    if (route.startsWith('${AppRouteNames.sellerOrders}/') &&
        route != AppRouteNames.sellerOrders) {
      return true;
    }
    if (route.startsWith('${AppRouteNames.sellerChat}/') &&
        route != AppRouteNames.sellerChat) {
      return true;
    }
    if (route.startsWith('${AppRouteNames.sellerInquiries}/') &&
        route != AppRouteNames.sellerInquiries &&
        route != AppRouteNames.sellerInquiryNew) {
      return true;
    }
    if (route.contains('/products/') && route.endsWith('/edit')) return true;
    return false;
  }

  static String _shellTitleFor(String route) {
    if (route == AppRouteNames.sellerDashboard) return 'Dashboard';
    if (route == AppRouteNames.sellerProducts) return 'Products';
    if (route == AppRouteNames.sellerOrders) return 'Orders';
    if (route == AppRouteNames.sellerWallet) return 'Wallet';
    if (route == AppRouteNames.sellerInquiries) return 'Inquiries';
    if (route == AppRouteNames.sellerInquiryNew) return 'Product inquiry';
    if (route.startsWith('${AppRouteNames.sellerInquiries}/')) {
      return 'Inquiry details';
    }
    if (route == AppRouteNames.sellerOffers) return 'Offers';
    if (route == AppRouteNames.sellerAuctions) return 'My Auctions';
    if (route == AppRouteNames.sellerAnalytics) return 'Analytics';
    if (route == AppRouteNames.sellerChat) return 'Messages';
    if (route.startsWith('${AppRouteNames.sellerChat}/')) return 'Chat';
    if (route == AppRouteNames.sellerHelpCenter) return 'Help center';
    if (route == AppRouteNames.sellerReferences) return 'References';
    if (route == AppRouteNames.sellerPromotions) return 'Promotions';
    if (route == AppRouteNames.sellerProfile) return 'Profile';
    if (route == AppRouteNames.sellerLoginHistory) return 'Login history';
    if (route == AppRouteNames.sellerApiKeys) return 'API keys';
    if (route.startsWith('${AppRouteNames.sellerOrders}/')) {
      return 'Order details';
    }
    if (route.contains('/products/') && route.endsWith('/edit')) {
      return 'Edit product';
    }
    return 'Seller';
  }
}
