import '../../domain/models/payment_models.dart';

/// Parses payment / order JSON into domain models.
abstract final class PaymentMapper {
  static ExchangeRate exchangeRateFromJson(Map<String, dynamic> json) {
    return ExchangeRate(
      rate: _num(json['rate']) ?? 0,
      from: _str(json['from']) ?? 'USD',
      to: _str(json['to']) ?? 'INR',
      source: _str(json['source']),
      updatedAt: _date(json['updatedAt']),
    );
  }

  static PaymentCheckoutSession checkoutSessionFromJson(
    Map<String, dynamic> json,
  ) {
    final user = json['user'];
    final userMap =
        user is Map<String, dynamic> ? user : const <String, dynamic>{};
    return PaymentCheckoutSession(
      orderId: _str(json['orderId']) ?? '',
      razorpayOrderId: _str(json['razorpayOrderId']) ?? '',
      amountPaise: _int(json['amount']) ??
          _int(json['amountPaise']) ??
          _int(json['amountDue']) ??
          0,
      currency: _str(json['currency']) ?? 'INR',
      keyId: _str(json['keyId']) ?? '',
      amountUsd: _num(json['amountUsd']),
      amountInr: _num(json['amountInr']) ?? _num(json['amountDueInr']),
      exchangeRate: _num(json['exchangeRate']),
      walletAppliedInr: _num(json['walletAppliedInr']) ??
          _num(json['walletAmount']) ??
          _num(json['walletDebited']),
      status: _str(json['status']) ?? _str(json['orderStatus']),
      userName: _str(userMap['name']),
      userEmail: _str(userMap['email']),
      userPhone: _str(userMap['phone']) ?? _str(userMap['contact']),
    );
  }

  static PaymentOrder orderFromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    final items = <PaymentOrderItem>[];
    if (itemsJson is List) {
      for (final item in itemsJson) {
        if (item is! Map<String, dynamic>) continue;
        items.add(orderItemFromJson(item));
      }
    }

    final sellersJson = json['sellers'];
    final sellers = <PaymentOrderSeller>[];
    if (sellersJson is List) {
      for (final s in sellersJson) {
        if (s is! Map<String, dynamic>) continue;
        sellers.add(
          PaymentOrderSeller(
            id: _str(s['id']) ?? '',
            companyName: _str(s['companyName']) ?? 'Seller',
            sellerType: _str(s['sellerType']),
            city: _str(s['city']),
            country: _str(s['country']),
            isVerified: s['isVerified'] == true,
          ),
        );
      }
    }

    final pricingJson = json['pricing'];
    PaymentOrderPricing? pricing;
    if (pricingJson is Map<String, dynamic>) {
      pricing = PaymentOrderPricing(
        subtotal: _num(pricingJson['subtotal']) ?? 0,
        discountedSubtotal: _num(pricingJson['discountedSubtotal']) ?? 0,
        promotionDiscount: _num(pricingJson['promotionDiscount']) ?? 0,
        gst: _num(pricingJson['gst']) ?? 0,
        transactionFee: _num(pricingJson['transactionFee']) ?? 0,
        platformFee: _num(pricingJson['platformFee']) ?? 0,
        gemworldVerificationCommission:
            _num(pricingJson['gemworldVerificationCommission']) ?? 0,
        totalUsd: _num(pricingJson['totalUsd']) ?? 0,
        exchangeRate: _num(pricingJson['exchangeRate']) ?? 0,
        subtotalInr: _num(pricingJson['subtotalInr']) ?? 0,
        totalInr: _num(pricingJson['totalInr']) ?? 0,
      );
    }

    return PaymentOrder(
      id: _str(json['id']) ?? '',
      status: _str(json['status']) ?? 'PENDING',
      amount: _num(json['amount']) ?? 0,
      amountUsd: _num(json['amountUsd']) ?? 0,
      currency: _str(json['currency']) ?? 'INR',
      createdAt: _date(json['createdAt']),
      receipt: _str(json['receipt']),
      invoiceNumber: _str(json['invoiceNumber']),
      invoiceUrl: _str(json['invoiceUrl']),
      orderType: _str(json['orderType']),
      items: items,
      pricing: pricing,
      sellers: sellers,
    );
  }

  static PaymentOrderItem orderItemFromJson(Map<String, dynamic> json) {
    final seller = json['seller'];
    final sellerMap =
        seller is Map<String, dynamic> ? seller : const <String, dynamic>{};
    return PaymentOrderItem(
      productId: _str(json['productId']) ?? '',
      productType: _str(json['productType']) ?? '',
      name: _str(json['name']) ?? 'Product',
      quantity: _int(json['quantity']) ?? 1,
      unitPrice: _num(json['unitPrice']) ?? 0,
      lineTotal: _num(json['lineTotal']) ?? 0,
      image: _str(json['image']),
      sellerId: _str(json['sellerId']) ?? _str(sellerMap['id']),
      sellerName: _str(sellerMap['companyName']),
      isReturned: json['isReturned'] == true,
    );
  }

  static PaymentOrdersPage ordersPageFromJson(
    Map<String, dynamic> root,
  ) {
    final data = root['data'];
    final dataMap =
        data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final ordersJson = dataMap['orders'] ?? data;
    final orders = <PaymentOrder>[];
    if (ordersJson is List) {
      for (final o in ordersJson) {
        if (o is! Map<String, dynamic>) continue;
        final order = orderFromJson(o);
        if (order.id.isEmpty) continue;
        orders.add(order);
      }
    }

    final meta = root['meta'];
    final metaMap =
        meta is Map<String, dynamic> ? meta : const <String, dynamic>{};
    final pagination = metaMap['pagination'];
    final pageMap = pagination is Map<String, dynamic>
        ? pagination
        : const <String, dynamic>{};

    return PaymentOrdersPage(
      orders: orders,
      page: _int(pageMap['page']) ?? 1,
      limit: _int(pageMap['limit']) ?? orders.length,
      total: _int(pageMap['total']) ?? orders.length,
      totalPages: _int(pageMap['totalPages']) ?? 1,
    );
  }

  static String? _str(Object? v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static double? _num(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int? _int(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static DateTime? _date(Object? v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}
