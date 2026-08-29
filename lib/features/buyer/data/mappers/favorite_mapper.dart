import '../../../../core/utils/app_currency.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../diamonds/domain/models/diamond_display.dart';
import '../../domain/models/wishlist_item.dart';

/// Parses `/favorites` JSON into wishlist domain models.
abstract final class FavoriteMapper {
  static WishlistItem fromJson(Map<String, dynamic> json) {
    final product = json['product'];
    final productMap = product is Map<String, dynamic>
        ? product
        : const <String, dynamic>{};
    final productType =
        _str(json['productType']) ??
        FavoriteProductType.fromCategory(WishlistCategory.diamond);
    final category = FavoriteProductType.toCategory(productType);
    final title = _title(productMap, productType);
    final subtitle = _subtitle(productMap, productType);
    final price =
        _num(productMap['totalPrice']) ??
        _num(productMap['price']) ??
        _variantNum(productMap, 'totalPrice') ??
        _variantNum(productMap, 'price');

    return WishlistItem(
      id: _str(json['productId']) ?? _str(productMap['id']) ?? '',
      category: category,
      productType: productType,
      title: title,
      subtitle: subtitle,
      priceLabel: price == null
          ? ''
          : AppCurrency.format(formatCatalogPrice(price)),
      imageUrl: _image(productMap, productType),
      favoriteId: _str(json['id']),
    );
  }

  static WishlistPage pageFromJson(
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

    final items = <WishlistItem>[];
    if (itemsJson is List) {
      for (final item in itemsJson) {
        if (item is! Map<String, dynamic>) continue;
        final mapped = fromJson(item);
        if (mapped.id.isEmpty) continue;
        items.add(mapped);
      }
    }

    final total = _int(meta['total']) ?? items.length;
    final currentPage = _int(meta['currentPage']) ?? page;
    final lastPage = _int(meta['lastPage']) ?? currentPage;
    final hasMore = meta.containsKey('next')
        ? meta['next'] != null
        : currentPage < lastPage;

    return WishlistPage(
      items: items,
      total: total,
      currentPage: currentPage,
      hasMore: hasMore,
    );
  }

  static String _title(Map<String, dynamic> product, String productType) {
    final built = switch (productType) {
      FavoriteProductType.diamond ||
      FavoriteProductType.meleeDiamond => _diamondTitle(product),
      FavoriteProductType.gemstone => _gemstoneTitle(product),
      FavoriteProductType.jewellery => _jewelryTitle(product),
      FavoriteProductType.watch => _watchTitle(product),
      FavoriteProductType.bullion => _bullionTitle(product),
      _ => _joinWords([
        _label(product['productTitle']),
        _label(product['name']),
      ]),
    };
    if (built.isNotEmpty) return built;
    return FavoriteProductType.label(productType);
  }

  static String _subtitle(Map<String, dynamic> product, String productType) {
    return switch (productType) {
      FavoriteProductType.diamond ||
      FavoriteProductType.meleeDiamond => _diamondSubtitle(product),
      FavoriteProductType.gemstone => _join([
        _titleCase(product['origin']),
        _titleCase(product['primaryColor']) ?? _titleCase(product['color']),
      ]),
      FavoriteProductType.jewellery => _join([
        _jewelryCategory(product),
        _titleCase(_variantLabel(product, 'metalType')) ??
            _titleCase(product['metalType']),
      ]),
      FavoriteProductType.watch => _join([
        _year(product['modelYear'] ?? product['year']),
        _titleCase(product['caseMaterial']),
      ]),
      FavoriteProductType.bullion => _join([
        _titleCase(product['metalShape']) ?? _titleCase(product['shape']),
        _titleCase(product['condition']),
      ]),
      _ => _join([
        _label(product['origin']),
        _label(product['color']),
        _label(product['model']),
      ]),
    };
  }

  static String _diamondTitle(Map<String, dynamic> product) {
    final carat =
        _num(product['caratWeight']) ??
        _num(product['totalCaratWeight']) ??
        _num(product['carat']);
    final shape = _diamondShape(product);
    return _joinWords([_caratText(carat), shape]);
  }

  static String _diamondSubtitle(Map<String, dynamic> product) {
    final color = DiamondDisplay.gradeChip(
      _label(product['color']) ?? _label(product['fancyColor']),
    );
    final clarity = DiamondDisplay.gradeChip(_label(product['clarity']));
    return _join([
      _isLabGrown(product) ? 'Lab Grown' : 'Natural',
      '$color $clarity'.trim(),
    ]);
  }

  static String _gemstoneTitle(Map<String, dynamic> product) {
    final carat =
        _num(product['totalCarat']) ??
        _num(product['caratWeight']) ??
        _num(product['carat']);
    return _joinWords([
      _caratText(carat),
      _titleCase(product['gemsType']) ?? _titleCase(product['type']),
    ]);
  }

  static String _jewelryTitle(Map<String, dynamic> product) {
    return _label(product['productTitle']) ??
        _label(product['name']) ??
        _label(product['title']) ??
        '';
  }

  static String _watchTitle(Map<String, dynamic> product) {
    return _joinWords([_label(product['brand']), _label(product['model'])]);
  }

  static String _bullionTitle(Map<String, dynamic> product) {
    final fromDesign = _humanName(_label(product['design']));
    if (fromDesign != null) return fromDesign;
    return _joinWords([
      _weightLabel(_num(product['metalWeight'])),
      _titleCase(product['metalType']),
    ]);
  }

  static String? _jewelryCategory(Map<String, dynamic> product) {
    final sub = product['subcategory'];
    String? raw;
    if (sub is Map) {
      final nested = sub['category'];
      raw = nested is Map ? _titleCase(nested['name']) : _titleCase(nested);
      raw ??= _titleCase(sub['name']);
    }
    raw ??= _titleCase(product['category']);
    return _jewelryCategoryLabel(raw);
  }

  static String? _jewelryCategoryLabel(String? raw) {
    if (raw == null) return null;
    return switch (raw.trim().toLowerCase()) {
      'ring' => 'Rings',
      'earring' => 'Earrings',
      'bracelet' => 'Bracelets',
      'necklace' => 'Necklaces',
      'chain' => 'Chains',
      _ => raw,
    };
  }

  static String? _diamondShape(Map<String, dynamic> product) {
    final raw = _label(product['shape']);
    if (raw == null) return null;
    final shaped = DiamondDisplay.shape(raw);
    if (shaped == DiamondDisplay.notAvailable) return null;
    return shaped;
  }

  static bool _isLabGrown(Map<String, dynamic> product) {
    final growth = (_label(product['growthType']) ?? '').toLowerCase();
    if (growth == 'cvd' || growth == 'hpht' || growth.contains('lab')) {
      return true;
    }
    final flag = product['isLabGrown'];
    return flag == true || flag == 'true';
  }

  static String? _image(Map<String, dynamic> product, String productType) {
    if (productType == FavoriteProductType.jewellery) {
      final fromVariant = _variantImage(product);
      if (fromVariant != null) return fromVariant;
    }
    return _imageFrom(product);
  }

  static String? _variantImage(Map<String, dynamic> product) {
    final variants = product['variants'];
    if (variants is! List) return null;
    for (final item in variants) {
      if (item is! Map<String, dynamic>) continue;
      final url = _imageFrom(item);
      if (url != null) return url;
    }
    return null;
  }

  static String? _imageFrom(Map<String, dynamic> product) {
    for (final key in [
      'image1',
      'image2',
      'image3',
      'image',
      'imageUrl',
      'thumbnail',
    ]) {
      final v = _str(product[key]);
      if (v != null) return v;
    }
    final images = product['images'];
    if (images is List && images.isNotEmpty) {
      return _str(images.first);
    }
    return null;
  }

  static String? _label(Object? v) {
    if (v == null) return null;
    if (v is Map) {
      return _label(v['name']) ??
          _label(v['value']) ??
          _label(v['label']) ??
          _label(v['title']);
    }
    if (v is List || v is num || v is bool) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    if (s.startsWith('{') && s.contains('id:')) return null;
    if (_isUuid(s)) return null;
    if (s == '-' || s == '—' || s == '–' || s.toLowerCase() == 'n/a') {
      return null;
    }
    return s;
  }

  static String? _humanName(String? raw) {
    if (raw == null) return null;
    if (_looksLikeStockId(raw)) return null;
    return raw;
  }

  static bool _looksLikeStockId(String raw) {
    final t = raw.trim();
    if (t.length < 4) return false;
    if (_isUuid(t)) return true;
    if (RegExp(r'^[A-Z]{2,}-[A-Z0-9-]+$').hasMatch(t)) return true;
    if (RegExp(r'^[a-z]{2,}\d{2,}[-_]\w+$', caseSensitive: false).hasMatch(t)) {
      return true;
    }
    return false;
  }

  static bool _isUuid(String raw) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(raw.trim());
  }

  static String? _titleCase(Object? v) {
    final raw = _label(v);
    if (raw == null) return null;
    return raw
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) return word;
          return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  static String? _caratText(double? carat) {
    if (carat == null || carat <= 0) return null;
    final text = carat == carat.roundToDouble()
        ? '${carat.toInt()}'
        : carat.toString();
    return '${text}ct';
  }

  static String? _weightLabel(double? grams) {
    if (grams == null || grams <= 0) return null;
    const oz = 31.103;
    if ((grams - oz).abs() < 0.05) return '1oz';
    if (grams >= 1000 && (grams % 1000).abs() < 0.01) {
      final kg = grams / 1000;
      return kg == kg.roundToDouble()
          ? '${kg.toInt()}kg'
          : '${kg.toStringAsFixed(1)}kg';
    }
    if (grams == grams.roundToDouble()) return '${grams.toInt()}g';
    return '${grams.toStringAsFixed(3)}g';
  }

  static String? _year(Object? v) {
    if (v is int) return v.toString();
    if (v is num) return v.toInt().toString();
    return _label(v);
  }

  static String _join(Iterable<String?> parts) {
    return parts
        .map((e) => e?.trim())
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' · ');
  }

  static String _joinWords(Iterable<String?> parts) {
    return parts
        .map((e) => e?.trim())
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' ');
  }

  static String? _variantLabel(Map<String, dynamic> product, String key) {
    final variants = product['variants'];
    if (variants is! List || variants.isEmpty) return null;
    final first = variants.first;
    if (first is! Map) return null;
    return _label(first[key]);
  }

  static double? _variantNum(Map<String, dynamic> product, String key) {
    final variants = product['variants'];
    if (variants is! List || variants.isEmpty) return null;
    final first = variants.first;
    if (first is! Map) return null;
    return _num(first[key]);
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
}
