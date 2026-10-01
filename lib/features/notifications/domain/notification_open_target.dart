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

/// An absolute http(s) link opened outside the app.
class NotificationExternal extends NotificationOpenTarget {
  const NotificationExternal(this.url);

  final Uri url;
}

/// Maps a notification `type` and `link` onto an existing app screen.
NotificationOpenTarget notificationOpenTarget(
  AppNotification notification, {
  required bool isSeller,
}) {
  final data = notification.data;
  switch (notification.type) {
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
      return const NotificationInApp(AppRouteNames.sellerAuctions);
    case 'OFFER_RECEIVED':
      return const NotificationInApp(AppRouteNames.sellerOffers);
    case 'HELP_CENTER_ANSWERED':
      return NotificationInApp(
        isSeller
            ? AppRouteNames.sellerHelpCenter
            : AppRouteNames.buyerHelpCenter,
      );
    case 'ADMIN_BROADCAST':
      return _fromLink(notification.link, isSeller: isSeller);
    case 'AUCTION_OUTBID':
    case 'AUCTION_WON':
    case 'OFFER_ACCEPTED':
    case 'OFFER_REJECTED':
      return _fromLink(notification.link, isSeller: isSeller);
    default:
      return _fromLink(notification.link, isSeller: isSeller);
  }
}

NotificationOpenTarget _fromLink(String link, {required bool isSeller}) {
  final trimmed = link.trim();
  if (trimmed.isEmpty) return const NotificationStay();
  final uri = Uri.tryParse(trimmed);
  if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
    return NotificationExternal(uri);
  }
  final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
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
