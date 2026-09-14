import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
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
    CompareAddSuccess() => context.tr(AccountCommerceL10n.addedComparison),
    CompareAddRemoved() => context.tr(AccountCommerceL10n.removedComparison),
    CompareAddAlreadySelected() => context.tr(
      AccountCommerceL10n.alreadySelected,
    ),
    CompareAddLimitReached() => context.tr(AccountCommerceL10n.compareLimit),
    CompareAddCategoryMismatch(:final existing, :final attempted) =>
      context.tr(AccountCommerceL10n.compareCategoryMismatch, {
        'existing': context.tr(existing.labelPluralKey),
        'attempted': context.tr(attempted.labelPluralKey),
      }),
  };
  switch (result) {
    case CompareAddSuccess() || CompareAddRemoved():
      AppHaptics.medium();
    default:
      AppHaptics.warning();
  }
  if (result is! CompareAddSuccess && result is! CompareAddRemoved) {
    showCompareFeedback(context, message);
  } else if (result is CompareAddSuccess) {
    showCompareFeedback(context, message);
  }
}
