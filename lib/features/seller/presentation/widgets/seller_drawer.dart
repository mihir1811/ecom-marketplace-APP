import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Side drawer for seller workspace screens only.
class SellerDrawer extends StatelessWidget {
  const SellerDrawer({
    super.key,
    required this.selectedRoute,
  });

  final String selectedRoute;

  @override
  Widget build(BuildContext context) {
    final items = <_DrawerItem>[
      const _DrawerItem(
        route: AppRouteNames.sellerDashboard,
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
      ),
      const _DrawerItem(
        route: AppRouteNames.sellerProducts,
        label: 'Products',
        icon: Icons.inventory_2_outlined,
      ),
      const _DrawerItem(
        route: AppRouteNames.sellerOrders,
        label: 'Orders',
        icon: Icons.shopping_bag_outlined,
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
      ),
      const _DrawerItem(
        route: AppRouteNames.sellerAuctions,
        label: 'Auctions',
        icon: Icons.gavel_outlined,
      ),
      const _DrawerItem(
        route: AppRouteNames.sellerAnalytics,
        label: 'Analytics',
        icon: Icons.bar_chart_outlined,
      ),
      const _DrawerItem(
        route: AppRouteNames.sellerChat,
        label: 'Chat',
        icon: Icons.chat_bubble_outline,
      ),
      const _DrawerItem(
        route: AppRouteNames.sellerHelpCenter,
        label: 'Help center',
        icon: Icons.help_outline,
      ),
      const _DrawerItem(
        route: AppRouteNames.sellerPromotions,
        label: 'Promotions',
        icon: Icons.card_giftcard_outlined,
      ),
      const _DrawerItem(
        route: AppRouteNames.sellerProfile,
        label: 'Profile',
        icon: Icons.person_outline,
      ),
    ];

    return Drawer(
      width: 280,
      backgroundColor: AppColors.warmWhite,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Row(
                children: [
                  Text(
                    'Seller workspace',
                    style: AppTypography.title,
                  ),
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
                  final isSelected = selectedRoute == item.route ||
                      selectedRoute.startsWith('${item.route}/');
                  return Material(
                    color: isSelected ? AppColors.charcoal : Colors.transparent,
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
                            Icon(
                              item.icon,
                              color: isSelected
                                  ? AppColors.warmWhite
                                  : AppColors.charcoal,
                            ),
                            const SizedBox(width: AppSpacing.s16),
                            Expanded(
                              child: Text(
                                item.label,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.warmWhite
                                      : AppColors.charcoal,
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
    );
  }
}

class _DrawerItem {
  const _DrawerItem({
    required this.route,
    required this.label,
    required this.icon,
  });

  final String route;
  final String label;
  final IconData icon;
}
