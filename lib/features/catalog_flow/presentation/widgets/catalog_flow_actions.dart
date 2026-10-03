import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/luxe/luxe_button.dart';
import '../../../cart/application/cart_provider.dart';
import '../../../home/presentation/widgets/home_search_overlay.dart';
import '../../../notifications/application/notifications_provider.dart';

/// Trailing top-bar actions shared by the luxe catalog flows (diamonds,
/// gemstones): catalog search, notifications and cart (the latter two when
/// signed in).
class CatalogFlowActions extends ConsumerWidget {
  const CatalogFlowActions({super.key, this.showSearch = true});

  final bool showSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(
      authProvider.select(
        (s) => (signedIn: s.isAuthenticated, seller: s.isSeller),
      ),
    );
    final cartCount = auth.signedIn ? ref.watch(cartItemCountProvider) : 0;
    final unread = auth.signedIn
        ? ref.watch(notificationUnreadCountProvider)
        : 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showSearch)
          LuxeIconButton(
            icon: Icons.search_rounded,
            tooltip: context.tr(HomeL10n.searchPrefix),
            size: 40,
            onPressed: () => showHomeSearch(context),
          ),
        if (auth.signedIn) ...[
          const SizedBox(width: 6),
          LuxeIconButton(
            icon: Icons.notifications_none_rounded,
            tooltip: context.tr(HomeL10n.notifications),
            size: 40,
            badge: unread,
            onPressed: () => context.switchToRoute(
              auth.seller
                  ? AppRouteNames.sellerNotifications
                  : AppRouteNames.buyerNotifications,
            ),
          ),
          const SizedBox(width: 6),
          LuxeIconButton(
            icon: Icons.shopping_bag_outlined,
            tooltip: context.tr(CoreL10n.cart),
            size: 40,
            badge: cartCount,
            onPressed: () => context.openRoute(AppRouteNames.cart),
          ),
        ],
      ],
    );
  }
}
