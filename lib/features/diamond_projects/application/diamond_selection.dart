import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../comparison/application/comparison_provider.dart';
import '../../comparison/domain/models/compare_category.dart';
import '../../comparison/domain/models/compare_item.dart';
import '../../diamonds/domain/models/diamond.dart';
import 'diamond_project_listing_pick_provider.dart';

/// Whether the signed-in user can pick stones for diamond projects.
final canPickDiamondsProvider = Provider<bool>(
  (ref) =>
      ref.watch(authProvider.select((s) => s.isSeller || s.sellerId != null)),
);

/// Compare snapshots of picked stones, so the comparison can mirror picks.
final _pickSnapshotsProvider = StateProvider<Map<String, CompareItem>>(
  (ref) => const {},
);

enum DiamondSelectionOutcome {
  added,
  removed,
  addedOverLimit,
  switchedCategory,
}

/// One selection, two uses: every pick feeds the diamond project, and while
/// at most [ComparisonState.maxItems] stones are picked the comparison
/// mirrors them. Above that the comparison steps aside (empty) until the
/// picks drop back within the limit.
abstract final class DiamondSelection {
  static DiamondSelectionOutcome toggle(WidgetRef ref, Diamond d) {
    _adoptCompared(ref);
    final picks = ref.read(diamondProjectListingPickProvider.notifier);
    final snaps = ref.read(_pickSnapshotsProvider.notifier);
    final had = ref.read(diamondProjectListingPickProvider).contains(d.id);
    if (had) {
      picks.remove(d.id);
      snaps.state = Map.of(snaps.state)..remove(d.id);
    } else {
      picks.addAll([d.id]);
      snaps.state = {...snaps.state, d.id: CompareItem.fromDiamond(d)};
    }
    final switched = _sync(ref);
    if (had) return DiamondSelectionOutcome.removed;
    if (switched) return DiamondSelectionOutcome.switchedCategory;
    return ref.read(diamondProjectListingPickProvider).length >
            ComparisonState.maxItems
        ? DiamondSelectionOutcome.addedOverLimit
        : DiamondSelectionOutcome.added;
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
