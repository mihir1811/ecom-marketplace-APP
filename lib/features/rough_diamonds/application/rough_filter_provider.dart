import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/riverpod/dispose_tolerant.dart';
import '../domain/models/rough_filter_state.dart';
import '../domain/models/rough_parcel.dart';
import '../domain/models/rough_sort_option.dart';

enum RoughViewMode { grid, list }

/// Filters the results list is searched with.
class RoughFilterNotifier extends Notifier<RoughFilterState>
    with DisposeTolerantNotifier<RoughFilterState> {
  @override
  RoughFilterState build() => const RoughFilterState();

  void setType(RoughDiamondType type) => state = state.withType(type);

  void setSearch(String query) => state = state.copyWith(search: query.trim());

  void replaceWith(RoughFilterState next) => state = next;

  /// Clears filters; keeps the tab and search text.
  void clearFilters() => state = state.cleared();
}

final roughFilterProvider =
    NotifierProvider<RoughFilterNotifier, RoughFilterState>(
      RoughFilterNotifier.new,
    );

final roughSortProvider = StateProvider<RoughSortOption>(
  (ref) => RoughSortOption.newest,
);

final roughViewModeProvider = StateProvider<RoughViewMode>(
  (ref) => RoughViewMode.grid,
);

/// Filter screen edits, applied to [roughFilterProvider] on "Show results".
class RoughFilterDraftNotifier extends Notifier<RoughFilterState>
    with DisposeTolerantNotifier<RoughFilterState> {
  @override
  RoughFilterState build() => ref.watch(roughFilterProvider);

  void syncFromApplied() => state = ref.read(roughFilterProvider);

  void setType(RoughDiamondType type) => state = state.withType(type);

  void toggle(String key, String value) => state = state.toggle(key, value);

  void setFlag(String key, bool on) => state = state.setFlag(key, on);

  void setRange(RoughRange range, double min, double max) =>
      state = state.setRange(range, min, max);

  void setYieldMin(double value) =>
      state = state.copyWith(yieldMin: value.clamp(0, 100).toDouble());

  /// Restores an earlier draft (undo after reset).
  void replaceDraft(RoughFilterState next) => state = next;

  void reset() => state = state.cleared();

  void apply() => ref.read(roughFilterProvider.notifier).replaceWith(state);
}

final roughFilterDraftProvider =
    NotifierProvider<RoughFilterDraftNotifier, RoughFilterState>(
      RoughFilterDraftNotifier.new,
    );
