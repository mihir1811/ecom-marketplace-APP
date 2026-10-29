import '../../../../core/router/route_names.dart';
import '../../domain/agent_effect.dart';
import '../../domain/agent_session.dart';
import '../../domain/agent_tool.dart';
import '../../domain/tool_result.dart';

/// One page the agent may open.
class _Destination {
  const _Destination(
    this.label,
    this.route, [
    this.access = AgentToolAccess.public,
  ]);

  final String label;
  final String route;
  final AgentToolAccess access;
}

/// Opens an app page by name. Only allow-listed destinations exist — the
/// model can never send the user to an arbitrary path — and each carries
/// the account it needs.
class OpenScreenTool extends AgentTool {
  const OpenScreenTool();

  static const _destinations = <String, _Destination>{
    'home': _Destination('Home', AppRouteNames.home),
    'natural_diamonds': _Destination(
      'Natural diamonds',
      AppRouteNames.diamonds,
    ),
    'lab_grown_diamonds': _Destination(
      'Lab-grown diamonds',
      AppRouteNames.labGrownDiamonds,
    ),
    'gemstones': _Destination('Gemstones', AppRouteNames.gemstones),
    'jewelry': _Destination('Jewelry', AppRouteNames.jewelry),
    'jewelry_houses': _Destination(
      'Jewelry houses',
      AppRouteNames.jewelryHouses,
    ),
    'watches': _Destination('Watches', AppRouteNames.watches),
    'bullion': _Destination('Bullion', AppRouteNames.bullions),
    'auctions': _Destination('Auctions', AppRouteNames.auctions),
    'live_shows': _Destination('Live shows', AppRouteNames.liveShows),
    'compare': _Destination('Compare', AppRouteNames.comparison),
    'learn_diamonds': _Destination(
      'Diamond guide',
      AppRouteNames.diamondEducation,
    ),
    'learn_jewelry': _Destination(
      'Jewelry guide',
      AppRouteNames.jewelryEducation,
    ),
    'cart': _Destination('Cart', AppRouteNames.cart, AgentToolAccess.signedIn),
    'jewelry_bag': _Destination('Jewelry bag', AppRouteNames.jewelryBag),
    'my_orders': _Destination(
      'My orders',
      AppRouteNames.buyerOrders,
      AgentToolAccess.signedIn,
    ),
    'jewelry_orders': _Destination(
      'Jewelry orders',
      AppRouteNames.jewelryOrders,
      AgentToolAccess.signedIn,
    ),
    'wishlist': _Destination(
      'Wishlist',
      AppRouteNames.buyerWishlist,
      AgentToolAccess.signedIn,
    ),
    'wallet': _Destination(
      'Wallet',
      AppRouteNames.buyerWallet,
      AgentToolAccess.signedIn,
    ),
    'rewards': _Destination(
      'Rewards',
      AppRouteNames.buyerRewards,
      AgentToolAccess.signedIn,
    ),
    'my_offers': _Destination(
      'My offers',
      AppRouteNames.buyerOffers,
      AgentToolAccess.signedIn,
    ),
    'my_auction_activity': _Destination(
      'My auction activity',
      AppRouteNames.auctionActivity,
      AgentToolAccess.signedIn,
    ),
    'auction_wins': _Destination(
      'Auction wins',
      AppRouteNames.auctionWins,
      AgentToolAccess.signedIn,
    ),
    'refunds': _Destination(
      'Refunds',
      AppRouteNames.buyerRefunds,
      AgentToolAccess.signedIn,
    ),
    'recently_viewed': _Destination(
      'Recently viewed',
      AppRouteNames.buyerRecentlyViewed,
      AgentToolAccess.signedIn,
    ),
    'messages': _Destination(
      'Messages',
      AppRouteNames.buyerMessages,
      AgentToolAccess.signedIn,
    ),
    'notifications': _Destination(
      'Notifications',
      AppRouteNames.buyerNotifications,
      AgentToolAccess.signedIn,
    ),
    'inquiries': _Destination(
      'Inquiries',
      AppRouteNames.buyerInquiries,
      AgentToolAccess.signedIn,
    ),
    'profile': _Destination(
      'Profile',
      AppRouteNames.buyerProfile,
      AgentToolAccess.signedIn,
    ),
    'settings': _Destination(
      'Settings',
      AppRouteNames.buyerSettings,
      AgentToolAccess.signedIn,
    ),
    'help': _Destination(
      'Help center',
      AppRouteNames.buyerHelpCenter,
      AgentToolAccess.signedIn,
    ),
    'seller_dashboard': _Destination(
      'Seller dashboard',
      AppRouteNames.sellerDashboard,
      AgentToolAccess.seller,
    ),
    'seller_orders': _Destination(
      'Seller orders',
      AppRouteNames.sellerOrders,
      AgentToolAccess.seller,
    ),
    'seller_products': _Destination(
      'My products',
      AppRouteNames.sellerProducts,
      AgentToolAccess.seller,
    ),
    'seller_offers': _Destination(
      'Offers received',
      AppRouteNames.sellerOffers,
      AgentToolAccess.seller,
    ),
    'seller_auctions': _Destination(
      'My auctions',
      AppRouteNames.sellerAuctions,
      AgentToolAccess.seller,
    ),
    'seller_analytics': _Destination(
      'Analytics',
      AppRouteNames.sellerAnalytics,
      AgentToolAccess.seller,
    ),
    'seller_wallet': _Destination(
      'Seller wallet',
      AppRouteNames.sellerWallet,
      AgentToolAccess.seller,
    ),
    'seller_promotions': _Destination(
      'Promotions',
      AppRouteNames.sellerPromotions,
      AgentToolAccess.seller,
    ),
    'seller_inquiries': _Destination(
      'Seller inquiries',
      AppRouteNames.sellerInquiries,
      AgentToolAccess.seller,
    ),
    'seller_messages': _Destination(
      'Seller messages',
      AppRouteNames.sellerChat,
      AgentToolAccess.seller,
    ),
    'seller_notifications': _Destination(
      'Seller notifications',
      AppRouteNames.sellerNotifications,
      AgentToolAccess.seller,
    ),
  };

  /// Pages that exist on both sides; the seller's copy is used on the
  /// seller side.
  static const _sellerTwin = {
    'wallet': 'seller_wallet',
    'messages': 'seller_messages',
    'notifications': 'seller_notifications',
    'inquiries': 'seller_inquiries',
  };

  @override
  String get name => 'open_screen';

  @override
  String get description =>
      'Open an app page by name ("take me to my wallet", "open seller '
      'dashboard"). Use only for plain navigation; use the data tools for '
      'questions.';

  @override
  Map<String, Object?> get parameters => {
    'type': 'object',
    'properties': {
      'screen': {'type': 'string', 'enum': _destinations.keys.toList()},
    },
    'required': ['screen'],
    'additionalProperties': false,
  };

  @override
  String progressLabel(Map<String, Object?> args) => 'Opening…';

  @override
  Future<ToolResult> execute(
    Map<String, Object?> args,
    AgentToolContext context,
  ) async {
    var key = args['screen']?.toString() ?? '';
    final session = context.session;
    if (session.onSellerSide && session.isSeller) {
      key = _sellerTwin[key] ?? key;
    }
    final destination = _destinations[key];
    if (destination == null) {
      return ToolFailure(
        'Unknown screen "$key". Pick one of the listed screens.',
        recoverable: true,
      );
    }
    if (!destination.access.allows(session)) {
      return ToolFailure(destination.access.deniedMessage(session));
    }
    return ToolSuccess(
      summary: 'Opening ${destination.label}.',
      completesTurn: true,
      effects: [OpenPageEffect(destination.route)],
    );
  }
}
