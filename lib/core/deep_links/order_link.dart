/// What a WhatsApp order button asks the app to open.
///
/// The buttons carry plain web links on [orderLinkHost]; the phone opens the
/// app for them through iOS universal links / Android App Links:
/// - buyer: `https://jewelry.gemworld.in/orders/{orderId}`
/// - shop:  `https://jewelry.gemworld.in/seller/orders?o={orderId}`
sealed class OrderLink {
  const OrderLink(this.orderId);

  /// The marketplace order's UUID, lower case.
  final String orderId;

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is OrderLink &&
      other.orderId == orderId;

  @override
  int get hashCode => Object.hash(runtimeType, orderId);
}

/// The buyer's own jewellery order.
class BuyerOrderLink extends OrderLink {
  const BuyerOrderLink(super.orderId);
}

/// A shop's incoming order (seller studio → orders).
class ShopOrderLink extends OrderLink {
  const ShopOrderLink(super.orderId);
}

/// The website the order buttons point at.
const orderLinkHost = 'jewelry.gemworld.in';

final _orderId = RegExp(
  r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}',
  caseSensitive: false,
);

/// The order [uri] points at, or null for any other link.
///
/// Accepts the full web link and the path-only form the router sees
/// (`/orders/{id}`). The id is picked out with a UUID pattern because
/// messages sent before the template fix carry `/orders/{{1}}<id>`.
OrderLink? parseOrderLink(Uri uri) {
  if (uri.host.isNotEmpty && uri.host.toLowerCase() != orderLinkHost) {
    return null;
  }
  final parts = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (parts.length == 2 && parts[0] == 'orders') {
    final id = _orderId.firstMatch(parts[1])?.group(0);
    return id == null ? null : BuyerOrderLink(id.toLowerCase());
  }
  if (parts.length == 2 && parts[0] == 'seller' && parts[1] == 'orders') {
    final id = _orderId.firstMatch(uri.queryParameters['o'] ?? '')?.group(0);
    return id == null ? null : ShopOrderLink(id.toLowerCase());
  }
  return null;
}
