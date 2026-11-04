import '../../../core/router/route_names.dart';
import '../../chat/domain/models/chat_product_type.dart';
import '../../chat/domain/models/chat_thread.dart';
import 'models/app_notification.dart';

/// Where a tapped notification should go.
sealed class NotificationOpenTarget {
  const NotificationOpenTarget();
}

/// Stay on the inbox (unknown type, or no matching screen yet).
class NotificationStay extends NotificationOpenTarget {
  const NotificationStay();
}

/// An in-app route.
class NotificationInApp extends NotificationOpenTarget {
  const NotificationInApp(this.route);

  final String route;
}

/// An absolute http(s) link opened outside the app, or in the in-app
/// browser when [inApp].
class NotificationExternal extends NotificationOpenTarget {
  const NotificationExternal(this.url, {this.inApp = false});

  final Uri url;
  final bool inApp;
}

/// Maps a notification `type` and `link` onto an existing app screen.
NotificationOpenTarget notificationOpenTarget(
  AppNotification notification, {
  required bool isSeller,
}) {
  final data = notification.data;
  // Jewellery marketplace pushes reuse ORDER_* type names; the entity type
  // tells them apart from catalog orders.
  switch (data['entityType']) {
    case 'MARKETPLACE_ORDER':
      final orderId = data['orderId'] ?? '';
      final forBuyer =
          notification.type != 'ORDER_RECEIVED' &&
          notification.type != 'ORDER_CANCELLED_BY_BUYER';
      if (forBuyer && orderId.isNotEmpty) {
        return NotificationInApp(AppRouteNames.jewelryOrderDetailPath(orderId));
      }
      // Shop orders are managed in the seller studio on the website.
      return _fromLink(notification.link, isSeller: isSeller);
    case 'MARKETPLACE_CHAT':
      // Shop messages live on jewelry.gemworld.in for now.
      return _fromLink(notification.link, isSeller: isSeller);
    case 'AD':
      return _spotlightAd(notification);
  }
  switch (notification.type) {
    // Spotlight (seller ads): open the app's own ad screen.
    case 'AD_APPROVED':
    case 'AD_REJECTED':
    case 'AD_STOPPED':
    case 'AD_EXPIRED':
    case 'AD_ENDED':
      return _spotlightAd(notification);
    case 'CHAT_MESSAGE':
      // Open the conversation itself when the product is known; chats are
      // always about a product, so otherwise fall back to the inbox.
      final productType = ChatProductType.fromApi(data['productType']);
      final productId = data['productId'] ?? '';
      final senderId = data['senderId'] ?? '';
      if (productType != null && productId.isNotEmpty && senderId.isNotEmpty) {
        final threadId = ChatThread.encodeId(
          productType: productType,
          productId: productId,
          peerUserId: senderId,
        );
        return NotificationInApp(
          isSeller
              ? AppRouteNames.sellerChatDetailPath(threadId)
              : AppRouteNames.buyerChatDetailPath(threadId),
        );
      }
      return NotificationInApp(
        isSeller ? AppRouteNames.sellerChat : AppRouteNames.buyerMessages,
      );
    case 'ORDER_ACCEPTED':
    case 'ORDER_REJECTED':
      final orderId = data['orderId'];
      if (orderId == null || orderId.isEmpty) return const NotificationStay();
      return NotificationInApp(AppRouteNames.buyerOrderDetailPath(orderId));
    case final type when type.startsWith('ORDER_') && isSeller:
      // New / updated incoming order for the seller.
      final id = data['sellerOrderId'] ?? data['orderId'] ?? '';
      return NotificationInApp(
        id.isEmpty
            ? AppRouteNames.sellerOrders
            : AppRouteNames.sellerOrderDetailPath(id),
      );
    case 'AUCTION_NEW_BID':
    case 'AUCTION_ENDED_SELLER':
    case 'AUCTION_WINNER_UNPAID_SELLER':
      return const NotificationInApp(AppRouteNames.sellerAuctions);
    case 'AUCTION_WON':
      // The win waits in the cart at the winning bid; it is paid there.
      return const NotificationInApp(AppRouteNames.cart);
    case 'AUCTION_WIN_UNPAID':
      final auctionId = data['auctionId'] ?? '';
      if (auctionId.isNotEmpty) {
        return NotificationInApp(AppRouteNames.auctionDetailPath(auctionId));
      }
      return _fromLink(notification.link, isSeller: false);
    case 'OFFER_RECEIVED':
    case 'OFFER_COUNTERED_BY_BUYER':
    case 'OFFER_COUNTER_ACCEPTED':
    case 'OFFER_COUNTER_DECLINED':
      return const NotificationInApp(AppRouteNames.sellerOffers);
    case 'OFFER_COUNTERED':
      // `/user/offers?counter=<offerId>`: open that counter-offer to answer.
      final counterId =
          _offerQueryId(notification.link, 'counter') ?? data['offerId'] ?? '';
      return NotificationInApp(
        counterId.isEmpty
            ? AppRouteNames.buyerOffers
            : AppRouteNames.buyerOfferCounterPath(counterId),
      );
    case 'HELP_CENTER_ANSWERED':
      return NotificationInApp(
        isSeller
            ? AppRouteNames.sellerHelpCenter
            : AppRouteNames.buyerHelpCenter,
      );
    case 'REWARD_CLUB_REACHED':
      return isSeller
          ? const NotificationStay()
          : const NotificationInApp(AppRouteNames.buyerRewards);
    case 'ADMIN_BROADCAST':
      return _fromLink(notification.link, isSeller: isSeller);
    case 'OFFER_ACCEPTED':
      // Like the website's `/user/offers?pay=<offerId>`: put the stone in
      // the bag at the offer price and open checkout.
      final payId = _offerPayId(notification.link) ?? data['offerId'] ?? '';
      return NotificationInApp(
        payId.isEmpty
            ? AppRouteNames.buyerOffers
            : AppRouteNames.buyerOfferPayPath(payId),
      );
    case 'OFFER_REJECTED':
    case 'OFFER_EXPIRED':
      return const NotificationInApp(AppRouteNames.buyerOffers);
    case 'AUCTION_OUTBID':
      return _fromLink(notification.link, isSeller: isSeller);
    default:
      return _fromLink(notification.link, isSeller: isSeller);
  }
}

/// A seller's ad push: `adId` in data, or the `/seller/spotlight/<adId>`
/// link; the ads list when neither is there.
///
/// Jewellery shop ads carry the full studio address
/// (`https://<jewellery site>/seller/advertising/<adId>`); it opens in the
/// in-app browser, since the app books diamond-site ads only.
NotificationOpenTarget _spotlightAd(AppNotification notification) {
  final link = notification.link.trim();
  if (link.toLowerCase().startsWith('http')) {
    final uri = Uri.tryParse(link);
    if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
      return NotificationExternal(uri, inApp: true);
    }
  }
  final id = (notification.data['adId'] ?? '').trim().isNotEmpty
      ? notification.data['adId']!.trim()
      : _spotlightAdIdFromLink(notification.link);
  return NotificationInApp(
    id == null || id.isEmpty
        ? AppRouteNames.sellerSpotlight
        : AppRouteNames.sellerSpotlightDetailPath(id),
  );
}

String? _spotlightAdIdFromLink(String link) {
  final uri = Uri.tryParse(link.trim());
  final m = RegExp(r'^/seller/spotlight/([^/?#]+)').firstMatch(uri?.path ?? '');
  return m?.group(1);
}

NotificationOpenTarget _fromLink(String link, {required bool isSeller}) {
  final trimmed = link.trim();
  if (trimmed.isEmpty) return const NotificationStay();
  final uri = Uri.tryParse(trimmed);
  if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
    return NotificationExternal(uri);
  }
  final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
  final spotlightPath = Uri.tryParse(path)?.path ?? path;
  if (spotlightPath == '/seller/spotlight') {
    return const NotificationInApp(AppRouteNames.sellerSpotlight);
  }
  if (_spotlightAdIdFromLink(path) case final adId?) {
    return NotificationInApp(AppRouteNames.sellerSpotlightDetailPath(adId));
  }
  if (path == '/user/cart' || path == '/cart') {
    return const NotificationInApp(AppRouteNames.cart);
  }
  // Website "Pay now" link for accepted offers.
  final offersPath = Uri.tryParse(path)?.path ?? path;
  if (offersPath == '/user/offers' || offersPath.startsWith('/user/offers/')) {
    final payId = _offerPayId(path);
    final counterId = _offerQueryId(path, 'counter');
    return NotificationInApp(
      payId != null
          ? AppRouteNames.buyerOfferPayPath(payId)
          : counterId != null
          ? AppRouteNames.buyerOfferCounterPath(counterId)
          : AppRouteNames.buyerOffers,
    );
  }
  final order = RegExp(r'^/user/orders/([^/]+)$').firstMatch(path);
  if (order != null) {
    return NotificationInApp(
      AppRouteNames.buyerOrderDetailPath(order.group(1)!),
    );
  }
  if (path.startsWith('/auctions/')) {
    final id = path.substring('/auctions/'.length).split('/').first;
    if (id.isEmpty || id == 'activity') {
      return const NotificationInApp(AppRouteNames.auctionActivity);
    }
    if (id == 'wins') {
      return const NotificationInApp(AppRouteNames.auctionWins);
    }
    if (isSeller) {
      return const NotificationInApp(AppRouteNames.sellerAuctions);
    }
    return NotificationInApp(AppRouteNames.auctionDetailPath(id));
  }
  return const NotificationStay();
}

/// `<offerId>` from `/user/offers?pay=<offerId>`.
String? _offerPayId(String link) => _offerQueryId(link, 'pay');

/// `<offerId>` from `/user/offers?<key>=<offerId>`.
String? _offerQueryId(String link, String key) {
  final uri = Uri.tryParse(link.trim());
  final id = uri?.queryParameters[key]?.trim();
  return id == null || id.isEmpty ? null : id;
}
