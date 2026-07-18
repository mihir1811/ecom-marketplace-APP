import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../diamonds/presentation/widgets/filter_range_slider.dart';
import '../../application/gemstone_search_provider.dart';
import '../../domain/models/gemstone_filter_state.dart';

/// Gemstone dimension filters: length, width, height, and L/W ratio,
/// each with min-max inputs only (no sliders, no clear buttons).
class GemstoneFilterCategoryMeasurements extends ConsumerWidget {
  const GemstoneFilterCategoryMeasurements({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gemstoneSearchProvider);
    final notifier = ref.read(gemstoneSearchProvider.notifier);

    return RepaintBoundary(
      child: Column(
        children: [
          FilterRangeSlider(
            title: 'Length',
            minLimit: GemstoneFilterState.dimensionMin,
            maxLimit: GemstoneFilterState.dimensionMax,
            currentMin: state.minLength,
            currentMax: state.maxLength,
            unitSuffix: 'mm',
            onChanged: (min, max) => notifier.updateLengthRange(min, max),
            onClear: () => notifier.updateLengthRange(
              GemstoneFilterState.dimensionMin,
              GemstoneFilterState.dimensionMax,
            ),
          ),
          const SizedBox(height: AppSpacing.s20),
          FilterRangeSlider(
            title: 'Width',
            minLimit: GemstoneFilterState.dimensionMin,
            maxLimit: GemstoneFilterState.dimensionMax,
            currentMin: state.minWidth,
            currentMax: state.maxWidth,
            unitSuffix: 'mm',
            onChanged: (min, max) => notifier.updateWidthRange(min, max),
            onClear: () => notifier.updateWidthRange(
              GemstoneFilterState.dimensionMin,
              GemstoneFilterState.dimensionMax,
            ),
          ),
          const SizedBox(height: AppSpacing.s20),
          FilterRangeSlider(
            title: 'Height',
            minLimit: GemstoneFilterState.dimensionMin,
            maxLimit: GemstoneFilterState.dimensionMax,
            currentMin: state.minHeight,
            currentMax: state.maxHeight,
            unitSuffix: 'mm',
            onChanged: (min, max) => notifier.updateHeightRange(min, max),
            onClear: () => notifier.updateHeightRange(
              GemstoneFilterState.dimensionMin,
              GemstoneFilterState.dimensionMax,
            ),
          ),
          const SizedBox(height: AppSpacing.s20),
          FilterRangeSlider(
            title: 'L/W Ratio',
            minLimit: GemstoneFilterState.ratioMin,
            maxLimit: GemstoneFilterState.ratioMax,
            currentMin: state.minRatio,
            currentMax: state.maxRatio,
            onChanged: (min, max) => notifier.updateRatioRange(min, max),
            onClear: () => notifier.updateRatioRange(
              GemstoneFilterState.ratioMin,
              GemstoneFilterState.ratioMax,
            ),
          ),
        ],
      ),
    );
  }
}
