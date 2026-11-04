import 'package:flutter_riverpod/legacy.dart';

import '../domain/models/product_jewelry_detail.dart';

/// The buyer's choices on a jewelry product page: one option per variation,
/// quantity and the text they typed (engraving and custom text options).
class JewelryConfigDraft {
  const JewelryConfigDraft({
    required this.selected,
    required this.quantity,
    this.customValues = const {},
  });

  /// Variation name → chosen option.
  final Map<String, String> selected;
  final int quantity;

  /// `Personalisation` for the engraving box, else the custom option name.
  final Map<String, String> customValues;

  /// Key for the engraving box in `customValues`.
  static const personalisationKey = 'Personalisation';

  /// Text values worth sending (blank ones are dropped by the API anyway).
  Map<String, String> get filledCustomValues => {
    for (final e in customValues.entries)
      if (e.value.trim().isNotEmpty) e.key: e.value.trim(),
  };

  JewelryConfigDraft copyWith({
    Map<String, String>? selected,
    int? quantity,
    Map<String, String>? customValues,
  }) => JewelryConfigDraft(
    selected: selected ?? this.selected,
    quantity: quantity ?? this.quantity,
    customValues: customValues ?? this.customValues,
  );
}

/// Keyed by product detail id (the listing slug).
final jewelryConfigDraftProvider = StateNotifierProvider.autoDispose
    .family<JewelryConfigDraftNotifier, JewelryConfigDraft?, String>(
      (ref, productId) => JewelryConfigDraftNotifier(),
    );

class JewelryConfigDraftNotifier extends StateNotifier<JewelryConfigDraft?> {
  JewelryConfigDraftNotifier() : super(null);

  /// Starts from the cheapest purchasable SKU (the listed "from" price).
  /// Re-seeds when the full record arrives with options the card lacked.
  void ensureSeeded(ProductJewelryDetail detail) {
    final current = state;
    if (current != null &&
        detail.variations.every((v) => current.selected[v.name] != null)) {
      return;
    }
    final active = [...detail.activeSkus]
      ..sort((a, b) => a.price.compareTo(b.price));
    final seed = active.isEmpty ? null : active.first;
    state = JewelryConfigDraft(
      selected: {
        for (final v in detail.variations)
          if (current?.selected[v.name] ?? seed?.options[v.name]
              case final option?)
            v.name: option,
      },
      quantity: current?.quantity ?? 1,
      customValues: current?.customValues ?? const {},
    );
  }

  /// Picks [option]; when that breaks the combination, moves the other
  /// choices to the closest purchasable SKU that has it.
  void select(String variation, String option, ProductJewelryDetail detail) {
    final current = state;
    if (current == null) return;
    final next = {...current.selected, variation: option};
    if (detail.skuFor(next) == null) {
      final candidates = detail.activeSkus
          .where((s) => s.options[variation] == option)
          .toList();
      if (candidates.isNotEmpty) {
        int overlap(ProductJewelrySku s) => detail.variations
            .where((v) => s.options[v.name] == current.selected[v.name])
            .length;
        candidates.sort((a, b) => overlap(b).compareTo(overlap(a)));
        next
          ..clear()
          ..addAll(candidates.first.options);
      }
    }
    final maxQty = detail.maxQuantityFor(detail.skuFor(next));
    state = current.copyWith(
      selected: next,
      quantity: current.quantity.clamp(1, maxQty < 1 ? 1 : maxQty),
    );
  }

  void setQuantity(int quantity, {int max = 20}) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(quantity: quantity.clamp(1, max < 1 ? 1 : max));
  }

  void setCustomValue(String key, String value) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(
      customValues: {...current.customValues, key: value},
    );
  }
}
