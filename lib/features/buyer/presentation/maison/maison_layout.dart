import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/theme_preference_provider.dart';
import '../../../../core/widgets/app_drawer_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/navigation/app_tab_top_bar.dart';
import '../../../../core/widgets/navigation/bottom_nav/app_bottom_nav_destinations.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../cart/application/cart_provider.dart';
import '../../../notifications/application/notifications_provider.dart';
import '../../../seller/presentation/atelier/atelier_components.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import '../widgets/buyer_drawer.dart';

/// Buyer account shell: quiet top bar, buyer drawer and the "back goes one
/// level up" rule. [detail] pages get Back. Bottom-nav tabs (Wishlist,
/// Profile) take the shared [AppTabTopBar] instead.
class MaisonLayout extends ConsumerWidget {
  const MaisonLayout({
    required this.child,
    this.detail = false,
    this.scrollsBehindDock = false,
    super.key,
  });

  final Widget child;
  final bool detail;

  /// [child] runs under the floating bottom dock and ends its own scroll
  /// with the bottom padding, instead of being inset above the dock.
  final bool scrollsBehindDock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(
      authProvider.select(
        (s) => (signedIn: s.isAuthenticated, pending: s.isVerificationPending),
      ),
    );
    if (!auth.signedIn) return const LoginScreen();

    final p = context.atelier;
    final location = GoRouterState.of(context).uri.path;
    final backFallback =
        AppNavigation.logicalParentOf(location) ?? AppRouteNames.home;
    void goBack() => context.goBack(fallbackLocation: backFallback);
    final isTab = AppBottomNav.isVisibleOn(location);

    return PopScope(
      canPop: GoRouter.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !context.mounted) return;
        goBack();
      },
      child: AppScaffold(
        drawer: const BuyerDrawer(),
        backgroundColor: p.canvas,
        safeBottom: !scrollsBehindDock,
        appBar: isTab
            ? const AppTabTopBar()
            : MaisonTopBar(
                location: location,
                showBack: detail,
                onBack: goBack,
                showWalletAction: detail && !auth.pending,
              ),
        body: child,
      ),
    );
  }
}

/// Quiet buyer bar: menu / back, notifications, bag, wallet (detail pages
/// only) and theme.
class MaisonTopBar extends ConsumerWidget implements PreferredSizeWidget {
  const MaisonTopBar({
    required this.location,
    required this.showBack,
    required this.onBack,
    this.showWalletAction = false,
    super.key,
  });

  final String location;
  final bool showBack;
  final VoidCallback onBack;
  final bool showWalletAction;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.atelier;
    final unread = ref.watch(notificationUnreadCountProvider);
    final bag = ref.watch(cartItemCountProvider);
    final dark = ref.watch(themePreferenceProvider);

    return Material(
      color: p.canvas,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                if (showBack)
                  AtelierIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    onPressed: onBack,
                    filled: true,
                  )
                else
                  Builder(
                    builder: (context) => AtelierIconButton(
                      icon: Icons.menu_rounded,
                      tooltip: context.tr(RemainingL10n.menu),
                      onPressed: () => openAppDrawer(context),
                      filled: true,
                    ),
                  ),
                const Spacer(),
                AtelierIconButton(
                  icon: unread > 0
                      ? Icons.notifications_rounded
                      : Icons.notifications_none_rounded,
                  tooltip: context.tr(NavL10n.notifications),
                  badgeCount: unread,
                  onPressed: location == AppRouteNames.buyerNotifications
                      ? null
                      : () => context.switchToRoute(
                          AppRouteNames.buyerNotifications,
                        ),
                ),
                AtelierIconButton(
                  icon: Icons.shopping_cart_outlined,
                  tooltip: context.tr(CoreL10n.cart),
                  badgeCount: bag,
                  onPressed: () => context.openRoute(AppRouteNames.cart),
                ),
                if (showWalletAction)
                  AtelierIconButton(
                    icon: Icons.account_balance_wallet_outlined,
                    tooltip: context.tr(CoreL10n.wallet),
                    onPressed: () =>
                        context.switchToRoute(AppRouteNames.buyerWallet),
                  ),
                AtelierIconButton(
                  icon: dark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  tooltip: context.tr(
                    dark
                        ? CoreL10n.switchToLightMode
                        : CoreL10n.switchToDarkMode,
                  ),
                  onPressed: () => ref
                      .read(palettePreferenceProvider.notifier)
                      .setDarkMode(!dark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
