import 'marketplace_order.dart';

/// A paid order as the jewellery shop sees it (`GET /marketplace/seller/orders`):
/// only this shop's pieces and shipment.
class ShopOrder {
  const ShopOrder({
    required this.id,
    required this.orderNumber,
    required this.buyerName,
    required this.items,
    required this.shopTotal,
    this.address,
    this.buyerNote,
    this.shipment,
    this.paidAt,
    this.createdAt,
  });

  final String id;
  final String orderNumber;
  final String buyerName;
  final MarketplaceAddress? address;
  final String? buyerNote;
  final List<MarketplaceOrderItem> items;
  final MarketplaceShipment? shipment;

  /// The price of this shop's pieces.
  final double shopTotal;
  final DateTime? paidAt;
  final DateTime? createdAt;

  String? get coverImageUrl {
    for (final item in items) {
      final url = item.imageUrl;
      if (url != null && url.isNotEmpty) return url;
    }
    return null;
  }
}
