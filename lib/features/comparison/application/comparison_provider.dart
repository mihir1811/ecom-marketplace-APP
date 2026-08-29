import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/compare_category.dart';
import '../domain/models/compare_item.dart';

/// Result of attempting to add an item to the comparison tray.
sealed class CompareAddResult {
  const CompareAddResult();
}

class CompareAddSuccess extends CompareAddResult {
  const CompareAddSuccess();
}

class CompareAddAlreadySelected extends CompareAddResult {
  const CompareAddAlreadySelected();
}

class CompareAddRemoved extends CompareAddResult {
  const CompareAddRemoved();
}

class CompareAddCategoryMismatch extends CompareAddResult {
  const CompareAddCategoryMismatch({
    required this.existing,
    required this.attempted,
  });

  final CompareCategory existing;
  final CompareCategory attempted;
}

class CompareAddLimitReached extends CompareAddResult {
  const CompareAddLimitReached();
}

/// Immutable comparison tray state (max 4 items, single category).
class ComparisonState {
  const ComparisonState({this.items = const [], this.category});

  static const int maxItems = 4;

  final List<CompareItem> items;
  final CompareCategory? category;

  int get count => items.length;
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  bool get isFull => items.length >= maxItems;
  bool containsId(String id) => items.any((e) => e.id == id);

  ComparisonState copyWith({
    List<CompareItem>? items,
    CompareCategory? category,
    bool clearCategory = false,
  }) {
    return ComparisonState(
      items: items ?? this.items,
      category: clearCategory ? null : (category ?? this.category),
    );
  }
}

class ComparisonNotifier extends Notifier<ComparisonState> {
  @override
  ComparisonState build() => const ComparisonState();

  /// Toggles [item] in the tray. Returns a result describing the outcome.
  CompareAddResult toggle(CompareItem item) {
    if (state.containsId(item.id)) {
      remove(item.id);
      return const CompareAddRemoved();
    }
    return add(item);
  }

  CompareAddResult add(CompareItem item) {
    if (state.containsId(item.id)) {
      return const CompareAddAlreadySelected();
    }
    if (state.category != null && state.category != item.category) {
      return CompareAddCategoryMismatch(
        existing: state.category!,
        attempted: item.category,
      );
    }
    if (state.isFull) {
      return const CompareAddLimitReached();
    }
    state = ComparisonState(
      items: [...state.items, item],
      category: item.category,
    );
    return const CompareAddSuccess();
  }

  void remove(String id) {
    final next = state.items.where((e) => e.id != id).toList();
    state = ComparisonState(
      items: next,
      category: next.isEmpty ? null : state.category,
    );
  }

  void clear() {
    state = const ComparisonState();
  }

  /// Moves the item at [oldIndex] to [newIndex] (column reorder on compare screen).
  void reorder(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    final items = state.items;
    if (oldIndex < 0 ||
        newIndex < 0 ||
        oldIndex >= items.length ||
        newIndex >= items.length) {
      return;
    }
    final next = [...items];
    final moved = next.removeAt(oldIndex);
    next.insert(newIndex, moved);
    state = ComparisonState(items: next, category: state.category);
  }
}

final comparisonProvider =
    NotifierProvider<ComparisonNotifier, ComparisonState>(
      ComparisonNotifier.new,
    );

/// Whether a specific product id is currently in the comparison tray.
final isInComparisonProvider = Provider.family<bool, String>((ref, id) {
  return ref.watch(comparisonProvider.select((s) => s.containsId(id)));
});
