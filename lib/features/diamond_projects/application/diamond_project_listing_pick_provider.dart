import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/riverpod/dispose_tolerant.dart';

/// Seller multi-select on the diamond listing before opening a project.
///
/// Empty set = "Select page" uses every loaded stone (legacy behavior).
/// Non-empty = only these IDs are pushed into [diamondProjectSelectionProvider].
///
/// Picks persist across navigation and list reloads so sellers can accumulate
/// stones, leave for analysis, and return without losing the selection.
class DiamondProjectListingPickNotifier extends Notifier<Set<String>>
    with DisposeTolerantNotifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void toggle(String diamondId) {
    if (diamondId.isEmpty) return;
    final next = Set<String>.from(state);
    if (!next.add(diamondId)) {
      next.remove(diamondId);
    }
    state = Set<String>.unmodifiable(next);
  }

  void addAll(Iterable<String> ids) {
    final next = Set<String>.from(state)
      ..addAll(ids.where((e) => e.isNotEmpty));
    if (next.length == state.length) return;
    state = Set<String>.unmodifiable(next);
  }

  void remove(String diamondId) {
    if (!state.contains(diamondId)) return;
    state = Set<String>.unmodifiable(
      Set<String>.from(state)..remove(diamondId),
    );
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
