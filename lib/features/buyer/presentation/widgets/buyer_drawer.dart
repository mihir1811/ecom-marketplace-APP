import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/translations/account_commerce_messages.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/auth/confirm_sign_out.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Buyer-side account drawer (home + buyer screens).
class BuyerDrawer extends ConsumerWidget {
  const BuyerDrawer({super.key});

  static final _buyerItems = <BuyerDrawerItem>[
    const BuyerDrawerItem(
      route: AppRouteNames.buyerProfile,
      label: AccountCommerceL10n.myProfileCaps,
      icon: Icons.person_outline,
    ),
    const BuyerDrawerItem(
      route: AppRouteNames.buyerOrders,
      label: AccountCommerceL10n.orders,
      icon: Icons.local_shipping_outlined,
      requiresVerified: true,
    ),
    const BuyerDrawerItem(
      route: AppRouteNames.buyerWallet,
      label: 'Wallet',
      icon: Icons.account_balance_wallet_outlined,
      requiresVerified: true,
    ),
    const BuyerDrawerItem(
      route: AppRouteNames.buyerRefunds,
      label: AccountCommerceL10n.refunds,
      icon: Icons.replay_outlined,
      requiresVerified: true,
    ),
    const BuyerDrawerItem(
      route: AppRouteNames.buyerReferences,
      label: 'References',
      icon: Icons.diversity_3_outlined,
    ),
    const BuyerDrawerItem(
      route: AppRouteNames.buyerInquiries,
      label: 'Inquiries',
      icon: Icons.mail_outline,
    ),
    const BuyerDrawerItem(
      route: AppRouteNames.buyerHelpCenter,
      label: AccountCommerceL10n.helpCenterCaps,
      icon: Icons.help_outline,
    ),
    const BuyerDrawerItem(
      route: AppRouteNames.buyerWishlist,
      label: AccountCommerceL10n.myWishlist,
      icon: Icons.favorite_border,
    ),
    const BuyerDrawerItem(
      route: AppRouteNames.buyerRecentlyViewed,
      label: AccountCommerceL10n.recentlyViewed,
      icon: Icons.history,
    ),
    const BuyerDrawerItem(
      route: AppRouteNames.buyerReviews,
      label: AccountCommerceL10n.myReviews,
      icon: Icons.star_outline,
    ),
    const BuyerDrawerItem(
      route: AppRouteNames.buyerMessages,
      label: 'Messages',
      icon: Icons.chat_bubble_outline,
      requiresSeller: true,
      requiresVerified: true,
    ),
    const BuyerDrawerItem(
      route: AppRouteNames.buyerSettings,
      label: 'Settings',
      icon: Icons.settings_outlined,
    ),
  ];

  static const _sellerDashboardItem = BuyerDrawerItem(
    route: AppRouteNames.sellerDashboard,
    label: AccountCommerceL10n.sellerDashboard,
    icon: Icons.dashboard_outlined,
    isSellerEntry: true,
    requiresSeller: true,
    requiresVerified: true,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(
      authProvider.select(
        (s) => (
          user: s.user,
          isSeller: s.isSeller,
          showProtected: !s.isVerificationPending,
        ),
      ),
    );
    final currentPath = GoRouterState.of(context).uri.path;
    final items = <BuyerDrawerItem>[
      _buyerItems.first,
      if (auth.isSeller && auth.showProtected) _sellerDashboardItem,
      ..._buyerItems.skip(1).where((item) {
        if (item.requiresSeller && !auth.isSeller) return false;
        if (item.requiresVerified && !auth.showProtected) return false;
        return true;
      }),
    ];

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
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.navSelectedFill(context),
                    child: Text(
                      _initials(
                        auth.user?.fullName ?? auth.user?.username ?? 'U',
                      ),
                      style: AppTypography.label.copyWith(
                        color: AppColors.navOnSelected(context),
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
                          auth.user?.fullName ??
                              context.tr(AccountCommerceL10n.accountLabel),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.title.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          auth.isSeller
                              ? context.tr(
                                  AccountCommerceL10n.sellerAccountLabel,
                                )
                              : context.tr(AccountCommerceL10n.accountLabel),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: context.tr(CoreL10n.close),
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
                      !item.isSellerEntry &&
                      (currentPath == item.route ||
                          currentPath.startsWith('${item.route}/'));
                  return Material(
                    color: isSelected
                        ? AppColors.navSelectedFill(context)
                        : Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).maybePop();
                        context.switchToRoute(item.route);
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
                                  ? AppColors.navOnSelected(context)
                                  : AppColors.textPrimary(context),
                            ),
                            const SizedBox(width: AppSpacing.s16),
                            Expanded(
                              child: Text(
                                item.label.startsWith('commerce.') ||
                                        item.label.startsWith('account.')
                                    ? context.tr(item.label)
                                    : item.label,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.navOnSelected(context)
                                      : AppColors.textPrimary(context),
                                ),
                              ),
                            ),
                            if (item.isSellerEntry)
                              Icon(
                                Icons.open_in_new,
                                size: 16,
                                color: isSelected
                                    ? AppColors.navOnSelected(context)
                                    : AppColors.textMuted(context),
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
                context.tr(AccountCommerceL10n.backToShop),
                style: AppTypography.label.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () {
                Navigator.of(context).maybePop();
                context.resetTo(AppRouteNames.home);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: Text(
                context.tr(AccountCommerceL10n.signOut),
                style: AppTypography.label.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () async {
                final confirmed = await confirmSignOut(context);
                if (!confirmed || !context.mounted) return;
                Navigator.of(context).maybePop();
                ref.read(authProvider.notifier).logout();
                context.resetTo(AppRouteNames.home);
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
    this.requiresSeller = false,
    this.requiresVerified = false,
  });

  final String route;
  final String label;
  final IconData icon;
  final bool isSellerEntry;
  final bool requiresSeller;
  final bool requiresVerified;
}
