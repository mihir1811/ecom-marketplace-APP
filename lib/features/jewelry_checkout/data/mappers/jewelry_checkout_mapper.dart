import '../../../jewelry/data/mappers/marketplace_json.dart';
import '../../domain/models/marketplace_charge.dart';
import '../../domain/models/marketplace_invoice.dart';
import '../../domain/models/marketplace_order.dart';
import '../../domain/models/marketplace_quote.dart';
import '../../domain/models/shop_order.dart';

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
      taxes: taxesOf(j),
      taxTotal: _J.money(j['taxTotal']),
    );
  }

  /// `taxes[]` of a quote, order or line; a missing list (before taxes
  /// go live) reads as none.
  static List<MarketplaceCharge> taxesOf(Map<String, dynamic> j) => [
    for (final t in _J.listOf(j['taxes'], _charge))
      if (t.label.isNotEmpty) t,
  ];

  static MarketplaceCharge _charge(Map<String, dynamic> j) => MarketplaceCharge(
    name: _J.text(j['name']) ?? '',
    label: _J.text(j['label']) ?? _J.text(j['name']) ?? '',
    amount: _J.money(j['amount']),
  );

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
    taxes: taxesOf(j),
    taxAmount: _J.money(j['taxAmount']),
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

  static List<MarketplaceOrder> orders(Object? data) => _J.listOf(data, order);

  /// `GET /marketplace/seller/orders`: a list, or a page `{ items: [...] }`.
  static List<ShopOrder> shopOrders(Object? data) {
    final raw = data is Map
        ? (_J.obj(data)['items'] ?? _J.obj(data)['orders'])
        : data;
    return _J.listOf(raw, shopOrder);
  }

  static ShopOrder shopOrder(Map<String, dynamic> j) {
    final shipment = _J.obj(j['shipment']);
    final buyer = _J.obj(j['buyer']);
    return ShopOrder(
      id: _J.text(j['id']) ?? '',
      orderNumber: _J.text(j['orderNumber']) ?? '',
      buyerName: _J.text(j['buyerName']) ?? _J.text(buyer['name']) ?? '',
      address: _address(j['shippingAddress']),
      buyerNote: _J.text(j['buyerNote']),
      items: _J.listOf(j['items'], _item),
      shipment: shipment.isEmpty ? null : _shipment(shipment),
      shopTotal: _J.money(j['shopTotal']),
      paidAt: _J.date(j['paidAt']),
      createdAt: _J.date(j['createdAt']),
    );
  }

  static MarketplaceAddress? _address(Object? raw) {
    final address = _J.obj(raw);
    if (address.isEmpty) return null;
    return MarketplaceAddress(
      fullName: _J.text(address['fullName']) ?? '',
      phone: _J.text(address['phone']) ?? '',
      line1: _J.text(address['line1']) ?? '',
      line2: _J.text(address['line2']),
      city: _J.text(address['city']) ?? '',
      state: _J.text(address['state']) ?? '',
      postalCode: _J.text(address['postalCode']) ?? '',
      country: _J.text(address['country']) ?? 'IN',
    );
  }

  static MarketplaceOrder order(Map<String, dynamic> j) {
    return MarketplaceOrder(
      id: _J.text(j['id']) ?? '',
      orderNumber: _J.text(j['orderNumber']) ?? '',
      status: _J.text(j['status']) ?? '',
      subtotal: _J.money(j['subtotal']),
      shippingTotal: _J.money(j['shippingTotal']),
      total: _J.money(j['total']),
      refundedTotal: _J.money(j['refundedTotal']),
      address: _address(j['shippingAddress']),
      buyerNote: _J.text(j['buyerNote']),
      paymentMethod: _J.text(j['paymentMethod']),
      paidAt: _J.date(j['paidAt']),
      createdAt: _J.date(j['createdAt']),
      items: _J.listOf(j['items'], _item),
      shipments: _J.listOf(j['shipments'], _shipment),
      taxes: taxesOf(j),
      taxTotal: _J.money(j['taxTotal']),
      invoice: _invoiceRef(j['invoice']),
      hasInvoiceField: j.containsKey('invoice'),
    );
  }

  static MarketplaceInvoiceRef? _invoiceRef(Object? raw) {
    final j = _J.obj(raw);
    final number = _J.text(j['number']);
    if (number == null) return null;
    return MarketplaceInvoiceRef(
      number: number,
      issuedAt: _J.date(j['issuedAt']),
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
        taxes: taxesOf(j),
        taxAmount: _J.money(j['taxAmount']),
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

  static MarketplaceInvoice invoice(Object? data) {
    final j = _J.obj(data);
    final issuer = _J.obj(j['issuer']);
    final buyer = _J.obj(j['buyer']);
    final shipTo = _J.obj(j['shipTo']);
    final supply = _J.obj(j['placeOfSupply']);
    final totals = _J.obj(j['totals']);
    final cityLine = [
      _J.text(issuer['city']),
      [
        _J.text(issuer['state']),
        _J.text(issuer['postalCode']),
      ].whereType<String>().join(' '),
    ].whereType<String>().where((s) => s.isNotEmpty).join(', ');
    return MarketplaceInvoice(
      number: _J.text(j['number']) ?? '',
      issuedAt: _J.date(j['issuedAt']),
      orderId: _J.text(j['orderId']) ?? '',
      orderNumber: _J.text(j['orderNumber']) ?? '',
      orderedAt: _J.date(j['orderedAt']),
      paidAt: _J.date(j['paidAt']),
      paymentMethod: _J.text(j['paymentMethod']),
      paymentReference: _J.text(j['paymentReference']),
      currency: _J.text(j['currency']) ?? 'INR',
      issuer: InvoiceIssuer(
        legalName: _J.text(issuer['legalName']) ?? '',
        tradeName: _J.text(issuer['tradeName']),
        gstin: _J.text(issuer['gstin']),
        pan: _J.text(issuer['pan']),
        addressLines: [
          ?_J.text(issuer['addressLine1']),
          ?_J.text(issuer['addressLine2']),
          if (cityLine.isNotEmpty) cityLine,
        ],
        state: _J.text(issuer['state']),
        stateCode: _J.text(issuer['stateCode']),
        email: _J.text(issuer['email']),
        phone: _J.text(issuer['phone']),
        defaultHsn: _J.text(issuer['defaultHsn']),
        footerNote: _J.text(issuer['footerNote']),
      ),
      buyer: InvoiceBuyer(
        name: _J.text(buyer['name']) ?? '',
        email: _J.text(buyer['email']),
        phone: _J.text(buyer['phone']),
      ),
      shipTo: InvoiceShipTo(
        fullName: _J.text(shipTo['fullName']) ?? '',
        phone: _J.text(shipTo['phone']),
        lines: _J.stringList(shipTo['lines']),
        state: _J.text(shipTo['state']),
        country: _J.text(shipTo['country']),
      ),
      placeOfSupplyState: _J.text(supply['state']),
      placeOfSupplyCode: _J.text(supply['code']),
      supplyType: _J.text(j['supplyType']) ?? 'UNKNOWN',
      lines: _J.listOf(
        j['lines'],
        (l) => InvoiceLine(
          id: _J.text(l['id']) ?? '',
          title: _J.text(l['title']) ?? '',
          maker: _J.text(l['maker']),
          details: _J.text(l['details']),
          hsnCode: _J.text(l['hsnCode']),
          quantity: _J.asInt(l['quantity'], 1),
          unitPrice: _J.money(l['unitPrice']),
          taxableValue: _J.money(l['taxableValue']),
          taxes: _J.listOf(l['taxes'], _invoiceTax),
          taxAmount: _J.money(l['taxAmount']),
          total: _J.money(l['total']),
          cancelled: l['cancelled'] == true,
        ),
      ),
      taxSummary: _J.listOf(j['taxSummary'], _invoiceTax),
      totals: InvoiceTotals(
        taxableValue: _J.money(totals['taxableValue']),
        taxTotal: _J.money(totals['taxTotal']),
        shipping: _J.money(totals['shipping']),
        total: _J.money(totals['total']),
        inWords: _J.text(totals['inWords']),
      ),
      refunds: _J.listOf(
        j['refunds'],
        (r) => InvoiceRefund(
          title: _J.text(r['title']) ?? '',
          amount: _J.money(r['amount']),
          status: _J.text(r['status']),
          cancelledAt: _J.date(r['cancelledAt']),
          refundedAt: _J.date(r['refundedAt']),
        ),
      ),
      refundedTotal: _J.money(j['refundedTotal']),
    );
  }

  static InvoiceTax _invoiceTax(Map<String, dynamic> j) => InvoiceTax(
    label: _J.text(j['label']) ?? _J.text(j['name']) ?? '',
    rate: _J.decimal(j['rate']),
    taxableValue: _J.money(j['taxableValue']),
    amount: _J.money(j['amount']),
  );
}
