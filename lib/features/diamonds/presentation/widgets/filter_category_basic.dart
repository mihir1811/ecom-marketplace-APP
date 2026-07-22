import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/diamond_search_provider.dart';
import '../../domain/models/diamond_filter_state.dart';
import 'filter_chip.dart';
import 'filter_text_segmented_control.dart';
import 'filter_section_header.dart';
import 'filter_segmented_control.dart';
import 'filter_color_selector.dart';
import 'filter_clarity_cards.dart';
import 'filter_finish_presets.dart';
import 'filter_scrollable_chips.dart';
import 'filter_quick_range_chip.dart';
import 'filter_shape_grid_cell.dart';
import 'filter_boolean_checkbox.dart';
import 'filter_sieve_size.dart';
import 'filter_melee_range_filters.dart';
import 'diamond_shape_carousel.dart';
import '../widgets/filter_range_slider.dart';

class FilterCategoryBasic extends ConsumerStatefulWidget {
  const FilterCategoryBasic({
    super.key,
    this.sectionTitle = 'Natural Diamond',
    this.showOriginToggle = true,
    this.isLabCatalog = false,
  });

  /// Header above the origin control / catalog label.
  final String sectionTitle;

  /// When false (lab-grown screen), hides Natural / Melee segmented control.
  final bool showOriginToggle;

  /// Lab-grown catalog mode: shows Diamond Category (multi-select) and
  /// Growth Method sections; melee/sieve filters follow the Lab Melee
  /// category instead of the natural origin toggle.
  final bool isLabCatalog;

  @override
  ConsumerState<FilterCategoryBasic> createState() =>
      _FilterCategoryBasicState();
}

class _FilterCategoryBasicState extends ConsumerState<FilterCategoryBasic> {
  bool _isAdvancedFiltersExpanded = false;
  int _shapeDisplayRows = 2;

  static const int _shapeGridColumns = 4;

  Color _parseHex(String hex) {
    try {
      final cleaned = hex.replaceAll('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diamondSearchProvider);
    final notifier = ref.read(diamondSearchProvider.notifier);
    final borderColor = AppColors.warmBorder;

    final totalShapes = kAllShapes.length;
    final totalRows = (totalShapes / _shapeGridColumns).ceil();
    final shapesToShow = _shapeDisplayRows * _shapeGridColumns;
    final isAtMax = _shapeDisplayRows >= totalRows;

    // Lab catalog: the Lab Diamond / Lab Melee switch drives the layout;
    // natural catalog: the origin toggle does. Either way it's an
    // either/or between standard ranges and melee filters, and the sieve
    // table only appears for melee when the Round shape is selected.
    final useMeleeFilters = widget.isLabCatalog
        ? state.labCategory == 'Lab Melee'
        : state.labNatural.usesMeleeFilters;
    final showStandardRanges = !useMeleeFilters;
    final showSieve = useMeleeFilters && state.shapes.contains('Round');

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilterSectionHeader(title: widget.sectionTitle),
          if (widget.showOriginToggle) ...[
            const SizedBox(height: AppSpacing.s8),
            FilterSegmentedControl(
              options: LabNaturalType.values,
              selected: state.labNatural,
              onSelected: (value) => notifier.updateOrigin(value),
            ),
          ],
          const SizedBox(height: AppSpacing.s20),

          if (widget.isLabCatalog) ...[
            const FilterSectionHeader(title: 'Diamond Category'),
            const SizedBox(height: AppSpacing.s8),
            FilterTextSegmentedControl(
              options: DiamondFilterState.labCategories,
              selected: state.labCategory,
              onSelected: (value) => notifier.updateLabCategory(value),
            ),
            const SizedBox(height: AppSpacing.s20),

            const FilterSectionHeader(title: 'Growth Method (CVD / HPHT)'),
            const SizedBox(height: AppSpacing.s8),
            Row(
              children: DiamondFilterState.growthMethods.map((method) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChipWidget(
                      label: method,
                      isSelected:
                          state.selectedGrowthMethods.contains(method),
                      centerLabel: true,
                      onTap: () => notifier.toggleGrowthMethod(method),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.s20),
          ],

          const FilterSectionHeader(title: 'Select Shape'),
          const SizedBox(height: AppSpacing.s8),

          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: shapesToShow,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _shapeGridColumns,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.35,
              ),
              itemBuilder: (context, index) {
                if (index >= totalShapes) {
                  return const SizedBox.shrink();
                }
                final name = kAllShapes[index]['name']!;
                final isSelected = state.shapes.contains(name);
                return FilterShapeGridCell(
                  name: name,
                  isSelected: isSelected,
                  onTap: () => notifier.toggleShape(name),
                );
              },
            ),
          ),

          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  if (isAtMax) {
                    _shapeDisplayRows = 2;
                  } else {
                    _shapeDisplayRows = (_shapeDisplayRows + 2).clamp(
                      0,
                      totalRows,
                    );
                  }
                });
              },
              icon: Icon(
                isAtMax ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: AppColors.bronze,
                size: 18,
              ),
              label: Text(
                isAtMax ? 'Show Less Shapes' : 'Show More Shapes',
                style: AppTypography.caption.copyWith(
                  color: AppColors.bronze,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s16),

          if (useMeleeFilters) ...[
            FilterBooleanCheckbox(
              label: 'Separable',
              value: state.separable,
              onChanged: (_) => notifier.toggleSeparable(),
            ),
            const SizedBox(height: AppSpacing.s16),
          ],

          FilterBooleanCheckbox(
            label: 'Filter by Media',
            value: state.searchByMedia,
            onChanged: (_) => notifier.toggleSearchByMedia(),
          ),
          const SizedBox(height: AppSpacing.s16),

          if (showSieve) ...[
            const FilterSieveSize(),
            const SizedBox(height: AppSpacing.s24),
          ],

          if (useMeleeFilters) ...[
            const FilterMeleeRangeFilters(),
            const SizedBox(height: AppSpacing.s20),
          ],
          if (showStandardRanges) ...[
            FilterRangeSlider(
              title: 'Total Price',
              minLimit: 0.0,
              maxLimit: 1000000.0,
              currentMin: state.minPrice,
              currentMax: state.maxPrice,
              unitSuffix: '\$',
              isInteger: true,
              onChanged: (min, max) => notifier.updatePriceRange(min, max),
              onClear: () => notifier.updatePriceRange(0.0, 1000000.0),
            ),
            const SizedBox(height: AppSpacing.s20),

            FilterRangeSlider(
              title: 'Total Carat',
              minLimit: 0.16,
              maxLimit: 100.00,
              currentMin: state.minCarat,
              currentMax: state.maxCarat,
              unitSuffix: ' ct',
              onChanged: (min, max) => notifier.updateCaratRange(min, max),
              onClear: () => notifier.updateCaratRange(0.16, 100.00),
            ),
            const SizedBox(height: AppSpacing.s12),
            Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.start,
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
                    onTap: () => notifier.toggleCaratQuickRange(index),
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
              onChanged: (min, max) =>
                  notifier.updatePricePerCaratRange(min, max),
              onClear: () => notifier.updatePricePerCaratRange(0.0, 200000.0),
            ),
            const SizedBox(height: AppSpacing.s24),
          ],

          // === COLOR, CLARITY, FINISH (always visible) ===
          const ColorTabsSelector(),
          const SizedBox(height: AppSpacing.s24),

          const ClarityCardsSection(),
          const SizedBox(height: AppSpacing.s24),

          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _isAdvancedFiltersExpanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.s24),

                      const FinishPresetsSection(),
                      const SizedBox(height: AppSpacing.s20),

                      FilterScrollableChips(
                        title: 'Cut Grade',
                        options: DiamondFilterState.cuts,
                        selectedItems: state.selectedCuts,
                        onToggle: (val) => notifier.toggleCut(val),
                        infoText: "Filter by the quality of the diamond's cut.",
                      ),
                      const SizedBox(height: AppSpacing.s20),

                      FilterScrollableChips(
                        title: 'Polish',
                        options: DiamondFilterState.polishingGrades,
                        selectedItems: state.selectedPolish,
                        onToggle: (val) => notifier.togglePolish(val),
                        infoText:
                            "Filter by the smoothness of the diamond's facets.",
                      ),
                      const SizedBox(height: AppSpacing.s20),

                      FilterScrollableChips(
                        title: 'Symmetry',
                        options: DiamondFilterState.symmetryGrades,
                        selectedItems: state.selectedSymmetry,
                        onToggle: (val) => notifier.toggleSymmetry(val),
                        infoText:
                            "Filter by the exactness of the diamond's shape.",
                      ),
                      const SizedBox(height: AppSpacing.s20),

                      FilterScrollableChips(
                        title: 'Certification',
                        options: DiamondFilterState.labs,
                        selectedItems: state.selectedLabs,
                        onToggle: (val) => notifier.toggleLab(val),
                        infoText:
                            "Filter by the gemological laboratory that certified the diamond.",
                      ),
                      const SizedBox(height: AppSpacing.s20),

                      // === INCLUSIONS ===
                      FilterBooleanCheckbox(
                        label: 'No BGM (No Brown, Green, Milky tints)',
                        value: state.noBgm,
                        onChanged: (_) => notifier.toggleNoBgm(),
                      ),
                      FilterBooleanCheckbox(
                        label: 'Eye Clean (No inclusions visible to naked eye)',
                        value: state.eyeClean,
                        onChanged: (_) => notifier.toggleEyeClean(),
                      ),
                      FilterBooleanCheckbox(
                        label: 'Hearts & Arrows',
                        value: state.heartAndArrow,
                        onChanged: (_) => notifier.toggleHeartAndArrow(),
                      ),
                      const SizedBox(height: AppSpacing.s20),

                      // === TREATMENT: Milky ===
                      const FilterSectionHeader(title: 'Milky'),
                      const SizedBox(height: AppSpacing.s8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: DiamondFilterState.milkyGrades.map((grade) {
                            final isSelected = state.selectedMilkyGrades
                                .contains(grade);
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: GestureDetector(
                                onTap: () => notifier.toggleMilkyGrade(grade),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.charcoal
                                        : (AppColors.warmWhite),
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.r8,
                                    ),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.charcoal
                                          : borderColor,
                                    ),
                                  ),
                                  child: Text(
                                    grade,
                                    style: AppTypography.caption.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? AppColors.warmWhite
                                          : (AppColors.textPrimaryLight),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s20),

                      // === TREATMENT: Fluorescence Intensity ===
                      const FilterSectionHeader(
                        title: 'Fluorescence Intensity',
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: DiamondFilterState.fluorescenceGrades.map((
                            grade,
                          ) {
                            final isSelected = state.selectedFluorescence
                                .contains(grade);
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: GestureDetector(
                                onTap: () => notifier.toggleFluorescence(grade),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.charcoal
                                        : (AppColors.warmWhite),
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.r8,
                                    ),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.charcoal
                                          : borderColor,
                                    ),
                                  ),
                                  child: Text(
                                    grade,
                                    style: AppTypography.caption.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? AppColors.warmWhite
                                          : (AppColors.textPrimaryLight),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s20),

                      // === TREATMENT: Fluorescence Color ===
                      const FilterSectionHeader(title: 'Fluorescence Color'),
                      const SizedBox(height: AppSpacing.s8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(AppSpacing.r8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            hint: const Text('Select fluorescence color'),
                            value: state.selectedFluorescenceColor,
                            items: DiamondFilterState.fluorescenceColors.map((
                              colorName,
                            ) {
                              final hex = DiamondFilterState
                                  .fluorescenceColorsHex[colorName]!;
                              return DropdownMenuItem<String>(
                                value: colorName,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: _parseHex(hex),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.s12),
                                    Text(colorName),
                                    const Spacer(),
                                    Text(
                                      hex,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black45,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                notifier.updateFluorescenceColor(val),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s20),

                      // === TREATMENT: Enhancement ===
                      const FilterSectionHeader(title: 'Enhancement'),
                      const SizedBox(height: AppSpacing.s8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(AppSpacing.r8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            hint: const Text('Select enhancement'),
                            value: state.selectedEnhancement,
                            items: DiamondFilterState.enhancements.map((enh) {
                              return DropdownMenuItem<String>(
                                value: enh,
                                child: Text(enh),
                              );
                            }).toList(),
                            onChanged: (val) => notifier.updateEnhancement(val),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s24),
                    ],
                  )
                : const SizedBox(width: double.infinity, height: 0),
          ),

          const SizedBox(height: AppSpacing.s24),

          if (showStandardRanges) ...[
            GestureDetector(
              onTap: () {
                setState(() {
                  _isAdvancedFiltersExpanded = !_isAdvancedFiltersExpanded;
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.creamBg,
                  borderRadius: BorderRadius.circular(AppSpacing.r8),
                  border: Border.all(
                    color: AppColors.warmBorder,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'View more filters',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.bronze,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      _isAdvancedFiltersExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.bronze,
                      size: 18,
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
