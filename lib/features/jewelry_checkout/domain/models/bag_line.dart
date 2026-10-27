/// One line in the on-device jewellery bag.
///
/// One line per variant and personalisation: the same ring engraved twice
/// is two lines. Title, image and options are kept so the bag draws offline;
/// the price shown always comes from the latest quote.
class BagLine {
  const BagLine({
    required this.skuId,
    required this.quantity,
    required this.listingSlug,
    required this.title,
    this.imageUrl,
    this.shopName,
    this.options = const {},
    this.customValues = const {},
    this.unitPrice,
  });

  /// The API takes at most 50 lines and 20 of one variant per line.
  static const maxLines = 50;
  static const maxQuantity = 20;

  final String skuId;
  final String listingSlug;
  final String title;
  final String? imageUrl;
  final String? shopName;
  final Map<String, String> options;
  final Map<String, String> customValues;

  /// 1 to 20.
  final int quantity;

  /// Price when added; replaced by the quote once the bag is priced.
  final double? unitPrice;

  /// The same variant with a different engraving is a separate line.
  String get key => keyFor(skuId, customValues);

  static String keyFor(String skuId, Map<String, String> customValues) {
    final parts = [
      for (final e in customValues.entries)
        if (e.value.trim().isNotEmpty) '${e.key}=${e.value.trim()}',
    ]..sort();
    return parts.isEmpty ? skuId : '$skuId|${parts.join('&')}';
  }

  BagLine copyWith({int? quantity, double? unitPrice}) => BagLine(
    skuId: skuId,
    quantity: quantity ?? this.quantity,
    listingSlug: listingSlug,
    title: title,
    imageUrl: imageUrl,
    shopName: shopName,
    options: options,
    customValues: customValues,
    unitPrice: unitPrice ?? this.unitPrice,
  );

  /// Body line for `/marketplace/cart/quote` and `/marketplace/orders`.
  Map<String, dynamic> toRequestJson() => {
    'skuId': skuId,
    'quantity': quantity,
    if (customValues.values.any((v) => v.trim().isNotEmpty))
      'customValues': {
        for (final e in customValues.entries)
          if (e.value.trim().isNotEmpty) e.key: e.value.trim(),
      },
  };

  Map<String, dynamic> toJson() => {
    'skuId': skuId,
    'quantity': quantity,
    'listingSlug': listingSlug,
    'title': title,
    'imageUrl': ?imageUrl,
    'shopName': ?shopName,
    'options': options,
    'customValues': customValues,
    'unitPrice': ?unitPrice,
  };

  static BagLine? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final skuId = raw['skuId']?.toString() ?? '';
    final slug = raw['listingSlug']?.toString() ?? '';
    if (skuId.isEmpty) return null;
    Map<String, String> strings(Object? v) => v is Map
        ? {for (final e in v.entries) '${e.key}': '${e.value}'}
        : const {};
    final qty = raw['quantity'];
    final price = raw['unitPrice'];
    return BagLine(
      skuId: skuId,
      quantity: (qty is num ? qty.toInt() : 1).clamp(1, maxQuantity),
      listingSlug: slug,
      title: raw['title']?.toString() ?? '',
      imageUrl: raw['imageUrl']?.toString(),
      shopName: raw['shopName']?.toString(),
      options: strings(raw['options']),
      customValues: strings(raw['customValues']),
      unitPrice: price is num ? price.toDouble() : null,
    );
  }
}
