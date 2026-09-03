import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

import '../../../../core/l10n/app_localizations.dart';

/// Side drawer for seller workspace screens only.
class SellerDrawer extends ConsumerWidget {
  const SellerDrawer({super.key, required this.selectedRoute});

  final String selectedRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(
      authProvider.select((s) => s.isVerificationPending),
    );
    final items = <_DrawerItem>[
      _DrawerItem(
        route: AppRouteNames.sellerDashboard,
        label: context.tr(RemainingL10n.dashboard),
        icon: Icons.dashboard_outlined,
        requiresVerified: true,
      ),
      _DrawerItem(
        route: AppRouteNames.sellerProducts,
        label: context.tr(RemainingL10n.products),
        icon: Icons.inventory_2_outlined,
        requiresVerified: true,
      ),
      _DrawerItem(
        route: AppRouteNames.sellerOrders,
        label: context.tr(RemainingL10n.orders),
        icon: Icons.shopping_bag_outlined,
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
        icon: Icons.mail_outline,
      ),
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
        icon: Icons.bar_chart_outlined,
        requiresVerified: true,
      ),
      _DrawerItem(
        route: AppRouteNames.sellerChat,
        label: context.tr(RemainingL10n.chat),
        icon: Icons.chat_bubble_outline,
        requiresVerified: true,
      ),
      _DrawerItem(
        route: AppRouteNames.sellerHelpCenter,
        label: context.tr(RemainingL10n.helpCenter),
        icon: Icons.help_outline,
      ),
      _DrawerItem(
        route: AppRouteNames.sellerReferences,
        label: context.tr(RemainingL10n.references),
        icon: Icons.diversity_3_outlined,
      ),
      _DrawerItem(
        route: AppRouteNames.sellerPromotions,
        label: context.tr(RemainingL10n.promotions),
        icon: Icons.card_giftcard_outlined,
        requiresVerified: true,
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
      _DrawerItem(
        route: AppRouteNames.sellerProfile,
        label: context.tr(RemainingL10n.profile),
        icon: Icons.person_outline,
      ),
    ].where((item) => !pending || !item.requiresVerified).toList();

    return Drawer(
      width: 280,
      backgroundColor: AppColors.card(context),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Row(
                children: [
                  Text(
                    context.tr(RemainingL10n.sellerWorkspace),
                    style: AppTypography.title,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: context.tr(RemainingL10n.close),
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected =
                      selectedRoute == item.route ||
                      selectedRoute.startsWith('${item.route}/');
                  final iconColor = isSelected
                      ? AppColors.navOnSelected(context)
                      : AppColors.textPrimary(context);
                  return Material(
                    color: isSelected
                        ? AppColors.navSelectedFill(context)
                        : Colors.transparent,
                    child: InkWell(
                      onTap: () => _go(context, item.route),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s16,
                          vertical: AppSpacing.s12,
                        ),
                        child: Row(
                          children: [
                            Icon(item.icon, color: iconColor),
                            const SizedBox(width: AppSpacing.s16),
                            Expanded(
                              child: Text(
                                item.label,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: iconColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: Text(
                context.tr(RemainingL10n.backToShop),
                style: AppTypography.label.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () => _goHome(context),
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

class _DrawerItem {
  const _DrawerItem({
    required this.route,
    required this.label,
    required this.icon,
    this.requiresVerified = false,
  });

  final String route;
  final String label;
  final IconData icon;
  final bool requiresVerified;
}
