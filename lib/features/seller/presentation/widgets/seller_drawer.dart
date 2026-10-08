import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/router/workspace_mode.dart';
import '../../../../core/widgets/navigation/app_nav_drawer.dart';
import '../../../notifications/application/notifications_provider.dart';

/// Side drawer for seller workspace screens: every seller tool, grouped by
/// intent, with the current page highlighted.
///
/// Mirrors [BuyerDrawer]: same header, same Buyer | Seller switch, same
/// "Messages & support" and "Account" groups, same footer.
class SellerDrawer extends ConsumerWidget {
  const SellerDrawer({super.key, required this.selectedRoute});

  final String selectedRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              : context.tr(NavL10n.seller));

    AppNavItem item(String route, String labelKey, IconData icon) =>
        AppNavItem(route: route, label: context.tr(labelKey), icon: icon);

    final groups = [
      AppNavGroup(
        title: context.tr(NavL10n.groupWorkspace),
        items: [
          if (!pending) ...[
            item(
              AppRouteNames.sellerDashboard,
              RemainingL10n.dashboard,
              Icons.space_dashboard_outlined,
            ),
            item(
              AppRouteNames.sellerProducts,
              RemainingL10n.products,
              Icons.diamond_outlined,
            ),
            item(
              AppRouteNames.sellerOrders,
              RemainingL10n.orders,
              Icons.receipt_long_outlined,
            ),
            item(
              AppRouteNames.sellerWallet,
              RemainingL10n.wallet,
              Icons.account_balance_wallet_outlined,
            ),
          ],
          item(
            AppRouteNames.sellerInquiries,
            RemainingL10n.inquiries,
            Icons.forum_outlined,
          ),
        ],
      ),
      AppNavGroup(
        title: context.tr(NavL10n.groupGrow),
        items: [
          if (!pending) ...[
            item(
              AppRouteNames.sellerOffers,
              RemainingL10n.offers,
              Icons.local_offer_outlined,
            ),
            item(
              AppRouteNames.sellerAuctions,
              RemainingL10n.auctions,
              Icons.gavel_outlined,
            ),
            item(
              AppRouteNames.sellerAnalytics,
              RemainingL10n.analytics,
              Icons.insights_outlined,
            ),
            item(
              AppRouteNames.sellerPromotions,
              RemainingL10n.promotions,
              Icons.card_giftcard_outlined,
            ),
          ],
          item(
            AppRouteNames.sellerReferences,
            RemainingL10n.references,
            Icons.diversity_3_outlined,
          ),
        ],
      ),
      AppNavGroup(
        title: context.tr(NavL10n.groupConversations),
        items: [
          if (!pending)
            item(
              AppRouteNames.sellerChat,
              CoreL10n.messages,
              Icons.chat_bubble_outline_rounded,
            ),
          AppNavItem(
            route: AppRouteNames.sellerNotifications,
            label: context.tr(NavL10n.notifications),
            icon: Icons.notifications_none_rounded,
            badge: unread,
          ),
          item(
            AppRouteNames.sellerHelpCenter,
            RemainingL10n.helpCenter,
            Icons.support_agent_outlined,
          ),
        ],
      ),
      AppNavGroup(
        title: context.tr(NavL10n.groupAccount),
        items: [
          item(
            AppRouteNames.sellerProfile,
            RemainingL10n.profile,
            Icons.person_outline_rounded,
          ),
          if (!pending)
            item(
              AppRouteNames.sellerApiKeys,
              RemainingL10n.apiKeys,
              Icons.vpn_key_outlined,
            ),
        ],
      ),
    ];

    return AppNavDrawer(
      workspace: AppWorkspace.seller,
      selectedRoute: selectedRoute,
      groups: groups,
      displayName: displayName,
      showPendingNotice: pending,
    );
  }
}
