import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../application/diamond_search_provider.dart';
import 'filter_advanced_range_input.dart';

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
        ],
      ),
    );
  }
}
