import '../../../router/app_navigation.dart';
import '../../../router/route_names.dart';

/// The group of screens a location belongs to. The top bar is configured
/// per section, never per screen: every screen of a section shows the same
/// bar, so moving between them only ever changes the page underneath.
enum TopBarSection {
  /// Home and the diamond / rough / gemstone / watch / bullion / auction
  /// catalogs.
  marketplace,

  /// The jewellery marketplace. It checks out through its own bag, never
  /// the common cart.
  jewelry,

  /// The buyer's own account area (`/buyer/...`).
  buyer,

  /// The seller workspace (`/seller/...`).
  seller,

  /// Flows that need the whole screen for one job (sign-in, cart, bag,
  /// checkout, filters, viewers, legal pages): back only, no actions.
  focused,
}

/// A shortcut the top bar can carry.
enum TopBarAction {
  notifications,

  /// The common cart (diamonds, rough, gemstones, watches, bullions).
  cart,

  /// The jewellery-only bag. Separate checkout from [cart]; a section shows
  /// at most one of the two.
  jewelryBag,

  /// The side's orders (buyer purchases / seller orders to fulfil).
  orders,

  /// Seller business chat.
  messages,
}

/// What the bar shows for one [TopBarSection].
class TopBarSpec {
  const TopBarSpec({required this.search, required this.actions});

  /// Whether the global catalog search sits in the bar.
  final bool search;

  /// Trailing shortcuts, left to right.
  final List<TopBarAction> actions;
}

/// Single source of truth for the top bar across the app.
///
/// Screens never pick their own bar icons: each bar asks the registry for the
/// current location's [TopBarSpec]. To change what a group of screens shows,
/// edit [specs]; to move a route between groups, edit [sectionFor].
abstract final class TopBarRegistry {
  static const specs = <TopBarSection, TopBarSpec>{
    TopBarSection.marketplace: TopBarSpec(
      search: true,
      actions: [TopBarAction.notifications, TopBarAction.cart],
    ),
    TopBarSection.jewelry: TopBarSpec(
      search: true,
      actions: [TopBarAction.notifications, TopBarAction.jewelryBag],
    ),
    TopBarSection.buyer: TopBarSpec(
      search: false,
      actions: [TopBarAction.notifications, TopBarAction.orders],
    ),
    TopBarSection.seller: TopBarSpec(
      search: false,
      actions: [
        TopBarAction.notifications,
        TopBarAction.messages,
        TopBarAction.orders,
      ],
    ),
    TopBarSection.focused: TopBarSpec(search: false, actions: []),
  };

  static const _focusedExact = <String>{
    AppRouteNames.login,
    AppRouteNames.register,
    AppRouteNames.forgotPassword,
    AppRouteNames.verifyOtp,
    AppRouteNames.resetPassword,
    AppRouteNames.recoverAccount,
    AppRouteNames.cart,
    AppRouteNames.jewelryBag,
    AppRouteNames.jewelryCheckout,
    AppRouteNames.aboutUs,
    AppRouteNames.privacyPolicy,
    AppRouteNames.termsAndConditions,
    AppRouteNames.buyerAbout,
    AppRouteNames.buyerPrivacy,
    AppRouteNames.buyerTerms,
    AppRouteNames.sellerAbout,
    AppRouteNames.sellerPrivacy,
    AppRouteNames.sellerTerms,
  };

  static const _focusedPrefixes = <String>[
    '/payment/',
    '/viewer/',
    '/learn/',
    // A single live show is a full-screen stage; the shows list is not.
    '/live/',
    AppRouteNames.policies,
    AppRouteNames.buyerPolicies,
    AppRouteNames.sellerPolicies,
  ];

  static TopBarSection sectionFor(String location) {
    final path = AppNavigation.canonicalPath(location);
    if (_focusedExact.contains(path) ||
        path.endsWith('/filters') ||
        _focusedPrefixes.any(
          (p) => path == p || path.startsWith(p.endsWith('/') ? p : '$p/'),
        )) {
      return TopBarSection.focused;
    }
    if (path == '/seller' || path.startsWith('/seller/')) {
      return TopBarSection.seller;
    }
    if (path == '/buyer' || path.startsWith('/buyer/')) {
      return TopBarSection.buyer;
    }
    if (path == AppRouteNames.jewelry ||
        path.startsWith('${AppRouteNames.jewelry}/') ||
        path.startsWith('/product/jewelry/')) {
      return TopBarSection.jewelry;
    }
    return TopBarSection.marketplace;
  }

  static TopBarSpec specFor(String location) => specs[sectionFor(location)]!;
}
