import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/jewelry_filter_state.dart';

Set<String> _toggle(Set<String> current, String value) {
  final next = Set<String>.from(current);
  if (!next.add(value)) next.remove(value);
  return next;
}

class JewelryFilterNotifier extends Notifier<JewelryFilterState> {
  @override
  JewelryFilterState build() => const JewelryFilterState();

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setCategory(String category) {
    state = state.copyWith(
      category: category,
      clearSubCategories: true,
    );
  }

  void toggleSubCategory(String subCategory) {
    state = state.copyWith(
      subCategories: _toggle(state.subCategories, subCategory),
    );
  }

  void clearSubCategories() {
    state = state.copyWith(clearSubCategories: true);
  }

  void removeSummaryLabel(String label) {
    if (state.subCategories.contains(label)) {
      state = state.copyWith(
        subCategories: _toggle(state.subCategories, label),
      );
    } else if (state.metalPurities.contains(label)) {
      state = state.copyWith(metalPurities: _toggle(state.metalPurities, label));
    } else if (state.metalColors.contains(label)) {
      state = state.copyWith(metalColors: _toggle(state.metalColors, label));
    } else if (state.stoneShapes.contains(label)) {
      state = state.copyWith(stoneShapes: _toggle(state.stoneShapes, label));
    } else if (state.stoneColors.contains(label)) {
      state = state.copyWith(stoneColors: _toggle(state.stoneColors, label));
    } else if (state.stoneClarities.contains(label)) {
      state =
          state.copyWith(stoneClarities: _toggle(state.stoneClarities, label));
    } else if (state.ringSizes.contains(label)) {
      state = state.copyWith(ringSizes: _toggle(state.ringSizes, label));
    } else if (state.braceletSizes.contains(label)) {
      state =
          state.copyWith(braceletSizes: _toggle(state.braceletSizes, label));
    } else if (state.braceletLengths.contains(label)) {
      state =
          state.copyWith(braceletLengths: _toggle(state.braceletLengths, label));
    } else if (state.chainLengths.contains(label)) {
      state = state.copyWith(chainLengths: _toggle(state.chainLengths, label));
    } else if (state.necklaceLengths.contains(label)) {
      state = state.copyWith(
          necklaceLengths: _toggle(state.necklaceLengths, label));
    } else if (state.stoneSettings.contains(label)) {
      state =
          state.copyWith(stoneSettings: _toggle(state.stoneSettings, label));
    } else if (state.metalTypes.contains(label)) {
      state = state.copyWith(metalTypes: _toggle(state.metalTypes, label));
    } else if (state.stoneCategories.contains(label)) {
      state =
          state.copyWith(stoneCategories: _toggle(state.stoneCategories, label));
    } else if (state.occasions.contains(label)) {
      state = state.copyWith(occasions: _toggle(state.occasions, label));
    } else if (state.availability.contains(label)) {
      state = state.copyWith(availability: _toggle(state.availability, label));
    } else if (state.genders.contains(label)) {
      state = state.copyWith(genders: _toggle(state.genders, label));
    } else if (label == state.stoneType) {
      state = state.copyWith(clearStoneType: true);
    } else if (label.startsWith('₹')) {
      state = state.copyWith(
        priceMin: JewelryFilterState.priceMinLimit,
        priceMax: JewelryFilterState.priceMaxLimit,
      );
    }
  }

  void replaceWith(JewelryFilterState next) {
    state = next;
  }

  void reset() {
    state = JewelryFilterState(
      searchQuery: state.searchQuery,
      category: state.category,
    );
  }
}

final jewelryFilterProvider =
    NotifierProvider<JewelryFilterNotifier, JewelryFilterState>(
  JewelryFilterNotifier.new,
);

final jewelrySortProvider =
    StateProvider<JewelrySortOption>((ref) => JewelrySortOption.featured);

final jewelryViewModeProvider =
    StateProvider<JewelryViewMode>((ref) => JewelryViewMode.grid);

class JewelryFilterDraftNotifier extends Notifier<JewelryFilterState> {
  @override
  JewelryFilterState build() => ref.watch(jewelryFilterProvider);

  void syncFromApplied() {
    state = ref.read(jewelryFilterProvider);
  }

  void toggleAvailability(String v) =>
      state = state.copyWith(availability: _toggle(state.availability, v));

  void setWithMediaOnly(bool v) => state = state.copyWith(withMediaOnly: v);

  void toggleGender(String v) =>
      state = state.copyWith(genders: _toggle(state.genders, v));

  void setPriceRange(double min, double max) =>
      state = state.copyWith(priceMin: min, priceMax: max);

  void clearPriceRange() => state = state.copyWith(
        priceMin: JewelryFilterState.priceMinLimit,
        priceMax: JewelryFilterState.priceMaxLimit,
      );

  void toggleOccasion(String v) =>
      state = state.copyWith(occasions: _toggle(state.occasions, v));

  void toggleMetalType(String v) =>
      state = state.copyWith(metalTypes: _toggle(state.metalTypes, v));

  void toggleMetalColor(String v) =>
      state = state.copyWith(metalColors: _toggle(state.metalColors, v));

  void toggleMetalPurity(String v) =>
      state = state.copyWith(metalPurities: _toggle(state.metalPurities, v));

  void setMetalWeight(double min, double max) =>
      state = state.copyWith(metalWeightMin: min, metalWeightMax: max);

  void clearMetalWeight() => state = state.copyWith(
        metalWeightMin: JewelryFilterState.metalWeightMinLimit,
        metalWeightMax: JewelryFilterState.metalWeightMaxLimit,
      );

  void toggleMetalFinish(String v) =>
      state = state.copyWith(metalFinishes: _toggle(state.metalFinishes, v));

  void togglePlating(String v) =>
      state = state.copyWith(platings: _toggle(state.platings, v));

  void setStoneType(String v) => state = state.copyWith(stoneType: v);

  void toggleStoneCategory(String v) =>
      state = state.copyWith(stoneCategories: _toggle(state.stoneCategories, v));

  void toggleStoneShape(String v) =>
      state = state.copyWith(stoneShapes: _toggle(state.stoneShapes, v));

  void setStoneWeight(double min, double max) =>
      state = state.copyWith(stoneWeightMin: min, stoneWeightMax: max);

  void clearStoneWeight() => state = state.copyWith(
        stoneWeightMin: JewelryFilterState.stoneWeightMinLimit,
        stoneWeightMax: JewelryFilterState.stoneWeightMaxLimit,
      );

  void toggleStoneSetting(String v) =>
      state = state.copyWith(stoneSettings: _toggle(state.stoneSettings, v));

  void toggleStoneColor(String v) =>
      state = state.copyWith(stoneColors: _toggle(state.stoneColors, v));

  void toggleStoneClarity(String v) =>
      state = state.copyWith(stoneClarities: _toggle(state.stoneClarities, v));

  void toggleBraceletSize(String v) =>
      state = state.copyWith(braceletSizes: _toggle(state.braceletSizes, v));

  void toggleBraceletLength(String v) => state =
      state.copyWith(braceletLengths: _toggle(state.braceletLengths, v));

  void toggleChainLength(String v) =>
      state = state.copyWith(chainLengths: _toggle(state.chainLengths, v));

  void toggleNecklaceLength(String v) => state =
      state.copyWith(necklaceLengths: _toggle(state.necklaceLengths, v));

  void toggleRingSize(String v) =>
      state = state.copyWith(ringSizes: _toggle(state.ringSizes, v));

  void toggleCertification(String v) =>
      state = state.copyWith(certifications: _toggle(state.certifications, v));

  void toggleCondition(String v) =>
      state = state.copyWith(conditions: _toggle(state.conditions, v));

  void setDeliveryTime(String? v) => state = v == null
      ? state.copyWith(clearDeliveryTime: true)
      : state.copyWith(deliveryTime: v);

  void reset() {
    state = JewelryFilterState(
      searchQuery: state.searchQuery,
      category: state.category,
    );
  }

  void apply() {
    ref.read(jewelryFilterProvider.notifier).replaceWith(state);
  }
}

final jewelryFilterDraftProvider =
    NotifierProvider<JewelryFilterDraftNotifier, JewelryFilterState>(
  JewelryFilterDraftNotifier.new,
);
