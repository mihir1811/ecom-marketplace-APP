import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
import 'package:gemstone/core/widgets/filters/filter_chip_scroll_row.dart';
import 'package:gemstone/core/widgets/filters/filter_text_segmented_control.dart';
import 'package:gemstone/core/widgets/filters/filter_section_header.dart';
import 'package:gemstone/core/widgets/filters/filter_section_divider.dart';
import 'package:gemstone/core/widgets/filters/filter_group_card.dart';
import 'package:gemstone/core/widgets/filters/filter_scrollable_chips.dart';
import 'package:gemstone/core/widgets/filters/catalog_availability_filter.dart';
import 'package:gemstone/core/widgets/filters/filter_boolean_checkbox.dart';
import 'package:gemstone/core/widgets/filters/melee_range_filters.dart';
import 'package:gemstone/core/widgets/filters/catalog_standard_range_filters.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/widgets/luxe/luxe_dropdown_field.dart';
import '../../../../core/widgets/luxe/luxe_layout.dart';
import '../../../../core/widgets/luxe/luxe_multi_select_field.dart';

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
          const FilterSectionDivider(),
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
        const FilterSectionDivider(),
        FilterSectionHeader(title: context.tr(CatalogL10n.availability)),
        const SizedBox(height: AppSpacing.s8),
        LuxeMultiSelectField(
          options: DiamondFilterState.availabilityOptions,
          selected: state.selectedAvailabilities,
          onChanged: notifier.setAvailabilities,
          hint: context.tr(CatalogL10n.selectAvailability),
          sheetTitle: context.tr(CatalogL10n.availability),
          labelOf: (o) => catalogAvailabilityLabel(context, o),
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
            caratLimits: (
              DiamondFilterState.caratMin,
              DiamondFilterState.caratMax,
            ),
            caratPerPcsLimits: (
              DiamondFilterState.caratPerPcsMinLimit,
              DiamondFilterState.caratPerPcsMaxLimit,
            ),
            pricePerUnitLimits: (
              DiamondFilterState.pricePerPcsMinLimit,
              DiamondFilterState.pricePerPcsMaxLimit,
            ),
            pcsLimits: (
              DiamondFilterState.totalPcsMinLimit,
              DiamondFilterState.totalPcsMaxLimit,
            ),
            totalPriceLimits: (
              DiamondFilterState.priceMin,
              DiamondFilterState.priceMax,
            ),
          )
        else
          CatalogStandardRangeFilters(
            totalPriceMin: state.minPrice,
            totalPriceMax: state.maxPrice,
            totalPriceLimits: (
              DiamondFilterState.priceMin,
              DiamondFilterState.priceMax,
            ),
            onTotalPriceChanged: notifier.updatePriceRange,
            totalCaratMin: state.minCarat,
            totalCaratMax: state.maxCarat,
            totalCaratLimits: (
              DiamondFilterState.caratMin,
              DiamondFilterState.caratMax,
            ),
            onTotalCaratChanged: notifier.updateCaratRange,
            pricePerCaratMin: state.minPricePerCarat,
            pricePerCaratMax: state.maxPricePerCarat,
            pricePerCaratLimits: (
              DiamondFilterState.pricePerCaratMin,
              DiamondFilterState.pricePerCaratMax,
            ),
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
        const FilterSectionDivider(),
        FilterScrollableChips(
          title: context.tr(CatalogL10n.cutGrade),
          options: DiamondFilterState.cuts,
          selectedItems: state.selectedCuts,
          onToggle: notifier.toggleCut,
          infoText: "Filter by the quality of the diamond's cut.",
          wrapWithCard: false,
        ),
        const FilterSectionDivider(),
        FilterScrollableChips(
          title: context.tr(CatalogL10n.polish),
          options: DiamondFilterState.polishingGrades,
          selectedItems: state.selectedPolish,
          onToggle: notifier.togglePolish,
          infoText: "Filter by the smoothness of the diamond's facets.",
          wrapWithCard: false,
        ),
        const FilterSectionDivider(),
        FilterScrollableChips(
          title: context.tr(CatalogL10n.symmetry),
          options: DiamondFilterState.symmetryGrades,
          selectedItems: state.selectedSymmetry,
          onToggle: notifier.toggleSymmetry,
          infoText: "Filter by the exactness of the diamond's shape.",
          wrapWithCard: false,
        ),
        const FilterSectionDivider(),
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
          FilterChipScrollRow(
            children: [
              for (final grade in options)
                FilterChipWidget(
                  label: context.trCatalogValue(grade),
                  isSelected: selected.contains(grade),
                  onTap: () => onToggle(grade),
                ),
            ],
          ),
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
        const FilterSectionDivider(),
        chips(
          context.tr(CatalogL10n.milky),
          DiamondFilterState.milkyGrades,
          state.selectedMilkyGrades,
          notifier.toggleMilkyGrade,
        ),
        const FilterSectionDivider(),
        chips(
          context.tr(CatalogL10n.fluorescenceIntensity),
          DiamondFilterState.fluorescenceGrades,
          state.selectedFluorescence,
          notifier.toggleFluorescence,
        ),
        const FilterSectionDivider(),
        FilterSectionHeader(title: context.tr(CatalogL10n.fluorescenceColor)),
        const SizedBox(height: AppSpacing.s8),
        LuxeMultiSelectField(
          options: DiamondFilterState.fluorescenceColors,
          selected: state.selectedFluorescenceColors,
          onChanged: notifier.setFluorescenceColors,
          hint: context.tr(CatalogL10n.selectFluorescenceColors),
          sheetTitle: context.tr(CatalogL10n.fluorescenceColor),
          labelOf: context.trCatalogValue,
          leadingOf: (colorName) => Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: _parseHex(
                DiamondFilterState.fluorescenceColorsHex[colorName] ?? '',
              ),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border(context)),
            ),
          ),
        ),
        const FilterSectionDivider(),
        FilterSectionHeader(title: context.tr(CatalogL10n.enhancement)),
        const SizedBox(height: AppSpacing.s8),
        LuxeMultiSelectField(
          options: DiamondFilterState.enhancements,
          selected: state.selectedEnhancements,
          onChanged: notifier.setEnhancements,
          hint: context.tr(CatalogL10n.selectEnhancements),
          sheetTitle: context.tr(CatalogL10n.enhancement),
          labelOf: context.trCatalogValue,
        ),
      ],
    );
  }
}

/// Kept for existing call sites; the shared field lives in core.
typedef DiamondDropdownField<T> = LuxeDropdownField<T>;

/// One clarity card: its loupe diagram (SVG asset) and the grades it holds.
class _ClarityGroup {
  const _ClarityGroup(this.asset, this.grades);

  final String asset;
  final List<String> grades;
}

const _clarityGroups = [
  _ClarityGroup('assets/clarity/clarity_fl_if.svg', ['FL', 'IF']),
  _ClarityGroup('assets/clarity/clarity_vvs.svg', ['VVS1', 'VVS2']),
  _ClarityGroup('assets/clarity/clarity_vs.svg', ['VS1', 'VS2']),
  _ClarityGroup('assets/clarity/clarity_si.svg', ['SI1', 'SI2', 'SI3']),
  _ClarityGroup('assets/clarity/clarity_i.svg', ['I1', 'I2', 'I3']),
];

/// Clarity as loupe cards: each card shows a round brilliant with the kind
/// of inclusions its grades allow. Tap a card to pick its whole group, or a
/// grade pill to pick just that grade; "Select All" toggles every grade.
class ClarityCardsSection extends ConsumerWidget {
  const ClarityCardsSection({super.key});

  static const _cardWidth = 156.0;
  static const _gap = 10.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      diamondSearchProvider.select((s) => s.selectedClarityGrades),
    );
    final notifier = ref.read(diamondSearchProvider.notifier);
    final allSelected = selected.length == DiamondFilterState.clarities.length;

    Widget card(_ClarityGroup g) => _ClarityCard(
      group: g,
      selected: selected,
      onToggleGroup: () => notifier.toggleClarityGroup(g.grades),
      onToggleGrade: notifier.toggleClarityGrade,
    );

    return FilterGroupCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: FilterSectionHeader(
                  title: context.tr(CatalogL10n.clarity),
                  infoText: context.tr(CatalogL10n.clarityCardsHelp),
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  AppHaptics.selection();
                  allSelected
                      ? notifier.clearClarityGrades()
                      : notifier.selectAllClarityGrades();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.bronze,
                  side: BorderSide(color: AppColors.border(context)),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.r8),
                  ),
                ),
                child: Text(
                  context.tr(
                    allSelected ? CatalogL10n.clear : CatalogL10n.selectAll,
                  ),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.bronze,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          LayoutBuilder(
            builder: (context, constraints) {
              final n = _clarityGroups.length;
              // Wide layouts fit every card in one row; phones scroll.
              if (constraints.maxWidth >= n * 132 + (n - 1) * _gap) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < n; i++) ...[
                        if (i > 0) const SizedBox(width: _gap),
                        Expanded(child: card(_clarityGroups[i])),
                      ],
                    ],
                  ),
                );
              }
              return SizedBox(
                height: 176,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: n,
                  separatorBuilder: (_, _) => const SizedBox(width: _gap),
                  itemBuilder: (context, i) => SizedBox(
                    width: _cardWidth,
                    child: card(_clarityGroups[i]),
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

class _ClarityCard extends StatelessWidget {
  const _ClarityCard({
    required this.group,
    required this.selected,
    required this.onToggleGroup,
    required this.onToggleGrade,
  });

  final _ClarityGroup group;
  final List<String> selected;
  final VoidCallback onToggleGroup;
  final ValueChanged<String> onToggleGrade;

  @override
  Widget build(BuildContext context) {
    final picked = group.grades.where(selected.contains).length;
    final full = picked == group.grades.length;
    final any = picked > 0;
    final ink = AppColors.textPrimary(context);

    return Semantics(
      button: true,
      selected: full,
      label: group.grades.join(', '),
      child: Material(
        color: AppColors.card(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.r12),
          side: BorderSide(
            color: any ? AppColors.bronze : AppColors.border(context),
            width: any ? 1.6 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            AppHaptics.selection();
            onToggleGroup();
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: any ? 1.04 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: SvgPicture.asset(
                    group.asset,
                    width: 96,
                    height: 96,
                    theme: SvgTheme(currentColor: ink),
                    placeholderBuilder: (_) =>
                        const SizedBox.square(dimension: 96),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (var i = 0; i < group.grades.length; i++) ...[
                      if (i > 0) const SizedBox(width: 5),
                      Expanded(
                        child: _ClarityGradePill(
                          grade: group.grades[i],
                          selected: selected.contains(group.grades[i]),
                          onTap: () {
                            AppHaptics.selection();
                            onToggleGrade(group.grades[i]);
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClarityGradePill extends StatelessWidget {
  const _ClarityGradePill({
    required this.grade,
    required this.selected,
    required this.onTap,
  });

  final String grade;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.selectedFill(context)
              : AppColors.field(context),
          borderRadius: BorderRadius.circular(AppSpacing.r8),
          border: Border.all(
            color: selected
                ? AppColors.selectedFill(context)
                : AppColors.border(context),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              grade,
              style: AppTypography.caption.copyWith(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? AppColors.onSelected(context)
                    : AppColors.textPrimary(context),
              ),
            ),
          ),
        ),
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
            const SizedBox(width: 5),
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
              child: Icon(
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
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
