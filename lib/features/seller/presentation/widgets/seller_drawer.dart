import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/auth/confirm_sign_out.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../notifications/application/notifications_provider.dart';
import '../atelier/atelier_components.dart';
import '../atelier/atelier_motion.dart';
import '../atelier/atelier_theme.dart';

/// Side drawer for seller workspace screens only: every seller tool,
/// grouped by intent, with the current page highlighted.
class SellerDrawer extends ConsumerWidget {
  const SellerDrawer({super.key, required this.selectedRoute});

  final String selectedRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.atelier;
    final pending = ref.watch(
      authProvider.select((s) => s.isVerificationPending),
    );
    final unread = ref.watch(notificationUnreadCountProvider);
    final user = ref.watch(authProvider.select((s) => s.user));
    final company = user?.sellerAccount?.companyName?.trim();
    final displayName = (company != null && company.isNotEmpty)
        ? company
        : (user?.fullName.trim().isNotEmpty == true
              ? user!.fullName
              : 'Seller');

    final groups = <(String, List<_DrawerItem>)>[
      (
        'Workspace',
        [
          _DrawerItem(
            route: AppRouteNames.sellerDashboard,
            label: context.tr(RemainingL10n.dashboard),
            icon: Icons.space_dashboard_outlined,
            requiresVerified: true,
          ),
          _DrawerItem(
            route: AppRouteNames.sellerProducts,
            label: context.tr(RemainingL10n.products),
            icon: Icons.diamond_outlined,
            requiresVerified: true,
          ),
          _DrawerItem(
            route: AppRouteNames.sellerOrders,
            label: context.tr(RemainingL10n.orders),
            icon: Icons.receipt_long_outlined,
            requiresVerified: true,
          ),
          _DrawerItem(
            route: AppRouteNames.sellerWallet,
            label: context.tr(RemainingL10n.wallet),
            icon: Icons.account_balance_wallet_outlined,
            requiresVerified: true,
          ),
          _DrawerItem(
            route: AppRouteNames.sellerInquiries,
            label: context.tr(RemainingL10n.inquiries),
            icon: Icons.forum_outlined,
          ),
          _DrawerItem(
            route: AppRouteNames.sellerNotifications,
            label: 'Notifications',
            icon: Icons.notifications_none_rounded,
            badge: unread,
          ),
        ],
      ),
      (
        'Grow',
        [
          _DrawerItem(
            route: AppRouteNames.sellerOffers,
            label: context.tr(RemainingL10n.offers),
            icon: Icons.local_offer_outlined,
            requiresVerified: true,
          ),
          _DrawerItem(
            route: AppRouteNames.sellerAuctions,
            label: context.tr(RemainingL10n.auctions),
            icon: Icons.gavel_outlined,
            requiresVerified: true,
          ),
          _DrawerItem(
            route: AppRouteNames.sellerAnalytics,
            label: context.tr(RemainingL10n.analytics),
            icon: Icons.insights_outlined,
            requiresVerified: true,
          ),
          _DrawerItem(
            route: AppRouteNames.sellerPromotions,
            label: context.tr(RemainingL10n.promotions),
            icon: Icons.card_giftcard_outlined,
            requiresVerified: true,
          ),
          _DrawerItem(
            route: AppRouteNames.sellerReferences,
            label: context.tr(RemainingL10n.references),
            icon: Icons.diversity_3_outlined,
          ),
        ],
      ),
      (
        'Conversations',
        [
          _DrawerItem(
            route: AppRouteNames.sellerChat,
            label: context.tr(RemainingL10n.chat),
            icon: Icons.chat_bubble_outline_rounded,
            requiresVerified: true,
          ),
          _DrawerItem(
            route: AppRouteNames.sellerHelpCenter,
            label: context.tr(RemainingL10n.helpCenter),
            icon: Icons.support_agent_outlined,
          ),
        ],
      ),
      (
        'Account',
        [
          _DrawerItem(
            route: AppRouteNames.sellerProfile,
            label: context.tr(RemainingL10n.profile),
            icon: Icons.person_outline_rounded,
          ),
          _DrawerItem(
            route: AppRouteNames.sellerLoginHistory,
            label: context.tr(RemainingL10n.loginHistory),
            icon: Icons.devices_outlined,
          ),
          _DrawerItem(
            route: AppRouteNames.sellerApiKeys,
            label: context.tr(RemainingL10n.apiKeys),
            icon: Icons.vpn_key_outlined,
            requiresVerified: true,
          ),
        ],
      ),
    ];

    var index = 0;
    return Drawer(
      width: 300,
      backgroundColor: p.raised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          right: Radius.circular(AtelierRadius.xl),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 10, 18),
              child: Row(
                children: [
                  AtelierMonogram(name: displayName, size: 44),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context
                              .tr(RemainingL10n.sellerWorkspace)
                              .toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AtelierType.overline(p.gold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AtelierType.display(p.ink, size: 21),
                        ),
                      ],
                    ),
                  ),
                  AtelierIconButton(
                    icon: Icons.close_rounded,
                    tooltip: context.tr(RemainingL10n.close),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
            if (pending)
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 0, 18, 12),
                child: AtelierPill(
                  label: 'Verification pending — some tools are locked',
                  tone: AtelierTone.amber,
                  icon: Icons.lock_clock_outlined,
                ),
              ),
            const AtelierHairline(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                children: [
                  for (final (title, items) in groups) ...[
                    if (items.any((i) => !pending || !i.requiresVerified)) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                        child: Text(
                          title.toUpperCase(),
                          style: AtelierType.overline(p.muted),
                        ),
                      ),
                      for (final item in items)
                        if (!pending || !item.requiresVerified)
                          Reveal(
                            index: index++,
                            horizontal: true,
                            offset: -12,
                            child: _DrawerTile(
                              item: item,
                              selected:
                                  selectedRoute == item.route ||
                                  selectedRoute.startsWith('${item.route}/'),
                              onTap: () => _go(context, item.route),
                            ),
                          ),
                    ],
                  ],
                ],
              ),
            ),
            const AtelierHairline(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: AtelierButton(
                      label: context.tr(RemainingL10n.backToShop),
                      icon: Icons.storefront_outlined,
                      variant: AtelierButtonVariant.secondary,
                      compact: true,
                      onPressed: () => _goHome(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AtelierButton(
                      label: context.tr(AccountCommerceL10n.signOut),
                      icon: Icons.logout_rounded,
                      variant: AtelierButtonVariant.danger,
                      compact: true,
                      onPressed: () async {
                        final confirmed = await confirmSignOut(context);
                        if (!confirmed || !context.mounted) return;
                        await Navigator.of(context).maybePop();
                        if (!context.mounted) return;
                        ref.read(authProvider.notifier).logout();
                        context.resetTo(AppRouteNames.home);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _go(BuildContext context, String route) async {
    await Navigator.of(context).maybePop();
    if (!context.mounted) return;
    // Replace, don't push — avoids blank screens when
    // popping through stacked shell peer routes.
    context.switchToRoute(route);
  }

  static Future<void> _goHome(BuildContext context) async {
    await Navigator.of(context).maybePop();
    if (!context.mounted) return;
    context.resetTo(AppRouteNames.home);
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _DrawerItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Semantics(
      selected: selected,
      child: Pressable(
        onTap: onTap,
        semanticLabel: item.label,
        child: AnimatedContainer(
          duration: AtelierMotion.base,
          curve: AtelierMotion.emphasized,
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? p.goldSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(AtelierRadius.md),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: AtelierMotion.base,
                width: 3,
                height: 18,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: selected ? p.gold : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Icon(item.icon, size: 20, color: selected ? p.gold : p.inkSoft),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.label,
                  overflow: TextOverflow.ellipsis,
                  style: AtelierType.label(
                    selected ? p.ink : p.inkSoft,
                    size: 14,
                    weight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              if (item.badge > 0) CountBubble(count: item.badge),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerItem {
  const _DrawerItem({
    required this.route,
    required this.label,
    required this.icon,
    this.requiresVerified = false,
    this.badge = 0,
  });

  final String route;
  final String label;
  final IconData icon;
  final bool requiresVerified;
  final int badge;
}
