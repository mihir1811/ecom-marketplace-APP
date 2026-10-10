import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'view_mode_toggle.dart';

/// Shared two-row listing toolbar used across catalog result screens.
///
/// Row 1: sort control (left) and view mode toggle (right).
/// Row 2: result count (left) and optional edit-filters action (right).
class CatalogListingHeaderRow extends StatelessWidget {
  const CatalogListingHeaderRow({
    required this.sortLabel,
    required this.onSortTap,
    required this.isGrid,
    required this.onGrid,
    required this.onList,
    required this.countLabel,
    this.onEditFilters,
    super.key,
  });

  final String sortLabel;
  final VoidCallback onSortTap;
  final bool isGrid;
  final VoidCallback onGrid;
  final VoidCallback onList;
  final String countLabel;
  final VoidCallback? onEditFilters;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.textMuted(context);
    final primary = AppColors.textPrimary(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16,
            AppSpacing.s8,
            AppSpacing.s16,
            AppSpacing.s4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: TextButton.icon(
                  onPressed: onSortTap,
                  icon: const Icon(Icons.sort, size: 18),
                  label: Text(
                    context.tr(CatalogL10n.sortByLabel, {'label': sortLabel}),
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: primary,
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
              ViewModeToggle(isGrid: isGrid, onGrid: onGrid, onList: onList),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16,
            0,
            AppSpacing.s16,
            AppSpacing.s8,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  countLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(color: muted),
                ),
              ),
              if (onEditFilters != null)
                TextButton(
                  onPressed: onEditFilters,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.only(left: AppSpacing.s8),
                  ),
                  child: Text(context.tr(CatalogL10n.editFilters)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
