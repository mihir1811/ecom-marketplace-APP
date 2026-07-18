import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/diamond_list_provider.dart';
import '../../domain/models/sorting_criteria.dart';
import 'diamond_sorting_bottom_sheet.dart';

/// Sort bar with a single button that opens the multi-criteria sorting bottom sheet.
class DiamondSortBar extends ConsumerWidget {
  const DiamondSortBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sorting = ref.watch(diamondSortingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s4,
      ),
      child: GestureDetector(
        onTap: () => DiamondSortingBottomSheet.show(context),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12,
            vertical: AppSpacing.s8,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.slateSurface : AppColors.warmWhite,
            borderRadius: BorderRadius.circular(AppSpacing.r8),
            border: Border.all(
              color: isDark ? AppColors.slateBorder : AppColors.warmBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sort, size: 16, color: mutedColor),
              const SizedBox(width: AppSpacing.s8),
              Text(
                _sortLabel(sorting),
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: sorting.isEmpty ? mutedColor : AppColors.bronze,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: AppSpacing.s4),
              Icon(
                Icons.arrow_drop_down,
                size: 16,
                color: sorting.isEmpty ? mutedColor : AppColors.bronze,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _sortLabel(List<SortingCriteria> sorting) {
    if (sorting.isEmpty) return 'Sort';
    if (sorting.length == 1) {
      return sorting.first.displayName;
    }
    return '${sorting.first.displayName} +${sorting.length - 1}';
  }
}
