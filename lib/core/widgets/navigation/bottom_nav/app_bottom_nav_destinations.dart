import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../router/route_names.dart';

/// The four main tabs of the buyer side.
enum AppBottomNavTab { home, wishlist, cart, profile }

/// One tab of the sticky bottom navigation.
class AppBottomNavDestination {
  const AppBottomNavDestination({
    required this.tab,
    required this.route,
    required this.labelKey,
    required this.icon,
    required this.selectedIcon,
  });

  final AppBottomNavTab tab;
  final String route;
  final String labelKey;
  final IconData icon;
  final IconData selectedIcon;
}

/// Tabs, which routes show the bar, and which tab a route belongs to.
///
/// The bar shows on the buyer side's top-level and browse screens. Detail,
/// checkout, filter, auth and seller screens keep the full height for their
/// own sticky actions.
abstract final class AppBottomNav {
  static const destinations = <AppBottomNavDestination>[
    AppBottomNavDestination(
      tab: AppBottomNavTab.home,
      route: AppRouteNames.home,
      labelKey: NavL10n.home,
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    AppBottomNavDestination(
      tab: AppBottomNavTab.wishlist,
      route: AppRouteNames.buyerWishlist,
      labelKey: HomeL10n.wishlist,
      icon: Icons.favorite_border_rounded,
      selectedIcon: Icons.favorite_rounded,
    ),
    AppBottomNavDestination(
      tab: AppBottomNavTab.cart,
      route: AppRouteNames.cart,
      labelKey: CoreL10n.cart,
      icon: Icons.shopping_bag_outlined,
      selectedIcon: Icons.shopping_bag_rounded,
    ),
    AppBottomNavDestination(
      tab: AppBottomNavTab.profile,
      route: AppRouteNames.buyerProfile,
      labelKey: RemainingL10n.profile,
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  ];

  /// Browse screens that belong to the Home tab.
  static const _homeBranch = <String>{
    AppRouteNames.diamonds,
    AppRouteNames.diamondResults,
    AppRouteNames.labGrownDiamonds,
    AppRouteNames.labGrownDiamondResults,
    AppRouteNames.gemstones,
    AppRouteNames.gemstoneResults,
    AppRouteNames.watches,
    AppRouteNames.jewelry,
    AppRouteNames.jewelryListing,
    AppRouteNames.bullions,
    AppRouteNames.auctions,
    AppRouteNames.auctionActivity,
    AppRouteNames.auctionWins,
  };

  static String _normalize(String path) => path.length > 1 && path.endsWith('/')
      ? path.substring(0, path.length - 1)
      : path;

  /// Brand pages are browse screens; their filter page is not.
  static bool _isBrandPage(String path) =>
      path.startsWith('/watches/brand/') && !path.endsWith('/filters');

  /// The tab [path] belongs to, or null when the bar is hidden there.
  static AppBottomNavTab? tabFor(String rawPath) {
    final path = _normalize(rawPath);
    for (final d in destinations) {
      if (d.route == path) return d.tab;
    }
    if (_homeBranch.contains(path) || _isBrandPage(path)) {
      return AppBottomNavTab.home;
    }
    return null;
  }

  static bool isVisibleOn(String path) => tabFor(path) != null;
}
