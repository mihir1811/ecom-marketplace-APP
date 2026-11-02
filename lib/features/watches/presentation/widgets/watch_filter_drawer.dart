import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/widgets/catalog_search_filter_shell.dart';
import '../../../../core/widgets/filters/catalog_availability_filter.dart';
import '../../../../core/widgets/filters/filter_boolean_checkbox.dart';
import '../../../../core/widgets/filters/filter_chip.dart';
import '../../../../core/widgets/filters/filter_chip_scroll_row.dart';
import '../../../../core/widgets/filters/filter_section_header.dart';
import '../../../../core/widgets/luxe/luxe_chip_group.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_finder.dart';
import '../../../../core/widgets/luxe/luxe_multi_select_field.dart';
import '../../../../core/widgets/luxe/luxe_range_fields.dart';
import '../../application/brand_watch_filter_provider.dart';
import '../../application/brand_watch_list_provider.dart';
import '../../application/watch_filter_provider.dart';
import '../../application/watch_list_provider.dart';
import '../../data/repositories/watch_brand_assets_data.dart';
import '../../domain/models/watch_brand_categories.dart';
import '../../domain/models/watch_filter_state.dart';
import '../../domain/models/watch_filter_summary.dart';
import 'watch_dial_style_index_grid.dart';
import 'watch_filter_labels.dart';
import 'watch_filter_swatch_pills.dart';

/// Watch filters on the shared luxe finder layout: editorial intro, pinned
/// section index, collapsible sections with live counts and a sticky
/// Reset / Show results bar.
///
/// Edits a draft that is applied on "Show results". When [lockedBrand] is
/// set, brand multi-select is hidden and models are scoped to that brand
/// (brand catalog page).
class WatchFilterDrawer extends ConsumerStatefulWidget {
  const WatchFilterDrawer({super.key, this.lockedBrand});

  final String? lockedBrand;

  @override
  ConsumerState<WatchFilterDrawer> createState() => _WatchFilterDrawerState();
}

class _WatchFilterDrawerState extends ConsumerState<WatchFilterDrawer>
    with
        CatalogSearchScrollMixin,
        LuxeFinderMixin<WatchFilterDrawer, WatchFilterSection> {
  @override
  final ScrollController catalogScrollController = ScrollController();
  @override
  final GlobalKey catalogNavKey = GlobalKey();
  @override
  double get catalogNavHeight => 56;

  @override
  List<WatchFilterSection> get finderVisibleSections =>
      WatchFilterSection.values;

  bool get _isBrandLocked =>
      widget.lockedBrand != null && widget.lockedBrand!.trim().isNotEmpty;

  String get _lockedBrandName => widget.lockedBrand!.trim();

  NotifierProvider<WatchFilterStateMutator, WatchFilterState>
  get _draftProvider =>
      _isBrandLocked ? brandWatchFilterDraftProvider : watchFilterDraftProvider;

  WatchFilterStateMutator get _n => ref.read(_draftProvider.notifier);

  @override
  void initState() {
    super.initState();
    catalogScrollController.addListener(finderOnScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isBrandLocked) {
        ref.read(brandWatchFilterDraftProvider.notifier).syncFromApplied();
      } else {
        ref.read(watchFilterDraftProvider.notifier).syncFromApplied();
      }
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

  /// Popular houses first, then every other brand alphabetically.
  static final List<String> _brandOptions = () {
    const popular = WatchFilterState.popularBrandOptions;
    final rest = watchBrandCategories
        .expand((g) => g.brands)
        .where((b) => !popular.contains(b))
        .toList();
    return [...popular, ...rest];
  }();

  List<String> _modelOptions(WatchFilterState draft) {
    const byBrand = WatchCatalogBrands.modelsByBrand;
    if (_isBrandLocked) {
      return List<String>.from(byBrand[_lockedBrandName] ?? const [])..sort();
    }
    if (draft.brands.isEmpty) {
      return byBrand.values.expand((m) => m).toSet().toList()..sort();
    }
    final models = <String>{};
    for (final brand in draft.brands) {
      models.addAll(byBrand[brand] ?? const []);
    }
    return models.toList()..sort();
  }

  void _reset() {
    final previous = ref.read(_draftProvider);
    _n.resetDraftKeepingSearch();
    showLuxeToast(
      context,
      context.tr(DiamondFlowL10n.filtersCleared),
      actionLabel: context.tr(DiamondFlowL10n.undo),
      onAction: () => _n.replaceDraft(previous),
    );
  }

  void _showResults() {
    if (_isBrandLocked) {
      ref.read(brandWatchFilterDraftProvider.notifier).apply();
      ref.read(brandWatchListProvider.notifier).refresh();
    } else {
      ref.read(watchFilterDraftProvider.notifier).apply();
      ref.read(watchListProvider.notifier).refresh();
    }
    context.goBack();
  }

  @override
  Widget build(BuildContext context) {
    return LuxeScope(child: Builder(builder: _buildScaffold));
  }

  Widget _buildScaffold(BuildContext context) {
    final draft = ref.watch(_draftProvider);
    final summary = WatchFilterSummary.of(draft);
    return LuxeFinderScaffold<WatchFilterSection>(
      title: _isBrandLocked ? _lockedBrandName : '',
      onBack: () => context.goBack(),
      sections: WatchFilterSection.values,
      active: finderActive,
      labelOf: (s) => watchSectionTitle(context, s),
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
    WatchFilterSection s,
    WatchFilterState d,
    WatchFilterSummary summary,
  ) {
    final (icon, child) = switch (s) {
      WatchFilterSection.brandModel => (
        Icons.workspace_premium_outlined,
        _brandModel(context, d),
      ),
      WatchFilterSection.style => (
        Icons.style_outlined,
        _stack([
          _scrollChips(
            null,
            WatchFilterState.styleOptions,
            d.categories,
            _n.toggleStyle,
          ),
          _scrollChips(
            context.tr(CatalogL10n.gender),
            WatchFilterState.genderOptions,
            d.genders,
            _n.toggleGender,
          ),
        ]),
      ),
      WatchFilterSection.price => (
        Icons.payments_outlined,
        LuxeRangeFields(
          min: d.priceMin,
          max: d.priceMax,
          prefix: '${AppCurrency.symbol} ',
          minLabel: context.tr(CatalogFlowL10n.min),
          maxLabel: context.tr(CatalogFlowL10n.max),
          invalidLabel: context.tr(CatalogFlowL10n.invalidRange),
          onChanged: (min, max) => _n.setPriceRange(min: min, max: max),
        ),
      ),
      WatchFilterSection.movement => (
        Icons.settings_outlined,
        _stack([
          _dropdown(
            context,
            context.tr(CatalogL10n.movement),
            WatchFilterState.movementOptions,
            d.movements,
            _n.toggleMovement,
          ),
          _dropdown(
            context,
            'Features',
            WatchFilterState.configurationOptions,
            d.configurations,
            _n.toggleConfiguration,
          ),
          _dropdown(
            context,
            'Special Features',
            WatchFilterState.materialOptions,
            d.materials,
            _n.toggleMaterial,
          ),
          _dropdown(
            context,
            'Power Reserve',
            WatchFilterState.powerReserveOptions,
            d.powerReserves,
            _n.togglePowerReserve,
          ),
          _dropdown(
            context,
            'Water Resistance',
            WatchFilterState.waterResistanceOptions,
            d.waterResistances,
            _n.toggleWaterResistance,
          ),
        ]),
      ),
      WatchFilterSection.caseBezel => (
        Icons.crop_square_rounded,
        _stack([
          _scrollChips(
            'Case Shape',
            WatchFilterState.caseShapeOptions,
            d.caseShapes,
            _n.toggleCaseShape,
          ),
          _scrollChips(
            'Case Size',
            WatchFilterState.caseSizeRangeOptions,
            d.caseSizeRanges,
            _n.toggleCaseSizeRange,
          ),
          _swatches(
            'Case Material',
            WatchFilterState.caseMaterialOptions,
            d.caseMaterials,
            _n.toggleCaseMaterial,
          ),
          _scrollChips(
            'Lug Width',
            WatchFilterState.lugWidthOptions,
            d.lugWidths,
            _n.toggleLugWidth,
          ),
          _scrollChips(
            'Bezel Type',
            WatchFilterState.bezelTypeOptions,
            d.bezelTypes,
            _n.toggleBezelType,
          ),
          _swatches(
            'Bezel Material',
            WatchFilterState.bezelMaterialOptions,
            d.bezelMaterials,
            _n.toggleBezelMaterial,
          ),
        ]),
      ),
      WatchFilterSection.dial => (
        Icons.watch_outlined,
        _stack([
          _swatches(
            'Dial Color',
            WatchFilterState.dialColorOptions,
            d.dialColors,
            _n.toggleDialColor,
          ),
          _chips(
            context,
            'Precious Stone Type',
            WatchFilterState.preciousStoneTypeOptions,
            d.preciousStoneTypes,
            _n.togglePreciousStoneType,
          ),
          _chips(
            context,
            'Glass',
            WatchFilterState.glassMaterialOptions,
            d.glassMaterials,
            _n.toggleGlassMaterial,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FilterSectionHeader(title: 'Dial Style / Indexes'),
              WatchDialStyleIndexGrid(
                selected: d.indexes,
                onToggle: _n.toggleIndexes,
                padding: const EdgeInsets.only(top: 6),
              ),
            ],
          ),
        ]),
      ),
      WatchFilterSection.strap => (
        Icons.link_rounded,
        _stack([
          _swatches(
            'Strap Material',
            WatchFilterState.strapMaterialOptions,
            d.strapMaterials,
            _n.toggleStrapMaterial,
          ),
          _swatches(
            'Strap Color',
            WatchFilterState.strapColorOptions,
            d.strapColors,
            _n.toggleStrapColor,
          ),
          _chips(
            context,
            'Clasp Type',
            WatchFilterState.claspTypeOptions,
            d.claspTypes,
            _n.toggleClaspType,
          ),
          _swatches(
            'Clasp Material',
            WatchFilterState.claspMaterialOptions,
            d.claspMaterials,
            _n.toggleClaspMaterial,
          ),
          _chips(
            context,
            context.tr(CatalogL10n.crown),
            WatchFilterState.crownTypeOptions,
            d.crownTypes,
            _n.toggleCrownType,
          ),
        ]),
      ),
      WatchFilterSection.condition => (
        Icons.verified_outlined,
        _stack([
          _chips(
            context,
            context.tr(CatalogL10n.condition),
            WatchFilterState.conditionOptions,
            d.conditions,
            _n.toggleCondition,
          ),
          _chips(
            context,
            context.tr(CatalogL10n.modelYear),
            WatchFilterState.modelYearOptions,
            d.modelYears,
            _n.toggleModelYear,
            initialVisible: 8,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilterSectionHeader(
                title: context.tr(CatalogL10n.authentication),
              ),
              FilterBooleanCheckbox(
                label: context.tr(CatalogL10n.boxIncluded),
                value: d.boxIncluded,
                onChanged: (v) => _n.setBoxIncluded(v ?? false),
              ),
              FilterBooleanCheckbox(
                label: context.tr(CatalogL10n.papersIncluded),
                value: d.papersIncluded,
                onChanged: (v) => _n.setPapersIncluded(v ?? false),
              ),
              FilterBooleanCheckbox(
                label: context.tr(CatalogL10n.warrantyCard),
                value: d.warrantyCardIncluded,
                onChanged: (v) => _n.setWarrantyCardIncluded(v ?? false),
              ),
              FilterBooleanCheckbox(
                label: context.tr(CatalogL10n.fullSetOnly),
                value: d.fullSetIncluded,
                onChanged: (v) => _n.setFullSetIncluded(v ?? false),
              ),
            ],
          ),
          _chips(
            context,
            'Certification',
            WatchFilterState.certificationOptions,
            d.certifications,
            _n.toggleCertification,
          ),
        ]),
      ),
      WatchFilterSection.listing => (
        Icons.tune_rounded,
        _stack([
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CatalogAvailabilityFilter(
                value: d.selectedAvailability,
                options: WatchFilterState.availabilityOptions,
                onChanged: _n.updateAvailability,
              ),
              const SizedBox(height: 4),
              FilterBooleanCheckbox(
                label: context.tr(CatalogL10n.makeOffer),
                value: d.makeAnOffer,
                onChanged: (v) => _n.setMakeAnOffer(v ?? false),
              ),
            ],
          ),
          _chips(
            context,
            context.tr(CatalogL10n.withMedia),
            WatchFilterState.withMediaOptions,
            d.withMedia,
            _n.toggleWithMedia,
          ),
        ]),
      ),
    };

    final essential =
        s == WatchFilterSection.brandModel ||
        s == WatchFilterSection.style ||
        s == WatchFilterSection.price;
    return finderSection(
      s,
      title: watchSectionTitle(context, s),
      icon: icon,
      count: summary.count(s),
      initiallyExpanded: essential,
      names: s == WatchFilterSection.brandModel
          ? [...d.brands, ...d.models]
          : const [],
      child: child,
    );
  }

  Widget _brandModel(BuildContext context, WatchFilterState d) {
    final p = LuxePalette.of(context);
    return _stack([
      if (_isBrandLocked)
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const FilterSectionHeader(title: 'Brand'),
            const SizedBox(height: 5),
            Text(_lockedBrandName, style: LuxeType.display(22, p.ink)),
          ],
        )
      else
        _dropdown(
          context,
          'Brand',
          _brandOptions,
          d.brands,
          _n.toggleBrand,
          hint: context.tr(CatalogL10n.selectBrands),
          searchHint: context.tr(CatalogL10n.searchBrands),
        ),
      _dropdown(
        context,
        'Model',
        _modelOptions(d),
        d.models,
        _n.toggleModel,
        hint: context.tr(CatalogL10n.selectModels),
      ),
    ]);
  }

  /// Multi-select dropdown (searchable once the list is long).
  Widget _dropdown(
    BuildContext context,
    String title,
    List<String> options,
    Set<String> selected,
    void Function(String) onToggle, {
    String? hint,
    String? searchHint,
  }) {
    final picked = [
      for (final o in options)
        if (selected.contains(o)) o,
      // Picks no longer in the list (e.g. models of a brand that was
      // unselected) stay visible and removable.
      for (final o in selected)
        if (!options.contains(o)) o,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilterSectionHeader(title: title),
        const SizedBox(height: 6),
        LuxeMultiSelectField(
          options: options,
          selected: picked,
          onChanged: (next) => applyMultiSelectToggles(picked, next, onToggle),
          hint: hint ?? context.tr(CatalogL10n.selectAny),
          sheetTitle: title,
          searchHint: searchHint,
        ),
      ],
    );
  }

  /// One sideways-scrolling line of chips.
  Widget _scrollChips(
    String? title,
    List<String> options,
    Set<String> selected,
    void Function(String) onToggle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) ...[
          FilterSectionHeader(title: title),
          const SizedBox(height: 6),
        ],
        FilterChipScrollRow(
          children: [
            for (final o in options)
              FilterChipWidget(
                label: o,
                isSelected: selected.contains(o),
                onTap: () => onToggle(o),
              ),
          ],
        ),
      ],
    );
  }

  Widget _stack(List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const SizedBox(height: 14),
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
    String? emptyLabel,
  }) {
    return LuxeChipGroup(
      title: title,
      options: options,
      selected: selected,
      onToggle: onToggle,
      initialVisible: initialVisible,
      searchHint: searchHint,
      emptyLabel: emptyLabel,
      showAllLabel: context.tr(CatalogFlowL10n.showAll),
      showLessLabel: context.tr(CatalogFlowL10n.showLess),
    );
  }

  Widget _swatches(
    String title,
    List<String> options,
    Set<String> selected,
    void Function(String) onToggle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilterSectionHeader(title: title),
        WatchFilterSwatchPillGrid(
          options: options,
          selected: selected,
          onToggle: onToggle,
          padding: const EdgeInsets.only(top: 8),
        ),
      ],
    );
  }
}
