/// Backend cart `productType` enum values.
abstract final class CartProductType {
  static const String diamond = 'diamond';
  static const String gemstone = 'gemstone';
  static const String meleeDiamond = 'meleeDiamond';
  static const String jewellery = 'jewellery';
  static const String watch = 'watch';
  static const String bullion = 'bullion';

  /// Jewellery marketplace piece (keyed by listing slug). Never sent to the
  /// server cart, favorites or recently viewed: it lives in the on-device
  /// jewellery bag and is priced by `/marketplace/cart/quote`.
  static const String marketplaceJewellery = 'marketplaceJewellery';

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
