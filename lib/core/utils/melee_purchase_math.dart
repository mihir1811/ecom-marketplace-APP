/// Shared melee partial-purchase pricing (detail draft, cart add, cart display).
abstract final class MeleePurchaseMath {
  /// Scales [lotPrice] to the selected share of the lot.
  static double proportionalLotPrice({
    required double lotPrice,
    required bool inCarat,
    required int selectedPcs,
    required double selectedCarat,
    int? totalPcs,
    double? totalCarat,
  }) {
    if (lotPrice <= 0) return 0;
    if (inCarat) {
      if (totalCarat != null && totalCarat > 0) {
        return lotPrice * (selectedCarat / totalCarat);
      }
    }
    if (totalPcs != null && totalPcs > 0 && selectedPcs > 0) {
      return lotPrice * (selectedPcs / totalPcs);
    }
    if (totalCarat != null && totalCarat > 0 && selectedCarat > 0) {
      return lotPrice * (selectedCarat / totalCarat);
    }
    return lotPrice;
  }

  /// Resolves cart line USD from stored specs + nested product fields.
  ///
  /// Prefers `calculatedPrice` (what the buyer saw on detail), otherwise
  /// recomputes from lot `totalPrice` × selected share — never `pricePerPcs`
  /// alone, which understates separable parcels.
  static double? linePriceFromCartPayload({
    required Map<String, dynamic>? specifications,
    required Map<String, dynamic> product,
  }) {
    if (specifications == null || specifications.isEmpty) return null;

    final calculated = _num(specifications['calculatedPrice']);
    if (calculated != null && calculated > 0) return calculated;

    final unit = (_str(specifications['purchaseUnit']) ?? '').toLowerCase();
    final selectedPcs = _int(specifications['selectedPcs']) ?? 0;
    final selectedCarat = _num(specifications['selectedCarat']) ?? 0;
    if (selectedPcs <= 0 && selectedCarat <= 0) return null;

    final lot = _num(product['totalPrice']) ?? _num(product['price']) ?? 0;
    if (lot <= 0) return null;

    final totalPcs = _int(product['totalPcs']);
    final totalCarat = _num(product['totalCaratWeight']) ??
        _num(product['totalCarat']) ??
        _num(product['caratWeight']);

    return proportionalLotPrice(
      lotPrice: lot,
      inCarat: unit == 'carat' || unit == 'ct',
      selectedPcs: selectedPcs,
      selectedCarat: selectedCarat,
      totalPcs: totalPcs,
      totalCarat: totalCarat,
    );
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
