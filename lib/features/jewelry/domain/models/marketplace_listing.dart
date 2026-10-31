/// Jewellery marketplace records from `GET /marketplace/*`.
///
/// Catalogue cards and the product page share [MarketplaceListing]; cards
/// leave out the description and gemstones, carry at most two media items
/// and only the active SKUs. Prices are rupees.
library;

/// A top-level category with its active sub-categories.
class MarketplaceCategory {
  const MarketplaceCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.parentId,
    this.imageUrl,
    this.position = 0,
    this.children = const [],
  });

  final String id;
  final String name;
  final String slug;
  final String? parentId;

  /// Usually null on the live API; the app ships fallback artwork.
  final String? imageUrl;
  final int position;
  final List<MarketplaceCategory> children;

  /// The category or sub-category with [slug] in [all], or null.
  static MarketplaceCategory? find(
    List<MarketplaceCategory> all,
    String? slug,
  ) {
    if (slug == null || slug.isEmpty) return null;
    for (final c in all) {
      if (c.slug == slug) return c;
      for (final child in c.children) {
        if (child.slug == slug) return child;
      }
    }
    return null;
  }

  /// The top-level category that is or contains [slug].
  static MarketplaceCategory? parentOf(
    List<MarketplaceCategory> all,
    String? slug,
  ) {
    if (slug == null || slug.isEmpty) return null;
    for (final c in all) {
      if (c.slug == slug || c.children.any((s) => s.slug == slug)) return c;
    }
    return null;
  }
}

/// A seller's storefront.
class MarketplaceShop {
  const MarketplaceShop({
    required this.id,
    required this.name,
    required this.slug,
    this.sellerId,
    this.headline,
    this.description,
    this.logoUrl,
    this.bannerUrl,
    this.policies = const {},
    this.showPriceBreakdown = false,
    this.listingCount,
    this.listings = const [],
  });

  final String id;
  final String name;
  final String slug;

  /// GemWorld seller id; matches the signed-in seller for own-shop checks.
  final String? sellerId;
  final String? headline;
  final String? description;
  final String? logoUrl;
  final String? bannerUrl;

  /// `processingTime`, `returns`, `shipping`, `location` as free text.
  final Map<String, String> policies;

  /// When true, SKUs carry a metal / making / stone / extra split.
  final bool showPriceBreakdown;
  final int? listingCount;

  /// Only from `GET /marketplace/shops/{slug}`.
  final List<MarketplaceListing> listings;
}

class MarketplaceMedia {
  const MarketplaceMedia({
    required this.id,
    required this.url,
    this.isVideo = false,
    this.position = 0,
    this.altText,
  });

  final String id;
  final String url;
  final bool isVideo;
  final int position;
  final String? altText;
}

/// One buyer choice, e.g. `Metal` with `14K Yellow Gold`, `14K White Gold`.
class MarketplaceVariation {
  const MarketplaceVariation({
    required this.name,
    required this.options,
    this.linkPhotos = false,
    this.optionMedia = const {},
  });

  final String name;
  final List<String> options;
  final bool linkPhotos;

  /// Option → media ids shown for it (when [linkPhotos]).
  final Map<String, List<String>> optionMedia;
}

/// A text box the buyer fills in; [name] is its key in `customValues`.
class MarketplaceCustomOption {
  const MarketplaceCustomOption({required this.name, this.isText = true});

  final String name;
  final bool isText;
}

/// One purchasable combination of variation options.
class MarketplaceSku {
  const MarketplaceSku({
    required this.id,
    required this.price,
    required this.stock,
    required this.isActive,
    this.label,
    this.options = const {},
    this.breakdown,
  });

  final String id;
  final String? label;

  /// What checkout charges: `regionalPrices.inr` when set, else `price`.
  final double price;
  final int stock;
  final bool isActive;

  /// Variation name → option.
  final Map<String, String> options;

  /// `metal`, `making`, `stone`, `extra` in rupees (when the shop shows it).
  final Map<String, double>? breakdown;
}

/// One stone row on the product page.
class MarketplaceGemstone {
  const MarketplaceGemstone({
    this.type,
    this.origin,
    this.shape,
    this.caratWeight,
    this.quantity,
    this.color,
    this.clarity,
    this.cut,
    this.certificationLab,
    this.reportNumber,
  });

  final String? type;
  final String? origin;
  final String? shape;
  final double? caratWeight;
  final int? quantity;
  final String? color;
  final String? clarity;
  final String? cut;
  final String? certificationLab;
  final String? reportNumber;
}

/// The listing's `detail` block.
class MarketplaceListingDetail {
  const MarketplaceListingDetail({
    this.isMadeToOrder = false,
    this.metalType,
    this.metalPurity,
    this.metalWeightGrams,
    this.grossWeightGrams,
    this.primaryGemstone,
    this.gemstoneOrigin,
    this.primaryShape,
    this.totalCaratWeight,
    this.style,
    this.occasion,
    this.processingDays = 3,
    this.personalizationEnabled = false,
    this.personalizationInstructions,
    this.freeShipping = false,
    this.shipsFromCountry,
    this.returnsAccepted = true,
    this.returnWindowDays,
    this.cancellationWindowHours = 24,
  });

  final bool isMadeToOrder;

  /// Metal enum, e.g. `YELLOW_GOLD`.
  final String? metalType;
  final String? metalPurity;
  final double? metalWeightGrams;
  final double? grossWeightGrams;

  /// Gemstone enum, e.g. `DIAMOND`.
  final String? primaryGemstone;

  /// `NATURAL` or `LAB_GROWN`.
  final String? gemstoneOrigin;
  final String? primaryShape;
  final double? totalCaratWeight;
  final String? style;
  final String? occasion;
  final int processingDays;
  final bool personalizationEnabled;
  final String? personalizationInstructions;
  final bool freeShipping;
  final String? shipsFromCountry;
  final bool returnsAccepted;
  final int? returnWindowDays;

  /// Hours after payment the buyer can cancel; 0 means never.
  final int cancellationWindowHours;
}

class MarketplaceListing {
  const MarketplaceListing({
    required this.id,
    required this.slug,
    required this.title,
    required this.minPrice,
    required this.maxPrice,
    required this.totalStock,
    required this.detail,
    this.description,
    this.stockNumber,
    this.coverImageUrl,
    this.tags = const [],
    this.categoryName,
    this.categorySlug,
    this.parentCategoryName,
    this.parentCategorySlug,
    this.shop,
    this.variations = const [],
    this.customOptions = const [],
    this.skus = const [],
    this.media = const [],
    this.gemstones = const [],
    this.favoriteCount = 0,
    this.publishedAt,
    this.isFullRecord = false,
    this.taxLabels = const [],
  });

  final String id;
  final String slug;
  final String title;
  final String? description;
  final String? stockNumber;
  final String? coverImageUrl;
  final double minPrice;
  final double maxPrice;
  final int totalStock;
  final List<String> tags;
  final String? categoryName;
  final String? categorySlug;
  final String? parentCategoryName;
  final String? parentCategorySlug;
  final MarketplaceShop? shop;
  final MarketplaceListingDetail detail;
  final List<MarketplaceVariation> variations;
  final List<MarketplaceCustomOption> customOptions;
  final List<MarketplaceSku> skus;

  /// Sorted by position.
  final List<MarketplaceMedia> media;
  final List<MarketplaceGemstone> gemstones;
  final int favoriteCount;
  final DateTime? publishedAt;

  /// True for `GET /marketplace/listings/{slug}` (description, all media,
  /// gemstones and inactive SKUs included).
  final bool isFullRecord;

  /// Taxes GemWorld adds at checkout ("GST (3%)"); product page only,
  /// empty before taxes go live.
  final List<String> taxLabels;

  bool get soldOut => totalStock == 0 && !detail.isMadeToOrder;

  /// Card price reads "from" when SKUs differ in price.
  bool get hasPriceRange => maxPrice > minPrice;

  List<String> get imageUrls {
    final urls = <String>[
      for (final m in media)
        if (!m.isVideo && m.url.isNotEmpty) m.url,
    ];
    final cover = coverImageUrl;
    if (urls.isEmpty && cover != null && cover.isNotEmpty) urls.add(cover);
    return urls;
  }

  String? get videoUrl {
    for (final m in media) {
      if (m.isVideo && m.url.isNotEmpty) return m.url;
    }
    return null;
  }
}

class MarketplaceListingPage {
  const MarketplaceListingPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<MarketplaceListing> items;
  final int total;
  final int page;
  final int limit;

  bool get hasMore => page * limit < total;
}

class MarketplaceFacetBucket {
  const MarketplaceFacetBucket(this.value, this.count);

  final String value;
  final int count;
}

/// Filter-sheet counts. Only category, search, shop and tag narrow them, so
/// every option stays visible while the buyer picks.
class MarketplaceFacets {
  const MarketplaceFacets({
    this.total = 0,
    this.priceMin = 0,
    this.priceMax = 0,
    this.metals = const [],
    this.gemstones = const [],
    this.origins = const [],
    this.styles = const [],
    this.occasions = const [],
    this.shapes = const [],
    this.readyToShip = 0,
    this.madeToOrder = 0,
  });

  final int total;
  final double priceMin;
  final double priceMax;
  final List<MarketplaceFacetBucket> metals;
  final List<MarketplaceFacetBucket> gemstones;
  final List<MarketplaceFacetBucket> origins;
  final List<MarketplaceFacetBucket> styles;
  final List<MarketplaceFacetBucket> occasions;
  final List<MarketplaceFacetBucket> shapes;
  final int readyToShip;
  final int madeToOrder;
}
