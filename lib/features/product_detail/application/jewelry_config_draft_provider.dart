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
  final double price;
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

  JewelryConfigDraft copyWith({
    String? purity,
    String? size,
    String? stoneWeightLabel,
    int? quantity,
    double? price,
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
}

final jewelryConfigDraftProvider = StateNotifierProvider.autoDispose
    .family<JewelryConfigDraftNotifier, JewelryConfigDraft?, String>(
  (ref, productId) => JewelryConfigDraftNotifier(),
);

class JewelryConfigDraftNotifier extends StateNotifier<JewelryConfigDraft?> {
  JewelryConfigDraftNotifier() : super(null);

  void ensureSeeded(ProductJewelryDetail detail) {
    if (state != null) return;
    state = JewelryConfigDraft(
      purity: detail.metalPurity.trim().isEmpty ? null : detail.metalPurity,
      size: detail.sizeLabel.trim().isEmpty ? null : detail.sizeLabel,
      stoneWeightLabel:
          detail.stoneWeightCt > 0 ? _formatCt(detail.stoneWeightCt) : null,
      quantity: 1,
      price: detail.price,
      sku: detail.styleNo,
      metalWeightG: detail.metalWeightG,
      totalWeightG: detail.totalWeightG,
      discountAmount: detail.discountAmount,
      discountPercent: detail.discountPercent,
      metalPrice: detail.metalPrice,
      stonePrice: detail.stonePrice,
      makingCharge: detail.makingCharge,
      metalType: detail.metalType,
      metalColor: detail.metalColor,
      metalFinish: detail.metalFinish,
      braceletSize: detail.braceletSize,
      ringSize: detail.ringSize,
      chainLength: detail.chainLength,
      stoneCount: detail.stoneCount,
      stoneWeightCt: detail.stoneWeightCt,
      stones: detail.stones,
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

  ProductJewelryVariant? _findVariant(
    List<ProductJewelryVariant> variants, {
    required String? purity,
    required String? size,
    required String? stoneWeightLabel,
  }) {
    if (variants.isEmpty) return null;
    ProductJewelryVariant? best;
    var bestScore = -1;
    for (final v in variants) {
      var score = 0;
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
      if (stoneWeightLabel != null &&
          stoneWeightLabel.isNotEmpty &&
          v.stoneWeightCt != null &&
          _formatCt(v.stoneWeightCt!) == stoneWeightLabel) {
        score += 3;
      }
      if (score > bestScore) {
        bestScore = score;
        best = v;
      }
    }
    return bestScore > 0 ? best : null;
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
