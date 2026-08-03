/// Backend cart `productType` enum values.
abstract final class CartProductType {
  static const String diamond = 'diamond';
  static const String gemstone = 'gemstone';
  static const String meleeDiamond = 'meleeDiamond';
  static const String jewellery = 'jewellery';
  static const String watch = 'watch';
  static const String bullion = 'bullion';

  static String label(String type) => switch (type) {
        diamond => 'Diamond',
        meleeDiamond => 'Melee Diamond',
        gemstone => 'Gemstone',
        jewellery => 'Jewelry',
        watch => 'Watch',
        bullion => 'Bullion',
        _ => type,
      };
}
