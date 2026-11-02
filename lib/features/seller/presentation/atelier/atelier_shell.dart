import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/app_drawer_button.dart';
import '../../../notifications/application/notifications_provider.dart';
import '../../application/seller_orders_provider.dart';
import 'atelier_components.dart';
import 'atelier_motion.dart';
import 'atelier_theme.dart';

/// One primary workspace destination (rail).
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
            const SizedBox(height: 14),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: extended ? 14 : 0),
              child: Row(
                mainAxisAlignment: extended
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  AtelierMonogram(name: company.isEmpty ? 'G W' : company),
                  if (extended) ...[
                    const SizedBox(width: 8),
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
            const SizedBox(height: 18),
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
            const SizedBox(height: 12),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
            padding: EdgeInsets.symmetric(horizontal: extended ? 10 : 0),
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
                  const SizedBox(width: 10),
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
