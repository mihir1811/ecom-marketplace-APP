import 'package:flutter/material.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

    final shellTitle = _shellTitleFor(selectedRoute);

    return AppScaffold(
      drawer: SellerDrawer(selectedRoute: selectedRoute),
      backgroundColor: AppColors.bg(context),
      appBar: shellTitle == null
          ? null
          : AppTopBar(
              title: shellTitle,
              leading: IconButton(
                tooltip: 'Menu',
                icon: const Icon(Icons.menu),
                onPressed: () => openSellerDrawer(context),
              ),
              showDrawerButton: false,
              showCart: true,
              showWallet: true,
              showMessages: true,
              showThemeToggle: true,
              onSellerWalletTap: () => context.push(AppRouteNames.sellerWallet),
              onSellerMessagesTap: () => context.push(AppRouteNames.sellerChat),
            ),
      body: child,
    );
  }

  static String? _shellTitleFor(String route) {
    if (route == AppRouteNames.sellerHelpCenter) return 'Help center';
    if (route == AppRouteNames.sellerInquiries) return 'Inquiries';
    return null;
  }
}
