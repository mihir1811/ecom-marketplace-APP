/// Jewelry-only layout data for the product detail screen.
///
/// Built from a marketplace listing. Card records ([isFullRecord] false)
/// lack the description, gemstones and inactive SKUs; the page loads the
/// full record by [slug] when it opens.
class ProductJewelryDetail {
  const ProductJewelryDetail({
    required this.slug,
    required this.listingId,
    required this.description,
    required this.category,
    required this.price,
    required this.maxPrice,
    required this.currencySymbol,
    required this.totalStock,
    this.subCategory,
    this.stockNumber,
    this.shop,
    this.metalType,
    this.metalPurity,
    this.metalWeightG,
    this.grossWeightG,
    this.primaryGemstone,
    this.gemstoneOrigin,
    this.primaryShape,
    this.totalCaratWeight,
    this.style,
    this.occasion,
    this.tags = const [],
    this.isMadeToOrder = false,
    this.processingDays = 3,
    this.personalizationEnabled = false,
    this.personalizationInstructions,
    this.freeShipping = false,
    this.shipsFromCountry,
    this.returnsAccepted = true,
    this.returnWindowDays,
    this.cancellationWindowHours = 24,
    this.stones = const [],
    this.variations = const [],
    this.customOptions = const [],
    this.skus = const [],
    this.coverImageUrl,
    this.isFullRecord = false,
    this.taxLabels = const [],
  });

  /// Taxes added at checkout ("GST (3%)"); empty when none.
  final List<String> taxLabels;

  final String slug;
  final String listingId;
  final String? description;
  final String category;
  final String? subCategory;
  final String? stockNumber;
  final ProductJewelryShop? shop;

  /// Lowest and highest SKU price.
  final double price;
  final double maxPrice;
  final String currencySymbol;
  final int totalStock;

  /// Display words (`Yellow Gold`, `Lab-Grown`), not API enums.
  final String? metalType;
  final String? metalPurity;
  final double? metalWeightG;
  final double? grossWeightG;
  final String? primaryGemstone;
  final String? gemstoneOrigin;
  final String? primaryShape;
  final double? totalCaratWeight;
  final String? style;
  final String? occasion;
  final List<String> tags;
  final bool isMadeToOrder;
  final int processingDays;
  final bool personalizationEnabled;
  final String? personalizationInstructions;
  final bool freeShipping;
  final String? shipsFromCountry;
  final bool returnsAccepted;
  final int? returnWindowDays;

  /// Hours after payment the buyer can cancel; 0 means never.
  final int cancellationWindowHours;
  final List<ProductJewelryStone> stones;
  final List<ProductJewelryVariation> variations;

  /// Text boxes; each name is its `customValues` key.
  final List<String> customOptions;
  final List<ProductJewelrySku> skus;
  final String? coverImageUrl;
  final bool isFullRecord;

  bool get soldOut => totalStock == 0 && !isMadeToOrder;

  bool get hasPriceRange => maxPrice > price;

  List<ProductJewelrySku> get activeSkus => [
    for (final s in skus)
      if (s.isActive) s,
  ];

  /// Purchasable SKU matching every variation in [selected], or null.
  ProductJewelrySku? skuFor(Map<String, String> selected) {
    for (final sku in skus) {
      if (!sku.isActive) continue;
      if (variations.every((v) => sku.options[v.name] == selected[v.name])) {
        return sku;
      }
    }
    return null;
  }

  /// Whether choosing [option] for [variation], keeping the other current
  /// choices, still leads to a purchasable SKU.
  bool optionAvailable(
    String variation,
    String option,
    Map<String, String> selected,
  ) {
    for (final sku in skus) {
      if (!sku.isActive || sku.options[variation] != option) continue;
      final fits = variations.every(
        (v) =>
            v.name == variation ||
            selected[v.name] == null ||
            sku.options[v.name] == selected[v.name],
      );
      if (fits) return true;
    }
    return false;
  }

  /// Most a buyer can order of [sku] in one bag line.
  int maxQuantityFor(ProductJewelrySku? sku) {
    if (isMadeToOrder) return 20;
    final stock = sku?.stock ?? 0;
    return stock.clamp(0, 20);
  }
}

class ProductJewelryShop {
  const ProductJewelryShop({
    required this.name,
    required this.slug,
    this.sellerId,
    this.logoUrl,
    this.policies = const {},
    this.showPriceBreakdown = false,
  });

  final String name;
  final String slug;
  final String? sellerId;
  final String? logoUrl;

  /// `processingTime`, `returns`, `shipping`, `location`.
  final Map<String, String> policies;
  final bool showPriceBreakdown;
}

class ProductJewelryStone {
  const ProductJewelryStone({
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

class ProductJewelryVariation {
  const ProductJewelryVariation({required this.name, required this.options});

  final String name;
  final List<String> options;
}

class ProductJewelrySku {
  const ProductJewelrySku({
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

  /// What checkout charges for one piece.
  final double price;
  final int stock;
  final bool isActive;
  final Map<String, String> options;

  /// `metal`, `making`, `stone`, `extra` in rupees.
  final Map<String, double>? breakdown;
}
