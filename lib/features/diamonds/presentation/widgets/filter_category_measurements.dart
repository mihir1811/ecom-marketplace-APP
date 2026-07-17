import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../application/diamond_search_provider.dart';
import '../../domain/models/diamond_filter_state.dart';
import 'filter_advanced_range_input.dart';
import 'filter_scrollable_chips.dart';

class FilterCategoryMeasurements extends ConsumerWidget {
  const FilterCategoryMeasurements({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(diamondSearchProvider);

    return RepaintBoundary(
      child: Column(
        children: [
          FilterAdvancedRangeInput(
            title: 'Length Range',
            currentMin: state.minLength,
            currentMax: state.maxLength,
            minLimit: 0.0,
            maxLimit: 100.0,
            unit: 'mm',
            infoText: 'Filter by the physical length of the diamond in millimeters.',
            onMinChanged: (v) => ref.read(diamondSearchProvider.notifier).updateLengthRange(v, state.maxLength),
            onMaxChanged: (v) => ref.read(diamondSearchProvider.notifier).updateLengthRange(state.minLength, v),
          ),
          const SizedBox(height: AppSpacing.s16),
          FilterAdvancedRangeInput(
            title: 'Width Range',
            currentMin: state.minWidth,
            currentMax: state.maxWidth,
            minLimit: 0.0,
            maxLimit: 100.0,
            unit: 'mm',
            infoText: 'Filter by the physical width of the diamond in millimeters.',
            onMinChanged: (v) => ref.read(diamondSearchProvider.notifier).updateWidthRange(v, state.maxWidth),
            onMaxChanged: (v) => ref.read(diamondSearchProvider.notifier).updateWidthRange(state.minWidth, v),
          ),
          const SizedBox(height: AppSpacing.s16),
          FilterAdvancedRangeInput(
            title: 'Height Range',
            currentMin: state.minHeight,
            currentMax: state.maxHeight,
            minLimit: 0.0,
            maxLimit: 100.0,
            unit: 'mm',
            infoText: 'Filter by the physical height of the diamond in millimeters.',
            onMinChanged: (v) => ref.read(diamondSearchProvider.notifier).updateHeightRange(v, state.maxHeight),
            onMaxChanged: (v) => ref.read(diamondSearchProvider.notifier).updateHeightRange(state.minHeight, v),
          ),
          const SizedBox(height: AppSpacing.s16),
          FilterAdvancedRangeInput(
            title: 'Length to Width Ratio Range',
            currentMin: state.minRatio,
            currentMax: state.maxRatio,
            minLimit: 0.5,
            maxLimit: 5.0,
            infoText: 'Filter by the ratio of length divided by width.',
            onMinChanged: (v) => ref.read(diamondSearchProvider.notifier).updateRatioRange(v, state.maxRatio),
            onMaxChanged: (v) => ref.read(diamondSearchProvider.notifier).updateRatioRange(state.minRatio, v),
          ),
          const SizedBox(height: AppSpacing.s16),
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
        ],
      ),
    );
  }
}
