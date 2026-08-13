import '../../../../core/utils/app_currency.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../domain/models/wishlist_item.dart';

/// Parses `/favorites` JSON into wishlist domain models.
abstract final class FavoriteMapper {
  static WishlistItem fromJson(Map<String, dynamic> json) {
    final product = json['product'];
    final productMap =
        product is Map<String, dynamic> ? product : const <String, dynamic>{};
    final productType = _str(json['productType']) ??
        FavoriteProductType.fromCategory(WishlistCategory.diamond);
    final category = FavoriteProductType.toCategory(productType);
    final title = _title(productMap, productType);
    final subtitle = _subtitle(productMap, productType);
    final price = _num(productMap['totalPrice']) ?? _num(productMap['price']);

    return WishlistItem(
      id: _str(json['productId']) ?? _str(productMap['id']) ?? '',
      category: category,
      productType: productType,
      title: title,
      subtitle: subtitle,
      priceLabel: price == null
          ? ''
          : AppCurrency.format(formatCatalogPrice(price)),
      imageUrl: _image(productMap),
      favoriteId: _str(json['id']),
    );
  }

  static WishlistPage pageFromJson(
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
    return _str(product['name']) ??
        _str(product['brand']) ??
        _str(product['stockNumber']) ??
        _str(product['title']) ??
        FavoriteProductType.label(productType);
  }

  static String _subtitle(Map<String, dynamic> product, String productType) {
    final candidates = <String?>[
      if (productType == FavoriteProductType.diamond ||
          productType == FavoriteProductType.meleeDiamond) ...[
        _str(product['shape']),
        _str(product['clarity']),
      ],
      _str(product['origin']),
      _str(product['color']),
      _str(product['metalType']),
      _str(product['model']),
    ];
    return candidates.whereType<String>().join(' · ');
  }

  static String? _image(Map<String, dynamic> product) {
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
}
