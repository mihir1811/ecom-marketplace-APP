import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_preference_provider.dart';

/// Side drawer for seller workspace screens only.
class SellerDrawer extends ConsumerWidget {
  const SellerDrawer({super.key, required this.selectedRoute});

  final String selectedRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(
      authProvider.select((s) => s.isVerificationPending),
    );
    final dark = ref.watch(themePreferenceProvider);
    final items = <_DrawerItem>[
      const _DrawerItem(
        route: AppRouteNames.sellerDashboard,
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        requiresVerified: true,
      ),
      const _DrawerItem(
        route: AppRouteNames.sellerProducts,
        label: 'Products',
        icon: Icons.inventory_2_outlined,
        requiresVerified: true,
      ),
      const _DrawerItem(
        route: AppRouteNames.sellerOrders,
        label: 'Orders',
        icon: Icons.shopping_bag_outlined,
        requiresVerified: true,
      ),
      const _DrawerItem(
        route: AppRouteNames.sellerWallet,
        label: 'Wallet',
        icon: Icons.account_balance_wallet_outlined,
        requiresVerified: true,
      ),
      const _DrawerItem(
        route: AppRouteNames.sellerInquiries,
        label: 'Inquiries',
        icon: Icons.mail_outline,
      ),
      const _DrawerItem(
        route: AppRouteNames.sellerOffers,
        label: 'Offers',
        icon: Icons.local_offer_outlined,
        requiresVerified: true,
      ),
      const _DrawerItem(
        route: AppRouteNames.sellerAuctions,
        label: 'Auctions',
        icon: Icons.gavel_outlined,
        requiresVerified: true,
      ),
      const _DrawerItem(
        route: AppRouteNames.sellerAnalytics,
        label: 'Analytics',
        icon: Icons.bar_chart_outlined,
        requiresVerified: true,
      ),
      const _DrawerItem(
        route: AppRouteNames.sellerChat,
        label: 'Chat',
        icon: Icons.chat_bubble_outline,
        requiresVerified: true,
      ),
      const _DrawerItem(
        route: AppRouteNames.sellerHelpCenter,
        label: 'Help center',
        icon: Icons.help_outline,
      ),
      const _DrawerItem(
        route: AppRouteNames.sellerReferences,
        label: 'References',
        icon: Icons.diversity_3_outlined,
      ),
      const _DrawerItem(
        route: AppRouteNames.sellerPromotions,
        label: 'Promotions',
        icon: Icons.card_giftcard_outlined,
        requiresVerified: true,
      ),
      const _DrawerItem(
        route: AppRouteNames.sellerLoginHistory,
        label: 'Login history',
        icon: Icons.devices_outlined,
      ),
      const _DrawerItem(
        route: AppRouteNames.sellerProfile,
        label: 'Profile',
        icon: Icons.person_outline,
      ),
    ].where((item) => !pending || !item.requiresVerified).toList();

    // Stay dark whenever dark mode is on, even when hosted by a light screen.
    return Theme(
      data: dark ? AppTheme.dark : Theme.of(context),
      child: Drawer(
        width: 280,
        backgroundColor: dark ? AppColors.slateSurface : AppColors.warmWhite,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: Row(
                  children: [
                    Text('Seller workspace', style: AppTypography.title),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Close',
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
                        ? AppColors.onSelected(context)
                        : AppColors.textPrimary(context);
                    return Material(
                      color: isSelected
                          ? AppColors.selectedFill(context)
                          : Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).maybePop();
                          context.go(item.route);
                        },
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
                  'Back to shop',
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).maybePop();
                  context.go(AppRouteNames.home);
                },
              ),
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
  });

  final String route;
  final String label;
  final IconData icon;
  final bool requiresVerified;
}
