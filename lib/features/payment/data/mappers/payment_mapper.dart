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
    final userMap = user is Map<String, dynamic>
        ? user
        : const <String, dynamic>{};
    return PaymentCheckoutSession(
      orderId: _str(json['orderId']) ?? '',
      razorpayOrderId: _str(json['razorpayOrderId']) ?? '',
      amountPaise:
          _int(json['amount']) ??
          _int(json['amountPaise']) ??
          _int(json['amountDue']) ??
          0,
      currency: _str(json['currency']) ?? 'INR',
      keyId: _str(json['keyId']) ?? '',
      amountUsd: _num(json['amountUsd']),
      amountInr: _num(json['amountInr']) ?? _num(json['amountDueInr']),
      exchangeRate: _num(json['exchangeRate']),
      walletAppliedInr:
          _num(json['walletAppliedInr']) ??
          _num(json['walletAmount']) ??
          _num(json['walletDebited']),
      rewardPointsUsed: _int(json['rewardPointsUsed']) ?? 0,
      rewardPointsAmountInr: _num(json['rewardPointsAmount']) ?? 0,
      razorpayAmountInr: _num(json['razorpayAmountInr']),
      paidWithWallet: json['paidWithWallet'] == true,
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
      createdAt:
          _date(json['createdAt']) ??
          _date(json['created_at']) ??
          _date(json['updatedAt']) ??
          _date(json['updated_at']),
      receipt: _str(json['receipt']),
      invoiceNumber: _str(json['invoiceNumber']),
      invoiceUrl: _str(json['invoiceUrl']),
      orderType: _str(json['orderType']),
      liveAuction: liveAuctionFromJson(json['liveAuction']),
      items: items,
      pricing: pricing,
      sellers: sellers,
      sellerDecisions: sellerDecisionsFromJson(json),
      rewardPoints: rewardPointsFromJson(json['rewardPoints']),
    );
  }

  static PaymentOrderRewardPoints rewardPointsFromJson(Object? raw) {
    if (raw is! Map) return PaymentOrderRewardPoints.none;
    final club = raw['club'];
    final clubName = club is Map ? club['name']?.toString().trim() : null;
    return PaymentOrderRewardPoints(
      used: _int(raw['used']) ?? 0,
      usedAmountInr: _num(raw['usedAmountInr']) ?? 0,
      earnsPoints: raw['earnsPoints'] == true,
      earned: _int(raw['earned']),
      clubName: clubName == null || clubName.isEmpty ? null : clubName,
      earnMultiplier: club is Map ? (_num(club['earnMultiplier']) ?? 1) : 1,
    );
  }

  /// Seller approval per seller. Swagger has no schema for it, so this reads
  /// the shapes the backend uses for seller-scoped order data: a
  /// `sellerOrders` list, a status on each `sellers[]` entry, a status on
  /// each item, or one order-level status. Only `PENDING` / `ACCEPTED` /
  /// `REJECTED` count, so the payment status is never mistaken for it.
  static List<PaymentOrderSellerDecision> sellerDecisionsFromJson(
    Map<String, dynamic> json,
  ) {
    final bySeller = <String, PaymentOrderSellerDecision>{};

    void add(Map<String, dynamic> row, {String? fallbackSellerId}) {
      final seller = row['seller'];
      final sellerMap = seller is Map
          ? Map<String, dynamic>.from(seller)
          : null;
      final sellerId =
          _str(row['sellerId']) ?? _str(sellerMap?['id']) ?? fallbackSellerId;
      final status = _decisionStatus(
        row['sellerOrderStatus'] ??
            row['sellerStatus'] ??
            row['approvalStatus'] ??
            row['orderStatus'] ??
            row['status'],
      );
      if (sellerId == null || status == null) return;
      bySeller[sellerId] = PaymentOrderSellerDecision(
        sellerId: sellerId,
        status: status,
        sellerName: _str(sellerMap?['companyName']) ?? _str(row['companyName']),
        reason:
            _str(row['rejectionReason']) ??
            _str(row['rejectReason']) ??
            _str(row['reason']),
        sellerNote: _str(row['sellerNote']),
        decidedAt:
            _date(row['rejectedAt']) ??
            _date(row['acceptedAt']) ??
            _date(row['respondedAt']) ??
            _date(row['decidedAt']),
      );
    }

    final sellerOrders = json['sellerOrders'] ?? json['seller_orders'];
    if (sellerOrders is List) {
      for (final row in sellerOrders) {
        if (row is Map) add(Map<String, dynamic>.from(row));
      }
    }
    final sellers = json['sellers'];
    if (sellers is List) {
      for (final row in sellers) {
        if (row is! Map) continue;
        final map = Map<String, dynamic>.from(row);
        final id = _str(map['id']);
        if (id == null || bySeller.containsKey(id)) continue;
        final nested = map['sellerOrder'];
        add(
          nested is Map ? Map<String, dynamic>.from(nested) : map,
          fallbackSellerId: id,
        );
      }
    }
    final items = json['items'];
    if (items is List) {
      for (final row in items) {
        if (row is! Map) continue;
        final map = Map<String, dynamic>.from(row);
        final nested = map['sellerOrder'];
        final source = nested is Map
            ? Map<String, dynamic>.from(nested)
            : <String, dynamic>{
                'sellerId': map['sellerId'],
                'seller': map['seller'],
                'sellerOrderStatus':
                    map['sellerOrderStatus'] ?? map['sellerStatus'],
              };
        final id = _str(source['sellerId']) ?? _str(map['sellerId']);
        if (id != null && bySeller.containsKey(id)) continue;
        add(source, fallbackSellerId: _str(map['sellerId']));
      }
    }
    if (bySeller.isEmpty) {
      final orderLevel = _decisionStatus(
        json['sellerOrderStatus'] ??
            json['sellerStatus'] ??
            json['approvalStatus'],
      );
      if (orderLevel != null) {
        final ids = <String>{
          if (sellers is List)
            for (final s in sellers)
              if (s is Map && _str(s['id']) != null) _str(s['id'])!,
          if (items is List)
            for (final i in items)
              if (i is Map && _str(i['sellerId']) != null) _str(i['sellerId'])!,
        };
        for (final id in ids) {
          add({
            'sellerId': id,
            'status': orderLevel,
            'rejectionReason': json['rejectionReason'],
            'sellerNote': json['sellerNote'],
          });
        }
      }
    }
    return bySeller.values.toList();
  }

  static String? _decisionStatus(Object? raw) {
    final value = _str(raw)?.toUpperCase();
    return value != null && SellerDecisionStatuses.all.contains(value)
        ? value
        : null;
  }

  static PaymentOrderItem orderItemFromJson(Map<String, dynamic> json) {
    final seller = json['seller'];
    final sellerMap = seller is Map<String, dynamic>
        ? seller
        : const <String, dynamic>{};
    final specs = json['specifications'];
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
      priceCurrency: _str(json['priceCurrency']),
      auctionId: specs is Map ? _str(specs['auctionId']) : null,
    );
  }

  static PaymentOrderLiveAuction? liveAuctionFromJson(Object? raw) {
    if (raw is! Map) return null;
    return PaymentOrderLiveAuction(
      lotId: _str(raw['lotId']) ?? '',
      showId: _str(raw['showId']) ?? '',
      showTitle: _str(raw['showTitle']) ?? 'Live show',
    );
  }

  static PaymentOrdersPage ordersPageFromJson(Map<String, dynamic> root) {
    final data = root['data'];
    final dataMap = data is Map<String, dynamic>
        ? data
        : data is Map
        ? Map<String, dynamic>.from(data)
        : const <String, dynamic>{};
    final ordersJson =
        dataMap['orders'] ??
        dataMap['items'] ??
        dataMap['results'] ??
        dataMap['docs'] ??
        data;
    final orders = <PaymentOrder>[];
    if (ordersJson is List) {
      for (final o in ordersJson) {
        if (o is! Map) continue;
        final map = o is Map<String, dynamic>
            ? o
            : Map<String, dynamic>.from(o);
        final order = orderFromJson(map);
        if (order.id.isEmpty) continue;
        orders.add(order);
      }
    }

    final meta = root['meta'];
    final metaMap = meta is Map<String, dynamic>
        ? meta
        : meta is Map
        ? Map<String, dynamic>.from(meta)
        : const <String, dynamic>{};
    final pagination = metaMap['pagination'] ?? dataMap['pagination'];
    final pageMap = pagination is Map<String, dynamic>
        ? pagination
        : pagination is Map
        ? Map<String, dynamic>.from(pagination)
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
    if (v is DateTime) return v;
    if (v is int) {
      // Heuristic: seconds vs milliseconds since epoch.
      return v > 9999999999
          ? DateTime.fromMillisecondsSinceEpoch(v)
          : DateTime.fromMillisecondsSinceEpoch(v * 1000);
    }
    if (v is num) {
      final n = v.toInt();
      return n > 9999999999
          ? DateTime.fromMillisecondsSinceEpoch(n)
          : DateTime.fromMillisecondsSinceEpoch(n * 1000);
    }
    final raw = v.toString().trim();
    if (raw.isEmpty) return null;
    final asInt = int.tryParse(raw);
    if (asInt != null) {
      return asInt > 9999999999
          ? DateTime.fromMillisecondsSinceEpoch(asInt)
          : DateTime.fromMillisecondsSinceEpoch(asInt * 1000);
    }
    return DateTime.tryParse(raw);
  }
}
