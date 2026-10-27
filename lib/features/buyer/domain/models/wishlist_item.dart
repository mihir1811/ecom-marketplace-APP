import '../../../../core/utils/format_catalog_price.dart';
import '../../../bullions/domain/models/billion.dart';
import '../../../diamonds/domain/models/diamond.dart';
import '../../../diamonds/domain/models/diamond_display.dart';
import '../../../gemstones/domain/models/gemstone.dart';
import '../../../jewelry/domain/models/jewelry.dart';
import '../../../watches/domain/models/watch.dart';
import '../../../../core/utils/app_currency.dart';

enum WishlistCategory { diamond, gemstone, jewelry, watch, bullion }

/// Backend `productType` values for `/favorites`.
abstract final class FavoriteProductType {
  static const String diamond = 'diamond';
  static const String gemstone = 'gemstone';
  static const String meleeDiamond = 'meleeDiamond';
  static const String jewellery = 'jewellery';
  static const String watch = 'watch';
  static const String bullion = 'bullion';

  /// Jewellery marketplace piece: saved on the device, never sent to
  /// `/favorites` (id is the listing slug).
  static const String marketplaceJewellery = 'marketplaceJewellery';

  static String fromCategory(WishlistCategory category) => switch (category) {
    WishlistCategory.diamond => diamond,
    WishlistCategory.gemstone => gemstone,
    WishlistCategory.jewelry => jewellery,
    WishlistCategory.watch => watch,
    WishlistCategory.bullion => bullion,
  };

  static WishlistCategory toCategory(String type) => switch (type) {
    gemstone => WishlistCategory.gemstone,
    jewellery || marketplaceJewellery => WishlistCategory.jewelry,
    watch => WishlistCategory.watch,
    bullion => WishlistCategory.bullion,
    _ => WishlistCategory.diamond,
  };

  static String label(String type) => switch (type) {
    diamond => 'Diamond',
    meleeDiamond => 'Melee Diamond',
    gemstone => 'Gemstone',
    jewellery || marketplaceJewellery => 'Jewelry',
    watch => 'Watch',
    bullion => 'Bullion',
    _ => type,
  };
}

/// Paginated GET `/favorites/all` payload.
class WishlistPage {
  const WishlistPage({
    required this.items,
    required this.total,
    required this.currentPage,
    required this.hasMore,
  });

  final List<WishlistItem> items;
  final int total;
  final int currentPage;
  final bool hasMore;
}

/// Snapshot of a catalog product saved to the buyer wishlist.
class WishlistItem {
  WishlistItem({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.priceLabel,
    this.imageUrl,
    this.imageAsset,
    String? productType,
    this.favoriteId,
  }) : productType = productType ?? FavoriteProductType.fromCategory(category);

  final String id;
  final WishlistCategory category;
  final String productType;
  final String title;
  final String subtitle;
  final String priceLabel;
  final String? imageUrl;
  final String? imageAsset;
  final String? favoriteId;

  factory WishlistItem.fromDiamond(Diamond d) {
    final color = DiamondDisplay.gradeChip(d.color);
    final clarity = DiamondDisplay.gradeChip(d.clarity);
    return WishlistItem(
      id: d.id,
      category: WishlistCategory.diamond,
      productType: d.isMelee
          ? FavoriteProductType.meleeDiamond
          : FavoriteProductType.diamond,
      title: '${d.carat}ct ${DiamondDisplay.shape(d.shape)}',
      subtitle: '${d.isLabGrown ? 'Lab Grown' : 'Natural'} · $color $clarity',
      priceLabel: AppCurrency.format(formatCatalogPrice(d.price)),
      imageUrl: d.imageUrl,
    );
  }

  factory WishlistItem.fromGemstone(Gemstone g) {
    return WishlistItem(
      id: g.id,
      category: WishlistCategory.gemstone,
      title: '${g.carat}ct ${g.type}',
      subtitle: '${g.origin} · ${g.color}',
      priceLabel: AppCurrency.format(formatCatalogPrice(g.price)),
      imageUrl: g.hasNetworkImage ? g.imageUrl : null,
    );
  }

  factory WishlistItem.fromJewelry(Jewelry j) {
    return WishlistItem(
      id: j.id,
      category: WishlistCategory.jewelry,
      productType: j.isMarketplace
          ? FavoriteProductType.marketplaceJewellery
          : FavoriteProductType.jewellery,
      title: j.name,
      subtitle: [
        j.subCategory ?? j.category,
        j.metalType,
      ].where((s) => s.trim().isNotEmpty).join(' · '),
      priceLabel: '${AppCurrency.inrSymbol}${formatInrPrice(j.price)}',
      imageUrl: j.displayImageUrl,
    );
  }

  factory WishlistItem.fromWatch(Watch w) {
    return WishlistItem(
      id: w.id,
      category: WishlistCategory.watch,
      title: '${w.brand} ${w.model}',
      subtitle: '${w.year} · ${w.caseMaterial}',
      priceLabel: AppCurrency.format(formatGroupedPrice(w.price)),
      imageUrl: w.renderableImageUrl,
    );
  }

  factory WishlistItem.fromBullion(Bullion b) {
    final metal = switch (b.metal) {
      BullionMetal.gold => 'Gold',
      BullionMetal.silver => 'Silver',
      BullionMetal.platinum => 'Platinum',
      BullionMetal.palladium => 'Palladium',
      BullionMetal.copper => 'Copper',
    };
    return WishlistItem(
      id: b.id,
      category: WishlistCategory.bullion,
      title: '${b.weightLabel} $metal',
      subtitle: '${b.shape} · ${b.condition}',
      priceLabel: AppCurrency.format(formatGroupedPrice(b.price)),
      imageUrl: b.renderableImageUrl,
    );
  }
}
