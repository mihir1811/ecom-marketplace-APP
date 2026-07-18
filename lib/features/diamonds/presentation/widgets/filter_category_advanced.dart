import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/diamond_search_provider.dart';
import '../../domain/models/diamond_filter_state.dart';
import 'filter_advanced_range_input.dart';
import 'filter_scrollable_chips.dart';

class FilterCategoryAdvanced extends ConsumerStatefulWidget {
  const FilterCategoryAdvanced({
    this.expandAdvanced = false,
    super.key,
  });

  final bool expandAdvanced;

  @override
  ConsumerState<FilterCategoryAdvanced> createState() =>
      _FilterCategoryAdvancedState();
}

class _FilterCategoryAdvancedState extends ConsumerState<FilterCategoryAdvanced> {
  bool _isExpanded = false;

  @override
  void didUpdateWidget(covariant FilterCategoryAdvanced oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expandAdvanced && !oldWidget.expandAdvanced) {
      setState(() => _isExpanded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diamondSearchProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isExpanded)
            GestureDetector(
              onTap: () => setState(() => _isExpanded = true),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.charcoalDark : AppColors.creamBg,
                  borderRadius: BorderRadius.circular(AppSpacing.r8),
                  border: Border.all(
                    color: isDark ? AppColors.slateBorder : AppColors.warmBorder,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'View Advanced Filters',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.bronze,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.bronze,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),

          if (_isExpanded) ...[
            FilterAdvancedRangeInput(
              title: 'Table Percentage',
              currentMin: state.minTable,
              currentMax: state.maxTable,
              minLimit: 0.0,
              maxLimit: 100.0,
              unit: '%',
              infoText: 'Filter by table width percentage relative to total diameter.',
              onMinChanged: (v) => ref.read(diamondSearchProvider.notifier).updateTableRange(v, state.maxTable),
              onMaxChanged: (v) => ref.read(diamondSearchProvider.notifier).updateTableRange(state.minTable, v),
            ),
            const SizedBox(height: AppSpacing.s16),
            FilterAdvancedRangeInput(
              title: 'Depth Percentage',
              currentMin: state.minDepth,
              currentMax: state.maxDepth,
              minLimit: 0.0,
              maxLimit: 100.0,
              unit: '%',
              infoText: 'Filter by total depth percentage relative to total diameter.',
              onMinChanged: (v) => ref.read(diamondSearchProvider.notifier).updateDepthRange(v, state.maxDepth),
              onMaxChanged: (v) => ref.read(diamondSearchProvider.notifier).updateDepthRange(state.minDepth, v),
            ),
            const SizedBox(height: AppSpacing.s16),
            FilterAdvancedRangeInput(
              title: 'Crown Angle Range',
              currentMin: state.minCrownAngle,
              currentMax: state.maxCrownAngle,
              minLimit: 0.0,
              maxLimit: 100.0,
              unit: '°',
              infoText: 'Filter by average crown facet angle.',
              onMinChanged: (v) => ref.read(diamondSearchProvider.notifier).updateCrownAngleRange(v, state.maxCrownAngle),
              onMaxChanged: (v) => ref.read(diamondSearchProvider.notifier).updateCrownAngleRange(state.minCrownAngle, v),
            ),
            const SizedBox(height: AppSpacing.s16),
            FilterAdvancedRangeInput(
              title: 'Crown Height Range',
              currentMin: state.minCrownHeight,
              currentMax: state.maxCrownHeight,
              minLimit: 0.0,
              maxLimit: 100.0,
              unit: '%',
              infoText: 'Filter by crown height relative to total depth.',
              onMinChanged: (v) => ref.read(diamondSearchProvider.notifier).updateCrownHeightRange(v, state.maxCrownHeight),
              onMaxChanged: (v) => ref.read(diamondSearchProvider.notifier).updateCrownHeightRange(state.minCrownHeight, v),
            ),
            const SizedBox(height: AppSpacing.s16),
            FilterAdvancedRangeInput(
              title: 'Pavilion Angle Range',
              currentMin: state.minPavilionAngle,
              currentMax: state.maxPavilionAngle,
              minLimit: 0.0,
              maxLimit: 100.0,
              unit: '°',
              infoText: 'Filter by average pavilion facet angle.',
              onMinChanged: (v) => ref.read(diamondSearchProvider.notifier).updatePavilionAngleRange(v, state.maxPavilionAngle),
              onMaxChanged: (v) => ref.read(diamondSearchProvider.notifier).updatePavilionAngleRange(state.minPavilionAngle, v),
            ),
            const SizedBox(height: AppSpacing.s16),
            FilterAdvancedRangeInput(
              title: 'Pavilion Depth Range',
              currentMin: state.minPavilionDepth,
              currentMax: state.maxPavilionDepth,
              minLimit: 0.0,
              maxLimit: 100.0,
              unit: '%',
              infoText: 'Filter by pavilion depth relative to total depth.',
              onMinChanged: (v) => ref.read(diamondSearchProvider.notifier).updatePavilionDepthRange(v, state.maxPavilionDepth),
              onMaxChanged: (v) => ref.read(diamondSearchProvider.notifier).updatePavilionDepthRange(state.minPavilionDepth, v),
            ),
            const SizedBox(height: AppSpacing.s20),
            FilterScrollableChips(
              title: 'Girdle',
              options: DiamondFilterState.girdles,
              selectedItems: state.selectedGirdles,
              onToggle: (val) => ref.read(diamondSearchProvider.notifier).toggleGirdle(val),
              infoText: "Filter by thickness of the girdle rim.",
            ),
            const SizedBox(height: AppSpacing.s20),
            FilterScrollableChips(
              title: 'Culet Size',
              options: DiamondFilterState.culets,
              selectedItems: state.selectedCulets,
              onToggle: (val) => ref.read(diamondSearchProvider.notifier).toggleCulet(val),
              infoText: "Filter by size of the culet facet.",
            ),
            const SizedBox(height: AppSpacing.s16),
            GestureDetector(
              onTap: () => setState(() => _isExpanded = false),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.charcoalDark : AppColors.creamBg,
                  borderRadius: BorderRadius.circular(AppSpacing.r8),
                  border: Border.all(
                    color: isDark ? AppColors.slateBorder : AppColors.warmBorder,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Hide Advanced Filters',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.bronze,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.keyboard_arrow_up,
                      color: AppColors.bronze,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
