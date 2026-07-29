import '../../../../core/utils/format_catalog_price.dart';
import '../../../diamonds/domain/models/diamond.dart';
import '../../../diamonds/domain/models/diamond_display.dart';
import '../../../gemstones/domain/models/gemstone.dart';
import '../../../jewelry/domain/models/jewelry.dart';
import '../../../watches/domain/models/watch.dart';
import '../../../../core/utils/app_currency.dart';

enum WishlistCategory { diamond, gemstone, jewelry, watch, bullion }

/// Snapshot of a catalog product saved to the buyer wishlist.
class WishlistItem {
  const WishlistItem({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.priceLabel,
    this.imageUrl,
    this.imageAsset,
  });

  final String id;
  final WishlistCategory category;
  final String title;
  final String subtitle;
  final String priceLabel;
  final String? imageUrl;
  final String? imageAsset;

  factory WishlistItem.fromDiamond(Diamond d) {
    final color = DiamondDisplay.gradeChip(d.color);
    final clarity = DiamondDisplay.gradeChip(d.clarity);
    return WishlistItem(
      id: d.id,
      category: WishlistCategory.diamond,
      title: '${d.carat}ct ${DiamondDisplay.shape(d.shape)}',
      subtitle:
          '${d.isLabGrown ? 'Lab Grown' : 'Natural'} · $color $clarity',
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
      imageUrl: g.imageUrl,
    );
  }

  factory WishlistItem.fromJewelry(Jewelry j) {
    return WishlistItem(
      id: j.id,
      category: WishlistCategory.jewelry,
      title: j.name,
      subtitle: '${j.category} · ${j.metalType}',
      priceLabel: AppCurrency.format(formatInrPrice(j.price)),
      imageAsset: j.imageAsset,
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
}
