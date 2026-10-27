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

  /// Opens a collection in one update (one reload): [category] (null shows
  /// every category), an optional [style] sub-category and [metal] enum.
  void openCollection({
    String? category,
    String? style,
    String? metal,
    String? shop,
  }) {
    final c = category?.trim();
    final s = style?.trim();
    final m = metal?.trim();
    state = state.copyWith(
      category: c,
      clearCategory: c == null || c.isEmpty,
      subCategory: s,
      clearSubCategory: s == null || s.isEmpty,
      shop: shop,
      clearShop: shop == null || shop.isEmpty,
      metals: m == null || m.isEmpty ? const {} : {m},
    );
  }

  /// Collection chip on the results header: keeps the other filters.
  void selectCategory(String slug) {
    state = state.copyWith(category: slug, clearSubCategory: true);
  }

  /// Style chip on the results header; tapping the selected one clears it.
  void selectSubCategory(String? slug) {
    state = slug == null || slug == state.subCategory
        ? state.copyWith(clearSubCategory: true)
        : state.copyWith(subCategory: slug);
  }

  /// Quick metal-tone toggle from the results header.
  void toggleMetal(String metal) {
    state = state.copyWith(metals: _toggle(state.metals, metal));
  }

  void clearShop() => state = state.copyWith(clearShop: true);

  void replaceWith(JewelryFilterState next) {
    state = next;
  }

  /// Clears filter-screen choices; search, collection and shop stay.
  void reset() {
    state = JewelryFilterState(
      searchQuery: state.searchQuery,
      category: state.category,
      subCategory: state.subCategory,
      shop: state.shop,
    );
  }
}

final jewelryFilterProvider =
    NotifierProvider<JewelryFilterNotifier, JewelryFilterState>(
      JewelryFilterNotifier.new,
    );

/// Null lets the API choose (relevance with a search, else newest).
final jewelrySortProvider = StateProvider<JewelrySortOption?>((ref) => null);

final jewelryViewModeProvider = StateProvider<JewelryViewMode>(
  (ref) => JewelryViewMode.grid,
);

class JewelryFilterDraftNotifier extends Notifier<JewelryFilterState> {
  @override
  JewelryFilterState build() => ref.watch(jewelryFilterProvider);

  void syncFromApplied() {
    state = ref.read(jewelryFilterProvider);
  }

  void toggleMetal(String v) =>
      state = state.copyWith(metals: _toggle(state.metals, v));

  void toggleGemstone(String v) =>
      state = state.copyWith(gemstones: _toggle(state.gemstones, v));

  void toggleOrigin(String v) =>
      state = state.copyWith(origins: _toggle(state.origins, v));

  void toggleStyle(String v) =>
      state = state.copyWith(styles: _toggle(state.styles, v));

  void toggleOccasion(String v) =>
      state = state.copyWith(occasions: _toggle(state.occasions, v));

  void toggleShape(String v) =>
      state = state.copyWith(shapes: _toggle(state.shapes, v));

  /// [min] / [max] at the facet bounds clear that side.
  void setPriceRange(double? min, double? max) => state = JewelryFilterState(
    searchQuery: state.searchQuery,
    category: state.category,
    subCategory: state.subCategory,
    shop: state.shop,
    tag: state.tag,
    metals: state.metals,
    gemstones: state.gemstones,
    origins: state.origins,
    styles: state.styles,
    occasions: state.occasions,
    shapes: state.shapes,
    priceMin: min,
    priceMax: max,
    availability: state.availability,
  );

  void clearPriceRange() => state = state.copyWith(clearPrice: true);

  void setAvailability(String? v) => state = v == null
      ? state.copyWith(clearAvailability: true)
      : state.copyWith(availability: v);

  void clearTag() => state = state.copyWith(clearTag: true);

  /// Clears the filter-screen selections; search, collection, style chip
  /// and shop are kept.
  void reset() {
    state = JewelryFilterState(
      searchQuery: state.searchQuery,
      category: state.category,
      subCategory: state.subCategory,
      shop: state.shop,
    );
  }

  /// Restores an earlier draft (undo after reset).
  void replaceDraft(JewelryFilterState previous) => state = previous;

  void apply() {
    ref.read(jewelryFilterProvider.notifier).replaceWith(state);
  }
}

final jewelryFilterDraftProvider =
    NotifierProvider<JewelryFilterDraftNotifier, JewelryFilterState>(
      JewelryFilterDraftNotifier.new,
    );
