import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/router/workspace_mode.dart';
import '../../../../core/theme/theme_preference_provider.dart';
import '../../../../core/widgets/app_drawer_button.dart';
import '../../../../core/widgets/navigation/workspace_switch.dart';
import '../../../chat/application/chat_providers.dart';
import '../../../notifications/application/notifications_provider.dart';
import '../../application/seller_orders_provider.dart';
import 'atelier_components.dart';
import 'atelier_motion.dart';
import 'atelier_theme.dart';

/// One primary workspace destination (dock / rail).
class SellerDestination {
  const SellerDestination({
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

/// The five daily destinations; everything else lives in the drawer.
List<SellerDestination> sellerPrimaryDestinations(
  BuildContext context, {
  required bool pending,
}) {
  final all = [
    SellerDestination(
      route: AppRouteNames.sellerDashboard,
      label: context.tr(RemainingL10n.dashboard),
      icon: Icons.space_dashboard_outlined,
      selectedIcon: Icons.space_dashboard_rounded,
    ),
    SellerDestination(
      route: AppRouteNames.sellerProducts,
      label: context.tr(RemainingL10n.products),
      icon: Icons.diamond_outlined,
      selectedIcon: Icons.diamond_rounded,
    ),
    SellerDestination(
      route: AppRouteNames.sellerOrders,
      label: context.tr(RemainingL10n.orders),
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
    ),
    SellerDestination(
      route: AppRouteNames.sellerWallet,
      label: context.tr(RemainingL10n.wallet),
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet_rounded,
    ),
    SellerDestination(
      route: AppRouteNames.sellerInquiries,
      label: context.tr(RemainingL10n.inquiries),
      icon: Icons.forum_outlined,
      selectedIcon: Icons.forum_rounded,
      requiresVerified: false,
    ),
  ];
  return [
    for (final d in all)
      if (!pending || !d.requiresVerified) d,
  ];
}

/// Pending-approval badge for the Orders destination.
int _pendingOrders(WidgetRef ref) {
  final pending = ref.watch(sellerPendingOrdersProvider);
  return pending.asData?.value.total ?? 0;
}

/// Workspace app bar: menu / back, quiet circular actions, and the
/// "⇄ Buyer" switch on every top-level page. No page title — the dock,
/// rail and drawer already mark where the user is.
class AtelierTopBar extends ConsumerWidget implements PreferredSizeWidget {
  const AtelierTopBar({
    required this.showBack,
    required this.onBack,
    required this.location,
    this.showWalletAction = false,
    super.key,
  });

  final String location;
  final bool showBack;
  final VoidCallback onBack;

  /// Wallet lives in the dock/rail; the bar only shows it when neither is up.
  final bool showWalletAction;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.atelier;
    final unread = ref.watch(notificationUnreadCountProvider);
    final chatUnread = ref.watch(chatHasUnreadProvider);
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
                // Same slot as the buyer bars: first trailing control.
                if (!showBack)
                  const WorkspaceSwitchPill(target: AppWorkspace.buyer),
                AtelierIconButton(
                  icon: unread > 0
                      ? Icons.notifications_rounded
                      : Icons.notifications_none_rounded,
                  tooltip: 'Notifications',
                  badgeCount: unread,
                  onPressed: location == AppRouteNames.sellerNotifications
                      ? null
                      : () => context.switchToRoute(
                          AppRouteNames.sellerNotifications,
                        ),
                ),
                AtelierIconButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  tooltip: context.tr(CoreL10n.messages),
                  dot: chatUnread,
                  onPressed: () =>
                      context.switchToRoute(AppRouteNames.sellerChat),
                ),
                if (showWalletAction)
                  AtelierIconButton(
                    icon: Icons.account_balance_wallet_outlined,
                    tooltip: context.tr(CoreL10n.wallet),
                    onPressed: () =>
                        context.switchToRoute(AppRouteNames.sellerWallet),
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

/// Floating glass dock for compact widths.
class SellerDock extends ConsumerWidget {
  const SellerDock({
    required this.destinations,
    required this.location,
    super.key,
  });

  final List<SellerDestination> destinations;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.atelier;
    final pendingOrders = _pendingOrders(ref);
    final selected = destinations.indexWhere((d) => d.matches(location));

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AtelierRadius.pill),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  height: 64,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: (p.isDark ? p.raised : p.surface).withValues(
                      alpha: 0.88,
                    ),
                    borderRadius: BorderRadius.circular(AtelierRadius.pill),
                    border: Border.all(color: p.hairline),
                    boxShadow: p.floatShadow,
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < destinations.length; i++)
                        Expanded(
                          flex: i == selected ? 7 : 4,
                          child: _DockItem(
                            destination: destinations[i],
                            selected: i == selected,
                            badge:
                                destinations[i].route ==
                                    AppRouteNames.sellerOrders
                                ? pendingOrders
                                : 0,
                          ),
                        ),
                    ],
                  ),
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

  final SellerDestination destination;
  final bool selected;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
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
        semanticLabel: destination.label,
        borderRadius: BorderRadius.circular(AtelierRadius.pill),
        child: AnimatedContainer(
          duration: AtelierMotion.slow,
          curve: AtelierMotion.emphasized,
          height: double.infinity,
          decoration: BoxDecoration(
            color: selected ? p.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(AtelierRadius.pill),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedSwitcher(
                    duration: AtelierMotion.base,
                    child: Icon(
                      selected ? destination.selectedIcon : destination.icon,
                      key: ValueKey(selected),
                      size: 21,
                      color: selected ? p.canvas : p.inkSoft,
                    ),
                  ),
                  if (badge > 0)
                    Positioned(
                      top: -7,
                      right: -10,
                      child: CountBubble(count: badge),
                    ),
                ],
              ),
              Flexible(
                child: AnimatedSize(
                  duration: AtelierMotion.slow,
                  curve: AtelierMotion.emphasized,
                  child: selected
                      ? Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            destination.label,
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: AtelierType.label(p.canvas, size: 12.5),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Persistent navigation rail for tablet / desktop widths.
class SellerRail extends ConsumerWidget {
  const SellerRail({
    required this.destinations,
    required this.location,
    required this.extended,
    super.key,
  });

  final List<SellerDestination> destinations;
  final String location;
  final bool extended;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.atelier;
    final pendingOrders = _pendingOrders(ref);
    final unread = ref.watch(notificationUnreadCountProvider);
    final company = ref.watch(
      authProvider.select(
        (s) => s.user?.sellerAccount?.companyName ?? s.user?.fullName ?? '',
      ),
    );
    final items = [
      ...destinations,
      const SellerDestination(
        route: AppRouteNames.sellerNotifications,
        label: 'Notifications',
        icon: Icons.notifications_none_rounded,
        selectedIcon: Icons.notifications_rounded,
        requiresVerified: false,
      ),
    ];

    return AnimatedContainer(
      duration: AtelierMotion.slow,
      curve: AtelierMotion.emphasized,
      width: extended ? 248 : 88,
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(right: BorderSide(color: p.hairline)),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: extended ? 22 : 0),
              child: Row(
                mainAxisAlignment: extended
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  AtelierMonogram(name: company.isEmpty ? 'G W' : company),
                  if (extended) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ATELIER', style: AtelierType.overline(p.gold)),
                          const SizedBox(height: 2),
                          Text(
                            company.isEmpty ? 'GemWorld' : company,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AtelierType.title(p.ink, size: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),
            for (var i = 0; i < items.length; i++)
              Reveal(
                index: i,
                horizontal: true,
                offset: -10,
                child: _RailItem(
                  destination: items[i],
                  selected: items[i].matches(location),
                  extended: extended,
                  badge: items[i].route == AppRouteNames.sellerOrders
                      ? pendingOrders
                      : items[i].route == AppRouteNames.sellerNotifications
                      ? unread
                      : 0,
                ),
              ),
            const Spacer(),
            Builder(
              builder: (context) => _RailItem(
                destination: const SellerDestination(
                  route: '',
                  label: 'All tools',
                  icon: Icons.apps_rounded,
                  selectedIcon: Icons.apps_rounded,
                ),
                selected: false,
                extended: extended,
                badge: 0,
                onTap: () => openAppDrawer(context),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.destination,
    required this.selected,
    required this.extended,
    required this.badge,
    this.onTap,
  });

  final SellerDestination destination;
  final bool selected;
  final bool extended;
  final int badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final icon = Icon(
      selected ? destination.selectedIcon : destination.icon,
      size: 21,
      color: selected ? p.gold : p.inkSoft,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Tooltip(
        message: extended ? '' : destination.label,
        child: Pressable(
          onTap:
              onTap ??
              (selected
                  ? null
                  : () => context.switchToRoute(destination.route)),
          semanticLabel: destination.label,
          child: AnimatedContainer(
            duration: AtelierMotion.base,
            curve: AtelierMotion.emphasized,
            height: 48,
            padding: EdgeInsets.symmetric(horizontal: extended ? 14 : 0),
            decoration: BoxDecoration(
              color: selected ? p.goldSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(AtelierRadius.md),
            ),
            child: Row(
              mainAxisAlignment: extended
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    icon,
                    if (badge > 0 && !extended)
                      Positioned(
                        top: -8,
                        right: -12,
                        child: CountBubble(count: badge),
                      ),
                  ],
                ),
                if (extended) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      destination.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtelierType.label(
                        selected ? p.ink : p.inkSoft,
                        size: 13.5,
                      ),
                    ),
                  ),
                  if (badge > 0) CountBubble(count: badge),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
