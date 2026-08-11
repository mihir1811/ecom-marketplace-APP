import '../../../../core/utils/app_currency.dart';
import '../../domain/models/product_offer.dart';

abstract final class ProductOfferMapper {
  static ProductOffer fromJson(Map<String, dynamic> json) {
    final product = json['product'];
    final productMap = product is Map<String, dynamic> ? product : null;
    final buyer = json['buyer'] ?? json['user'];
    final buyerMap = buyer is Map<String, dynamic> ? buyer : null;

    return ProductOffer(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productType: json['productType']?.toString() ?? '',
      buyerId: json['buyerId']?.toString() ?? '',
      sellerId: json['sellerId']?.toString() ?? '',
      amount: _asDouble(json['amount']) ?? 0,
      status: ProductOfferStatus.fromApi(json['status']?.toString()),
      message: _nullableString(json['message']),
      createdAtLabel: _label(_parseDate(json['createdAt'])),
      updatedAtLabel: _label(_parseDate(json['updatedAt'])),
      productLabel: _productLabel(productMap, json),
      stockNumber: _nullableString(productMap?['stockNumber']) ??
          _nullableString(json['stockNumber']),
      listPrice: _asDouble(productMap?['totalPrice']) ??
          _asDouble(productMap?['price']) ??
          _asDouble(json['listPrice']),
      buyerName: _nullableString(buyerMap?['name']) ??
          _nullableString(buyerMap?['fullName']),
      buyerEmail: _nullableString(buyerMap?['email']),
    );
  }

  static ProductOfferListPage listPageFromJson(
    Map<String, dynamic>? root, {
    required int page,
    required int limit,
  }) {
    final dataNode = root?['data'];
    final payload =
        dataNode is Map<String, dynamic> ? dataNode : const <String, dynamic>{};
    final itemsJson = payload['data'];
    final metaJson = payload['meta'];
    final meta =
        metaJson is Map<String, dynamic> ? metaJson : const <String, dynamic>{};

    final list = itemsJson is List ? itemsJson : const [];
    final items = <ProductOffer>[];
    for (final item in list) {
      if (item is! Map<String, dynamic>) continue;
      final offer = fromJson(item);
      if (offer.id.isEmpty) continue;
      items.add(offer);
    }

    final total = _asInt(meta['total']) ?? items.length;
    final currentPage = _asInt(meta['currentPage']) ?? page;
    final lastPage = _asInt(meta['lastPage']) ?? currentPage;
    final perPage = _asInt(meta['perPage']) ?? limit;
    final hasMore = meta.containsKey('next')
        ? meta['next'] != null
        : currentPage < lastPage;

    return ProductOfferListPage(
      items: items,
      total: total,
      currentPage: currentPage,
      lastPage: lastPage,
      perPage: perPage,
      hasMore: hasMore,
    );
  }

  static String offerPriceLabel(double amount) => AppCurrency.format(amount);

  static String? _productLabel(
    Map<String, dynamic>? product,
    Map<String, dynamic> json,
  ) {
    if (product != null) {
      final shape = _nullableString(product['shape']);
      final carat = product['caratWeight'] ?? product['totalCaratWeight'];
      if (shape != null && carat != null) {
        return '${_formatNum(carat)} ct $shape';
      }
      final title = _nullableString(product['title']) ??
          _nullableString(product['name']);
      if (title != null) return title;
    }
    return _nullableString(json['productLabel']) ??
        _nullableString(json['productType']);
  }

  static String _formatNum(Object? value) {
    final n = _asDouble(value);
    if (n == null) return value?.toString() ?? '';
    return n.toStringAsFixed(2);
  }

  static String? _nullableString(Object? raw) {
    if (raw == null) return null;
    final text = raw.toString().trim();
    return text.isEmpty ? null : text;
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  static String _label(DateTime? date) {
    if (date == null) return '—';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }

  static int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double? _asDouble(Object? value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
