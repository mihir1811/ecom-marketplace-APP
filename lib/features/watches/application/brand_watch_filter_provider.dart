import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/watch_filter_state.dart';
import 'watch_filter_provider.dart';

/// Applied filters for a brand catalog page (brand is injected at list load).
final brandWatchFilterProvider =
    NotifierProvider<WatchFilterNotifier, WatchFilterState>(
  WatchFilterNotifier.new,
);

final brandWatchSortProvider =
    StateProvider<WatchSortOption>((ref) => WatchSortOption.priceHighToLow);

/// Draft filters for the brand full-screen filter sheet.
class BrandWatchFilterDraftNotifier extends WatchFilterStateMutator {
  @override
  WatchFilterState build() => ref.read(brandWatchFilterProvider);

  void syncFromApplied() {
    state = ref.read(brandWatchFilterProvider);
  }

  void reset() => resetDraftKeepingSearch();

  void apply() {
    // Brand is locked by the page route — never persist brand multi-select.
    final cleaned = state.copyWith(brands: const {});
    ref.read(brandWatchFilterProvider.notifier).replaceWith(cleaned);
  }
}

final brandWatchFilterDraftProvider =
    NotifierProvider<BrandWatchFilterDraftNotifier, WatchFilterState>(
  BrandWatchFilterDraftNotifier.new,
);

/// Sort choices shown on the brand watch screen.
const brandWatchSortOptions = <WatchSortOption>[
  WatchSortOption.priceHighToLow,
  WatchSortOption.priceLowToHigh,
  WatchSortOption.newest,
];
