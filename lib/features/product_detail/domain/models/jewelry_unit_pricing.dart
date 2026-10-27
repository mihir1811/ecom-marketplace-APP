/// Single-unit jewelry price math from API component fields.
///
/// API `totalPrice` is the net sell price. When metal/stone/making are present:
/// `list = metal + stone + making`, `net = list - discount` (matches `totalPrice`).
class JewelryUnitPricing {
  const JewelryUnitPricing({
    required this.metal,
    required this.stone,
    required this.making,
    required this.discount,
    required this.listPrice,
    required this.netPrice,
  });

  final double metal;
  final double stone;
  final double making;
  final double discount;
  final double listPrice;
  final double netPrice;

  bool get hasDiscount => discount > 0 && listPrice > netPrice;

  /// Percent of list price that is discounted (0–100).
  double get discountPercent {
    if (!hasDiscount || listPrice <= 0) return 0;
    return (discount / listPrice) * 100;
  }

  static JewelryUnitPricing from({
    double? metalPrice,
    double? stonePrice,
    double? makingCharge,
    double? discountAmount,
    required double totalPrice,
  }) {
    final metal = _nonNeg(metalPrice);
    final stone = _nonNeg(stonePrice);
    final making = _nonNeg(makingCharge);
    final discount = _nonNeg(discountAmount);
    final apiTotal = _nonNeg(totalPrice);
    final components = metal + stone + making;

    if (components > 0) {
      final list = components;
      final net = (list - discount).clamp(0.0, double.infinity);
      // Prefer API total when it matches the computed net (normal path).
      final resolvedNet = (apiTotal > 0 && (apiTotal - net).abs() < 0.5)
          ? apiTotal
          : net;
      return JewelryUnitPricing(
        metal: metal,
        stone: stone,
        making: making,
        discount: discount,
        listPrice: list,
        netPrice: resolvedNet,
      );
    }

    // Flat totalPrice listing (no component breakup).
    if (discount > 0 && apiTotal > 0) {
      return JewelryUnitPricing(
        metal: 0,
        stone: 0,
        making: 0,
        discount: discount,
        listPrice: apiTotal + discount,
        netPrice: apiTotal,
      );
    }

    return JewelryUnitPricing(
      metal: 0,
      stone: 0,
      making: 0,
      discount: 0,
      listPrice: apiTotal,
      netPrice: apiTotal,
    );
  }

  static double _nonNeg(double? value) {
    if (value == null || value.isNaN || value.isInfinite) return 0;
    return value < 0 ? 0 : value;
  }
}
