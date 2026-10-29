import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/cart/application/cart_provider.dart';
import '../../../../features/chat/application/chat_providers.dart';
import '../../../../features/home/presentation/widgets/home_search_overlay.dart';
import '../../../../features/jewelry_checkout/application/jewelry_bag_provider.dart';
import '../../../../features/notifications/application/notifications_provider.dart';
import '../../../../features/seller/application/seller_orders_provider.dart';
import '../../../auth/auth_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../router/app_navigation.dart';
import '../../../router/route_names.dart';
import '../../../theme/luxe_tokens.dart';
import '../../luxe/luxe_button.dart';
import 'top_bar_registry.dart';

/// One [TopBarAction] resolved for the current location and user.
class ResolvedTopBarAction {
  const ResolvedTopBarAction({
    required this.action,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badge = 0,
    this.dot = false,
    this.active = false,
  });

  final TopBarAction action;
  final IconData icon;
  final String tooltip;

  /// Null while the user is already on the action's screen.
  final VoidCallback? onPressed;
  final int badge;
  final bool dot;
  final bool active;
}

/// Turns the registry's spec for [location] into tappable actions.
///
/// Every action needs an account, so guests get none (their bar offers
/// sign-in instead). Sellers awaiting verification lose the seller tools
/// they cannot open yet.
List<ResolvedTopBarAction> resolveTopBarActions(
  BuildContext context,
  WidgetRef ref,
  String location,
) {
  final auth = ref.watch(
    authProvider.select(
      (s) => (signedIn: s.isAuthenticated, pending: s.isVerificationPending),
    ),
  );
  if (!auth.signedIn) return const [];

  final path = AppNavigation.canonicalPath(location);
  final section = TopBarRegistry.sectionFor(path);
  final seller = section == TopBarSection.seller;

  bool on(String route) => path == route || path.startsWith('$route/');
  VoidCallback? peer(String route) =>
      path == route ? null : () => context.switchToRoute(route);
  VoidCallback? stacked(String route) =>
      path == route ? null : () => context.openRoute(route);

  final result = <ResolvedTopBarAction>[];
  for (final action in TopBarRegistry.specs[section]!.actions) {
    switch (action) {
      case TopBarAction.notifications:
        final route = seller
            ? AppRouteNames.sellerNotifications
            : AppRouteNames.buyerNotifications;
        final unread = ref.watch(notificationUnreadCountProvider);
        result.add(
          ResolvedTopBarAction(
            action: action,
            // Outlined at rest, solid on its own screen (same for all below).
            icon: on(route)
                ? Icons.notifications_rounded
                : Icons.notifications_none_rounded,
            tooltip: context.tr(NavL10n.notifications),
            badge: unread,
            active: on(route),
            onPressed: peer(route),
          ),
        );
      case TopBarAction.cart:
        result.add(
          ResolvedTopBarAction(
            action: action,
            icon: on(AppRouteNames.cart)
                ? Icons.shopping_cart_rounded
                : Icons.shopping_cart_outlined,
            tooltip: context.tr(CoreL10n.cart),
            badge: ref.watch(cartItemCountProvider),
            active: on(AppRouteNames.cart),
            onPressed: stacked(AppRouteNames.cart),
          ),
        );
      case TopBarAction.jewelryBag:
        result.add(
          ResolvedTopBarAction(
            action: action,
            icon: on(AppRouteNames.jewelryBag)
                ? Icons.shopping_bag_rounded
                : Icons.shopping_bag_outlined,
            tooltip: context.tr(JewelryMarketL10n.bagTitle),
            badge: ref.watch(jewelryBagCountProvider),
            active: on(AppRouteNames.jewelryBag),
            onPressed: stacked(AppRouteNames.jewelryBag),
          ),
        );
      case TopBarAction.orders:
        if (seller && auth.pending) continue;
        final route = seller
            ? AppRouteNames.sellerOrders
            : AppRouteNames.buyerOrders;
        result.add(
          ResolvedTopBarAction(
            action: action,
            icon: on(route)
                ? Icons.receipt_long_rounded
                : Icons.receipt_long_outlined,
            tooltip: context.tr(RemainingL10n.orders),
            badge: seller
                ? ref.watch(sellerPendingOrdersProvider).asData?.value.total ??
                      0
                : 0,
            active: on(route),
            onPressed: peer(route),
          ),
        );
      case TopBarAction.messages:
        if (!seller || auth.pending) continue;
        result.add(
          ResolvedTopBarAction(
            action: action,
            icon: on(AppRouteNames.sellerChat)
                ? Icons.chat_bubble_rounded
                : Icons.chat_bubble_outline_rounded,
            tooltip: context.tr(CoreL10n.messages),
            dot: ref.watch(chatHasUnreadProvider),
            active: on(AppRouteNames.sellerChat),
            onPressed: peer(AppRouteNames.sellerChat),
          ),
        );
    }
  }
  return result;
}

/// How [TopBarActions] draws its buttons.
enum TopBarActionLook {
  /// Bare icons, for the app's own bars.
  plain,

  /// Circular luxe controls, for catalog headers ([glass] over imagery).
  luxe,
}

/// The current section's search and shortcuts, for bars a screen still
/// draws itself (catalog headers over imagery, Material bars).
///
/// The icons come from [TopBarRegistry] — callers only pick the look.
class TopBarActions extends ConsumerWidget {
  const TopBarActions({
    super.key,
    this.location,
    this.look = TopBarActionLook.luxe,
    this.glass = false,
    this.includeSearch = true,
  });

  /// Defaults to the enclosing route's location.
  final String? location;
  final TopBarActionLook look;

  /// Frosted luxe treatment for use over imagery or a dark stage.
  final bool glass;

  /// Show the search button when the section has search. Bars that draw a
  /// search field of their own turn this off.
  final bool includeSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = location ?? GoRouterState.of(context).uri.path;
    final search = includeSearch && TopBarRegistry.specFor(loc).search;
    final actions = resolveTopBarActions(context, ref, loc);
    if (!search && actions.isEmpty) return const SizedBox.shrink();

    final children = <Widget>[
      if (search)
        _button(
          context,
          icon: Icons.search_rounded,
          tooltip: context.tr(HomeL10n.searchPrefix),
          onPressed: () => showHomeSearch(context),
        ),
      for (final a in actions)
        _button(
          context,
          icon: a.icon,
          tooltip: a.tooltip,
          onPressed: a.onPressed,
          badge: a.badge,
          dot: a.dot,
          active: a.active,
        ),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0 && look == TopBarActionLook.luxe) const SizedBox(width: 6),
          children[i],
        ],
      ],
    );
  }

  Widget _button(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    int badge = 0,
    bool dot = false,
    bool active = false,
  }) {
    final p = LuxePalette.of(context);
    if (look == TopBarActionLook.luxe) {
      return LuxeIconButton(
        icon: icon,
        tooltip: tooltip,
        size: 40,
        glass: glass,
        active: active,
        badge: badge > 0 ? badge : (dot ? 1 : null),
        onPressed: onPressed ?? () {},
      );
    }
    return IconButton(
      tooltip: tooltip,
      // Already here: keep the icon lit instead of greying it out.
      onPressed: onPressed ?? () {},
      color: active ? p.accent : null,
      icon: Badge(
        isLabelVisible: badge > 0 || dot,
        smallSize: 8,
        backgroundColor: p.accent,
        textColor: p.onAccent,
        label: badge > 0 ? Text(badge > 99 ? '99+' : '$badge') : null,
        child: Icon(icon),
      ),
    );
  }
}
