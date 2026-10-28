import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/luxe/luxe_button.dart';
import '../../../cart/application/cart_provider.dart';
import '../../../home/presentation/widgets/home_search_overlay.dart';
import '../../../jewelry_checkout/application/jewelry_bag_provider.dart';
import '../../../notifications/application/notifications_provider.dart';

/// Trailing top-bar actions shared by the luxe catalog flows (diamonds,
/// gemstones, jewellery): catalog search, then notifications and one bag
/// (when signed in).
///
/// The diamond/gem cart and the jewellery bag check out separately, so a
/// screen shows exactly one of them: the cart (cart icon) by default, the
/// jewellery bag (bag icon) when [jewelryBag] is set.
class CatalogFlowActions extends ConsumerWidget {
  const CatalogFlowActions({
    super.key,
    this.showSearch = true,
    this.glass = false,
    this.jewelryBag = false,
  });

  final bool showSearch;

  /// Frosted treatment for use over imagery or a dark stage.
  final bool glass;

  /// Jewellery screens: the bag button opens the jewellery bag instead of
  /// the diamond/gem cart.
  final bool jewelryBag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(
      authProvider.select((s) => (signedIn: s.isAuthenticated)),
    );
    final unread = auth.signedIn
        ? ref.watch(notificationUnreadCountProvider)
        : 0;
    final bag = !auth.signedIn
        ? 0
        : jewelryBag
        ? ref.watch(jewelryBagCountProvider)
        : ref.watch(cartItemCountProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showSearch)
          LuxeIconButton(
            icon: Icons.search_rounded,
            tooltip: context.tr(HomeL10n.searchPrefix),
            size: 40,
            glass: glass,
            onPressed: () => showHomeSearch(context),
          ),
        if (auth.signedIn) ...[
          const SizedBox(width: 6),
          LuxeIconButton(
            icon: Icons.notifications_none_rounded,
            tooltip: context.tr(HomeL10n.notifications),
            size: 40,
            glass: glass,
            badge: unread,
            // Catalog pages are the buyer side; stay on it.
            onPressed: () =>
                context.switchToRoute(AppRouteNames.buyerNotifications),
          ),
          const SizedBox(width: 6),
          if (jewelryBag)
            LuxeIconButton(
              icon: Icons.shopping_bag_outlined,
              tooltip: context.tr(JewelryMarketL10n.bagTitle),
              size: 40,
              glass: glass,
              badge: bag,
              onPressed: () => context.push(AppRouteNames.jewelryBag),
            )
          else
            LuxeIconButton(
              icon: Icons.shopping_cart_outlined,
              tooltip: context.tr(CoreL10n.cart),
              size: 40,
              glass: glass,
              badge: bag,
              onPressed: () => context.openRoute(AppRouteNames.cart),
            ),
        ],
      ],
    );
  }
}
