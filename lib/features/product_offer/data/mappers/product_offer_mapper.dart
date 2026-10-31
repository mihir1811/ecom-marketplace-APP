import '../../../../core/utils/app_currency.dart';
import '../../domain/models/product_offer.dart';

abstract final class ProductOfferMapper {
  static ProductOffer fromJson(Map<String, dynamic> json) {
    final product = json['product'];
    final productMap = product is Map<String, dynamic> ? product : null;
    final buyer = json['buyer'] ?? json['user'];
    final buyerMap = buyer is Map<String, dynamic> ? buyer : null;
    final productId = json['productId']?.toString() ??
        productMap?['id']?.toString() ??
        '';
    final createdAt = _parseDate(json['createdAt']);

    return ProductOffer(
      id: json['id']?.toString() ?? '',
      productId: productId,
      productType: json['productType']?.toString() ??
          productMap?['productType']?.toString() ??
          '',
      buyerId: json['buyerId']?.toString() ?? '',
      sellerId: json['sellerId']?.toString() ?? '',
      amount: _asDouble(json['amount']) ?? 0,
      status: ProductOfferStatus.fromApi(json['status']?.toString()),
      message: _nullableString(json['message']),
      createdAtLabel: _label(createdAt),
      updatedAtLabel: _label(_parseDate(json['updatedAt'])),
      createdAt: createdAt,
      acceptedAt: _parseDate(json['acceptedAt']),
      paidAt: _parseDate(json['paidAt']),
      paymentExpiresAt: _parseDate(json['paymentExpiresAt']),
      paymentWithGemworld: json['paymentWithGemworld'] == true,
      belowMinimum: json['belowMinimum'] == true,
      productLabel: _productLabel(productMap, json),
      stockNumber: _nullableString(productMap?['stockNumber']) ??
          _nullableString(json['stockNumber']),
      listPrice: _asDouble(productMap?['listedPrice']) ??
          _asDouble(productMap?['totalPrice']) ??
          _asDouble(productMap?['price']) ??
          _asDouble(json['listPrice']),
      buyerName: _nullableString(buyerMap?['name']) ??
          _nullableString(buyerMap?['fullName']),
      buyerEmail: _nullableString(buyerMap?['email']),
      imageUrl: _imageUrl(productMap) ?? _imageUrl(json),
      productSpecs: _productSpecs(productMap),
      certificateLabel: _certificateLabel(productMap),
      productIsSold: productMap?['isSold'] == true,
      fromSeller: json['fromSeller'] == true,
      counterToId: _nullableString(json['counterToId']),
      history: _history(json['history']),
      attemptsUsed: _asInt(json['attemptsUsed']),
      maxAttempts: _asInt(json['maxAttempts']),
    );
  }

  static List<OfferMove> _history(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final m in raw)
        if (m is Map<String, dynamic>)
          OfferMove(
            id: m['id']?.toString() ?? '',
            amount: _asDouble(m['amount']) ?? 0,
            fromSeller: m['fromSeller'] == true,
            status: ProductOfferStatus.fromApi(m['status']?.toString()),
            message: _nullableString(m['message']),
            createdAt: _parseDate(m['createdAt']),
          ),
    ];
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
          _nullableString(product['name']) ??
          _nullableString(product['productName']);
      if (title != null) return title;
      if (shape != null) return shape;
      final stock = _nullableString(product['stockNumber']);
      if (stock != null) return stock;
    }
    return _nullableString(json['productLabel']) ??
        _nullableString(json['stockNumber']);
  }

  static String? _productSpecs(Map<String, dynamic>? product) {
    if (product == null) return null;
    final parts = <String>[
      ?_nullableString(product['color']) ??
          _nullableString(product['colorFrom']),
      ?_nullableString(product['clarity']) ??
          _nullableString(product['clarityMin']),
      ?_nullableString(product['cut']) ?? _nullableString(product['cutFrom']),
      ?_nullableString(product['polish']) ??
          _nullableString(product['polishFrom']),
      ?_nullableString(product['symmetry']) ??
          _nullableString(product['symmetryFrom']),
    ];
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  static String? _certificateLabel(Map<String, dynamic>? product) {
    if (product == null) return null;
    final lab = _nullableString(product['certificateCompanyName']) ??
        _nullableString(product['lab']) ??
        _nullableString(product['certificateCompany']);
    final number = _nullableString(product['certificateNumber']) ??
        _nullableString(product['certificateNo']);
    if (lab != null && number != null) return '$lab · $number';
    return lab ?? number;
  }

  static String? _imageUrl(Map<String, dynamic>? map) {
    if (map == null) return null;
    for (final key in [
      'image',
      'imageUrl',
      'image1',
      'image2',
      'thumbnail',
      'coverImage',
      'primaryImage',
    ]) {
      final direct = _nullableString(map[key]);
      if (direct != null) return direct;
    }
    final images = map['images'] ?? map['imageUrls'] ?? map['media'];
    if (images is List) {
      for (final item in images) {
        if (item is String) {
          final url = _nullableString(item);
          if (url != null) return url;
        } else if (item is Map<String, dynamic>) {
          final url = _nullableString(item['url']) ??
              _nullableString(item['imageUrl']);
          if (url != null) return url;
        }
      }
    }
    return null;
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
    return DateTime.tryParse(raw.toString())?.toLocal();
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
