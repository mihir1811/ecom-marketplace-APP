import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../application/diamond_search_provider.dart';
import '../../domain/models/diamond_filter_state.dart';
import 'filter_section_header.dart';
import 'filter_segmented_control.dart';
import 'filter_color_selector.dart';
import 'filter_clarity_cards.dart';
import 'filter_finish_presets.dart';
import 'filter_scrollable_chips.dart';
import 'filter_quick_range_chip.dart';
import 'filter_shape_grid_cell.dart';
import '../widgets/filter_range_slider.dart';
import 'diamond_shape_carousel.dart';

class FilterCategoryBasic extends ConsumerWidget {
  const FilterCategoryBasic({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(diamondSearchProvider);

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FilterSectionHeader(
            title: 'Natural Diamond',
            infoText: 'Filter diamonds by their origin (Natural Diamond vs Natural Melee).',
          ),
          const SizedBox(height: AppSpacing.s8),
          FilterSegmentedControl(
            options: LabNaturalType.values,
            selected: state.labNatural,
            onSelected: (value) => ref.read(diamondSearchProvider.notifier).updateOrigin(value),
          ),
          const SizedBox(height: AppSpacing.s20),

          const FilterSectionHeader(
            title: 'Select Shape',
            infoText: 'Select one or more diamond shape outlines to filter the results.',
          ),
          const SizedBox(height: AppSpacing.s8),
          SizedBox(
            height: 156,
            child: GridView.builder(
              scrollDirection: Axis.horizontal,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.62,
              ),
              itemCount: kAllShapes.length,
              itemBuilder: (context, index) {
                final name = kAllShapes[index]['name']!;
                final isSelected = state.shapes.contains(name);
                return FilterShapeGridCell(
                  name: name,
                  isSelected: isSelected,
                  onTap: () => ref.read(diamondSearchProvider.notifier).toggleShape(name),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.s24),

          FilterRangeSlider(
            title: 'Total Carat',
            minLimit: 0.16,
            maxLimit: 100.00,
            currentMin: state.minCarat,
            currentMax: state.maxCarat,
            unitSuffix: ' ct',
            onChanged: (min, max) => ref.read(diamondSearchProvider.notifier).updateCaratRange(min, max),
            onClear: () => ref.read(diamondSearchProvider.notifier).updateCaratRange(0.16, 100.00),
          ),
          const SizedBox(height: AppSpacing.s12),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: List.generate(
              DiamondFilterState.caratQuickRanges.length,
              (index) {
                final range = DiamondFilterState.caratQuickRanges[index];
                final label = '${range['min']} - ${range['max']}';
                return FilterQuickRangeChip(
                  label: label,
                  isSelected: state.selectedCaratQuickRanges.contains(index),
                  onTap: () => ref.read(diamondSearchProvider.notifier).toggleCaratQuickRange(index),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.s20),

          FilterRangeSlider(
            title: 'Price / Carat',
            minLimit: 0.0,
            maxLimit: 200000.0,
            currentMin: state.minPricePerCarat,
            currentMax: state.maxPricePerCarat,
            unitSuffix: '\$',
            isInteger: true,
            onChanged: (min, max) => ref.read(diamondSearchProvider.notifier).updatePricePerCaratRange(min, max),
            onClear: () => ref.read(diamondSearchProvider.notifier).updatePricePerCaratRange(0.0, 200000.0),
          ),
          const SizedBox(height: AppSpacing.s20),

          FilterRangeSlider(
            title: 'Total Price',
            minLimit: 0.0,
            maxLimit: 1000000.0,
            currentMin: state.minPrice,
            currentMax: state.maxPrice,
            unitSuffix: '\$',
            isInteger: true,
            onChanged: (min, max) => ref.read(diamondSearchProvider.notifier).updatePriceRange(min, max),
            onClear: () => ref.read(diamondSearchProvider.notifier).updatePriceRange(0.0, 1000000.0),
          ),
          const SizedBox(height: AppSpacing.s24),

          const ColorTabsSelector(),
          const SizedBox(height: AppSpacing.s24),

          const ClarityCardsSection(),
          const SizedBox(height: AppSpacing.s24),

          const FinishPresetsSection(),
          const SizedBox(height: AppSpacing.s20),

          FilterScrollableChips(
            title: 'Cut Grade',
            options: DiamondFilterState.cuts,
            selectedItems: state.selectedCuts,
            onToggle: (val) => ref.read(diamondSearchProvider.notifier).toggleCut(val),
            infoText: "Filter by the quality of the diamond's cut, affecting its brilliance.",
          ),
          const SizedBox(height: AppSpacing.s20),

          FilterScrollableChips(
            title: 'Polish',
            options: DiamondFilterState.polishingGrades,
            selectedItems: state.selectedPolish,
            onToggle: (val) => ref.read(diamondSearchProvider.notifier).togglePolish(val),
            infoText: "Filter by the smoothness of the diamond's facets.",
          ),
          const SizedBox(height: AppSpacing.s20),

          FilterScrollableChips(
            title: 'Symmetry',
            options: DiamondFilterState.symmetryGrades,
            selectedItems: state.selectedSymmetry,
            onToggle: (val) => ref.read(diamondSearchProvider.notifier).toggleSymmetry(val),
            infoText: "Filter by the exactness of the diamond's shape and alignment.",
          ),
          const SizedBox(height: AppSpacing.s20),

          FilterScrollableChips(
            title: 'Certification',
            options: DiamondFilterState.labs,
            selectedItems: state.selectedLabs,
            onToggle: (val) => ref.read(diamondSearchProvider.notifier).toggleLab(val),
            infoText: "Filter by the gemological laboratory that certified the diamond.",
          ),
        ],
      ),
    );
  }
}
