import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/brand_watch_state.dart';

Set<String> _toggle(Set<String> current, String value) {
  final next = Set<String>.from(current);
  if (!next.add(value)) next.remove(value);
  return next;
}

/// Manages filter state for the brand-specific watch screen.
class BrandWatchFilterNotifier extends Notifier<BrandWatchFilterState> {
  @override
  BrandWatchFilterState build() => const BrandWatchFilterState();

  void toggleStyle(String style) {
    state = state.copyWith(
      selectedStyles: _toggle(state.selectedStyles, style),
    );
  }

  void setPriceMin(String value) {
    state = state.copyWith(priceMin: value);
  }

  void setPriceMax(String value) {
    state = state.copyWith(priceMax: value);
  }

  void setSort(BrandWatchSortOption sort) {
    state = state.copyWith(sort: sort);
  }

  void reset() {
    state = const BrandWatchFilterState();
  }
}

final brandWatchFilterProvider =
    NotifierProvider<BrandWatchFilterNotifier, BrandWatchFilterState>(
  BrandWatchFilterNotifier.new,
);
