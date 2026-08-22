import '../../domain/models/recently_viewed.dart';

abstract final class RecentlyViewedMapper {
  static RecentlyViewedEntry fromJson(Map<String, dynamic> json) {
    final product = json['product'];
    final productMap = product is Map<String, dynamic> ? product : null;
    final productType = json['productType']?.toString() ?? '';

    return RecentlyViewedEntry(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productType: productType,
      viewedAtLabel: _label(_parseDate(json['viewedAt'] ?? json['createdAt'])),
      stockNumber: _nullableString(productMap?['stockNumber']),
      productTitle: _extractTitle(productMap, productType),
      imageUrl: _extractImageUrl(productMap),
      price: _formatPrice(productMap),
      carat: _asDouble(productMap?['carat']),
      shape: _nullableString(productMap?['shape']),
      color: _nullableString(productMap?['color']),
      clarity: _nullableString(productMap?['clarity']),
      cut: _nullableString(productMap?['cut']),
      availability: _availabilityForType(productType, productMap),
    );
  }

  static String? _extractImageUrl(Map<String, dynamic>? product) {
    if (product == null) return null;
    // Direct fields
    final direct = _nullableString(product['imageUrl']) ??
        _nullableString(product['image']) ??
        _nullableString(product['photoUrl']) ??
        _nullableString(product['thumbnailUrl']);
    if (direct != null) return direct;
    // image1–image6 fields (diamonds, gemstones, watches, bullions)
    for (var i = 1; i <= 6; i++) {
      final url = _nullableString(product['image$i']);
      if (url != null) return url;
    }
    // images array
    final images = product['images'];
    if (images is List && images.isNotEmpty) {
      final first = _nullableString(images.first);
      if (first != null) return first;
    }
    return null;
  }

  static String? _extractTitle(Map<String, dynamic>? product, String type) {
    if (product == null) return null;
    final explicit = _nullableString(product['title']) ??
        _nullableString(product['name']) ??
        _nullableString(product['productName']);
    if (explicit != null) return explicit;
    // Construct from available data per type
    return switch (type) {
      'diamond' || 'meleeDiamond' => _diamondTitle(product),
      'gemstone' => _gemstoneTitle(product),
      'jewelry' || 'jewellery' => _jewelryTitle(product),
      'watch' => _watchTitle(product),
      'bullion' => _bullionTitle(product),
      _ => null,
    };
  }

  static String? _diamondTitle(Map<String, dynamic> p) {
    final carat = _asDouble(p['carat']);
    final shape = _nullableString(p['shape']);
    if (carat != null && shape != null && shape.isNotEmpty) {
      return '${carat.toStringAsFixed(2)}ct $shape';
    }
    if (carat != null) return '${carat.toStringAsFixed(2)}ct Diamond';
    return _nullableString(p['stockNumber']);
  }

  static String? _gemstoneTitle(Map<String, dynamic> p) {
    final gemType = _nullableString(p['gemType']) ?? _nullableString(p['type']);
    final carat = _asDouble(p['carat']);
    if (gemType != null && carat != null) {
      return '${carat.toStringAsFixed(2)}ct $gemType';
    }
    if (gemType != null) return gemType;
    if (carat != null) return '${carat.toStringAsFixed(2)}ct Gemstone';
    return _nullableString(p['stockNumber']);
  }

  static String? _jewelryTitle(Map<String, dynamic> p) {
    final name = _nullableString(p['name']) ?? _nullableString(p['title']);
    if (name != null) return name;
    final type = _nullableString(p['jewelryType']) ?? _nullableString(p['type']);
    if (type != null) return type;
    return _nullableString(p['stockNumber']);
  }

  static String? _watchTitle(Map<String, dynamic> p) {
    final brand = _nullableString(p['brand']);
    final model = _nullableString(p['model']) ?? _nullableString(p['name']);
    if (brand != null && model != null) return '$brand $model';
    if (brand != null) return brand;
    if (model != null) return model;
    return _nullableString(p['stockNumber']);
  }

  static String? _bullionTitle(Map<String, dynamic> p) {
    final metal = _nullableString(p['metal']) ?? _nullableString(p['metalType']);
    final weight = _asDouble(p['weight']) ?? _asDouble(p['weightOz']);
    if (metal != null && weight != null) {
      return '$metal ${weight.toStringAsFixed(2)} oz';
    }
    if (metal != null) return metal;
    return _nullableString(p['stockNumber']);
  }

  static RecentlyViewedListPage listPageFromJson(
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
    final items = <RecentlyViewedEntry>[];
    for (final item in list) {
      if (item is! Map<String, dynamic>) continue;
      final entry = fromJson(item);
      if (entry.id.isEmpty) continue;
      items.add(entry);
    }

    final total = _asInt(meta['total']) ?? items.length;
    final currentPage = _asInt(meta['currentPage']) ?? page;
    final lastPage = _asInt(meta['lastPage']) ?? currentPage;
    final hasMore = meta.containsKey('next')
        ? meta['next'] != null
        : currentPage < lastPage;

    return RecentlyViewedListPage(
      items: items,
      total: total,
      currentPage: currentPage,
      hasMore: hasMore,
    );
  }

  static RecentlyViewedId idFromJson(Map<String, dynamic> json) {
    return RecentlyViewedId(
      productId: json['productId']?.toString() ?? '',
      productType: json['productType']?.toString() ?? '',
    );
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

  static String? _formatPrice(Map<String, dynamic>? product) {
    if (product == null) return null;
    // Try common price fields in order of priority
    for (final key in [
      'price',
      'salePrice',
      'discountPrice',
      'retailPrice',
      'totalPrice',
      'amount',
    ]) {
      final value = product[key];
      if (value == null) continue;
      if (value is num && value > 0) return value.toString();
      if (value is String && value.isNotEmpty) {
        final parsed = num.tryParse(value.replaceAll(RegExp(r'[^\d.]'), ''));
        if (parsed != null && parsed > 0) return parsed.toString();
      }
    }
    return null;
  }

  static String? _availabilityForType(
    String productType,
    Map<String, dynamic>? product,
  ) {
    if (product == null) return null;
    return switch (productType) {
      'diamond' || 'meleeDiamond' => _diamondAvailability(product),
      'gemstone' => _gemstoneAvailability(product),
      'jewelry' || 'jewellery' => _jewelryAvailability(product),
      'watch' => _watchAvailability(product),
      'bullion' => _bullionAvailability(product),
      _ => null,
    };
  }

  static String? _diamondAvailability(Map<String, dynamic> product) {
    if (product['isSold'] == true) return 'Sold';
    return switch ((product['available'] ?? '').toString().toLowerCase()) {
      'yes' => 'Available',
      'hold' => 'On Hold',
      'memo' => 'On Memo',
      _ => null,
    };
  }

  static String? _gemstoneAvailability(Map<String, dynamic> product) {
    if (product['isSold'] == true) return 'Sold';
    return switch ((product['availability'] ?? '').toString().toLowerCase()) {
      'yes' => 'Available',
      'hold' => 'On Hold',
      'memo' => 'On Memo',
      _ => null,
    };
  }

  static String? _jewelryAvailability(Map<String, dynamic> product) {
    final raw = (product['availability'] ?? '').toString().toLowerCase();
    if (raw.contains('out of stock') || raw.contains('sold')) return 'Sold';
    if (raw.isNotEmpty) return raw;
    return null;
  }

  static String? _watchAvailability(Map<String, dynamic> product) {
    return switch ((product['availabilityStatus'] ?? '')
        .toString()
        .toLowerCase()) {
      'yes' || 'available' => 'Available',
      'hold' || 'on hold' => 'On Hold',
      'memo' => 'On Memo',
      final v when v.isNotEmpty => v,
      _ => null,
    };
  }

  static String? _bullionAvailability(Map<String, dynamic> product) {
    final qty = product['quantityAvailable'];
    if (qty is num && qty <= 0) return 'Sold';
    return switch ((product['availability'] ?? '').toString().toLowerCase()) {
      'yes' || 'available' => 'Available',
      'hold' || 'on hold' => 'On Hold',
      'memo' => 'On Memo',
      _ => null,
    };
  }
}
