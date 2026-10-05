import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/filters/catalog_availability_filter.dart';
import '../../../../core/widgets/filters/catalog_standard_range_filters.dart';
import '../../../../core/widgets/filters/filter_boolean_checkbox.dart';
import '../../../../core/widgets/filters/filter_scrollable_chips.dart';
import '../../../../core/widgets/filters/filter_section_header.dart';
import '../../../../core/widgets/filters/melee_range_filters.dart';
import '../../../../core/widgets/luxe/luxe_chip_group.dart';
import '../../../../core/widgets/luxe/luxe_layout.dart';
import '../../../../core/widgets/luxe/luxe_shape_dial.dart';
import '../../../../core/widgets/luxe/luxe_shape_picker.dart';
import '../../../diamonds/presentation/widgets/diamond_shape_picker.dart'
    show shapeOutlineIcon, shapePhotoFor;
import '../../application/gemstone_search_provider.dart';
import '../../domain/gemstone_assets.dart';
import '../../domain/models/gemstone_filter_state.dart';
import 'birthstone_month_card.dart';

/// Featured gemstone types shown as photo tiles before the full list.
const List<String> kFeaturedGemstones = [
  'Ruby',
  'Sapphire',
  'Emerald',
  'Diamond',
  'Tanzanite',
  'Amethyst',
  'Aquamarine',
  'Opal',
  'Tourmaline',
  'Garnet',
  'Peridot',
  'Topaz',
  'Citrine',
  'Pearl',
  'Moonstone',
  'Lapis Lazuli',
];

bool gemstoneIsMelee(GemstoneFilterState s) => s.lotType == 'Melee';

/// Natural / lab grown and single / melee switches for the finder intro.
class GemstoneCatalogModeControls extends ConsumerWidget {
  const GemstoneCatalogModeControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stoneType = ref.watch(
      gemstoneSearchProvider.select((s) => s.stoneType),
    );
    final lotType = ref.watch(gemstoneSearchProvider.select((s) => s.lotType));
    final notifier = ref.read(gemstoneSearchProvider.notifier);
    return Row(
      children: [
        Expanded(
          child: LuxeSegmented<String>(
            options: GemstoneFilterState.stoneTypes,
            selected: stoneType ?? GemstoneFilterState.stoneTypes.first,
            onChanged: notifier.updateStoneType,
            dense: true,
            labelOf: (v) => context.tr(
              v == 'Natural' ? CatalogL10n.natural : CatalogL10n.labGrown,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: LuxeSegmented<String>(
            options: GemstoneFilterState.lotTypes,
            selected: lotType ?? GemstoneFilterState.lotTypes.first,
            onChanged: notifier.updateLotType,
            dense: true,
            labelOf: (v) => context.tr(
              v == 'Single' ? CatalogL10n.single : CatalogL10n.melee,
            ),
          ),
        ),
      ],
    );
  }
}

/// Gemstone type: featured photo tiles, a searchable list of every type and
/// the birthstone calendar.
class GemstoneTypeFilters extends ConsumerWidget {
  const GemstoneTypeFilters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = LuxePalette.of(context);
    final selected = ref.watch(
      gemstoneSearchProvider.select((s) => s.selectedGemstoneTypes),
    );
    final months = ref.watch(
      gemstoneSearchProvider.select((s) => s.selectedBirthstoneMonths),
    );
    final notifier = ref.read(gemstoneSearchProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr(GemstoneFlowL10n.popularGems).toUpperCase(),
          style: LuxeType.eyebrow(p.inkMuted),
        ),
        const SizedBox(height: 10),
        LuxeShapeDialPicker(
          shapes: [
            for (final name in kFeaturedGemstones)
              LuxeShapeOption(
                value: name,
                label: name,
                image: gemstoneImagePath(name),
              ),
          ],
          selected: selected,
          onToggle: notifier.toggleGemstoneType,
          iconBuilder: (value, _, size) =>
              GemstoneHueOrb(hue: gemstoneHue(value), size: size + 8),
          selectLabel: (gem) =>
              context.tr(DiamondFlowL10n.selectShape, {'shape': gem}),
          selectedLabel: (gem) =>
              context.tr(DiamondFlowL10n.shapeSelected, {'shape': gem}),
        ),
        const SizedBox(height: 14),
        LuxeChipGroup(
          title: context.tr(CatalogL10n.gemstoneType),
          options: GemstoneFilterState.allGemstoneTypes,
          selected: selected,
          onToggle: notifier.toggleGemstoneType,
          initialVisible: 12,
          searchHint: context.tr(CatalogL10n.searchGemstoneTypes),
          emptyLabel: context.tr(CatalogL10n.noGemstones),
          showAllLabel: context.tr(CatalogFlowL10n.showAll),
          showLessLabel: context.tr(CatalogL10n.viewLess),
        ),
        const SizedBox(height: 16),
        FilterSectionHeader(
          title: context.tr(CatalogL10n.birthstones),
          infoText: context.tr(CatalogL10n.birthstonesHelp),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 8.0;
            final columns = constraints.maxWidth > 520 ? 6 : 4;
            final w = ((constraints.maxWidth - gap * (columns - 1)) / columns)
                .floorToDouble();
            return Wrap(
              alignment: WrapAlignment.center,
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final e in GemstoneFilterState.birthstones.entries)
                  SizedBox(
                    width: w,
                    height: w / 1.5,
                    child: BirthstoneMonthCard(
                      month: e.key,
                      gemstone: e.value,
                      isSelected: months.contains(e.key),
                      onTap: () => notifier.toggleBirthstoneMonth(e.key),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Soft radial orb in a gem's hue, used when no photo exists.
class GemstoneHueOrb extends StatelessWidget {
  const GemstoneHueOrb({required this.hue, super.key, this.size = 42});

  final Color hue;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.4, -0.4),
          colors: [
            Color.lerp(hue, Colors.white, 0.55)!,
            hue,
            Color.lerp(hue, Colors.black, 0.25)!,
          ],
          stops: const [0.0, 0.65, 1.0],
        ),
      ),
      child: Icon(
        Icons.diamond_outlined,
        size: size * 0.45,
        color: Colors.white.withValues(alpha: 0.55),
      ),
    );
  }
}

/// Gemstone shapes on the shared [LuxeShapeDialPicker], drawn with the closest
/// diamond shape artwork.
class GemstoneShapePicker extends ConsumerWidget {
  const GemstoneShapePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      gemstoneSearchProvider.select((s) => s.selectedShapes),
    );
    const art = GemstoneFilterState.shapeSvgNames;
    return LuxeShapeDialPicker(
      shapes: [
        for (final name in GemstoneFilterState.shapes)
          LuxeShapeOption(
            value: name,
            label: context.trCatalogValue(name),
            image: shapePhotoFor(art[name] ?? name),
          ),
      ],
      selected: selected,
      onToggle: ref.read(gemstoneSearchProvider.notifier).toggleShape,
      iconBuilder: (value, color, size) =>
          shapeOutlineIcon(art[value] ?? value, color, size),
      selectLabel: (shape) =>
          context.tr(DiamondFlowL10n.selectShape, {'shape': shape}),
      selectedLabel: (shape) =>
          context.tr(DiamondFlowL10n.shapeSelected, {'shape': shape}),
      expandLabel: context.tr(DiamondFlowL10n.allShapes),
      collapseLabel: context.tr(DiamondFlowL10n.fewerShapes),
    );
  }
}

/// Size & price: per-piece ranges for melee lots, carat / total price /
/// price-per-carat with quick carat ranges for single stones.
class GemstoneSizePriceFilters extends ConsumerWidget {
  const GemstoneSizePriceFilters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gemstoneSearchProvider);
    final notifier = ref.read(gemstoneSearchProvider.notifier);
    if (gemstoneIsMelee(state)) {
      return MeleeRangeFilters(
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
      );
    }
    return CatalogStandardRangeFilters(
      totalPriceMin: state.minTotalPrice,
      totalPriceMax: state.maxTotalPrice,
      totalPriceLimits: (
        GemstoneFilterState.priceMin,
        GemstoneFilterState.totalPriceMax,
      ),
      onTotalPriceChanged: notifier.updateTotalPriceRange,
      totalCaratMin: state.minTotalCarat,
      totalCaratMax: state.maxTotalCarat,
      totalCaratLimits: (
        GemstoneFilterState.caratMin,
        GemstoneFilterState.caratMax,
      ),
      onTotalCaratChanged: notifier.updateTotalCaratRange,
      caratQuickRanges: GemstoneFilterState.caratQuickRanges,
      selectedCaratQuickRanges: state.selectedCaratQuickRanges,
      onToggleCaratQuickRange: notifier.toggleCaratQuickRange,
      // Single-stone price per carat is sent as the per-piece range.
      pricePerCaratMin: state.minPricePerPiece,
      pricePerCaratMax: state.maxPricePerPiece,
      pricePerCaratLimits: (
        GemstoneFilterState.priceMin,
        GemstoneFilterState.pricePerPieceMax,
      ),
      onPricePerCaratChanged: notifier.updatePricePerPieceRange,
      pricePerCaratTitle: 'Price Per Carat',
    );
  }
}

/// Certifying lab, cut grade and treatments (single stones).
class GemstoneGradingFilters extends ConsumerWidget {
  const GemstoneGradingFilters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gemstoneSearchProvider);
    final notifier = ref.read(gemstoneSearchProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilterScrollableChips(
          wrapWithCard: false,
          title: context.tr(CatalogL10n.certification),
          options: GemstoneFilterState.certifications,
          selectedItems: state.selectedCertifications,
          onToggle: notifier.toggleCertification,
          infoText:
              'Filter by the gemological laboratory that certified the stone.',
        ),
        const SizedBox(height: 20),
        FilterScrollableChips(
          wrapWithCard: false,
          title: context.tr(CatalogL10n.cutGrade),
          options: GemstoneFilterState.cutGrades,
          selectedItems: state.selectedCutGrades,
          onToggle: notifier.toggleCutGrade,
          infoText: context.tr(CatalogL10n.gemstoneCutHelp),
        ),
        const SizedBox(height: 20),
        LuxeChipGroup(
          title: context.tr(CatalogL10n.treatments),
          infoText: 'Filter by enhancement processes applied to the gemstone.',
          options: GemstoneFilterState.treatments,
          selected: state.selectedTreatments,
          onToggle: notifier.toggleTreatment,
          initialVisible: 8,
          showAllLabel: context.tr(CatalogFlowL10n.showAll),
          showLessLabel: context.tr(CatalogL10n.viewLess),
        ),
      ],
    );
  }
}

/// Separable (melee), media, offer and availability listing options.
class GemstoneListingOptionsFilters extends ConsumerWidget {
  const GemstoneListingOptionsFilters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gemstoneSearchProvider);
    final notifier = ref.read(gemstoneSearchProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (gemstoneIsMelee(state))
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
        const SizedBox(height: 16),
        CatalogAvailabilityFilter(
          value: state.selectedAvailability,
          options: GemstoneFilterState.availabilityOptions,
          onChanged: notifier.updateAvailability,
        ),
      ],
    );
  }
}
