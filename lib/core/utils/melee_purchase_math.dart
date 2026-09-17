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
  ///
  /// For jewellery, also resolves selected variant price via `variantId` /
  /// `stoneWeight` when the parent product still carries the first-variant
  /// listing price.
  static double? linePriceFromCartPayload({
    required Map<String, dynamic>? specifications,
    required Map<String, dynamic> product,
  }) {
    if (specifications == null || specifications.isEmpty) return null;

    final calculated = _num(specifications['calculatedPrice']);
    if (calculated != null && calculated > 0) return calculated;

    final jewelryVariant = _jewelryVariantLinePrice(
      specifications: specifications,
      product: product,
    );
    if (jewelryVariant != null && jewelryVariant > 0) return jewelryVariant;

    final unit = (_str(specifications['purchaseUnit']) ?? '').toLowerCase();
    final selectedPcs = _int(specifications['selectedPcs']) ?? 0;
    final selectedCarat = _num(specifications['selectedCarat']) ?? 0;
    if (selectedPcs <= 0 && selectedCarat <= 0) {
      final unitPrice = _num(specifications['unitPrice']);
      if (unitPrice != null && unitPrice > 0) {
        final qty = _int(specifications['quantity']) ?? 1;
        return unitPrice * (qty < 1 ? 1 : qty);
      }
      return null;
    }

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

  static double? _jewelryVariantLinePrice({
    required Map<String, dynamic> specifications,
    required Map<String, dynamic> product,
  }) {
    final variantId = _str(specifications['variantId']);
    final stoneLabel = (_str(specifications['stoneWeight']) ?? '').toLowerCase();
    final stoneCt = _num(specifications['stoneWeightCt']);
    final unitFromSpecs = _num(specifications['unitPrice']);

    Map<String, dynamic>? matched;
    final variants = product['variants'];
    if (variants is List) {
      for (final raw in variants) {
        if (raw is! Map<String, dynamic>) continue;
        final id = _str(raw['id']);
        if (variantId != null && id == variantId) {
          matched = raw;
          break;
        }
      }
      if (matched == null && (stoneLabel.isNotEmpty || stoneCt != null)) {
        for (final raw in variants) {
          if (raw is! Map<String, dynamic>) continue;
          final ct = _num(raw['totalStoneCarat']) ??
              _num(raw['stoneWeightCt']) ??
              _stoneWeightFromNested(raw);
          if (ct == null) continue;
          if (stoneCt != null && (ct - stoneCt).abs() < 1e-6) {
            matched = raw;
            break;
          }
          if (stoneLabel.isNotEmpty && _formatCt(ct).toLowerCase() == stoneLabel) {
            matched = raw;
            break;
          }
        }
      }
    }

    final unit = unitFromSpecs ??
        _num(matched?['totalPrice']) ??
        _num(matched?['price']);
    if (unit == null || unit <= 0) return null;
    final qty = _int(specifications['quantity']) ?? 1;
    return unit * (qty < 1 ? 1 : qty);
  }

  static double? _stoneWeightFromNested(Map<String, dynamic> variant) {
    final stones = variant['stones'];
    if (stones is! List || stones.isEmpty) return null;
    final first = stones.first;
    if (first is! Map<String, dynamic>) return null;
    return _num(first['centerStoneWeight']) ?? _num(first['weightCt']);
  }

  static String _formatCt(double ct) {
    final fixed = ct == ct.roundToDouble()
        ? ct.toStringAsFixed(0)
        : ct
            .toStringAsFixed(2)
            .replaceFirst(RegExp(r'0+$'), '')
            .replaceFirst(RegExp(r'\.$'), '');
    return '${fixed}ct';
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
