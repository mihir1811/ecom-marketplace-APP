import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/router/workspace_mode.dart';
import '../../../../core/theme/theme_preference_provider.dart';
import '../../../../core/widgets/app_drawer_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/navigation/workspace_switch.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../cart/application/cart_provider.dart';
import '../../../notifications/application/notifications_provider.dart';
import '../../../refunds/application/refund_providers.dart';
import '../../../seller/presentation/atelier/atelier_components.dart';
import '../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import '../../application/wishlist_provider.dart';
import '../widgets/buyer_drawer.dart';

/// One destination of the buyer account dock.
class MaisonDestination {
  const MaisonDestination({
    required this.route,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.requiresVerified = true,
  });

  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool requiresVerified;

  bool matches(String location) =>
      location == route || location.startsWith('$route/');
}

/// The four everyday account spaces a buyer moves between.
List<MaisonDestination> maisonDestinations(
  BuildContext context, {
  required bool verified,
}) {
  final all = [
    MaisonDestination(
      route: AppRouteNames.buyerOrders,
      label: context.tr(AccountCommerceL10n.orders),
      icon: Icons.local_mall_outlined,
      selectedIcon: Icons.local_mall_rounded,
    ),
    MaisonDestination(
      route: AppRouteNames.buyerRefunds,
      label: context.tr(AccountCommerceL10n.refunds),
      icon: Icons.replay_rounded,
      selectedIcon: Icons.replay_circle_filled_rounded,
    ),
    MaisonDestination(
      route: AppRouteNames.buyerWallet,
      label: context.tr(CoreL10n.wallet),
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet_rounded,
    ),
    const MaisonDestination(
      route: AppRouteNames.buyerWishlist,
      label: 'Wishlist',
      icon: Icons.favorite_border_rounded,
      selectedIcon: Icons.favorite_rounded,
      requiresVerified: false,
    ),
  ];
  return [
    for (final d in all)
      if (verified || !d.requiresVerified) d,
  ];
}

/// Buyer account shell for Orders, Refunds, Wallet and Wishlist: quiet top
/// bar, floating dock between the four spaces, buyer drawer and the
/// "back goes one level up" rule. [detail] pages get Back and no dock.
class MaisonLayout extends ConsumerWidget {
  const MaisonLayout({required this.child, this.detail = false, super.key});

  final Widget child;
  final bool detail;

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
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final destinations = maisonDestinations(context, verified: !auth.pending);
    final showDock = !detail && !keyboardOpen && destinations.length >= 2;

    return PopScope(
      canPop: GoRouter.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !context.mounted) return;
        goBack();
      },
      child: AppScaffold(
        drawer: const BuyerDrawer(),
        backgroundColor: p.canvas,
        appBar: MaisonTopBar(
          location: location,
          showBack: detail,
          onBack: goBack,
          showWalletAction: detail && !auth.pending,
        ),
        bottomNavigationBar: showDock
            ? MaisonDock(destinations: destinations, location: location)
            : null,
        body: child,
      ),
    );
  }
}

/// Quiet buyer bar: menu / back, the Seller switch on top-level pages,
/// notifications, bag, wallet (detail pages only) and theme.
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
    final isSeller = ref.watch(authProvider.select((s) => s.isSeller));
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
                if (isSeller && !showBack)
                  const WorkspaceSwitchPill(target: AppWorkspace.seller),
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
                  icon: Icons.shopping_bag_outlined,
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
                      .read(themePreferenceProvider.notifier)
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

/// Floating glass dock: every label stays visible and one ink capsule
/// glides to the current space. Badges show refunds in review and the
/// wishlist size.
class MaisonDock extends ConsumerWidget {
  const MaisonDock({
    required this.destinations,
    required this.location,
    super.key,
  });

  final List<MaisonDestination> destinations;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.atelier;
    final selected = destinations.indexWhere((d) => d.matches(location));
    final saved = ref.watch(wishlistCountProvider);
    final showsRefunds = destinations.any(
      (d) => d.route == AppRouteNames.buyerRefunds,
    );
    final inReview = showsRefunds
        ? ref.watch(
            buyerRefundListProvider.select(
              (s) => s.items.where((r) => r.status.isPending).length,
            ),
          )
        : 0;

    int badgeFor(MaisonDestination d) => switch (d.route) {
      AppRouteNames.buyerRefunds => inReview,
      AppRouteNames.buyerWishlist => saved,
      _ => 0,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AtelierRadius.pill),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                height: 66,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: (p.isDark ? p.raised : p.surface).withValues(
                    alpha: 0.9,
                  ),
                  borderRadius: BorderRadius.circular(AtelierRadius.pill),
                  border: Border.all(color: p.hairline),
                  boxShadow: p.floatShadow,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth / destinations.length;
                    return Stack(
                      children: [
                        if (selected >= 0)
                          AnimatedPositioned(
                            duration: AtelierMotion.slow,
                            curve: AtelierMotion.settle,
                            left: w * selected,
                            top: 0,
                            bottom: 0,
                            width: w,
                            child: Container(
                              decoration: BoxDecoration(
                                color: p.ink,
                                borderRadius: BorderRadius.circular(
                                  AtelierRadius.pill,
                                ),
                              ),
                            ),
                          ),
                        Row(
                          children: [
                            for (var i = 0; i < destinations.length; i++)
                              Expanded(
                                child: _DockItem(
                                  destination: destinations[i],
                                  selected: i == selected,
                                  badge: badgeFor(destinations[i]),
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.destination,
    required this.selected,
    required this.badge,
  });

  final MaisonDestination destination;
  final bool selected;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final color = selected ? p.canvas : p.inkSoft;
    return Semantics(
      selected: selected,
      child: Pressable(
        onTap: selected
            ? null
            : () {
                AppHaptics.selection();
                context.switchToRoute(destination.route);
              },
        haptic: false,
        semanticLabel: badge > 0
            ? '${destination.label}, $badge'
            : destination.label,
        borderRadius: BorderRadius.circular(AtelierRadius.pill),
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedSwitcher(
                    duration: AtelierMotion.base,
                    transitionBuilder: (c, a) => ScaleTransition(
                      scale: CurvedAnimation(
                        parent: a,
                        curve: AtelierMotion.settle,
                      ),
                      child: c,
                    ),
                    child: Icon(
                      selected ? destination.selectedIcon : destination.icon,
                      key: ValueKey(selected),
                      size: 20,
                      color: selected ? p.gold : color,
                    ),
                  ),
                  if (badge > 0)
                    Positioned(
                      top: -6,
                      right: -12,
                      child: CountBubble(count: badge),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: AtelierMotion.base,
                style: AtelierType.label(color, size: 11),
                child: Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
