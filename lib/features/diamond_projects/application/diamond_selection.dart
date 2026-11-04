import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/auth/auth_providers.dart';
import '../../comparison/application/comparison_provider.dart';
import '../../comparison/domain/models/compare_category.dart';
import '../../comparison/domain/models/compare_item.dart';
import '../../diamonds/domain/models/diamond.dart';
import 'diamond_project_listing_pick_provider.dart';

/// Whether the signed-in user gets detailed analytics (diamond projects).
/// Selecting, comparing and the summary strip are for everyone.
final canAnalyzeDiamondsProvider = Provider<bool>(
  (ref) =>
      ref.watch(authProvider.select((s) => s.isSeller || s.sellerId != null)),
);

/// Compare snapshots of picked stones, so the comparison can mirror picks.
final _pickSnapshotsProvider = StateProvider<Map<String, CompareItem>>(
  (ref) => const {},
);

/// Full rows of picked stones, for the summary strip and the project. Rows
/// outlive an unpick (so an undo restores them) until the picks are cleared.
final _pickedRowsProvider = StateProvider<Map<String, Diamond>>(
  (ref) => const {},
);

/// Picked stones whose full row is known, in pick order.
final pickedDiamondsProvider = Provider<List<Diamond>>((ref) {
  final picks = ref.watch(diamondProjectListingPickProvider);
  final rows = ref.watch(_pickedRowsProvider);
  return [for (final id in picks) ?rows[id]];
});

enum DiamondSelectionOutcome {
  added,
  removed,
  addedOverLimit,
  switchedCategory,
}

/// One selection, two uses: every pick feeds the summary strip (and, for
/// sellers, the diamond project), and while at most
/// [ComparisonState.maxItems] stones are picked the comparison mirrors them. Above that the comparison steps aside (empty) until the
/// picks drop back within the limit.
abstract final class DiamondSelection {
  static DiamondSelectionOutcome toggle(WidgetRef ref, Diamond d) {
    _adoptCompared(ref);
    final picks = ref.read(diamondProjectListingPickProvider.notifier);
    final snaps = ref.read(_pickSnapshotsProvider.notifier);
    final rows = ref.read(_pickedRowsProvider.notifier);
    final had = ref.read(diamondProjectListingPickProvider).contains(d.id);
    if (had) {
      picks.remove(d.id);
      snaps.state = Map.of(snaps.state)..remove(d.id);
    } else {
      picks.addAll([d.id]);
      snaps.state = {...snaps.state, d.id: CompareItem.fromDiamond(d)};
      rows.state = {...rows.state, d.id: d};
    }
    final switched = _sync(ref);
    if (had) return DiamondSelectionOutcome.removed;
    if (switched) return DiamondSelectionOutcome.switchedCategory;
    return ref.read(diamondProjectListingPickProvider).length >
            ComparisonState.maxItems
        ? DiamondSelectionOutcome.addedOverLimit
        : DiamondSelectionOutcome.added;
  }

  /// Picks every stone in [all] (the whole matching inventory, not just
  /// the loaded page). Above four picks the comparison steps aside.
  static void selectAll(WidgetRef ref, List<Diamond> all) {
    _adoptCompared(ref);
    final fresh = [
      for (final d in all)
        if (d.id.isNotEmpty) d,
    ];
    if (fresh.isEmpty) return;
    ref
        .read(diamondProjectListingPickProvider.notifier)
        .addAll(fresh.map((d) => d.id));
    final snaps = ref.read(_pickSnapshotsProvider.notifier);
    final rows = ref.read(_pickedRowsProvider.notifier);
    snaps.state = {
      ...snaps.state,
      for (final d in fresh)
        if (!snaps.state.containsKey(d.id)) d.id: CompareItem.fromDiamond(d),
    };
    rows.state = {...rows.state, for (final d in fresh) d.id: d};
    _sync(ref);
  }

  /// Removes [id] from the comparison and from the picks. Returns whether
  /// it was picked, for [restore].
  static bool remove(WidgetRef ref, String id) {
    ref.read(comparisonProvider.notifier).remove(id);
    final picked = ref.read(diamondProjectListingPickProvider).contains(id);
    if (picked) {
      ref.read(diamondProjectListingPickProvider.notifier).remove(id);
      final snaps = ref.read(_pickSnapshotsProvider.notifier);
      snaps.state = Map.of(snaps.state)..remove(id);
    }
    return picked;
  }

  /// Undoes [remove].
  static void restore(
    WidgetRef ref,
    CompareItem item,
    int index, {
    required bool repick,
  }) {
    ref.read(comparisonProvider.notifier).restore(item, index);
    if (!repick) return;
    ref.read(diamondProjectListingPickProvider.notifier).addAll([item.id]);
    final snaps = ref.read(_pickSnapshotsProvider.notifier);
    snaps.state = {...snaps.state, item.id: item};
  }

  /// Empties the comparison, and the picks when they back it.
  static void clearComparison(WidgetRef ref) {
    final category = ref.read(comparisonProvider).category;
    final ownsPicks = category == null || category == CompareCategory.diamond;
    ref.read(comparisonProvider.notifier).clear();
    if (ownsPicks) _clearPicks(ref);
  }

  /// Empties the picks, and the comparison when it mirrors them.
  static void clearPicks(WidgetRef ref) {
    if (ref.read(comparisonProvider).category == CompareCategory.diamond) {
      ref.read(comparisonProvider.notifier).clear();
    }
    _clearPicks(ref);
  }

  static void _clearPicks(WidgetRef ref) {
    ref.read(diamondProjectListingPickProvider.notifier).clear();
    ref.read(_pickSnapshotsProvider.notifier).state = const {};
    ref.read(_pickedRowsProvider.notifier).state = const {};
  }

  /// Diamonds compared from elsewhere (detail page, recently viewed) join
  /// the picks, so the two never disagree.
  static void _adoptCompared(WidgetRef ref) {
    final compare = ref.read(comparisonProvider);
    if (compare.category != CompareCategory.diamond) return;
    final picks = ref.read(diamondProjectListingPickProvider);
    final missing = [
      for (final e in compare.items)
        if (!picks.contains(e.id)) e,
    ];
    if (missing.isEmpty) return;
    ref
        .read(diamondProjectListingPickProvider.notifier)
        .addAll(missing.map((e) => e.id));
    final snaps = ref.read(_pickSnapshotsProvider.notifier);
    snaps.state = {...snaps.state, for (final e in missing) e.id: e};
  }

  /// Mirrors the picks into the comparison. Returns true when that replaced
  /// a comparison of another category.
  static bool _sync(WidgetRef ref) {
    final picks = ref.read(diamondProjectListingPickProvider);
    final snaps = ref.read(_pickSnapshotsProvider);
    final compare = ref.read(comparisonProvider);
    final notifier = ref.read(comparisonProvider.notifier);
    final foreign =
        compare.isNotEmpty && compare.category != CompareCategory.diamond;
    if (picks.isEmpty || picks.length > ComparisonState.maxItems) {
      if (!foreign && compare.isNotEmpty) notifier.replaceAll(const []);
      return false;
    }
    // Keep the order the comparison already shows, then the new picks.
    final ordered = <String>[
      if (!foreign)
        for (final e in compare.items)
          if (picks.contains(e.id)) e.id,
    ];
    for (final id in picks) {
      if (!ordered.contains(id)) ordered.add(id);
    }
    notifier.replaceAll([for (final id in ordered) ?snaps[id]]);
    return foreign;
  }
}
