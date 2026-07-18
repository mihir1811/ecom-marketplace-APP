import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../diamonds/presentation/widgets/filter_boolean_checkbox.dart';
import '../../../diamonds/presentation/widgets/filter_chip.dart';
import '../../../diamonds/presentation/widgets/filter_melee_range_filters.dart';
import '../../../diamonds/presentation/widgets/filter_origin_dropdown.dart';
import '../../../diamonds/presentation/widgets/filter_quick_range_chip.dart';
import '../../../diamonds/presentation/widgets/filter_range_slider.dart';
import '../../../diamonds/presentation/widgets/filter_scrollable_chips.dart';
import '../../../diamonds/presentation/widgets/filter_section_header.dart';
import '../../../diamonds/presentation/widgets/filter_shape_grid_cell.dart';
import '../../application/gemstone_search_provider.dart';
import '../../domain/models/gemstone_filter_state.dart';
import 'birthstone_month_card.dart';
import 'gemstone_segmented_control.dart';

class GemstoneFilterCategoryBasic extends ConsumerStatefulWidget {
  const GemstoneFilterCategoryBasic({super.key});

  @override
  ConsumerState<GemstoneFilterCategoryBasic> createState() =>
      _GemstoneFilterCategoryBasicState();
}

class _GemstoneFilterCategoryBasicState
    extends ConsumerState<GemstoneFilterCategoryBasic> {
  bool _isTypesExpanded = false;
  int _typeDisplayRows = 2;
  String _typeSearchQuery = '';
  bool _isAdvancedExpanded = false;
  int _shapeDisplayRows = 2;
  int _treatmentDisplayCount = 8;

  static const int _shapeGridColumns = 4;
  static const int _typeColumns = 4;
  static const int _typeRowsPerStep = 2;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gemstoneSearchProvider);
    final notifier = ref.read(gemstoneSearchProvider.notifier);

    // --- Gemstone types with search filtering ---
    final allTypes = GemstoneFilterState.allGemstoneTypes;
    final filteredTypes = _typeSearchQuery.isEmpty
        ? allTypes
        : allTypes
              .where(
                (t) => t.toLowerCase().contains(_typeSearchQuery.toLowerCase()),
              )
              .toList();

    final visibleTypeCount = (_typeDisplayRows * _typeColumns).clamp(
      0,
      filteredTypes.length,
    );
    final visibleTypes = filteredTypes.take(visibleTypeCount).toList();
    final hiddenTypeCount = filteredTypes.length - visibleTypeCount;
    final isTypesAtMax = visibleTypeCount >= filteredTypes.length;

    // --- Shape pagination ---
    final shapeNames = GemstoneFilterState.shapes;
    final totalShapeRows = (shapeNames.length / _shapeGridColumns).ceil();
    final shapesToShow = (_shapeDisplayRows * _shapeGridColumns).clamp(
      0,
      shapeNames.length,
    );
    final isShapesAtMax = _shapeDisplayRows >= totalShapeRows;

    final isMelee = state.lotType == 'Melee';

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === STONE TYPE ===
          const FilterSectionHeader(title: 'Stone Type'),
          const SizedBox(height: AppSpacing.s8),
          GemstoneSegmentedControl(
            options: const [
              SegmentOption(
                value: 'Natural',
                label: 'Natural',
                icon: Icons.wb_sunny_outlined,
              ),
              SegmentOption(
                value: 'Lab Grown',
                label: 'Lab-Grown',
                icon: Icons.science_outlined,
              ),
            ],
            selected: state.stoneType,
            onSelected: (val) => notifier.updateStoneType(val),
          ),
          const SizedBox(height: AppSpacing.s20),

          // === LOT TYPE ===
          const FilterSectionHeader(title: 'Lot Type'),
          const SizedBox(height: AppSpacing.s8),
          GemstoneSegmentedControl(
            options: const [
              SegmentOption(
                value: 'Single',
                label: 'Single',
                icon: Icons.star_border,
              ),
              SegmentOption(value: 'Melee', label: 'Melee', icon: Icons.grain),
            ],
            selected: state.lotType,
            onSelected: (val) => notifier.updateLotType(val),
          ),
          const SizedBox(height: AppSpacing.s20),

          // === SEPARABLE ===
          FilterBooleanCheckbox(
            label: 'Separable',
            value: state.separable,
            onChanged: (_) => notifier.toggleSeparable(),
          ),
          const SizedBox(height: AppSpacing.s20),

          // === GEMSTONE TYPE ===
          const FilterSectionHeader(title: 'Gemstone Type'),
          const SizedBox(height: AppSpacing.s8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppSpacing.r8),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.slateBorder
                    : AppColors.warmBorder,
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s12,
              vertical: AppSpacing.s4,
            ),
            child: TextField(
              onChanged: (val) => setState(() => _typeSearchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search gemstone types...',
                hintStyle: AppTypography.caption.copyWith(
                  color: AppColors.textMutedLight,
                ),
                prefixIcon: const Icon(Icons.search, size: 18),
                prefixIconColor: AppColors.textMutedLight,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                suffixIcon: _typeSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () => setState(() => _typeSearchQuery = ''),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                ...visibleTypes.map((type) {
                  return FilterChipWidget(
                    label: type,
                    isSelected: state.selectedGemstoneTypes.contains(type),
                    onTap: () => notifier.toggleGemstoneType(type),
                  );
                }),
                if (hiddenTypeCount > 0)
                  FilterChipWidget(
                    label: 'Others ($hiddenTypeCount)',
                    isSelected: false,
                    onTap: () =>
                        setState(() => _isTypesExpanded = !_isTypesExpanded),
                    selectedColor: AppColors.sandSurface,
                    unselectedBgColor: AppColors.sandSurface,
                    unselectedTextColor: AppColors.bronze,
                    borderColor: AppColors.bronze,
                  ),
              ],
            ),
          ),
          if (filteredTypes.isNotEmpty)
            Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    if (isTypesAtMax) {
                      _typeDisplayRows = 2;
                      _isTypesExpanded = false;
                    } else {
                      _typeDisplayRows += _typeRowsPerStep;
                    }
                  });
                },
                icon: Icon(
                  isTypesAtMax
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.bronze,
                  size: 18,
                ),
                label: Text(
                  isTypesAtMax
                      ? 'View Less'
                      : 'View More ($hiddenTypeCount more)',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.bronze,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.s16),

          // === BIRTHSTONES ===
          const FilterSectionHeader(
            title: 'Birthstones',
            infoText: 'Filter gemstones by their associated birth month.',
          ),
          const SizedBox(height: AppSpacing.s8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: GemstoneFilterState.birthstones.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.5,
            ),
            itemBuilder: (context, index) {
              final month = GemstoneFilterState.birthstones.keys.elementAt(
                index,
              );
              final gemstone = GemstoneFilterState.birthstones[month]!;
              return BirthstoneMonthCard(
                month: month,
                gemstone: gemstone,
                isSelected: state.selectedBirthstoneMonths.contains(month),
                onTap: () => notifier.toggleBirthstoneMonth(month),
              );
            },
          ),
          const SizedBox(height: AppSpacing.s20),

          // === SHAPE ===
          const FilterSectionHeader(title: 'Shape'),
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
                final name = shapeNames[index];
                return FilterShapeGridCell(
                  name: name,
                  svgName: GemstoneFilterState.shapeSvgNames[name],
                  isSelected: state.selectedShapes.contains(name),
                  onTap: () => notifier.toggleShape(name),
                );
              },
            ),
          ),
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  if (isShapesAtMax) {
                    _shapeDisplayRows = 2;
                  } else {
                    _shapeDisplayRows = (_shapeDisplayRows + 2).clamp(
                      0,
                      totalShapeRows,
                    );
                  }
                });
              },
              icon: Icon(
                isShapesAtMax
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: AppColors.bronze,
                size: 18,
              ),
              label: Text(
                isShapesAtMax ? 'Show Less Shapes' : 'Show More Shapes',
                style: AppTypography.caption.copyWith(
                  color: AppColors.bronze,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s16),

          if (isMelee) ...[
            MeleeRangeFilters(
              caratPerPcsMin: state.minCaratPerPiece,
              caratPerPcsMax: state.maxCaratPerPiece,
              onCaratPerPcsChanged: notifier.updateCaratPerPieceRange,
              pricePerPcsMin: state.minPricePerPiece,
              pricePerPcsMax: state.maxPricePerPiece,
              onPricePerPcsChanged: notifier.updatePricePerPieceRange,
              totalPcsMin: state.minTotalPcs,
              totalPcsMax: state.maxTotalPcs,
              onTotalPcsChanged: notifier.updateTotalPcsRange,
              totalPriceMin: state.minTotalPrice,
              totalPriceMax: state.maxTotalPrice,
              onTotalPriceChanged: notifier.updateTotalPriceRange,
              pricePerCaratMin: state.minPricePerCarat,
              pricePerCaratMax: state.maxPricePerCarat,
              onPricePerCaratChanged: notifier.updatePricePerCaratRange,
              totalCaratMin: state.minTotalCarat,
              totalCaratMax: state.maxTotalCarat,
              onTotalCaratChanged: notifier.updateTotalCaratRange,
            ),
          ] else ...[
            FilterRangeSlider(
              title: 'Total Carat',
              minLimit: GemstoneFilterState.caratMin,
              maxLimit: GemstoneFilterState.caratMax,
              currentMin: state.minTotalCarat,
              currentMax: state.maxTotalCarat,
              unitSuffix: ' ct',
              onChanged: (min, max) => notifier.updateTotalCaratRange(min, max),
              onClear: () => notifier.updateTotalCaratRange(
                GemstoneFilterState.caratMin,
                GemstoneFilterState.caratMax,
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: List.generate(
                GemstoneFilterState.caratQuickRanges.length,
                (index) {
                  final range = GemstoneFilterState.caratQuickRanges[index];
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
              title: 'Price Per Carat',
              minLimit: GemstoneFilterState.priceMin,
              maxLimit: GemstoneFilterState.pricePerPieceMax,
              currentMin: state.minPricePerPiece,
              currentMax: state.maxPricePerPiece,
              unitSuffix: '\$',
              isInteger: true,
              onChanged: (min, max) =>
                  notifier.updatePricePerPieceRange(min, max),
              onClear: () => notifier.updatePricePerPieceRange(
                GemstoneFilterState.priceMin,
                GemstoneFilterState.pricePerPieceMax,
              ),
            ),
            const SizedBox(height: AppSpacing.s20),

            FilterRangeSlider(
              title: 'Total Price',
              minLimit: GemstoneFilterState.priceMin,
              maxLimit: GemstoneFilterState.totalPriceMax,
              currentMin: state.minTotalPrice,
              currentMax: state.maxTotalPrice,
              unitSuffix: '\$',
              isInteger: true,
              onChanged: (min, max) => notifier.updateTotalPriceRange(min, max),
              onClear: () => notifier.updateTotalPriceRange(
                GemstoneFilterState.priceMin,
                GemstoneFilterState.totalPriceMax,
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.s24),
          const Divider(),
          const SizedBox(height: AppSpacing.s16),

          // === ADVANCED CONTENT (moved from Advanced section) ===
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() => _isAdvancedExpanded = !_isAdvancedExpanded);
              },
              icon: Icon(
                _isAdvancedExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: AppColors.bronze,
                size: 18,
              ),
              label: Text(
                _isAdvancedExpanded
                    ? 'Hide Advanced Filters'
                    : 'Show Advanced Filters',
                style: AppTypography.caption.copyWith(
                  color: AppColors.bronze,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          if (_isAdvancedExpanded) ...[
            const SizedBox(height: AppSpacing.s16),

            // === TREATMENTS (View More only) ===
            const FilterSectionHeader(
              title: 'Treatments',
              infoText:
                  'Filter by enhancement processes applied to the gemstone.',
            ),
            const SizedBox(height: AppSpacing.s8),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: Wrap(
                spacing: AppSpacing.s8,
                runSpacing: AppSpacing.s8,
                children: [
                  ...GemstoneFilterState.treatments
                      .take(_treatmentDisplayCount)
                      .map((treatment) {
                        return FilterChipWidget(
                          label: treatment,
                          isSelected: state.selectedTreatments.contains(
                            treatment,
                          ),
                          onTap: () => notifier.toggleTreatment(treatment),
                        );
                      }),
                  if (_treatmentDisplayCount <
                      GemstoneFilterState.treatments.length)
                    FilterChipWidget(
                      label:
                          'Others (${GemstoneFilterState.treatments.length - _treatmentDisplayCount})',
                      isSelected: false,
                      onTap: () {
                        setState(() {
                          _treatmentDisplayCount =
                              GemstoneFilterState.treatments.length;
                        });
                      },
                      selectedColor: AppColors.sandSurface,
                      unselectedBgColor: AppColors.sandSurface,
                      unselectedTextColor: AppColors.bronze,
                      borderColor: AppColors.bronze,
                    ),
                ],
              ),
            ),
            if (_treatmentDisplayCount < GemstoneFilterState.treatments.length)
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _treatmentDisplayCount = (_treatmentDisplayCount + 8)
                          .clamp(0, GemstoneFilterState.treatments.length);
                    });
                  },
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.bronze,
                    size: 18,
                  ),
                  label: Text(
                    'View More',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.bronze,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            if (_treatmentDisplayCount >= GemstoneFilterState.treatments.length)
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    setState(() => _treatmentDisplayCount = 8);
                  },
                  icon: const Icon(
                    Icons.keyboard_arrow_up,
                    color: AppColors.bronze,
                    size: 18,
                  ),
                  label: Text(
                    'View Less',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.bronze,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.s20),

            // === CERTIFICATION ===
            const FilterSectionHeader(
              title: 'Certification',
              infoText:
                  'Filter by the gemological laboratory that certified the stone.',
            ),
            const SizedBox(height: AppSpacing.s8),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: GemstoneFilterState.certifications.map((cert) {
                return FilterChipWidget(
                  label: cert,
                  isSelected: state.selectedCertifications.contains(cert),
                  onTap: () => notifier.toggleCertification(cert),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.s20),

            // === SELECT ORIGIN ===
            FilterOriginDropdown(
              title: 'Select Origin',
              hint: 'Select origin',
              infoText: "Filter by the gemstone's mined origin.",
              pickerTitle: 'Select Origin',
              options: GemstoneFilterState.origins,
              flags: GemstoneFilterState.originFlags,
              showFlags: true,
              selectedOrigin: state.selectedOrigin,
              onSelected: (val) => notifier.updateOrigin(val),
              isDark: Theme.of(context).brightness == Brightness.dark,
            ),
            const SizedBox(height: AppSpacing.s20),

            // === CUT GRADE ===
            FilterScrollableChips(
              title: 'Cut Grade',
              options: GemstoneFilterState.cutGrades,
              selectedItems: state.selectedCutGrades,
              onToggle: (val) => notifier.toggleCutGrade(val),
              infoText: "Filter by the quality of the gemstone's cut.",
            ),
          ],
        ],
      ),
    );
  }
}
