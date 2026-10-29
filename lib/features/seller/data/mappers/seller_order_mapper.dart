import '../../domain/models/seller_order.dart';

/// Parses `/seller/orders` payloads.
///
/// Swagger documents the routes but not their response bodies, so the mapper
/// accepts the shapes this backend uses elsewhere: a seller-order row that may
/// embed the marketplace `order`, or the flat `RecentOrderDto` style
/// (`displayId`, `customerName`, `amount`, `itemCount`) from `/seller/stats`.
abstract final class SellerOrderMapper {
  static SellerOrdersPage pageFromResponse(
    Object? root, {
    required int page,
    required int limit,
  }) {
    final rootMap = _map(root) ?? const <String, dynamic>{};
    final data = rootMap['data'];
    final dataMap = _map(data);

    List<dynamic> rows = const [];
    Map<String, dynamic>? meta;
    if (data is List) {
      rows = data;
      meta = _map(rootMap['meta']);
    } else if (dataMap != null) {
      final nested =
          dataMap['data'] ??
          dataMap['orders'] ??
          dataMap['items'] ??
          dataMap['results'];
      if (nested is List) rows = nested;
      meta = _map(dataMap['meta']) ?? _map(rootMap['meta']);
    }

    final orders = <SellerOrder>[];
    for (final row in rows) {
      final map = _map(row);
      if (map == null) continue;
      final order = fromJson(map);
      if (order.id.isEmpty) continue;
      orders.add(order);
    }

    final pagination = _map(meta?['pagination']) ?? meta;
    final total = _int(pagination?['total']) ?? orders.length;
    final perPage =
        _int(pagination?['perPage']) ?? _int(pagination?['limit']) ?? limit;
    final lastPage =
        _int(pagination?['lastPage']) ??
        _int(pagination?['totalPages']) ??
        (perPage > 0 ? ((total + perPage - 1) ~/ perPage) : 1);
    return SellerOrdersPage(
      orders: orders,
      page:
          _int(pagination?['currentPage']) ?? _int(pagination?['page']) ?? page,
      total: total,
      lastPage: lastPage < 1 ? 1 : lastPage,
    );
  }

  /// Unwraps `{ data: {...} }` from detail / accept / reject responses.
  static SellerOrder? fromResponse(Object? root) {
    final rootMap = _map(root);
    if (rootMap == null) return null;
    final data = _map(rootMap['data']);
    if (data == null) return null;
    final nested = _map(data['sellerOrder']) ?? _map(data['order']);
    // `{ data: { sellerOrder: {...} } }` or `{ data: {...order row...} }`.
    final candidate = data['id'] == null && nested != null ? nested : data;
    final order = fromJson(candidate);
    return order.id.isEmpty ? null : order;
  }

  static SellerOrder fromJson(Map<String, dynamic> json) {
    final embedded = _map(json['order']) ?? _map(json['paymentOrder']);
    final buyer =
        _map(json['buyer']) ??
        _map(json['customer']) ??
        _map(json['user']) ??
        _map(embedded?['user']) ??
        _map(embedded?['buyer']);

    final itemsJson =
        json['items'] ??
        json['orderItems'] ??
        json['products'] ??
        embedded?['items'];
    final items = <SellerOrderItem>[];
    if (itemsJson is List) {
      for (final raw in itemsJson) {
        final item = _map(raw);
        if (item != null) items.add(_itemFromJson(item));
      }
    }

    final id = _str(json['id']) ?? _str(json['sellerOrderId']) ?? '';
    final orderId =
        _str(json['orderId']) ??
        _str(json['paymentOrderId']) ??
        _str(embedded?['id']) ??
        id;
    final rawStatus =
        _str(json['status']) ??
        _str(json['sellerStatus']) ??
        _str(json['sellerOrderStatus']) ??
        '';

    final customerName =
        _str(json['customerName']) ??
        _str(json['buyerName']) ??
        _str(buyer?['name']) ??
        _str(buyer?['fullName']) ??
        _str(buyer?['userName']);

    return SellerOrder(
      id: id,
      orderId: orderId,
      displayId: _str(json['displayId']) ?? _str(embedded?['displayId']),
      status: SellerOrderStatus.fromApi(rawStatus),
      rawStatus: rawStatus,
      customer: customerName == null && buyer == null
          ? null
          : SellerOrderCustomer(
              id: _str(buyer?['id']) ?? _str(json['userId']),
              name: customerName ?? 'Customer',
              email: _str(json['customerEmail']) ?? _str(buyer?['email']),
              phone: _str(json['customerPhone']) ?? _str(buyer?['phone']),
            ),
      items: items,
      amount:
          _num(json['amount']) ??
          _num(json['total']) ??
          _num(json['totalAmount']) ??
          _num(json['subtotal']) ??
          _num(embedded?['amount']),
      amountUsd:
          _num(json['amountUsd']) ??
          _num(json['totalUsd']) ??
          _num(json['subtotalUsd']),
      amountInr:
          _num(json['amountInr']) ??
          _num(json['totalInr']) ??
          _num(json['subtotalInr']),
      currency: _str(json['currency']) ?? _str(embedded?['currency']),
      paymentStatus:
          _str(json['paymentStatus']) ??
          _str(json['orderStatus']) ??
          _str(embedded?['status']),
      itemCount:
          _int(json['itemCount']) ?? (items.isEmpty ? null : items.length),
      createdAt: _date(json['createdAt']) ?? _date(embedded?['createdAt']),
      updatedAt: _date(json['updatedAt']),
      decidedAt:
          _date(json['acceptedAt']) ??
          _date(json['rejectedAt']) ??
          _date(json['respondedAt']) ??
          _date(json['decidedAt']),
      rejectionReason:
          _str(json['rejectionReason']) ??
          _str(json['rejectReason']) ??
          _str(json['reason']),
      sellerNote: _str(json['sellerNote']),
      shippingAddress: _address(
        _map(json['shippingAddress']) ??
            _map(json['deliveryAddress']) ??
            _map(embedded?['shippingAddress']) ??
            _map(embedded?['deliveryAddress']),
      ),
      isAuctionSale: json['isAuctionSale'] == true,
    );
  }

  static SellerOrderItem _itemFromJson(Map<String, dynamic> json) {
    final product = _map(json['product']);
    return SellerOrderItem(
      productId: _str(json['productId']) ?? _str(product?['id']),
      productType: _str(json['productType']),
      name:
          _str(json['name']) ??
          _str(json['productName']) ??
          _str(json['title']) ??
          _str(product?['name']) ??
          _str(product?['productTitle']) ??
          _str(product?['stockNumber']) ??
          'Product',
      stockNumber: _str(json['stockNumber']) ?? _str(product?['stockNumber']),
      quantity: _int(json['quantity']) ?? 1,
      unitPrice: _num(json['unitPrice']) ?? _num(json['price']),
      lineTotal: _num(json['lineTotal']) ?? _num(json['total']),
      image:
          _str(json['image']) ??
          _str(product?['image']) ??
          _str(product?['image1']),
    );
  }

  static String? _address(Map<String, dynamic>? json) {
    if (json == null) return null;
    final parts = [
      _str(json['fullName']),
      _str(json['addressLine1']),
      _str(json['addressLine2']),
      _str(json['city']),
      _str(json['state']),
      _str(json['zipCode']),
      _str(json['country']),
    ].whereType<String>().toList();
    return parts.isEmpty ? null : parts.join(', ');
  }

  static Map<String, dynamic>? _map(Object? v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  static String? _str(Object? v) {
    if (v == null || v is Map || v is List) return null;
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
    return DateTime.tryParse(v.toString())?.toLocal();
  }
}
