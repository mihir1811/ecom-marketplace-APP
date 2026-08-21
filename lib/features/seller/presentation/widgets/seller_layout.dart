import 'package:flutter/material.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/account_access.dart';
import '../../../../core/auth/auth_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_preference_provider.dart';
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
        context.go(AppRouteNames.home);
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
    final dark =
        ref.watch(themePreferenceProvider) && _isDarkRoute(selectedRoute);
    final theme = dark ? AppTheme.dark : AppTheme.light;

    return Theme(
      data: theme,
      child: AppScaffold(
        scaffoldKey: sellerScaffoldKey,
        drawer: SellerDrawer(selectedRoute: selectedRoute),
        appBar: shellTitle == null
            ? null
            : AppBar(
                backgroundColor: AppColors.bg(context),
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  tooltip: 'Menu',
                  icon: const Icon(Icons.menu),
                  onPressed: () => openSellerDrawer(context),
                ),
                title: Text(
                  shellTitle,
                  style: AppTypography.title.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
        body: child,
      ),
    );
  }

  /// Seller workspace routes that opt into the dark theme. The shared shell
  /// switches to [AppTheme.dark] only on these (/sub-routes); every other
  /// seller page keeps the light theme.
  static const _darkRoutes = <String>[
    AppRouteNames.sellerWallet,
    AppRouteNames.sellerOrders,
    AppRouteNames.sellerProfile,
  ];

  static bool _isDarkRoute(String route) {
    return _darkRoutes.any((r) => route == r || route.startsWith('$r/'));
  }

  static String? _shellTitleFor(String route) {
    if (route == AppRouteNames.sellerHelpCenter) return 'Help center';
    if (route == AppRouteNames.sellerInquiries) return 'Inquiries';
    return null;
  }
}
