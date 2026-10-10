import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/widgets/catalog_search_filter_shell.dart';
import '../../../../core/widgets/filters/catalog_availability_filter.dart';
import '../../../../core/widgets/filters/filter_boolean_checkbox.dart';
import '../../../../core/widgets/filters/filter_range_slider.dart';
import '../../../../core/widgets/filters/filter_section_header.dart';
import '../../../../core/widgets/luxe/luxe_chip_group.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_finder.dart';
import '../../../../core/widgets/luxe/luxe_layout.dart';
import '../../../../core/widgets/luxe/luxe_metal_swatch.dart';
import '../../../../core/widgets/luxe/luxe_shape_picker.dart';
import '../../../diamonds/presentation/widgets/diamond_shape_picker.dart';
import '../../application/jewelry_filter_provider.dart';
import '../../application/jewelry_list_provider.dart';
import '../../domain/models/jewelry_filter_state.dart';
import '../../domain/models/jewelry_filter_summary.dart';
import '../widgets/jewelry_filter_labels.dart';

/// Jewelry filters on the shared luxe finder layout: editorial intro,
/// pinned section index, collapsible sections with live counts and a
/// sticky Reset / Show results bar.
///
/// Edits a draft that is applied on "Show results". Size filters appear
/// only for collections that have them (rings, bracelets, chains,
/// necklaces).
class JewelryFilterScreen extends ConsumerStatefulWidget {
  const JewelryFilterScreen({super.key});

  @override
  ConsumerState<JewelryFilterScreen> createState() =>
      _JewelryFilterScreenState();
}

class _JewelryFilterScreenState extends ConsumerState<JewelryFilterScreen>
    with
        CatalogSearchScrollMixin,
        LuxeFinderMixin<JewelryFilterScreen, JewelryFilterSection> {
  @override
  final ScrollController catalogScrollController = ScrollController();
  @override
  final GlobalKey catalogNavKey = GlobalKey();
  @override
  double get catalogNavHeight => 56;

  @override
  List<JewelryFilterSection> get finderVisibleSections {
    final category = ref.read(jewelryFilterDraftProvider).category;
    final sized = jewelrySizeKindsFor(category).isNotEmpty;
    return [
      for (final s in JewelryFilterSection.values)
        if (s != JewelryFilterSection.size || sized) s,
    ];
  }

  JewelryFilterDraftNotifier get _n =>
      ref.read(jewelryFilterDraftProvider.notifier);

  @override
  void initState() {
    super.initState();
    catalogScrollController.addListener(finderOnScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _n.syncFromApplied();
    });
  }

  @override
  void dispose() {
    catalogScrollController
      ..removeListener(finderOnScroll)
      ..dispose();
    disposeFinder();
    super.dispose();
  }

  void _reset() {
    final previous = ref.read(jewelryFilterDraftProvider);
    _n.reset();
    showLuxeToast(
      context,
      context.tr(DiamondFlowL10n.filtersCleared),
      actionLabel: context.tr(DiamondFlowL10n.undo),
      onAction: () => _n.replaceDraft(previous),
    );
  }

  void _showResults() {
    _n.apply();
    ref.read(jewelryListProvider.notifier).refresh();
    context.goBack();
  }

  @override
  Widget build(BuildContext context) {
    return LuxeScope(child: Builder(builder: _buildScaffold));
  }

  Widget _buildScaffold(BuildContext context) {
    final draft = ref.watch(jewelryFilterDraftProvider);
    final summary = JewelryFilterSummary.of(draft);
    return LuxeFinderScaffold<JewelryFilterSection>(
      title: jewelryCollectionTitle(context, draft.category),
      onBack: () => context.goBack(),
      sections: finderVisibleSections,
      active: finderActive,
      labelOf: (s) => jewelrySectionTitle(context, s),
      countOf: summary.count,
      pillKeyOf: finderPillKey,
      onJump: finderJumpTo,
      navKey: catalogNavKey,
      sectionBuilder: (s) => _section(context, s, draft, summary),
      scrollController: catalogScrollController,
      scrollOffset: finderOffset,
      onScrollNotification: catalogHandleScrollNotification,
      actionBar: LuxeFinderActionBar(
        activeCount: summary.total,
        onReset: summary.total == 0 ? null : _reset,
        onShow: _showResults,
        showLabel: context.tr(CatalogL10n.showResults),
        resetLabel: context.tr(DiamondFlowL10n.reset),
      ),
    );
  }

  Widget _section(
    BuildContext context,
    JewelryFilterSection s,
    JewelryFilterState d,
    JewelryFilterSummary summary,
  ) {
    final (icon, child) = switch (s) {
      JewelryFilterSection.style => (
        Icons.auto_awesome_outlined,
        _stack([
          _chips(
            context,
            context.tr(CatalogL10n.gender),
            JewelryFilterState.genderOptions,
            d.genders,
            _n.toggleGender,
          ),
          _chips(
            context,
            context.tr(CatalogL10n.occasion),
            JewelryFilterState.occasionOptions,
            d.occasions,
            _n.toggleOccasion,
            initialVisible: 8,
          ),
        ]),
      ),
      JewelryFilterSection.price => (
        Icons.payments_outlined,
        FilterRangeSlider(
          title: context.tr(CatalogL10n.price),
          minLimit: JewelryFilterState.priceMinLimit,
          maxLimit: JewelryFilterState.priceMaxLimit,
          currentMin: d.priceMin,
          currentMax: d.priceMax,
          unitPrefix: AppCurrency.symbol,
          isInteger: true,
          onChanged: _n.setPriceRange,
          onClear: _n.clearPriceRange,
        ),
      ),
      JewelryFilterSection.metal => (
        Icons.blur_circular_rounded,
        _stack([
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilterSectionHeader(title: context.tr(CatalogL10n.metalColor)),
              const SizedBox(height: 12),
              LuxeMetalSwatchPicker(
                options: JewelryFilterState.metalColorOptions,
                selected: d.metalColors,
                onToggle: _n.toggleMetalColor,
                labelOf: context.trCatalogValue,
              ),
            ],
          ),
          _chips(
            context,
            context.tr(CatalogL10n.metalType),
            JewelryFilterState.metalTypeOptions,
            d.metalTypes,
            _n.toggleMetalType,
          ),
          _chips(
            context,
            context.tr(CatalogL10n.metalPurity),
            JewelryFilterState.metalPurityOptions,
            d.metalPurities,
            _n.toggleMetalPurity,
          ),
          FilterRangeSlider(
            title: context.tr(CatalogL10n.metalWeight),
            minLimit: JewelryFilterState.metalWeightMinLimit,
            maxLimit: JewelryFilterState.metalWeightMaxLimit,
            currentMin: d.metalWeightMin,
            currentMax: d.metalWeightMax,
            unitSuffix: 'g',
            isInteger: true,
            onChanged: _n.setMetalWeight,
            onClear: _n.clearMetalWeight,
          ),
          _chips(
            context,
            context.tr(CatalogL10n.metalFinish),
            JewelryFilterState.metalFinishOptions,
            d.metalFinishes,
            _n.toggleMetalFinish,
            initialVisible: 5,
          ),
          _chips(
            context,
            context.tr(CatalogL10n.plating),
            JewelryFilterState.platingOptions,
            d.platings,
            _n.togglePlating,
            initialVisible: 4,
          ),
        ]),
      ),
      JewelryFilterSection.stone => (
        Icons.diamond_outlined,
        _stack([
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilterSectionHeader(title: context.tr(CatalogL10n.stoneType)),
              const SizedBox(height: 10),
              LuxeSegmented<String?>(
                options: const [null, ...JewelryFilterState.stoneTypeOptions],
                selected: d.stoneType,
                labelOf: (o) => o == null
                    ? context.tr(DiamondFlowL10n.any)
                    : context.trCatalogValue(o),
                onChanged: (o) =>
                    o == null ? _n.clearStoneType() : _n.setStoneType(o),
              ),
            ],
          ),
          _chips(
            context,
            context.tr(CatalogL10n.stoneCategory),
            JewelryFilterState.stoneCategoryOptions,
            d.stoneCategories,
            _n.toggleStoneCategory,
            initialVisible: 6,
            searchHint: context.tr(CatalogL10n.search),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilterSectionHeader(title: context.tr(CatalogL10n.stoneShape)),
              const SizedBox(height: 10),
              LuxeShapePicker(
                shapes: [
                  for (final name in JewelryFilterState.stoneShapeOptions)
                    LuxeShapeOption(
                      value: name,
                      label: context.trCatalogValue(name),
                      image: shapePhotoFor(name),
                    ),
                ],
                selected: d.stoneShapes.toList(),
                onToggle: _n.toggleStoneShape,
                iconBuilder: shapeOutlineIcon,
                expandLabel: context.tr(DiamondFlowL10n.allShapes),
                collapseLabel: context.tr(DiamondFlowL10n.fewerShapes),
              ),
            ],
          ),
          FilterRangeSlider(
            title: context.tr(CatalogL10n.stoneWeight),
            minLimit: JewelryFilterState.stoneWeightMinLimit,
            maxLimit: JewelryFilterState.stoneWeightMaxLimit,
            currentMin: d.stoneWeightMin,
            currentMax: d.stoneWeightMax,
            unitSuffix: 'ct',
            onChanged: _n.setStoneWeight,
            onClear: _n.clearStoneWeight,
          ),
          _chips(
            context,
            context.tr(CatalogL10n.stoneColor),
            JewelryFilterState.stoneColorOptions,
            d.stoneColors,
            _n.toggleStoneColor,
          ),
          _chips(
            context,
            context.tr(CatalogL10n.stoneClarity),
            JewelryFilterState.stoneClarityOptions,
            d.stoneClarities,
            _n.toggleStoneClarity,
          ),
          _chips(
            context,
            context.tr(CatalogL10n.stoneSetting),
            JewelryFilterState.stoneSettingOptions,
            d.stoneSettings,
            _n.toggleStoneSetting,
          ),
        ]),
      ),
      JewelryFilterSection.size => (
        Icons.straighten_rounded,
        _stack([
          for (final kind in jewelrySizeKindsFor(d.category))
            switch (kind) {
              JewelrySizeKind.ring => _chips(
                context,
                context.tr(CatalogL10n.ringSize),
                JewelryFilterState.ringSizeOptions,
                d.ringSizes,
                _n.toggleRingSize,
              ),
              JewelrySizeKind.braceletSize => _chips(
                context,
                context.tr(CatalogL10n.braceletSize),
                JewelryFilterState.braceletSizeOptions,
                d.braceletSizes,
                _n.toggleBraceletSize,
              ),
              JewelrySizeKind.braceletLength => _chips(
                context,
                context.tr(CatalogL10n.braceletLength),
                JewelryFilterState.braceletLengthOptions,
                d.braceletLengths,
                _n.toggleBraceletLength,
              ),
              JewelrySizeKind.chain => _chips(
                context,
                context.tr(CatalogL10n.chainLength),
                JewelryFilterState.chainLengthOptions,
                d.chainLengths,
                _n.toggleChainLength,
              ),
              JewelrySizeKind.necklace => _chips(
                context,
                context.tr(CatalogL10n.necklaceLength),
                JewelryFilterState.necklaceLengthOptions,
                d.necklaceLengths,
                _n.toggleNecklaceLength,
              ),
            },
        ]),
      ),
      JewelryFilterSection.quality => (
        Icons.verified_outlined,
        _stack([
          _chips(
            context,
            context.tr(CatalogL10n.certification),
            JewelryFilterState.certificationOptions,
            d.certifications,
            _n.toggleCertification,
            initialVisible: 6,
          ),
          _chips(
            context,
            context.tr(CatalogL10n.condition),
            JewelryFilterState.conditionOptions,
            d.conditions,
            _n.toggleCondition,
          ),
        ]),
      ),
      JewelryFilterSection.listing => (
        Icons.tune_rounded,
        _stack([
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CatalogAvailabilityFilter(
                value: d.selectedAvailability,
                options: JewelryFilterState.availabilityOptions,
                onChanged: _n.updateAvailability,
              ),
              const SizedBox(height: 4),
              FilterBooleanCheckbox(
                label: context.tr(CatalogL10n.makeOffer),
                value: d.makeAnOffer,
                onChanged: (v) => _n.setMakeAnOffer(v ?? false),
              ),
              FilterBooleanCheckbox(
                label: context.tr(CatalogL10n.mediaOnly),
                value: d.withMediaOnly,
                onChanged: (v) => _n.setWithMediaOnly(v ?? false),
              ),
            ],
          ),
          _chips(
            context,
            context.tr(CatalogL10n.deliveryTime),
            JewelryFilterState.deliveryTimeOptions,
            {?d.deliveryTime},
            (v) => _n.setDeliveryTime(d.deliveryTime == v ? null : v),
          ),
        ]),
      ),
    };

    final essential =
        s == JewelryFilterSection.style ||
        s == JewelryFilterSection.price ||
        s == JewelryFilterSection.metal;
    return finderSection(
      s,
      title: jewelrySectionTitle(context, s),
      icon: icon,
      count: summary.count(s),
      initiallyExpanded: essential,
      names: switch (s) {
        JewelryFilterSection.style => [...d.genders, ...d.occasions],
        JewelryFilterSection.metal
            when d.metalTypes.isEmpty &&
                d.metalFinishes.isEmpty &&
                d.platings.isEmpty =>
          [...d.metalColors, ...d.metalPurities],
        _ => const [],
      },
      child: child,
    );
  }

  Widget _stack(List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const SizedBox(height: 22),
        children[i],
      ],
    ],
  );

  Widget _chips(
    BuildContext context,
    String? title,
    List<String> options,
    Set<String> selected,
    void Function(String) onToggle, {
    int? initialVisible,
    String? searchHint,
  }) {
    return LuxeChipGroup(
      title: title,
      options: options,
      selected: selected,
      onToggle: onToggle,
      labelOf: context.trCatalogValue,
      initialVisible: initialVisible,
      searchHint: searchHint,
      showAllLabel: context.tr(CatalogFlowL10n.showAll),
      showLessLabel: context.tr(CatalogFlowL10n.showLess),
    );
  }
}
