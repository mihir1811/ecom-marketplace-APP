import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/watch_filter_state.dart';

Set<String> _toggle(Set<String> current, String value) {
  final next = Set<String>.from(current);
  if (!next.add(value)) next.remove(value);
  return next;
}

/// Shared mutators for applied/draft watch filter notifiers.
abstract class WatchFilterStateMutator extends Notifier<WatchFilterState> {
  void toggleBrand(String v) =>
      state = state.copyWith(brands: _toggle(state.brands, v));

  void toggleModel(String v) =>
      state = state.copyWith(models: _toggle(state.models, v));

  void toggleStyle(String v) =>
      state = state.copyWith(categories: _toggle(state.categories, v));

  void toggleMovement(String v) =>
      state = state.copyWith(movements: _toggle(state.movements, v));

  void toggleGender(String v) =>
      state = state.copyWith(genders: _toggle(state.genders, v));

  void toggleCondition(String v) =>
      state = state.copyWith(conditions: _toggle(state.conditions, v));

  void updateAvailability(String? value) {
    final next = (value == null || value.trim().isEmpty) ? 'All' : value.trim();
    state = state.copyWith(selectedAvailability: next);
  }

  void setMakeAnOffer(bool v) => state = state.copyWith(makeAnOffer: v);

  void toggleWithMedia(String v) =>
      state = state.copyWith(withMedia: _toggle(state.withMedia, v));

  void setPriceRange({double? min, double? max}) {
    state = state.copyWith(
      priceMin: min ?? state.priceMin,
      priceMax: max ?? state.priceMax,
    );
  }

  void toggleCaseMaterial(String v) =>
      state = state.copyWith(caseMaterials: _toggle(state.caseMaterials, v));

  void toggleDialColor(String v) =>
      state = state.copyWith(dialColors: _toggle(state.dialColors, v));

  void toggleCaseSizeRange(String v) =>
      state = state.copyWith(caseSizeRanges: _toggle(state.caseSizeRanges, v));

  void toggleCaseShape(String v) =>
      state = state.copyWith(caseShapes: _toggle(state.caseShapes, v));

  void toggleCaseBack(String v) =>
      state = state.copyWith(caseBacks: _toggle(state.caseBacks, v));

  void toggleStrapMaterial(String v) =>
      state = state.copyWith(strapMaterials: _toggle(state.strapMaterials, v));

  void toggleCrownType(String v) =>
      state = state.copyWith(crownTypes: _toggle(state.crownTypes, v));

  void toggleStrapColor(String v) =>
      state = state.copyWith(strapColors: _toggle(state.strapColors, v));

  void toggleClaspType(String v) =>
      state = state.copyWith(claspTypes: _toggle(state.claspTypes, v));

  void toggleClaspMaterial(String v) =>
      state = state.copyWith(claspMaterials: _toggle(state.claspMaterials, v));

  void toggleGlassMaterial(String v) =>
      state = state.copyWith(glassMaterials: _toggle(state.glassMaterials, v));

  void toggleLugWidth(String v) =>
      state = state.copyWith(lugWidths: _toggle(state.lugWidths, v));

  void togglePowerReserve(String v) =>
      state = state.copyWith(powerReserves: _toggle(state.powerReserves, v));

  void toggleWaterResistance(String v) => state =
      state.copyWith(waterResistances: _toggle(state.waterResistances, v));

  void toggleModelYear(String v) =>
      state = state.copyWith(modelYears: _toggle(state.modelYears, v));

  void toggleCertification(String v) =>
      state = state.copyWith(certifications: _toggle(state.certifications, v));

  void toggleBezelType(String v) =>
      state = state.copyWith(bezelTypes: _toggle(state.bezelTypes, v));

  void toggleBezelMaterial(String v) =>
      state = state.copyWith(bezelMaterials: _toggle(state.bezelMaterials, v));

  void toggleConfiguration(String v) =>
      state = state.copyWith(configurations: _toggle(state.configurations, v));

  void toggleMaterial(String v) =>
      state = state.copyWith(materials: _toggle(state.materials, v));

  void togglePreciousStoneType(String v) => state = state.copyWith(
        preciousStoneTypes: _toggle(state.preciousStoneTypes, v),
      );

  void toggleIndexes(String v) =>
      state = state.copyWith(indexes: _toggle(state.indexes, v));

  void setBoxIncluded(bool v) => state = state.copyWith(boxIncluded: v);

  void setPapersIncluded(bool v) => state = state.copyWith(papersIncluded: v);

  void setWarrantyCardIncluded(bool v) =>
      state = state.copyWith(warrantyCardIncluded: v);

  void setFullSetIncluded(bool v) =>
      state = state.copyWith(fullSetIncluded: v);

  /// Restores a previous draft (e.g. undo after reset).
  void replaceDraft(WatchFilterState next) => state = next;

  /// Clears all draft filter fields (keeps listing search query only).
  void resetDraftKeepingSearch() {
    state = WatchFilterState(searchQuery: state.searchQuery);
  }
}

class WatchFilterNotifier extends Notifier<WatchFilterState> {
  @override
  WatchFilterState build() => const WatchFilterState();

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void toggleBrand(String brand) {
    state = state.copyWith(brands: _toggle(state.brands, brand));
  }

  void clearBrands() {
    state = state.copyWith(brands: {});
  }

  void toggleCategory(String category) {
    state = state.copyWith(categories: _toggle(state.categories, category));
  }

  void replaceWith(WatchFilterState next) {
    state = next;
  }

  void reset() {
    state = const WatchFilterState();
  }
}

final watchFilterProvider =
    NotifierProvider<WatchFilterNotifier, WatchFilterState>(
  WatchFilterNotifier.new,
);

final watchSortProvider =
    StateProvider<WatchSortOption>((ref) => WatchSortOption.featured);

final watchViewModeProvider =
    StateProvider<WatchViewMode>((ref) => WatchViewMode.grid);

/// Draft filters edited on the full-screen filter sheet before "SHOW RESULTS".
class WatchFilterDraftNotifier extends WatchFilterStateMutator {
  @override
  WatchFilterState build() {
    // Seed once from applied filters. Do not `watch` applied state — that
    // would overwrite draft edits (including Reset) whenever applied notifies.
    // Opening the sheet always calls [syncFromApplied].
    return ref.read(watchFilterProvider);
  }

  void syncFromApplied() {
    state = ref.read(watchFilterProvider);
  }

  void reset() => resetDraftKeepingSearch();

  void apply() {
    ref.read(watchFilterProvider.notifier).replaceWith(state);
  }
}

final watchFilterDraftProvider =
    NotifierProvider<WatchFilterDraftNotifier, WatchFilterState>(
  WatchFilterDraftNotifier.new,
);
