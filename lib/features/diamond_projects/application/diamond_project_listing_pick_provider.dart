import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../diamonds/application/diamond_list_provider.dart';

/// Seller multi-select on the diamond listing before opening a project.
///
/// Empty set = "Select page" uses every loaded stone (legacy behavior).
/// Non-empty = only these IDs are pushed into [diamondProjectSelectionProvider].
class DiamondProjectListingPickNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    ref.listen(diamondListProvider, (previous, next) {
      final ids = next.valueOrNull?.diamonds.map((d) => d.id).toSet();
      if (ids == null) return;
      final pruned = state.where(ids.contains).toSet();
      if (pruned.length != state.length) {
        state = Set<String>.unmodifiable(pruned);
      }
    });
    return const {};
  }

  void toggle(String diamondId) {
    if (diamondId.isEmpty) return;
    final next = Set<String>.from(state);
    if (!next.add(diamondId)) {
      next.remove(diamondId);
    }
    state = Set<String>.unmodifiable(next);
  }

  void clear() {
    if (state.isEmpty) return;
    state = const {};
  }
}

final diamondProjectListingPickProvider =
    NotifierProvider<DiamondProjectListingPickNotifier, Set<String>>(
  DiamondProjectListingPickNotifier.new,
);

final isDiamondProjectPickedProvider = Provider.family<bool, String>((ref, id) {
  return ref.watch(
    diamondProjectListingPickProvider.select((s) => s.contains(id)),
  );
});
