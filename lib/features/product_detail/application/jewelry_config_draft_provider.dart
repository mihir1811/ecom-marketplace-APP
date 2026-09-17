import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/product_jewelry_detail.dart';

/// Selected purity / size / stone weight + quantity for a jewelry PDP.
class JewelryConfigDraft {
  const JewelryConfigDraft({
    required this.purity,
    required this.size,
    required this.stoneWeightLabel,
    required this.quantity,
    required this.price,
    this.variantId,
    this.sku,
    this.metalWeightG,
    this.totalWeightG,
    this.discountAmount,
    this.discountPercent,
    this.metalPrice,
    this.stonePrice,
    this.makingCharge,
    this.metalType,
    this.metalColor,
    this.metalFinish,
    this.braceletSize,
    this.ringSize,
    this.chainLength,
    this.stoneCount,
    this.stoneWeightCt,
    this.stones = const [],
  });

  final String? purity;
  final String? size;
  final String? stoneWeightLabel;
  final int quantity;

  /// Net unit price for the selected variant (same units as PDP).
  final double price;

  /// Selected jewellery variant id — must be sent to cart when present.
  final String? variantId;
  final String? sku;
  final double? metalWeightG;
  final double? totalWeightG;
  final double? discountAmount;
  final double? discountPercent;
  final double? metalPrice;
  final double? stonePrice;
  final double? makingCharge;
  final String? metalType;
  final String? metalColor;
  final String? metalFinish;
  final String? braceletSize;
  final String? ringSize;
  final String? chainLength;
  final int? stoneCount;
  final double? stoneWeightCt;
  final List<ProductJewelryStone> stones;

  /// Line total for the current quantity (what the buyer sees before add).
  double get lineTotal => price * quantity;

  JewelryConfigDraft copyWith({
    String? purity,
    String? size,
    String? stoneWeightLabel,
    int? quantity,
    double? price,
    String? variantId,
    String? sku,
    double? metalWeightG,
    double? totalWeightG,
    double? discountAmount,
    double? discountPercent,
    double? metalPrice,
    double? stonePrice,
    double? makingCharge,
    String? metalType,
    String? metalColor,
    String? metalFinish,
    String? braceletSize,
    String? ringSize,
    String? chainLength,
    int? stoneCount,
    double? stoneWeightCt,
    List<ProductJewelryStone>? stones,
    bool clearSize = false,
  }) {
    return JewelryConfigDraft(
      purity: purity ?? this.purity,
      size: clearSize ? null : (size ?? this.size),
      stoneWeightLabel: stoneWeightLabel ?? this.stoneWeightLabel,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      variantId: variantId ?? this.variantId,
      sku: sku ?? this.sku,
      metalWeightG: metalWeightG ?? this.metalWeightG,
      totalWeightG: totalWeightG ?? this.totalWeightG,
      discountAmount: discountAmount ?? this.discountAmount,
      discountPercent: discountPercent ?? this.discountPercent,
      metalPrice: metalPrice ?? this.metalPrice,
      stonePrice: stonePrice ?? this.stonePrice,
      makingCharge: makingCharge ?? this.makingCharge,
      metalType: metalType ?? this.metalType,
      metalColor: metalColor ?? this.metalColor,
      metalFinish: metalFinish ?? this.metalFinish,
      braceletSize: braceletSize ?? this.braceletSize,
      ringSize: ringSize ?? this.ringSize,
      chainLength: chainLength ?? this.chainLength,
      stoneCount: stoneCount ?? this.stoneCount,
      stoneWeightCt: stoneWeightCt ?? this.stoneWeightCt,
      stones: stones ?? this.stones,
    );
  }

  /// Specs payload for POST /cart — includes price so cart never falls back
  /// to the parent listing's first-variant price.
  Map<String, dynamic> toCartSpecifications() {
    return {
      if (purity != null && purity!.isNotEmpty) 'purity': purity,
      if (size != null && size!.isNotEmpty) 'size': size,
      if (stoneWeightLabel != null && stoneWeightLabel!.isNotEmpty)
        'stoneWeight': stoneWeightLabel,
      if (stoneWeightCt != null && stoneWeightCt! > 0)
        'stoneWeightCt': stoneWeightCt,
      if (sku != null && sku!.isNotEmpty) 'sku': sku,
      if (variantId != null && variantId!.isNotEmpty) 'variantId': variantId,
      'unitPrice': price,
      'calculatedPrice': lineTotal,
    };
  }
}

final jewelryConfigDraftProvider = StateNotifierProvider.autoDispose
    .family<JewelryConfigDraftNotifier, JewelryConfigDraft?, String>(
  (ref, productId) => JewelryConfigDraftNotifier(),
);

class JewelryConfigDraftNotifier extends StateNotifier<JewelryConfigDraft?> {
  JewelryConfigDraftNotifier() : super(null);

  void ensureSeeded(ProductJewelryDetail detail) {
    if (state != null) return;
    final seed = _findVariant(
          detail.variants,
          purity: detail.metalPurity.trim().isEmpty ? null : detail.metalPurity,
          size: detail.sizeLabel.trim().isEmpty ? null : detail.sizeLabel,
          stoneWeightLabel:
              detail.stoneWeightCt > 0 ? _formatCt(detail.stoneWeightCt) : null,
        ) ??
        (detail.variants.isNotEmpty ? detail.variants.first : null);

    state = JewelryConfigDraft(
      purity: detail.metalPurity.trim().isEmpty ? null : detail.metalPurity,
      size: detail.sizeLabel.trim().isEmpty ? null : detail.sizeLabel,
      stoneWeightLabel: seed?.stoneWeightCt != null && seed!.stoneWeightCt! > 0
          ? _formatCt(seed.stoneWeightCt!)
          : (detail.stoneWeightCt > 0 ? _formatCt(detail.stoneWeightCt) : null),
      quantity: 1,
      price: seed?.price ?? detail.price,
      variantId: seed?.id,
      sku: seed?.sku ?? detail.styleNo,
      metalWeightG: seed?.metalWeightG ?? detail.metalWeightG,
      totalWeightG: seed?.totalWeightG ?? detail.totalWeightG,
      discountAmount: seed?.discountAmount ?? detail.discountAmount,
      discountPercent: seed?.discountPercent ?? detail.discountPercent,
      metalPrice: seed?.metalPrice ?? detail.metalPrice,
      stonePrice: seed?.stonePrice ?? detail.stonePrice,
      makingCharge: seed?.makingCharge ?? detail.makingCharge,
      metalType: seed?.metalType ?? detail.metalType,
      metalColor: seed?.metalColor ?? detail.metalColor,
      metalFinish: seed?.metalFinish ?? detail.metalFinish,
      braceletSize: seed?.braceletSize ?? detail.braceletSize,
      ringSize: seed?.ringSize ?? detail.ringSize,
      chainLength: seed?.chainLength ?? detail.chainLength,
      stoneCount: seed?.stoneCount ?? detail.stoneCount,
      stoneWeightCt: seed?.stoneWeightCt ?? detail.stoneWeightCt,
      stones: (seed?.stones.isNotEmpty ?? false) ? seed!.stones : detail.stones,
    );
  }

  void selectPurity(String purity, ProductJewelryDetail detail) {
    _applySelection(detail, purity: purity);
  }

  void selectSize(String? size, ProductJewelryDetail detail) {
    _applySelection(detail, size: size, clearSize: size == null);
  }

  void selectStoneWeight(String label, ProductJewelryDetail detail) {
    _applySelection(detail, stoneWeightLabel: label);
  }

  void setQuantity(int quantity) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(quantity: quantity.clamp(1, 99));
  }

  void _applySelection(
    ProductJewelryDetail detail, {
    String? purity,
    String? size,
    String? stoneWeightLabel,
    bool clearSize = false,
  }) {
    final current = state;
    if (current == null) return;
    final nextPurity = purity ?? current.purity;
    final nextSize = clearSize ? null : (size ?? current.size);
    final nextStone = stoneWeightLabel ?? current.stoneWeightLabel;
    final match = _findVariant(
      detail.variants,
      purity: nextPurity,
      size: nextSize,
      stoneWeightLabel: nextStone,
    );
    if (match != null) {
      state = JewelryConfigDraft(
        purity: nextPurity,
        size: nextSize,
        stoneWeightLabel: nextStone,
        quantity: current.quantity,
        price: match.price,
        variantId: match.id,
        sku: match.sku ?? detail.styleNo,
        metalWeightG: match.metalWeightG ?? detail.metalWeightG,
        totalWeightG: match.totalWeightG ?? detail.totalWeightG,
        discountAmount: match.discountAmount,
        discountPercent: match.discountPercent,
        metalPrice: match.metalPrice,
        stonePrice: match.stonePrice,
        makingCharge: match.makingCharge,
        metalType: match.metalType ?? detail.metalType,
        metalColor: match.metalColor ?? detail.metalColor,
        metalFinish: match.metalFinish ?? detail.metalFinish,
        braceletSize: match.braceletSize ?? detail.braceletSize,
        ringSize: match.ringSize ?? detail.ringSize,
        chainLength: match.chainLength ?? detail.chainLength,
        stoneCount: match.stoneCount ?? detail.stoneCount,
        stoneWeightCt: match.stoneWeightCt ?? detail.stoneWeightCt,
        stones: match.stones.isNotEmpty ? match.stones : detail.stones,
      );
      return;
    }
    state = current.copyWith(
      purity: nextPurity,
      size: nextSize,
      stoneWeightLabel: nextStone,
      clearSize: clearSize,
    );
  }

  /// Picks the best variant. When a stone-weight label is set, only variants
  /// with that weight compete — avoids matching purity alone on the wrong ct.
  ProductJewelryVariant? _findVariant(
    List<ProductJewelryVariant> variants, {
    required String? purity,
    required String? size,
    required String? stoneWeightLabel,
  }) {
    if (variants.isEmpty) return null;

    final stoneFiltered = (stoneWeightLabel != null &&
            stoneWeightLabel.isNotEmpty)
        ? variants
            .where(
              (v) =>
                  v.stoneWeightCt != null &&
                  _formatCt(v.stoneWeightCt!) == stoneWeightLabel,
            )
            .toList(growable: false)
        : variants;
    final pool = stoneFiltered.isNotEmpty ? stoneFiltered : variants;

    ProductJewelryVariant? best;
    var bestScore = -1;
    for (final v in pool) {
      var score = 0;
      if (stoneWeightLabel != null &&
          stoneWeightLabel.isNotEmpty &&
          v.stoneWeightCt != null &&
          _formatCt(v.stoneWeightCt!) == stoneWeightLabel) {
        score += 8;
      }
      if (purity != null &&
          purity.isNotEmpty &&
          (v.metalPurity ?? '').trim() == purity.trim()) {
        score += 4;
      }
      if (size != null &&
          size.isNotEmpty &&
          (v.sizeLabel ?? '').trim() == size.trim()) {
        score += 2;
      }
      if (score > bestScore) {
        bestScore = score;
        best = v;
      }
    }
    // Prefer an exact stone-weight hit; otherwise accept purity/size match.
    if (stoneWeightLabel != null &&
        stoneWeightLabel.isNotEmpty &&
        stoneFiltered.isNotEmpty) {
      return best;
    }
    return bestScore > 0 ? best : pool.first;
  }
}

String _formatCt(double ct) {
  final fixed = ct == ct.roundToDouble()
      ? ct.toStringAsFixed(0)
      : ct
          .toStringAsFixed(2)
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '');
  return '${fixed}ct';
}
