import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Buyer-side account drawer (home + buyer screens). Dashboard alone opens seller.
class BuyerDrawer extends ConsumerWidget {
  const BuyerDrawer({super.key});

  static const items = <BuyerDrawerItem>[
    BuyerDrawerItem(
      route: AppRouteNames.buyerProfile,
      label: 'My Profile',
      icon: Icons.person_outline,
    ),
    BuyerDrawerItem(
      route: AppRouteNames.sellerDashboard,
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      isSellerEntry: true,
    ),
    BuyerDrawerItem(
      route: AppRouteNames.buyerOrders,
      label: 'Orders',
      icon: Icons.local_shipping_outlined,
    ),
    BuyerDrawerItem(
      route: AppRouteNames.buyerInquiries,
      label: 'Inquiries',
      icon: Icons.mail_outline,
    ),
    BuyerDrawerItem(
      route: AppRouteNames.buyerHelpCenter,
      label: 'Help Center',
      icon: Icons.help_outline,
    ),
    BuyerDrawerItem(
      route: AppRouteNames.buyerWishlist,
      label: 'My Wishlist',
      icon: Icons.favorite_border,
    ),
    BuyerDrawerItem(
      route: AppRouteNames.buyerReviews,
      label: 'My Reviews',
      icon: Icons.star_outline,
    ),
    BuyerDrawerItem(
      route: AppRouteNames.buyerMessages,
      label: 'Messages',
      icon: Icons.chat_bubble_outline,
    ),
    BuyerDrawerItem(
      route: AppRouteNames.buyerSettings,
      label: 'Settings',
      icon: Icons.settings_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final currentPath = GoRouterState.of(context).uri.path;

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
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.charcoal,
                    child: Text(
                      _initials(user?.fullName ?? user?.username ?? 'U'),
                      style: AppTypography.label.copyWith(
                        color: AppColors.warmWhite,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'Account',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.title.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Account',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                  final isSelected = !item.isSellerEntry &&
                      (currentPath == item.route ||
                          currentPath.startsWith('${item.route}/'));
                  return Material(
                    color:
                        isSelected ? AppColors.charcoal : Colors.transparent,
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
                            if (item.isSellerEntry)
                              Icon(
                                Icons.open_in_new,
                                size: 16,
                                color: isSelected
                                    ? AppColors.warmWhite
                                    : AppColors.textMutedLight,
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
              leading: const Icon(Icons.home_outlined),
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
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: Text(
                'Sign out',
                style: AppTypography.label.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () {
                Navigator.of(context).maybePop();
                ref.read(authProvider.notifier).logout();
                context.go(AppRouteNames.home);
              },
            ),
          ],
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class BuyerDrawerItem {
  const BuyerDrawerItem({
    required this.route,
    required this.label,
    required this.icon,
    this.isSellerEntry = false,
  });

  final String route;
  final String label;
  final IconData icon;
  final bool isSellerEntry;
}
