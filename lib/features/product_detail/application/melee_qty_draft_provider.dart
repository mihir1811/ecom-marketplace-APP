import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/melee_purchase_math.dart';
import '../domain/models/product_detail.dart';

/// Partial melee purchase selected on product detail (pieces and carat).
class MeleeQtyDraft {
  const MeleeQtyDraft({
    required this.inCarat,
    required this.pieces,
    required this.carat,
  });

  final bool inCarat;
  final int pieces;
  final double carat;

  /// Lot price scaled to the selected pcs or carat share.
  double proportionalPrice(double lotPrice, ProductMeleeQty qty) {
    return MeleePurchaseMath.proportionalLotPrice(
      lotPrice: lotPrice,
      inCarat: inCarat,
      selectedPcs: pieces,
      selectedCarat: carat,
      totalPcs: qty.totalPcs,
      totalCarat: qty.totalCarat,
    );
  }

  /// Cart `specifications` shape from CART_API (melee partial buy).
  Map<String, dynamic> toSpecifications({required double calculatedPrice}) => {
    'purchaseUnit': inCarat ? 'carat' : 'pcs',
    'selectedPcs': pieces,
    'selectedCarat': double.parse(carat.toStringAsFixed(4)),
    'calculatedPrice': double.parse(calculatedPrice.toStringAsFixed(2)),
  };
}

class MeleeQtyDraftNotifier extends FamilyNotifier<MeleeQtyDraft?, String> {
  @override
  MeleeQtyDraft? build(String productId) => null;

  void ensureSeeded(ProductMeleeQty qty) {
    if (state != null) return;
    final pcs = qty.totalPcs ?? 0;
    final ct =
        qty.totalCarat ?? (pcs > 0 ? pcs * qty.resolvedCaratPerPcs : 0.0);
    state = MeleeQtyDraft(
      inCarat: false,
      pieces: pcs > 0 ? pcs : 0,
      carat: ct > 0 ? ct : 0,
    );
  }

  void setUnit({required bool inCarat, required ProductMeleeQty qty}) {
    final current =
        state ?? const MeleeQtyDraft(inCarat: false, pieces: 1, carat: 0);
    state = MeleeQtyDraft(
      inCarat: inCarat,
      pieces: current.pieces,
      carat: current.carat,
    );
  }

  void setFromPieces(int pieces, ProductMeleeQty qty) {
    final maxPcs = qty.totalPcs;
    var pcs = pieces < 0 ? 0 : pieces;
    if (maxPcs != null && pcs > maxPcs) pcs = maxPcs;
    final cpp = qty.resolvedCaratPerPcs;
    final carat = cpp > 0 ? pcs * cpp : 0.0;
    final maxCt = qty.totalCarat;
    final clampedCt = maxCt != null && carat > maxCt ? maxCt : carat;
    state = MeleeQtyDraft(inCarat: false, pieces: pcs, carat: clampedCt);
  }

  void setFromCarat(double carat, ProductMeleeQty qty) {
    final maxCt = qty.totalCarat;
    var ct = carat < 0 ? 0.0 : carat;
    if (maxCt != null && ct > maxCt) ct = maxCt;
    final cpp = qty.resolvedCaratPerPcs;
    var pcs = cpp > 0 ? (ct / cpp).round() : 0;
    if (pcs < 0) pcs = 0;
    final maxPcs = qty.totalPcs;
    if (maxPcs != null && pcs > maxPcs) {
      pcs = maxPcs;
      ct = cpp > 0 ? pcs * cpp : ct;
    }
    state = MeleeQtyDraft(inCarat: true, pieces: pcs, carat: ct);
  }
}

final meleeQtyDraftProvider =
    NotifierProvider.family<MeleeQtyDraftNotifier, MeleeQtyDraft?, String>(
      MeleeQtyDraftNotifier.new,
    );
