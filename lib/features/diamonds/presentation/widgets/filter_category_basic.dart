import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/haptics/app_haptics.dart';
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
import 'package:gemstone/core/widgets/filters/filter_scrollable_chips.dart';
import 'package:gemstone/core/widgets/filters/filter_boolean_checkbox.dart';
import 'package:gemstone/core/widgets/filters/melee_range_filters.dart';
import 'package:gemstone/core/widgets/filters/catalog_standard_range_filters.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/widgets/luxe/luxe_layout.dart';

/// Whether the current catalog shows melee (sieve / per-piece) filters.
bool diamondUsesMeleeFilters(DiamondFilterState state, {required bool isLab}) =>
    isLab
    ? state.labCategory == 'Lab Melee'
    : state.labNatural.usesMeleeFilters;

/// Catalog mode controls: Natural / Melee for the natural finder; diamond
/// category and growth method for the lab-grown finder.
class DiamondCatalogModeControls extends ConsumerWidget {
  const DiamondCatalogModeControls({
    super.key,
    this.showOriginToggle = true,
    this.isLabCatalog = false,
  });

  final bool showOriginToggle;
  final bool isLabCatalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(diamondSearchProvider);
    final notifier = ref.read(diamondSearchProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showOriginToggle)
          FilterSegmentedControl(
            options: LabNaturalType.values,
            selected: state.labNatural,
            onSelected: notifier.updateOrigin,
          ),
        if (isLabCatalog) ...[
          FilterSectionHeader(title: context.tr(CatalogL10n.diamondCategory)),
          const SizedBox(height: AppSpacing.s8),
          FilterTextSegmentedControl(
            options: DiamondFilterState.labCategories,
            selected: state.labCategory,
            onSelected: notifier.updateLabCategory,
          ),
          const SizedBox(height: AppSpacing.s16),
          FilterSectionHeader(title: context.tr(CatalogL10n.growthMethod)),
          const SizedBox(height: AppSpacing.s8),
          Row(
            children: [
              for (final method in DiamondFilterState.growthMethods)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChipWidget(
                      label: method,
                      isSelected: state.selectedGrowthMethods.contains(method),
                      centerLabel: true,
                      onTap: () => notifier.toggleGrowthMethod(method),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Media, offer, availability and (melee) separable listing options.
class DiamondListingOptionsFilters extends ConsumerWidget {
  const DiamondListingOptionsFilters({required this.isLabCatalog, super.key});

  final bool isLabCatalog;

  String _availabilityLabel(BuildContext context, String option) {
    return switch (option) {
      'All' => context.tr(RemainingL10n.all),
      'Available' => context.tr(CatalogL10n.available),
      'On Memo' => context.tr(CatalogL10n.onMemo),
      'On Hold' => context.tr(CatalogL10n.onHold),
      'Sold' => context.tr(CatalogL10n.sold),
      _ => option,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(diamondSearchProvider);
    final notifier = ref.read(diamondSearchProvider.notifier);
    final melee = diamondUsesMeleeFilters(state, isLab: isLabCatalog);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (melee)
          FilterBooleanCheckbox(
            label: context.tr(CatalogL10n.separable),
            value: state.separable,
            onChanged: (_) => notifier.toggleSeparable(),
          ),
        FilterBooleanCheckbox(
          label: context.tr(CatalogL10n.filterByMedia),
          value: state.searchByMedia,
          onChanged: (_) => notifier.toggleSearchByMedia(),
        ),
        FilterBooleanCheckbox(
          label: context.tr(CatalogL10n.makeOffer),
          value: state.makeAnOffer,
          onChanged: (_) => notifier.toggleMakeAnOffer(),
        ),
        const SizedBox(height: AppSpacing.s16),
        FilterSectionHeader(title: context.tr(CatalogL10n.availability)),
        const SizedBox(height: AppSpacing.s8),
        DiamondDropdownField<String>(
          value: state.selectedAvailability,
          items: [
            for (final opt in DiamondFilterState.availabilityOptions)
              DropdownMenuItem(
                value: opt,
                child: Text(_availabilityLabel(context, opt)),
              ),
          ],
          onChanged: notifier.updateAvailability,
        ),
      ],
    );
  }
}

/// Size & price: sieve table and per-piece ranges for melee, or the
/// carat / total price / price-per-carat ranges for single stones.
class DiamondSizePriceFilters extends ConsumerWidget {
  const DiamondSizePriceFilters({required this.isLabCatalog, super.key});

  final bool isLabCatalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(diamondSearchProvider);
    final notifier = ref.read(diamondSearchProvider.notifier);
    final melee = diamondUsesMeleeFilters(state, isLab: isLabCatalog);
    final showSieve = melee && state.shapes.contains('Round');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showSieve) const FilterSieveSize(),
        if (melee)
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
          )
        else
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
    );
  }
}

/// Finish presets, cut, polish, symmetry and certifying lab.
class DiamondGradingFilters extends ConsumerWidget {
  const DiamondGradingFilters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(diamondSearchProvider);
    final notifier = ref.read(diamondSearchProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FinishPresetsSection(wrapWithCard: false),
        const SizedBox(height: AppSpacing.s20),
        FilterScrollableChips(
          title: context.tr(CatalogL10n.cutGrade),
          options: DiamondFilterState.cuts,
          selectedItems: state.selectedCuts,
          onToggle: notifier.toggleCut,
          infoText: "Filter by the quality of the diamond's cut.",
          wrapWithCard: false,
        ),
        const SizedBox(height: AppSpacing.s20),
        FilterScrollableChips(
          title: context.tr(CatalogL10n.polish),
          options: DiamondFilterState.polishingGrades,
          selectedItems: state.selectedPolish,
          onToggle: notifier.togglePolish,
          infoText: "Filter by the smoothness of the diamond's facets.",
          wrapWithCard: false,
        ),
        const SizedBox(height: AppSpacing.s20),
        FilterScrollableChips(
          title: context.tr(CatalogL10n.symmetry),
          options: DiamondFilterState.symmetryGrades,
          selectedItems: state.selectedSymmetry,
          onToggle: notifier.toggleSymmetry,
          infoText: "Filter by the exactness of the diamond's shape.",
          wrapWithCard: false,
        ),
        const SizedBox(height: AppSpacing.s20),
        FilterScrollableChips(
          title: context.tr(CatalogL10n.certification),
          options: DiamondFilterState.labs,
          selectedItems: state.selectedLabs,
          onToggle: notifier.toggleLab,
          infoText:
              'Filter by the gemological laboratory that certified the diamond.',
          wrapWithCard: false,
        ),
      ],
    );
  }
}

/// Eye-clean / BGM / H&A, milky, fluorescence and enhancement.
class DiamondInclusionFilters extends ConsumerWidget {
  const DiamondInclusionFilters({super.key});

  static Color _parseHex(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(diamondSearchProvider);
    final notifier = ref.read(diamondSearchProvider.notifier);

    Widget chips(
      String title,
      List<String> options,
      List<String> selected,
      void Function(String) onToggle,
    ) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilterSectionHeader(title: title),
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final grade in options)
                FilterChipWidget(
                  label: context.trCatalogValue(grade),
                  isSelected: selected.contains(grade),
                  onTap: () => onToggle(grade),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s20),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(height: AppSpacing.s16),
        chips(
          context.tr(CatalogL10n.milky),
          DiamondFilterState.milkyGrades,
          state.selectedMilkyGrades,
          notifier.toggleMilkyGrade,
        ),
        chips(
          context.tr(CatalogL10n.fluorescenceIntensity),
          DiamondFilterState.fluorescenceGrades,
          state.selectedFluorescence,
          notifier.toggleFluorescence,
        ),
        FilterSectionHeader(title: context.tr(CatalogL10n.fluorescenceColor)),
        const SizedBox(height: AppSpacing.s8),
        DiamondDropdownField<String>(
          hint: context.tr(CatalogL10n.selectFluorescenceColor),
          value: state.selectedFluorescenceColor,
          items: [
            for (final colorName in DiamondFilterState.fluorescenceColors)
              DropdownMenuItem(
                value: colorName,
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _parseHex(
                          DiamondFilterState.fluorescenceColorsHex[colorName]!,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border(context)),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Text(context.trCatalogValue(colorName)),
                  ],
                ),
              ),
          ],
          onChanged: notifier.updateFluorescenceColor,
        ),
        const SizedBox(height: AppSpacing.s20),
        FilterSectionHeader(title: context.tr(CatalogL10n.enhancement)),
        const SizedBox(height: AppSpacing.s8),
        DiamondDropdownField<String>(
          hint: context.tr(CatalogL10n.selectEnhancement),
          value: state.selectedEnhancement,
          items: [
            for (final enh in DiamondFilterState.enhancements)
              DropdownMenuItem(
                value: enh,
                child: Text(context.trCatalogValue(enh)),
              ),
          ],
          onChanged: notifier.updateEnhancement,
        ),
      ],
    );
  }
}

/// Rounded dropdown that follows the ambient (luxe-aware) palette.
class DiamondDropdownField<T> extends StatelessWidget {
  const DiamondDropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
    super.key,
    this.hint,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        border: Border.all(color: AppColors.border(context)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          hint: hint == null ? null : Text(hint!),
          borderRadius: BorderRadius.circular(14),
          dropdownColor: AppColors.card(context),
          icon: Icon(
            Icons.expand_more_rounded,
            color: AppColors.textSecondary(context),
          ),
          style: AppTypography.body.copyWith(
            fontSize: 14,
            color: AppColors.textPrimary(context),
          ),
          items: items,
          onChanged: onChanged,
        ),
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
          FilterSectionHeader(title: context.tr(CatalogL10n.clarity)),
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
                    borderRadius: BorderRadius.circular(100),
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
    if (LuxeScope.paletteOf(context) != null) {
      return LuxeSegmented<LabNaturalType>(
        options: options,
        selected: selected,
        onChanged: onSelected,
        labelOf: (o) => o.usesMeleeFilters
            ? context.tr(CatalogL10n.melee)
            : context.tr(DiamondFlowL10n.singleStones),
      );
    }
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
                ? AppColors.naturalMeleeAccent
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
                  onTap: () {
                    if (!isCurrent) AppHaptics.selection();
                    onSelected(opt);
                  },
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
              accentColor: AppColors.finderAccent(
                context,
                family: MeleeBgFamily.natural,
                melee: true,
              ),
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
      onTap: () {
        AppHaptics.selection();
        onTap();
      },
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
      onTap: () {
        AppHaptics.selection();
        onTap();
      },
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
  final Color accentColor;
  final VoidCallback? onClear;

  const _SelectionSummaryCard({
    required this.count,
    required this.borderColor,
    required this.accentColor,
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
            color: count > 0 ? accentColor : (AppColors.textMuted(context)),
          ),
          const SizedBox(width: AppSpacing.s8),
          Text(
            count == 0 ? '0 Selected' : '$count Selected',
            style: AppTypography.label.copyWith(
              fontWeight: FontWeight.bold,
              color: count > 0
                  ? accentColor
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
