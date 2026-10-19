import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../router/route_names.dart';

/// The four main tabs of the buyer side.
enum AppBottomNavTab { home, wishlist, auctions, profile }

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
/// The bar shows on the four tab screens and on catalog product listing
/// screens. Filter, detail, checkout, account, and seller screens keep the
/// full height for their own actions.
abstract final class AppBottomNav {
  /// Catalog product listing routes that keep the dock visible (no tab
  /// selected — the last tab highlight is retained by the host).
  static const listingRoutes = <String>{
    AppRouteNames.diamondResults,
    AppRouteNames.labGrownDiamondResults,
    AppRouteNames.gemstoneResults,
    AppRouteNames.jewelryListing,
    AppRouteNames.watches,
    AppRouteNames.bullions,
  };

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
      tab: AppBottomNavTab.auctions,
      route: AppRouteNames.auctions,
      labelKey: HomeL10n.auctions,
      icon: Icons.gavel_outlined,
      selectedIcon: Icons.gavel_rounded,
    ),
    AppBottomNavDestination(
      tab: AppBottomNavTab.profile,
      route: AppRouteNames.buyerProfile,
      labelKey: RemainingL10n.profile,
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  ];

  /// Bar slots, left to right: the tabs with the Categories action (null)
  /// in the centre. Categories opens a menu and never owns a route.
  static final slots = <AppBottomNavDestination?>[
    ...destinations.take(categoriesSlot),
    null,
    ...destinations.skip(categoriesSlot),
  ];

  /// Position of the Categories action among [slots].
  static const categoriesSlot = 2;
  static const categoriesLabelKey = NavL10n.categories;
  static const categoriesIcon = Icons.grid_view_outlined;
  static const categoriesSelectedIcon = Icons.grid_view_rounded;

  /// Maps a position along the bar (0 = centre of the first slot) onto tab
  /// coordinates (0 = first tab), squeezing the Categories slot out so a
  /// scrub glides straight from the tab on its left to the one on its right.
  static double tabCoordinate(double slot) {
    const left = categoriesSlot - 1.0, right = categoriesSlot + 1.0;
    if (slot <= left) return slot;
    if (slot >= right) return slot - 1;
    return left + (slot - left) / 2;
  }

  static String _normalize(String path) => path.length > 1 && path.endsWith('/')
      ? path.substring(0, path.length - 1)
      : path;

  /// The tab [path] belongs to, or null when none of the four tabs own it.
  static AppBottomNavTab? tabFor(String rawPath) {
    final path = _normalize(rawPath);
    for (final d in destinations) {
      if (d.route == path) return d.tab;
    }
    return null;
  }

  /// Whether the floating compare button rides beside the dock on [rawPath]:
  /// catalog listings whose products can be compared.
  static bool comparesOn(String rawPath) {
    final path = _normalize(rawPath);
    return tabFor(path) == null &&
        path != AppRouteNames.bullions &&
        isVisibleOn(path);
  }

  /// Diamond result listings, where listing picks drive the comparison.
  static bool isDiamondListing(String rawPath) {
    final path = _normalize(rawPath);
    return path == AppRouteNames.diamondResults ||
        path == AppRouteNames.labGrownDiamondResults;
  }

  /// Whether the floating dock should show on [rawPath].
  static bool isVisibleOn(String rawPath) {
    final path = _normalize(rawPath);
    if (tabFor(path) != null) return true;
    if (listingRoutes.contains(path)) return true;
    // Brand watch catalogue listings (not their filter drawers).
    if (path.startsWith('/watches/brand/') && !path.endsWith('/filters')) {
      return true;
    }
    return false;
  }
}
