import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../theme/home_tokens.dart';
import 'home_section.dart';
import '../../../../core/widgets/luxe/scroll_reveal.dart';

/// One-tap shortcuts to the signed-in user's own spaces.
class HomeAtelierLinks extends ConsumerWidget {
  const HomeAtelierLinks({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = HomePalette.of(context);
    final workspace = ref.watch(
      authProvider.select((s) => s.isSeller && s.canTransact),
    );
    final links = workspace
        ? const [
            (
              HomeL10n.dashboard,
              Icons.space_dashboard_outlined,
              AppRouteNames.sellerDashboard,
            ),
            (
              HomeL10n.orders,
              Icons.receipt_long_outlined,
              AppRouteNames.sellerOrders,
            ),
            (
              HomeL10n.auctions,
              Icons.gavel_rounded,
              AppRouteNames.sellerAuctions,
            ),
            (
              HomeL10n.wallet,
              Icons.account_balance_wallet_outlined,
              AppRouteNames.sellerWallet,
            ),
          ]
        : const [
            (
              HomeL10n.orders,
              Icons.receipt_long_outlined,
              AppRouteNames.buyerOrders,
            ),
            (
              HomeL10n.wishlist,
              Icons.favorite_border_rounded,
              AppRouteNames.buyerWishlist,
            ),
            (
              HomeL10n.myBids,
              Icons.gavel_rounded,
              AppRouteNames.auctionActivity,
            ),
            (
              HomeL10n.wallet,
              Icons.account_balance_wallet_outlined,
              AppRouteNames.buyerWallet,
            ),
          ];
    final gutter = homeGutter(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, 28, gutter, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScrollReveal(
            child: Text(
              // Sellers' shortcuts open the seller workspace — say so.
              context
                  .tr(
                    workspace
                        ? NavL10n.homeSellerShortcuts
                        : HomeL10n.atelierTitle,
                  )
                  .toUpperCase(),
              style: HomeType.eyebrow(palette.inkMuted),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < links.length; i++)
                Expanded(
                  child: ScrollReveal(
                    delay: HomeMotion.stagger * i,
                    child: _AtelierLink(
                      label: context.tr(links[i].$1),
                      icon: links[i].$2,
                      onTap: () => context.openRoute(links[i].$3),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AtelierLink extends StatelessWidget {
  const _AtelierLink({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(HomeSpace.radiusSmall),
        onTap: () {
          AppHaptics.selection();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.surface,
                  border: Border.all(color: palette.hairline),
                ),
                child: Icon(icon, size: 22, color: palette.ink),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: HomeType.label(palette.inkMuted, size: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
