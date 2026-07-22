import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/comparison_provider.dart';
import '../../domain/models/compare_item.dart';
import 'compare_add_button.dart';

/// Handles add/remove for a [CompareItem] and surfaces snackbar feedback.
void handleCompareToggle(
  BuildContext context,
  WidgetRef ref,
  CompareItem item,
) {
  final result = ref.read(comparisonProvider.notifier).toggle(item);
  final message = switch (result) {
    CompareAddSuccess() => 'Added to comparison',
    CompareAddRemoved() => 'Removed from comparison',
    CompareAddAlreadySelected() => 'Already selected',
    CompareAddLimitReached() => 'You can compare up to 4 items',
    CompareAddCategoryMismatch(:final existing, :final attempted) =>
      'You can only compare ${existing.labelPlural} with ${existing.labelPlural}. '
          'Clear the tray to compare ${attempted.labelPlural}.',
  };
  if (result is! CompareAddSuccess && result is! CompareAddRemoved) {
    showCompareFeedback(context, message);
  } else if (result is CompareAddSuccess) {
    showCompareFeedback(context, message);
  }
}
