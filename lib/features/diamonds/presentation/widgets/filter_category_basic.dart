import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/models/sieve_size.dart';
import '../../../../core/widgets/melee_background_shell.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/diamond_search_provider.dart';
import '../../domain/models/diamond_filter_state.dart';
import 'package:gemstone/core/widgets/filters/filter_chip.dart';
import 'package:gemstone/core/widgets/filters/filter_text_segmented_control.dart';
import 'package:gemstone/core/widgets/filters/filter_section_header.dart';
import 'package:gemstone/core/widgets/filters/filter_group_card.dart';
import 'filter_color_selector.dart';
import 'package:gemstone/core/widgets/filters/filter_scrollable_chips.dart';
import 'filter_shape_grid_cell.dart';
import 'package:gemstone/core/widgets/filters/filter_boolean_checkbox.dart';
import 'package:gemstone/core/widgets/filters/melee_range_filters.dart';
import 'package:gemstone/core/widgets/filters/catalog_standard_range_filters.dart';
import 'diamond_svg_data.dart';

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
    final borderColor = AppColors.border(context);

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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FilterSectionHeader(
                  title: context.tr(CatalogL10n.diamondCategory),
                ),
                const SizedBox(height: AppSpacing.s8),
                FilterTextSegmentedControl(
                  options: DiamondFilterState.labCategories,
                  selected: state.labCategory,
                  onSelected: (value) => notifier.updateLabCategory(value),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.s16),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FilterSectionHeader(
                  title: context.tr(CatalogL10n.growthMethod),
                ),
                const SizedBox(height: AppSpacing.s8),
                Row(
                  children: DiamondFilterState.growthMethods.map((method) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChipWidget(
                          label: method,
                          isSelected: state.selectedGrowthMethods.contains(
                            method,
                          ),
                          centerLabel: true,
                          onTap: () => notifier.toggleGrowthMethod(method),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.s20),
          ],

          FilterGroupCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FilterSectionHeader(title: context.tr(CatalogL10n.selectShape)),
                const SizedBox(height: AppSpacing.s8),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: shapesToShow,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                      isAtMax
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
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
              ],
            ),
          ),

          FilterGroupCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (useMeleeFilters) ...[
                  FilterBooleanCheckbox(
                    label: context.tr(CatalogL10n.separable),
                    value: state.separable,
                    onChanged: (_) => notifier.toggleSeparable(),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                ],
                FilterBooleanCheckbox(
                  label: context.tr(CatalogL10n.filterByMedia),
                  value: state.searchByMedia,
                  onChanged: (_) => notifier.toggleSearchByMedia(),
                ),
              ],
            ),
          ),

          if (showSieve) ...[const FilterSieveSize()],

          if (useMeleeFilters) ...[
            MeleeRangeFilters(
              caratPerPcsMin: state.minCaratPerPcs,
              caratPerPcsMax: state.maxCaratPerPcs,
              onCaratPerPcsChanged: notifier.updateCaratPerPcsRange,
              pricePerPcsMin: state.minPricePerPcs,
              pricePerPcsMax: state.maxPricePerPcs,
              onPricePerPcsChanged: notifier.updatePricePerPcsRange,
              totalPcsMin: state.minTotalPcs,
              totalPcsMax: state.maxTotalPcs,
              onTotalPcsChanged: notifier.updateTotalPcsRange,
              totalPriceMin: state.minPrice,
              totalPriceMax: state.maxPrice,
              onTotalPriceChanged: notifier.updatePriceRange,
              pricePerCaratMin: state.minPricePerCarat,
              pricePerCaratMax: state.maxPricePerCarat,
              onPricePerCaratChanged: notifier.updatePricePerCaratRange,
              totalCaratMin: state.minCarat,
              totalCaratMax: state.maxCarat,
              onTotalCaratChanged: notifier.updateCaratRange,
            ),
          ],
          if (showStandardRanges) ...[
            CatalogStandardRangeFilters(
              totalPriceMin: state.minPrice,
              totalPriceMax: state.maxPrice,
              totalPriceLimits: (0.0, 1000000.0),
              onTotalPriceChanged: notifier.updatePriceRange,
              totalCaratMin: state.minCarat,
              totalCaratMax: state.maxCarat,
              totalCaratLimits: (0.0, 100.00),
              onTotalCaratChanged: notifier.updateCaratRange,
              caratQuickRanges: DiamondFilterState.caratQuickRanges,
              selectedCaratQuickRanges: state.selectedCaratQuickRanges,
              onToggleCaratQuickRange: notifier.toggleCaratQuickRange,
              pricePerCaratMin: state.minPricePerCarat,
              pricePerCaratMax: state.maxPricePerCarat,
              pricePerCaratLimits: (0.0, 200000.0),
              onPricePerCaratChanged: notifier.updatePricePerCaratRange,
            ),
          ],

          // === COLOR, CLARITY, FINISH (always visible) ===
          const ColorTabsSelector(),

          const ClarityCardsSection(),

          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _isAdvancedFiltersExpanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FilterGroupCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FinishPresetsSection(wrapWithCard: false),
                            const SizedBox(height: AppSpacing.s20),
                            FilterScrollableChips(
                              title: context.tr(CatalogL10n.cutGrade),
                              options: DiamondFilterState.cuts,
                              selectedItems: state.selectedCuts,
                              onToggle: (val) => notifier.toggleCut(val),
                              infoText:
                                  "Filter by the quality of the diamond's cut.",
                              wrapWithCard: false,
                            ),
                            const SizedBox(height: AppSpacing.s20),
                            FilterScrollableChips(
                              title: context.tr(CatalogL10n.polish),
                              options: DiamondFilterState.polishingGrades,
                              selectedItems: state.selectedPolish,
                              onToggle: (val) => notifier.togglePolish(val),
                              infoText:
                                  "Filter by the smoothness of the diamond's facets.",
                              wrapWithCard: false,
                            ),
                            const SizedBox(height: AppSpacing.s20),
                            FilterScrollableChips(
                              title: context.tr(CatalogL10n.symmetry),
                              options: DiamondFilterState.symmetryGrades,
                              selectedItems: state.selectedSymmetry,
                              onToggle: (val) => notifier.toggleSymmetry(val),
                              infoText:
                                  "Filter by the exactness of the diamond's shape.",
                              wrapWithCard: false,
                            ),
                            const SizedBox(height: AppSpacing.s20),
                            FilterScrollableChips(
                              title: context.tr(CatalogL10n.certification),
                              options: DiamondFilterState.labs,
                              selectedItems: state.selectedLabs,
                              onToggle: (val) => notifier.toggleLab(val),
                              infoText:
                                  "Filter by the gemological laboratory that certified the diamond.",
                              wrapWithCard: false,
                            ),
                          ],
                        ),
                      ),

                      // === INCLUSIONS ===
                      FilterGroupCard(
                        child: Column(
                          children: [
                            FilterBooleanCheckbox(
                              label: context.tr(CatalogL10n.noBgmLong),
                              value: state.noBgm,
                              onChanged: (_) => notifier.toggleNoBgm(),
                            ),
                            FilterBooleanCheckbox(
                              label: context.tr(CatalogL10n.eyeCleanLong),
                              value: state.eyeClean,
                              onChanged: (_) => notifier.toggleEyeClean(),
                            ),
                            FilterBooleanCheckbox(
                              label: context.tr(CatalogL10n.heartsAndArrows),
                              value: state.heartAndArrow,
                              onChanged: (_) => notifier.toggleHeartAndArrow(),
                            ),
                          ],
                        ),
                      ),

                      // === TREATMENT ===
                      FilterGroupCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FilterSectionHeader(
                              title: context.tr(CatalogL10n.milky),
                            ),
                            const SizedBox(height: AppSpacing.s8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: DiamondFilterState.milkyGrades.map((
                                  grade,
                                ) {
                                  final isSelected = state.selectedMilkyGrades
                                      .contains(grade);
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: GestureDetector(
                                      onTap: () =>
                                          notifier.toggleMilkyGrade(grade),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 150,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.selectedFill(context)
                                              : AppColors.card(context),
                                          borderRadius: BorderRadius.circular(
                                            AppSpacing.r8,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.selectedFill(
                                                    context,
                                                  )
                                                : borderColor,
                                          ),
                                        ),
                                        child: Text(
                                          context.trCatalogValue(grade),
                                          style: AppTypography.caption.copyWith(
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? AppColors.onSelected(context)
                                                : (AppColors.textPrimary(
                                                    context,
                                                  )),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            FilterSectionHeader(
                              title: context.tr(
                                CatalogL10n.fluorescenceIntensity,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.s8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: DiamondFilterState.fluorescenceGrades
                                    .map((grade) {
                                      final isSelected = state
                                          .selectedFluorescence
                                          .contains(grade);
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8.0,
                                        ),
                                        child: GestureDetector(
                                          onTap: () => notifier
                                              .toggleFluorescence(grade),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 150,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? AppColors.selectedFill(
                                                      context,
                                                    )
                                                  : AppColors.card(context),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppSpacing.r8,
                                                  ),
                                              border: Border.all(
                                                color: isSelected
                                                    ? AppColors.selectedFill(
                                                        context,
                                                      )
                                                    : borderColor,
                                              ),
                                            ),
                                            child: Text(
                                              context.trCatalogValue(grade),
                                              style: AppTypography.caption
                                                  .copyWith(
                                                    fontWeight: isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.w500,
                                                    color: isSelected
                                                        ? AppColors.onSelected(
                                                            context,
                                                          )
                                                        : (AppColors.textPrimary(
                                                            context,
                                                          )),
                                                  ),
                                            ),
                                          ),
                                        ),
                                      );
                                    })
                                    .toList(),
                              ),
                            ),
                            FilterSectionHeader(
                              title: context.tr(CatalogL10n.fluorescenceColor),
                            ),
                            const SizedBox(height: AppSpacing.s8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: borderColor),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.r8,
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  hint: Text(
                                    context.tr(
                                      CatalogL10n.selectFluorescenceColor,
                                    ),
                                  ),
                                  value: state.selectedFluorescenceColor,
                                  items: DiamondFilterState.fluorescenceColors
                                      .map((colorName) {
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
                                              const SizedBox(
                                                width: AppSpacing.s12,
                                              ),
                                              Text(context.trCatalogValue(colorName)),
                                              const Spacer(),
                                              Text(
                                                hex,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.textMuted(
                                                    context,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      })
                                      .toList(),
                                  onChanged: (val) =>
                                      notifier.updateFluorescenceColor(val),
                                ),
                              ),
                            ),
                            FilterSectionHeader(
                              title: context.tr(CatalogL10n.enhancement),
                            ),
                            const SizedBox(height: AppSpacing.s8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: borderColor),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.r8,
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  hint: Text(
                                    context.tr(CatalogL10n.selectEnhancement),
                                  ),
                                  value: state.selectedEnhancement,
                                  items: DiamondFilterState.enhancements.map((
                                    enh,
                                  ) {
                                    return DropdownMenuItem<String>(
                                      value: enh,
                                      child: Text(context.trCatalogValue(enh)),
                                    );
                                  }).toList(),
                                  onChanged: (val) =>
                                      notifier.updateEnhancement(val),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity, height: 0),
          ),

          const SizedBox(height: AppSpacing.s8),

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
                  color: AppColors.bg(context),
                  borderRadius: BorderRadius.circular(AppSpacing.r8),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.tr(CatalogL10n.viewMoreFilters),
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

class ClarityCardsSection extends ConsumerStatefulWidget {
  const ClarityCardsSection({super.key});

  @override
  ConsumerState<ClarityCardsSection> createState() =>
      _ClarityCardsSectionState();
}

class _ClarityCardsSectionState extends ConsumerState<ClarityCardsSection> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diamondSearchProvider);
    final notifier = ref.read(diamondSearchProvider.notifier);
    final borderColor = AppColors.border(context);

    return FilterGroupCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(CatalogL10n.clarity),
            style: AppTypography.label.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.s8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: DiamondFilterState.clarities.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 2.2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final grade = DiamondFilterState.clarities[index];
              final isSelected = state.selectedClarityGrades.contains(grade);
              return GestureDetector(
                onTap: () => notifier.toggleClarityGradeGroup(grade),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.selectedFill(context)
                        : AppColors.card(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.selectedFill(context)
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
                          ? AppColors.onSelected(context)
                          : (AppColors.textPrimary(context)),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class FinishPresetsSection extends ConsumerWidget {
  const FinishPresetsSection({this.wrapWithCard = true, super.key});

  final bool wrapWithCard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(diamondSearchProvider);
    final notifier = ref.read(diamondSearchProvider.notifier);
    final borderColor = AppColors.border(context);
    final presets = ['3X', 'EX-', 'VG+', 'VG-'];

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              context.tr(CatalogL10n.finishQuickSelect),
              style: AppTypography.label.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 6),
            Tooltip(
              message:
                  "Quickly select combined grades for Cut, Polish, and Symmetry.",
              triggerMode: TooltipTriggerMode.tap,
              preferBelow: false,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(6),
              ),
              textStyle: const TextStyle(color: Colors.white, fontSize: 13),
              child: const Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.bronze,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: presets.map((preset) {
            final isSelected = state.selectedFinishPreset.contains(preset);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: GestureDetector(
                  onTap: () => notifier.selectFinishPreset(preset),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.selectedFill(context)
                          : AppColors.card(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.selectedFill(context)
                            : borderColor,
                      ),
                    ),
                    child: Text(
                      preset,
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? AppColors.onSelected(context)
                            : (AppColors.textPrimary(context)),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );

    if (!wrapWithCard) {
      return content;
    }

    return FilterGroupCard(child: content);
  }
}

class FilterSegmentedControl extends StatelessWidget {
  const FilterSegmentedControl({
    required this.options,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<LabNaturalType> options;
  final LabNaturalType selected;
  final void Function(LabNaturalType) onSelected;

  @override
  Widget build(BuildContext context) {
    final borderColor = AppColors.border(context);

    return MeleeTintExtentAnchor(
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.r8),
          border: Border.all(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: options.map((opt) {
            final isCurrent = opt == selected;
            final splash = opt.usesMeleeFilters
                ? AppColors.screenBgFor(
                    context,
                    melee: true,
                    family: MeleeBgFamily.natural,
                  )
                : AppColors.bronzeLight;
            return Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTapDown: (details) {
                    MeleeRippleOriginNotification(
                      details.globalPosition,
                    ).dispatch(context);
                  },
                  onTap: () => onSelected(opt),
                  splashColor: splash.withValues(alpha: 0.55),
                  highlightColor: splash.withValues(alpha: 0.22),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? AppColors.selectedFill(context)
                          : AppColors.card(context),
                      borderRadius: BorderRadius.circular(AppSpacing.r8 - 1),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      opt.label,
                      style: AppTypography.caption.copyWith(
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isCurrent
                            ? AppColors.onSelected(context)
                            : (AppColors.textPrimary(context)),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class FilterSieveSize extends ConsumerStatefulWidget {
  const FilterSieveSize({super.key});

  @override
  ConsumerState<FilterSieveSize> createState() => _FilterSieveSizeState();
}

class _FilterSieveSizeState extends ConsumerState<FilterSieveSize> {
  static const double _tableHeight = 280.0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diamondSearchProvider);
    final notifier = ref.read(diamondSearchProvider.notifier);
    final borderColor = AppColors.border(context);

    const sieves = SieveSize.defaultSieves;
    final selectedSet = state.selectedSieveIndices.toSet();

    return RepaintBoundary(
      child: FilterGroupCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FilterSectionHeader(title: context.tr(CatalogL10n.sieveSize)),
            const SizedBox(height: AppSpacing.s12),

            // ---- Lot Type Presets ----
            FilterSectionHeader(title: context.tr(CatalogL10n.lotTypePresets)),
            const SizedBox(height: AppSpacing.s8),
            Row(
              children: SieveSize.lotTypePresets.keys.map((label) {
                final isActive = state.activeSievePresets.contains(label);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _CompactPresetChip(
                      label: label,
                      isActive: isActive,
                      onTap: () => notifier.applySievePreset(label),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.s16),

            // ---- Scrollable Sieve Table ----
            Container(
              height: _tableHeight,
              decoration: BoxDecoration(
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(AppSpacing.r8),
              ),
              child: Column(
                children: [
                  _SieveTableHeader(borderColor: borderColor),
                  Expanded(
                    child: Scrollbar(
                      child: ListView.builder(
                        itemCount: sieves.length,
                        itemExtent: 36.0,
                        itemBuilder: (context, index) {
                          final sieve = sieves[index];
                          final isSelected = selectedSet.contains(sieve.index);
                          return _SieveTableRow(
                            sieve: sieve,
                            isSelected: isSelected,
                            borderColor: borderColor,
                            onTap: () => notifier.toggleSieveSize(sieve.index),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s16),

            // ---- Selection Summary ----
            _SelectionSummaryCard(
              count: state.selectedSieveIndices.length,
              borderColor: borderColor,
              onClear: state.selectedSieveIndices.isEmpty
                  ? null
                  : () => notifier.clearSieves(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactPresetChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _CompactPresetChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.selectedFill(context)
              : AppColors.card(context),
          borderRadius: BorderRadius.circular(AppSpacing.r8),
          border: Border.all(
            color: isActive
                ? AppColors.selectedFill(context)
                : AppColors.border(context),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.visible,
          style: AppTypography.caption.copyWith(
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 11,
            height: 1.2,
            color: isActive
                ? AppColors.onSelected(context)
                : (AppColors.textPrimary(context)),
          ),
        ),
      ),
    );
  }
}

class _SieveTableHeader extends StatelessWidget {
  final Color borderColor;

  const _SieveTableHeader({required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Expanded(child: _HeaderCell(label: context.tr(CatalogL10n.sieve))),
          Container(width: 1, color: borderColor),
          const Expanded(child: _HeaderCell(label: 'MM')),
          Container(width: 1, color: borderColor),
          Expanded(child: _HeaderCell(label: context.tr(CatalogL10n.carat))),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  const _HeaderCell({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _SieveTableRow extends StatelessWidget {
  final SieveSize sieve;
  final bool isSelected;
  final Color borderColor;
  final VoidCallback onTap;

  const _SieveTableRow({
    required this.sieve,
    required this.isSelected,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.selectedFill(context)
              : Colors.transparent,
          border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _DataCell(text: sieve.sieve, isSelected: isSelected),
            ),
            Container(width: 1, color: borderColor),
            Expanded(
              child: _DataCell(
                text:
                    '${sieve.mmMin.toStringAsFixed(2)}-${sieve.mmMax.toStringAsFixed(2)}',
                isSelected: isSelected,
              ),
            ),
            Container(width: 1, color: borderColor),
            Expanded(
              child: _DataCell(
                text: sieve.carat.toStringAsFixed(3),
                isSelected: isSelected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String text;
  final bool isSelected;
  const _DataCell({required this.text, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
          fontSize: 11,
          color: isSelected
              ? AppColors.onSelected(context)
              : (AppColors.textSecondary(context)),
        ),
      ),
    );
  }
}

class _SelectionSummaryCard extends StatelessWidget {
  final int count;
  final Color borderColor;
  final VoidCallback? onClear;

  const _SelectionSummaryCard({
    required this.count,
    required this.borderColor,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppSpacing.r8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            count > 0 ? Icons.check_circle : Icons.circle_outlined,
            size: 18,
            color: count > 0
                ? AppColors.bronze
                : (AppColors.textMuted(context)),
          ),
          const SizedBox(width: AppSpacing.s8),
          Text(
            count == 0 ? '0 Selected' : '$count Selected',
            style: AppTypography.label.copyWith(
              fontWeight: FontWeight.bold,
              color: count > 0
                  ? AppColors.bronze
                  : (AppColors.textSecondary(context)),
            ),
          ),
          const Spacer(),
          if (onClear != null)
            GestureDetector(
              onTap: onClear,
              child: Text(
                context.tr(CatalogL10n.clear),
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.terracotta,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
