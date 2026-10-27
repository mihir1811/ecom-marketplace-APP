import '../../../jewelry/data/mappers/marketplace_json.dart';
import '../../domain/models/marketplace_order.dart';
import '../../domain/models/marketplace_quote.dart';

typedef _J = MarketplaceJson;

/// Maps marketplace quote, checkout and order JSON (amounts are numbers in
/// rupees, the Razorpay amount in paise).
abstract final class JewelryCheckoutMapper {
  static CartQuote quote(Object? data) {
    final j = _J.obj(data);
    return CartQuote(
      lines: _J.listOf(j['lines'], _quoteLine),
      subtotal: _J.money(j['subtotal']),
      shipping: _J.money(j['shipping']),
      total: _J.money(j['total']),
      ready: j['ready'] == true,
    );
  }

  static QuoteLine _quoteLine(Map<String, dynamic> j) => QuoteLine(
    skuId: _J.text(j['skuId']) ?? '',
    listingId: _J.text(j['listingId']),
    listingSlug: _J.text(j['listingSlug']),
    title: _J.text(j['title']) ?? '',
    imageUrl: _J.text(j['imageUrl']),
    shopName: _J.text(j['shopName']) ?? '',
    options: _J.strings(j['options']),
    customValues: _J.strings(j['customValues']),
    unitPrice: _J.money(j['unitPrice']),
    quantity: _J.asInt(j['quantity']),
    lineTotal: _J.money(j['lineTotal']),
    maxQuantity: _J.asInt(j['maxQuantity']),
    cancellationWindowHours: _J.asInt(j['cancellationWindowHours']),
    problem: _J.text(j['problem']),
  );

  static MarketplaceCheckoutSession session(Object? data) {
    final j = _J.obj(data);
    return MarketplaceCheckoutSession(
      orderId: _J.text(j['orderId']) ?? '',
      orderNumber: _J.text(j['orderNumber']) ?? '',
      razorpayOrderId: _J.text(j['razorpayOrderId']) ?? '',
      amountPaise: _J.asInt(j['amount']),
      currency: _J.text(j['currency']) ?? 'INR',
      keyId: _J.text(j['keyId']) ?? '',
      name: _J.text(j['name']) ?? 'jewellery by GemWorld',
      description: _J.text(j['description']) ?? '',
      prefill: {
        for (final e in _J.strings(j['prefill']).entries)
          if (e.value.trim().isNotEmpty) e.key: e.value.trim(),
      },
    );
  }

  static List<MarketplaceOrder> orders(Object? data) =>
      _J.listOf(data, order);

  static MarketplaceOrder order(Map<String, dynamic> j) {
    final address = _J.obj(j['shippingAddress']);
    return MarketplaceOrder(
      id: _J.text(j['id']) ?? '',
      orderNumber: _J.text(j['orderNumber']) ?? '',
      status: _J.text(j['status']) ?? '',
      subtotal: _J.money(j['subtotal']),
      shippingTotal: _J.money(j['shippingTotal']),
      total: _J.money(j['total']),
      refundedTotal: _J.money(j['refundedTotal']),
      address: address.isEmpty
          ? null
          : MarketplaceAddress(
              fullName: _J.text(address['fullName']) ?? '',
              phone: _J.text(address['phone']) ?? '',
              line1: _J.text(address['line1']) ?? '',
              line2: _J.text(address['line2']),
              city: _J.text(address['city']) ?? '',
              state: _J.text(address['state']) ?? '',
              postalCode: _J.text(address['postalCode']) ?? '',
            ),
      buyerNote: _J.text(j['buyerNote']),
      paymentMethod: _J.text(j['paymentMethod']),
      paidAt: _J.date(j['paidAt']),
      createdAt: _J.date(j['createdAt']),
      items: _J.listOf(j['items'], _item),
      shipments: _J.listOf(j['shipments'], _shipment),
    );
  }

  static MarketplaceOrder orderFrom(Object? data) => order(_J.obj(data));

  static MarketplaceOrderItem _item(Map<String, dynamic> j) =>
      MarketplaceOrderItem(
        id: _J.text(j['id']) ?? '',
        title: _J.text(j['title']) ?? '',
        shopName: _J.text(j['shopName']) ?? '',
        listingSlug: _J.text(j['listingSlug']),
        imageUrl: _J.text(j['imageUrl']),
        options: _J.strings(j['options']),
        customValues: _J.strings(j['customValues']),
        unitPrice: _J.money(j['unitPrice']),
        quantity: _J.asInt(j['quantity'], 1),
        lineTotal: _J.money(j['lineTotal']),
        status: _J.text(j['status']) ?? '',
        canCancel: j['canCancel'] == true,
        cancellableUntil: _J.date(j['cancellableUntil']),
        cancellationWindowHours: _J.asInt(j['cancellationWindowHours']),
        cancelledAt: _J.date(j['cancelledAt']),
        cancelReason: _J.text(j['cancelReason']),
        refundAmount: _J.decimal(j['refundAmount']),
        refundStatus: _J.text(j['refundStatus']),
        refundedAt: _J.date(j['refundedAt']),
      );

  static MarketplaceShipment _shipment(Map<String, dynamic> j) =>
      MarketplaceShipment(
        shopName: _J.text(j['shopName']) ?? '',
        status: _J.text(j['status']) ?? '',
        itemIds: _J.stringList(j['itemIds']),
        shippingMethod: _J.text(j['shippingMethod']),
        courierName: _J.text(j['courierName']),
        trackingNumber: _J.text(j['trackingNumber']),
        trackingUrl: _J.text(j['trackingUrl']),
        expectedDeliveryAt: _J.text(j['expectedDeliveryAt']),
        sellerPhone: _J.text(j['sellerPhone']),
        updates: _J.listOf(
          j['updates'],
          (u) => MarketplaceOrderUpdate(
            id: _J.text(u['id']) ?? '',
            status: _J.text(u['status']) ?? '',
            message: _J.text(u['message']),
            location: _J.text(u['location']),
            imageUrls: _J.stringList(u['imageUrls']),
            createdAt: _J.date(u['createdAt']),
          ),
        ),
      );
}
