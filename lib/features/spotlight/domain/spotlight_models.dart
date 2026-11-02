import '../../product_detail/domain/models/product_detail.dart';

/// Where a paid placement is drawn. Values match the API's `placement`.
enum SpotlightPlacement {
  homeBanner('HOME_BANNER'),
  homeFeaturedSeller('HOME_FEATURED_SELLER'),
  categoryBanner('CATEGORY_BANNER'),
  categorySponsored('CATEGORY_SPONSORED'),
  productSponsored('PRODUCT_SPONSORED');

  const SpotlightPlacement(this.api);

  final String api;

  /// Placements that need a `category` (the API answers 400 without it).
  bool get needsCategory =>
      this == categoryBanner ||
      this == categorySponsored ||
      this == productSponsored;

  /// Sponsored placements take a `limit` (1–24, default 8).
  bool get isSponsoredProducts =>
      this == categorySponsored || this == productSponsored;

  static SpotlightPlacement? fromApi(Object? value) {
    final raw = value?.toString().trim().toUpperCase();
    for (final p in values) {
      if (p.api == raw) return p;
    }
    return null;
  }
}

/// The five catalogue sections ads are booked in. Values match `category`.
enum SpotlightCategory {
  diamonds('diamonds'),
  gemstones('gemstones'),
  jewellery('jewellery'),
  watches('watches'),
  bullion('bullion');

  const SpotlightCategory(this.api);

  final String api;

  static SpotlightCategory? fromApi(Object? value) {
    final raw = value?.toString().trim().toLowerCase();
    for (final c in values) {
      if (c.api == raw) return c;
    }
    return null;
  }

  /// The section a product page belongs to.
  static SpotlightCategory fromSegment(ProductSegment segment) =>
      switch (segment) {
        ProductSegment.naturalDiamond ||
        ProductSegment.labGrownDiamond => diamonds,
        ProductSegment.gemstone => gemstones,
        ProductSegment.jewelry => jewellery,
        ProductSegment.watch => watches,
        ProductSegment.bullion => bullion,
      };
}

/// One GET /spotlight call's parameters; a record so it works as a
/// provider family key.
typedef SpotlightQuery = ({
  SpotlightPlacement placement,
  SpotlightCategory? category,
  String? excludeProductId,
  int? limit,
});

SpotlightQuery spotlightQuery(
  SpotlightPlacement placement, {
  SpotlightCategory? category,
  String? excludeProductId,
  int? limit,
}) => (
  placement: placement,
  category: category,
  excludeProductId: excludeProductId,
  limit: limit,
);

/// Where a banner tap goes.
enum SpotlightLinkKind { product, seller }

class SpotlightLink {
  const SpotlightLink({
    required this.kind,
    this.productType,
    this.productId,
    this.sellerId,
  });

  final SpotlightLinkKind kind;
  final String? productType;
  final String? productId;
  final String? sellerId;

  factory SpotlightLink.fromJson(Map<String, dynamic> j) {
    final kind = SpotlightJson.text(j['kind'])?.toUpperCase() == 'PRODUCT'
        ? SpotlightLinkKind.product
        : SpotlightLinkKind.seller;
    return SpotlightLink(
      kind: kind,
      productType: SpotlightJson.text(j['productType']),
      productId: SpotlightJson.text(j['productId']),
      sellerId: SpotlightJson.text(j['sellerId']),
    );
  }

  bool get opensProduct =>
      kind == SpotlightLinkKind.product &&
      (productId?.isNotEmpty ?? false) &&
      (productType?.isNotEmpty ?? false);
}

/// `seller: { id, name }` on banners and sponsored products.
class SpotlightSellerRef {
  const SpotlightSellerRef({required this.id, required this.name});

  final String id;
  final String name;

  static SpotlightSellerRef? fromJson(Object? raw) {
    final j = SpotlightJson.map(raw);
    if (j == null) return null;
    final id = SpotlightJson.text(j['id']) ?? SpotlightJson.text(j['_id']);
    if (id == null) return null;
    return SpotlightSellerRef(id: id, name: SpotlightJson.text(j['name']) ?? '');
  }
}

/// The public seller card of a featured-seller ad. Also handed to the shop
/// screen so its header shows without another call.
class SpotlightSellerProfile {
  const SpotlightSellerProfile({
    required this.id,
    required this.name,
    this.logoUrl,
    this.bannerUrl,
    this.sellerType,
    this.city,
    this.state,
    this.rating,
    this.reviewCount = 0,
    this.tagline,
  });

  final String id;
  final String name;
  final String? logoUrl;
  final String? bannerUrl;

  /// naturalDiamond, labGrownDiamond, gemstone, jewellery, watch or bullion.
  final String? sellerType;
  final String? city;
  final String? state;
  final double? rating;
  final int reviewCount;
  final String? tagline;

  /// Rating is shown only once someone has reviewed the seller.
  bool get showsRating => reviewCount > 0 && rating != null;

  String? get place {
    final parts = [?city, ?state].where((s) => s.trim().isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(', ');
  }

  static SpotlightSellerProfile? fromJson(Object? raw, {String? tagline}) {
    final j = SpotlightJson.map(raw);
    if (j == null) return null;
    final id = SpotlightJson.text(j['id']) ?? SpotlightJson.text(j['_id']);
    if (id == null) return null;
    return SpotlightSellerProfile(
      id: id,
      name: SpotlightJson.text(j['name']) ?? '',
      logoUrl: SpotlightJson.text(j['logoUrl']),
      bannerUrl: SpotlightJson.text(j['bannerUrl']),
      sellerType: SpotlightJson.text(j['sellerType']),
      city: SpotlightJson.text(j['city']),
      state: SpotlightJson.text(j['state']),
      rating: SpotlightJson.number(j['rating']),
      reviewCount: SpotlightJson.integer(j['reviewCount']) ?? 0,
      tagline: tagline,
    );
  }
}

/// A live ad. Every item carries the [adId] its views and clicks go with.
sealed class SpotlightItem {
  const SpotlightItem({required this.adId});

  final String adId;

  /// Parses one `items[]` entry by its `kind`; null for unknown shapes.
  static SpotlightItem? fromJson(Object? raw) {
    final j = SpotlightJson.map(raw);
    if (j == null) return null;
    final adId = SpotlightJson.text(j['adId']);
    if (adId == null) return null;
    switch (SpotlightJson.text(j['kind'])?.toUpperCase()) {
      case 'BANNER':
        final image = SpotlightJson.text(j['imageUrl']);
        if (image == null) return null;
        final link = SpotlightJson.map(j['link']);
        return SpotlightBanner(
          adId: adId,
          title: SpotlightJson.text(j['title']) ?? '',
          subtitle: SpotlightJson.text(j['subtitle']),
          imageUrl: image,
          mobileImageUrl: SpotlightJson.text(j['mobileImageUrl']) ?? image,
          link: link == null
              ? SpotlightLink(
                  kind: SpotlightLinkKind.seller,
                  sellerId: SpotlightSellerRef.fromJson(j['seller'])?.id,
                )
              : SpotlightLink.fromJson(link),
          seller: SpotlightSellerRef.fromJson(j['seller']),
        );
      case 'FEATURED_SELLER':
        final tagline = SpotlightJson.text(j['tagline']);
        final seller = SpotlightSellerProfile.fromJson(
          j['seller'],
          tagline: tagline,
        );
        if (seller == null) return null;
        return SpotlightFeaturedSeller(adId: adId, seller: seller);
      case 'SPONSORED_PRODUCT':
        final product = SpotlightProduct.fromJson(j['product']);
        if (product == null) return null;
        return SpotlightSponsoredProduct(
          adId: adId,
          product: product,
          seller: SpotlightSellerRef.fromJson(j['seller']),
        );
    }
    return null;
  }
}

/// HOME_BANNER and CATEGORY_BANNER.
class SpotlightBanner extends SpotlightItem {
  const SpotlightBanner({
    required super.adId,
    required this.title,
    required this.imageUrl,
    required this.mobileImageUrl,
    required this.link,
    this.subtitle,
    this.seller,
  });

  /// Up to 60 characters.
  final String title;

  /// Up to 120 characters; may be null.
  final String? subtitle;

  /// 4:1, for tablets.
  final String imageUrl;

  /// 2:1, for phones; repeats [imageUrl] when the seller gave none.
  final String mobileImageUrl;
  final SpotlightLink link;
  final SpotlightSellerRef? seller;
}

/// HOME_FEATURED_SELLER.
class SpotlightFeaturedSeller extends SpotlightItem {
  const SpotlightFeaturedSeller({required super.adId, required this.seller});

  final SpotlightSellerProfile seller;
}

/// CATEGORY_SPONSORED and PRODUCT_SPONSORED.
class SpotlightSponsoredProduct extends SpotlightItem {
  const SpotlightSponsoredProduct({
    required super.adId,
    required this.product,
    this.seller,
  });

  final SpotlightProduct product;
  final SpotlightSellerRef? seller;
}

class SpotlightProduct {
  const SpotlightProduct({
    required this.productType,
    required this.productId,
    required this.title,
    this.stockNumber,
    this.subtitle,
    this.imageUrl,
    this.shape,
    this.price,
    this.currency = 'USD',
    this.isOnAuction = false,
  });

  /// diamond, meleeDiamond, gemstone, jewellery, watch or bullion.
  final String productType;
  final String productId;
  final String? stockNumber;
  final String title;
  final String? subtitle;
  final String? imageUrl;

  /// The listing's own shape, drawn when there is no photo.
  final String? shape;

  /// US dollars; null means price on request.
  final double? price;
  final String currency;
  final bool isOnAuction;

  static SpotlightProduct? fromJson(Object? raw) {
    final j = SpotlightJson.map(raw);
    if (j == null) return null;
    final type = SpotlightJson.text(j['productType']);
    final id =
        SpotlightJson.text(j['productId']) ??
        SpotlightJson.text(j['id']) ??
        SpotlightJson.text(j['_id']);
    if (type == null || id == null) return null;
    return SpotlightProduct(
      productType: type,
      productId: id,
      stockNumber: SpotlightJson.text(j['stockNumber']),
      title:
          SpotlightJson.text(j['title']) ??
          SpotlightJson.text(j['name']) ??
          '',
      subtitle: SpotlightJson.text(j['subtitle']),
      imageUrl: SpotlightJson.text(j['imageUrl']),
      shape: SpotlightJson.text(j['shape']),
      price: SpotlightJson.number(j['price']),
      currency: SpotlightJson.text(j['currency']) ?? 'USD',
      isOnAuction: j['isOnAuction'] == true,
    );
  }
}

/// Lenient JSON readers shared by the spotlight models.
abstract final class SpotlightJson {
  static Map<String, dynamic>? map(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v));
    return null;
  }

  static List<Object?> list(Object? value) =>
      value is List ? value : const <Object?>[];

  static String? text(Object? value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty || s == 'null' ? null : s;
  }

  static double? number(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int? integer(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static bool flag(Object? value) =>
      value == true || value?.toString().toLowerCase() == 'true';

  static DateTime? date(Object? value) {
    final s = text(value);
    return s == null ? null : DateTime.tryParse(s);
  }
}
