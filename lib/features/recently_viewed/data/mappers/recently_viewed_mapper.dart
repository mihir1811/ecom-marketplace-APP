import '../../../bullions/data/mappers/bullion_mapper.dart';
import '../../../bullions/data/models/bullion_dto.dart';
import '../../../bullions/domain/models/billion.dart';
import '../../../diamonds/data/mappers/diamond_mapper.dart';
import '../../../diamonds/data/models/diamond_dto.dart';
import '../../../diamonds/domain/models/diamond.dart';
import '../../../diamonds/domain/models/diamond_display.dart';
import '../../../gemstones/data/mappers/gemstone_mapper.dart';
import '../../../gemstones/data/models/gemstone_dto.dart';
import '../../../gemstones/domain/models/gemstone.dart';
import '../../../jewelry/data/mappers/jewelry_mapper.dart';
import '../../../jewelry/domain/models/jewelry.dart';
import '../../../watches/data/mappers/watch_mapper.dart';
import '../../../watches/data/models/watch_dto.dart';
import '../../../watches/domain/models/watch.dart';
import '../../domain/models/recently_viewed.dart';

abstract final class RecentlyViewedMapper {
  static RecentlyViewedEntry fromJson(Map<String, dynamic> json) {
    final product = json['product'];
    final productMap = product is Map<String, dynamic> ? product : null;
    final productType = json['productType']?.toString() ?? '';
    final productId = json['productId']?.toString() ?? '';
    final normalized = productMap == null
        ? null
        : _normalizeProduct(productMap, productId);

    final diamond = _parseDiamond(normalized, productType);
    final gemstone = _parseGemstone(normalized, productType);
    final watch = _parseWatch(normalized, productType);
    final jewelry = _parseJewelry(normalized, productType);
    final bullion = _parseBullion(normalized, productType);

    final viewedAt = _parseDate(json['viewedAt'] ?? json['createdAt']);
    return RecentlyViewedEntry(
      id: json['id']?.toString() ?? '',
      productId: productId,
      productType: productType,
      viewedAtLabel: _label(viewedAt),
      viewedAt: viewedAt,
      stockNumber: _nullableString(normalized?['stockNumber']),
      productTitle:
          _listingTitle(
            diamond: diamond,
            gemstone: gemstone,
            watch: watch,
            jewelry: jewelry,
            bullion: bullion,
          ) ??
          _extractTitle(normalized, productType),
      imageUrl:
          diamond?.imageUrl ??
          gemstone?.imageUrl ??
          watch?.renderableImageUrl ??
          jewelry?.imageUrl ??
          bullion?.renderableImageUrl ??
          _extractImageUrl(normalized),
      price: diamond != null
          ? diamond.price.toString()
          : gemstone != null
          ? gemstone.price.toString()
          : watch != null
          ? watch.price.toString()
          : jewelry != null
          ? jewelry.price.toString()
          : bullion != null
          ? bullion.price.toString()
          : _formatPrice(normalized),
      carat:
          diamond?.carat ??
          gemstone?.carat ??
          _asDouble(normalized?['caratWeight']) ??
          _asDouble(normalized?['totalCarat']) ??
          _asDouble(normalized?['totalCaratWeight']) ??
          _asDouble(normalized?['carat']),
      shape:
          _nullableString(diamond?.shape) ??
          _nullableString(gemstone?.shape) ??
          _nullableString(normalized?['shape']),
      color:
          _nullableString(diamond?.color) ??
          _nullableString(gemstone?.color) ??
          _nullableString(normalized?['primaryColor']) ??
          _nullableString(normalized?['color']),
      clarity:
          _nullableString(diamond?.clarity) ??
          _nullableString(gemstone?.clarity) ??
          _nullableString(normalized?['clarity']),
      cut:
          _nullableString(diamond?.cut) ??
          _nullableString(gemstone?.cut) ??
          _nullableString(normalized?['cut']),
      availability:
          diamond?.available ??
          gemstone?.availability ??
          watch?.availabilityStatus ??
          jewelry?.availability ??
          bullion?.availability ??
          _availabilityForType(productType, normalized),
      diamond: diamond,
      gemstone: gemstone,
      watch: watch,
      jewelry: jewelry,
      bullion: bullion,
    );
  }

  static String? _extractImageUrl(Map<String, dynamic>? product) {
    if (product == null) return null;
    // Direct fields
    final direct =
        _nullableString(product['imageUrl']) ??
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
    final stock = _nullableString(product['stockNumber']);
    final explicit =
        _nullableString(product['displayName']) ??
        _nullableString(product['title']) ??
        _nullableString(product['name']) ??
        _nullableString(product['productName']) ??
        _nullableString(product['productTitle']);
    if (explicit != null &&
        (stock == null || explicit.toLowerCase() != stock.toLowerCase())) {
      return explicit;
    }
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
    final carat =
        _asDouble(p['caratWeight']) ??
        _asDouble(p['totalCaratWeight']) ??
        _asDouble(p['caratWeightPerpcs']) ??
        _asDouble(p['carat']);
    final shape = _nullableString(p['shape']);
    if (carat != null && shape != null && shape.isNotEmpty) {
      return '${carat.toStringAsFixed(2)}ct $shape';
    }
    if (carat != null) return '${carat.toStringAsFixed(2)}ct Diamond';
    return _nullableString(p['stockNumber']);
  }

  static String? _gemstoneTitle(Map<String, dynamic> p) {
    final gemType =
        _nullableString(p['gemsType']) ??
        _nullableString(p['gemType']) ??
        _nullableString(p['type']);
    final carat =
        _asDouble(p['totalCarat']) ??
        _asDouble(p['caratPerPcs']) ??
        _asDouble(p['carat']);
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
    final type =
        _nullableString(p['jewelryType']) ?? _nullableString(p['type']);
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
    final metal =
        _nullableString(p['metal']) ?? _nullableString(p['metalType']);
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
    final payload = dataNode is Map<String, dynamic>
        ? dataNode
        : const <String, dynamic>{};
    final itemsJson = payload['data'];
    final metaJson = payload['meta'];
    final meta = metaJson is Map<String, dynamic>
        ? metaJson
        : const <String, dynamic>{};

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
      // Rough parcels share the diamond `available` / `isSold` fields.
      'roughDiamond' => _diamondAvailability(product),
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

  static Map<String, dynamic> _normalizeProduct(
    Map<String, dynamic> product,
    String productId,
  ) {
    final map = Map<String, dynamic>.from(product);
    if ((map['id']?.toString() ?? '').trim().isEmpty && productId.isNotEmpty) {
      map['id'] = productId;
    }
    map['caratWeight'] ??= map['carat'];
    map['totalCarat'] ??= map['carat'] ?? map['caratWeight'];
    map['totalPrice'] ??=
        map['price'] ?? map['salePrice'] ?? map['retailPrice'];
    map['gemsType'] ??= map['gemType'] ?? map['type'];
    map['primaryColor'] ??= map['color'];
    map['productTitle'] ??= map['title'] ?? map['name'] ?? map['productName'];
    return map;
  }

  static String? _listingTitle({
    Diamond? diamond,
    Gemstone? gemstone,
    Watch? watch,
    Jewelry? jewelry,
    Bullion? bullion,
  }) {
    if (diamond != null) {
      return '${diamond.carat.toStringAsFixed(2)}ct ${DiamondDisplay.shape(diamond.shape)}';
    }
    if (gemstone != null) {
      final carat = '${gemstone.carat.toStringAsFixed(2)}ct';
      final shape = _nullableString(gemstone.shape);
      if (shape != null) return '$carat $shape';
      final type = _nullableString(gemstone.type);
      return type == null ? carat : '$carat $type';
    }
    if (watch != null) {
      final model = watch.model.trim();
      if (model.isNotEmpty) return model;
      final brand = watch.brand.trim();
      return brand.isEmpty ? null : brand;
    }
    if (jewelry != null) {
      final name = jewelry.name.trim();
      return name.isEmpty ? null : name;
    }
    if (bullion != null) {
      final parts = [
        if (bullion.weightLabel.isNotEmpty) bullion.weightLabel,
        if (bullion.presetVariant.isNotEmpty) bullion.presetVariant,
      ];
      if (parts.isNotEmpty) return parts.join(' ');
      final name = bullion.name.trim();
      return name.isEmpty ? null : name;
    }
    return null;
  }

  static Diamond? _parseDiamond(Map<String, dynamic>? product, String type) {
    if (product == null) return null;
    if (type != 'diamond' && type != 'meleeDiamond') return null;
    try {
      final dto = DiamondDto.fromJson(product, isMelee: type == 'meleeDiamond');
      if (dto.id.isEmpty) return null;
      return DiamondMapper.toDomain(dto, isLabGrown: false);
    } catch (_) {
      return null;
    }
  }

  static Gemstone? _parseGemstone(Map<String, dynamic>? product, String type) {
    if (product == null || type != 'gemstone') return null;
    try {
      final dto = GemstoneDto.fromJson(product);
      if (dto.id.isEmpty) return null;
      return GemstoneMapper.toDomain(dto);
    } catch (_) {
      return null;
    }
  }

  static Watch? _parseWatch(Map<String, dynamic>? product, String type) {
    if (product == null || type != 'watch') return null;
    try {
      final dto = WatchDto.fromJson(product);
      if (dto.id.isEmpty) return null;
      return WatchMapper.toDomain(dto);
    } catch (_) {
      return null;
    }
  }

  static Jewelry? _parseJewelry(Map<String, dynamic>? product, String type) {
    if (product == null) return null;
    if (type != 'jewelry' && type != 'jewellery') return null;
    try {
      final jewelry = JewelryMapper.fromJson(product);
      return jewelry.id.isEmpty ? null : jewelry;
    } catch (_) {
      return null;
    }
  }

  static Bullion? _parseBullion(Map<String, dynamic>? product, String type) {
    if (product == null || type != 'bullion') return null;
    try {
      final dto = BullionDto.fromJson(product);
      if (dto.id.isEmpty) return null;
      return BullionMapper.toDomain(dto);
    } catch (_) {
      return null;
    }
  }
}
