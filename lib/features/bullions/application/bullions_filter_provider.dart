import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/bullions_filter_state.dart';

Set<String> _toggle(Set<String> current, String value) {
  final next = Set<String>.from(current);
  if (!next.add(value)) next.remove(value);
  return next;
}

class BullionsFilterNotifier extends Notifier<BullionsFilterState> {
  @override
  BullionsFilterState build() => const BullionsFilterState();

  void setMetalFilter(BullionsMetalFilter filter) {
    final available =
        BullionsFilterState.metalVariants[filter] ?? const <String>[];
    // Keep only the purities the new metal offers.
    state = state.copyWith(
      metalFilter: filter,
      selectedVariants: state.selectedVariants
          .where(available.contains)
          .toSet(),
    );
  }

  /// Purity chips are multi-select.
  void toggleVariant(String variant) {
    state = state.copyWith(
      selectedVariants: _toggle(state.selectedVariants, variant),
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void replaceWith(BullionsFilterState next) {
    state = next;
  }

  void reset() {
    state = const BullionsFilterState();
  }
}

final bullionsFilterProvider =
    NotifierProvider<BullionsFilterNotifier, BullionsFilterState>(
      BullionsFilterNotifier.new,
    );

final bullionsViewModeProvider = StateProvider<BullionsViewMode>(
  (ref) => BullionsViewMode.grid,
);

final bullionsSortProvider = StateProvider<BullionsSortOption>(
  (ref) => BullionsSortOption.featured,
);

class BullionsFilterDraftNotifier extends Notifier<BullionsFilterState> {
  @override
  BullionsFilterState build() => ref.watch(bullionsFilterProvider);

  void syncFromApplied() {
    state = ref.read(bullionsFilterProvider);
  }

  void toggleShape(String value) =>
      state = state.copyWith(shapes: _toggle(state.shapes, value));

  void updateAvailability(String? value) {
    final next = (value == null || value.trim().isEmpty) ? 'All' : value.trim();
    state = state.copyWith(selectedAvailability: next);
  }

  void setMakeAnOffer(bool value) => state = state.copyWith(makeAnOffer: value);

  void toggleWeightChip(String value) =>
      state = state.copyWith(weightChips: _toggle(state.weightChips, value));

  void toggleCondition(String value) =>
      state = state.copyWith(conditions: _toggle(state.conditions, value));

  void toggleCertification(String value) => state = state.copyWith(
    certifications: _toggle(state.certifications, value),
  );

  void toggleMintMark(String value) =>
      state = state.copyWith(mintMarks: _toggle(state.mintMarks, value));

  void setPriceRange({double? min, double? max}) {
    state = state.copyWith(
      priceMin: min ?? state.priceMin,
      priceMax: max ?? state.priceMax,
    );
  }

  void setWeightRange({double? min, double? max}) {
    state = state.copyWith(
      weightMin: min ?? state.weightMin,
      weightMax: max ?? state.weightMax,
    );
  }

  void setQuantityRange({double? min, double? max}) {
    state = state.copyWith(
      quantityMin: min ?? state.quantityMin,
      quantityMax: max ?? state.quantityMax,
    );
  }

  void setLengthRange({double? min, double? max}) {
    state = state.copyWith(
      lengthMin: min ?? state.lengthMin,
      lengthMax: max ?? state.lengthMax,
    );
  }

  void setWidthRange({double? min, double? max}) {
    state = state.copyWith(
      widthMin: min ?? state.widthMin,
      widthMax: max ?? state.widthMax,
    );
  }

  void setHeightRange({double? min, double? max}) {
    state = state.copyWith(
      heightMin: min ?? state.heightMin,
      heightMax: max ?? state.heightMax,
    );
  }

  /// Restores a previous draft (e.g. undo after reset).
  void replaceDraft(BullionsFilterState next) => state = next;

  void reset() {
    state = BullionsFilterState(
      metalFilter: state.metalFilter,
      selectedVariants: state.selectedVariants,
      searchQuery: state.searchQuery,
    );
  }

  void apply() {
    ref.read(bullionsFilterProvider.notifier).replaceWith(state);
  }
}

final bullionsFilterDraftProvider =
    NotifierProvider<BullionsFilterDraftNotifier, BullionsFilterState>(
      BullionsFilterDraftNotifier.new,
    );
