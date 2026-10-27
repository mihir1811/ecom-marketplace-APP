import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/router/workspace_mode.dart';
import '../../../../core/widgets/navigation/app_nav_drawer.dart';

/// Buyer-side drawer (home, catalog and `/buyer/...` screens).
///
/// Mirrors [SellerDrawer]: same header, same Buyer | Seller switch, same
/// "Messages & support" and "Account" groups, same footer. Home, Wishlist,
/// Cart and Profile live in the bottom nav and Notifications in the top bar,
/// so the drawer leaves them out.
/// Whether Jewelry education shows under Learn.
const _showJewelryEducation = false;

class BuyerDrawer extends ConsumerWidget {
  const BuyerDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(
      authProvider.select(
        (s) => (
          user: s.user,
          isSeller: s.isSeller,
          verified: !s.isVerificationPending,
        ),
      ),
    );
    final currentPath = GoRouterState.of(context).uri.path;
    final name = auth.user?.fullName.trim();

    AppNavItem item(String route, String labelKey, IconData icon) =>
        AppNavItem(route: route, label: context.tr(labelKey), icon: icon);

    final groups = [
      AppNavGroup(
        title: context.tr(NavL10n.groupShopping),
        items: [
          if (auth.verified) ...[
            item(
              AppRouteNames.buyerOrders,
              AccountCommerceL10n.orders,
              Icons.local_shipping_outlined,
            ),
            item(
              AppRouteNames.jewelryOrders,
              JewelryMarketL10n.ordersTitle,
              Icons.diamond_outlined,
            ),
            item(
              AppRouteNames.buyerWallet,
              CoreL10n.wallet,
              Icons.account_balance_wallet_outlined,
            ),
            item(
              AppRouteNames.buyerRewards,
              CoreL10n.rewards,
              Icons.auto_awesome_outlined,
            ),
            item(
              AppRouteNames.buyerOffers,
              DiamondFlowL10n.myOffers,
              Icons.local_offer_outlined,
            ),
            item(
              AppRouteNames.buyerRefunds,
              AccountCommerceL10n.refunds,
              Icons.replay_outlined,
            ),
          ],
          item(
            AppRouteNames.buyerRecentlyViewed,
            AccountCommerceL10n.recentlyViewed,
            Icons.history,
          ),
          item(
            AppRouteNames.buyerReviews,
            AccountCommerceL10n.myReviews,
            Icons.star_outline,
          ),
        ],
      ),
      AppNavGroup(
        title: context.tr(NavL10n.groupAuctions),
        items: [
          item(
            AppRouteNames.auctions,
            NavL10n.liveAuctions,
            Icons.gavel_outlined,
          ),
          if (auth.verified) ...[
            item(
              AppRouteNames.auctionActivity,
              HomeL10n.myBids,
              Icons.price_change_outlined,
            ),
            item(
              AppRouteNames.auctionWins,
              NavL10n.myWins,
              Icons.emoji_events_outlined,
            ),
          ],
        ],
      ),
      AppNavGroup(
        title: context.tr(EducationL10n.navLearn),
        items: [
          item(
            AppRouteNames.diamondEducation,
            EducationL10n.navEducation,
            Icons.school_outlined,
          ),
          // Hidden for now; the route and page stay in place.
          if (_showJewelryEducation)
            item(
              AppRouteNames.jewelryEducation,
              JewelryEduL10n.navEducation,
              Icons.diamond_outlined,
            ),
        ],
      ),
      AppNavGroup(
        title: context.tr(NavL10n.groupConversations),
        items: [
          if (auth.isSeller && auth.verified)
            item(
              AppRouteNames.buyerMessages,
              CoreL10n.messages,
              Icons.chat_bubble_outline_rounded,
            ),
          item(
            AppRouteNames.buyerInquiries,
            RemainingL10n.inquiries,
            Icons.forum_outlined,
          ),
          item(
            AppRouteNames.buyerHelpCenter,
            AccountCommerceL10n.helpCenterCaps,
            Icons.support_agent_outlined,
          ),
        ],
      ),
      AppNavGroup(
        title: context.tr(NavL10n.groupAccount),
        items: [
          item(
            AppRouteNames.buyerReferences,
            RemainingL10n.references,
            Icons.diversity_3_outlined,
          ),
          item(
            AppRouteNames.buyerSettings,
            CoreL10n.settings,
            Icons.settings_outlined,
          ),
        ],
      ),
    ];

    return AppNavDrawer(
      workspace: AppWorkspace.buyer,
      selectedRoute: currentPath,
      groups: groups,
      displayName: (name != null && name.isNotEmpty)
          ? name
          : (auth.user?.username ??
                context.tr(AccountCommerceL10n.accountLabel)),
      imageUrl: auth.user?.profilePicture,
      showPendingNotice: !auth.verified,
    );
  }
}
