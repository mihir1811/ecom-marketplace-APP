import 'package:flutter/material.dart';

import '../haptics/app_haptics.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../l10n/app_localizations.dart';

/// Single-select sort bottom sheet used by watches / jewelry / brand watches.
Future<T?> showSimpleSortSheet<T>({
  required BuildContext context,
  required List<T> options,
  required String Function(T) labelOf,
  required T current,
  String? title,
  ShapeBorder? shape,
}) {
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    shape: shape,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Text(
                title ?? context.tr(RemainingL10n.sortBy),
                style: AppTypography.title.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (final option in options)
              ListTile(
                title: Text(labelOf(option)),
                trailing: current == option
                    ? const Icon(Icons.check, color: AppColors.bronze)
                    : null,
                onTap: () {
                  AppHaptics.selection();
                  Navigator.pop(context, option);
                },
              ),
            const SizedBox(height: AppSpacing.s12),
          ],
        ),
      );
    },
  );
}
