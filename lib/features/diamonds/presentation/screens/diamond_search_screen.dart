import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/widgets/catalog_search_filter_shell.dart';
import '../../../../core/widgets/filters/catalog_expandable_advanced_filters.dart';
import '../../../../core/widgets/filters/catalog_measurement_filters.dart';
import '../../../../core/widgets/filters/catalog_preferences_filters.dart';
import '../../../../core/widgets/filters/catalog_search_add_field.dart';
import '../../../../core/widgets/filters/filter_proportion_diagram.dart';
import '../../../../core/widgets/filters/filter_section_header.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_finder.dart';
import '../../../../core/widgets/luxe/luxe_multi_select_field.dart';
import '../../application/diamond_list_provider.dart';
import '../../application/diamond_search_provider.dart';
import '../../domain/models/diamond_catalog_type.dart';
import '../../domain/models/diamond_filter_state.dart';
import '../../domain/models/diamond_filter_summary.dart';
import '../../../catalog_flow/presentation/widgets/catalog_flow_actions.dart';
import '../../../../core/widgets/filters/filter_section_divider.dart';
import '../widgets/diamond_shape_picker.dart';
import '../widgets/filter_category_basic.dart';
import '../widgets/filter_color_selector.dart';

/// Diamond finder (natural and lab grown).
///
/// Layout: editorial header with the catalog mode switch → pinned section
/// index → shape, listing preferences, then the essentials (size & price,
/// colour & clarity) open by
/// default → refinements in collapsible sections that report how many
/// filters each holds → sticky "Show diamonds" bar with the active count.
class DiamondSearchScreen extends ConsumerStatefulWidget {
  const DiamondSearchScreen({
    super.key,
    this.catalog = DiamondCatalogType.natural,
    this.title = 'DIAMOND FINDER',
    this.resultsRoute = AppRouteNames.diamondResults,
  });

  final DiamondCatalogType catalog;
  final String title;
  final String resultsRoute;

  @override
  ConsumerState<DiamondSearchScreen> createState() =>
      _DiamondSearchScreenState();
}

class _DiamondSearchScreenState extends ConsumerState<DiamondSearchScreen>
    with
        CatalogSearchScrollMixin,
        LuxeFinderMixin<DiamondSearchScreen, DiamondFinderSection> {
  @override
  final ScrollController catalogScrollController = ScrollController();
  @override
  final GlobalKey catalogNavKey = GlobalKey();
  @override
  double get catalogNavHeight => 56;

  final _companyController = TextEditingController();
  final _locationController = TextEditingController();

  /// Whether the company / location fields currently add exclusions.
  bool _excludeCompany = false;
  bool _excludeLocation = false;

  bool get _isLab => widget.catalog == DiamondCatalogType.labGrown;

  @override
  void initState() {
    super.initState();
    catalogScrollController.addListener(finderOnScroll);
  }

  @override
  void dispose() {
    catalogScrollController
      ..removeListener(finderOnScroll)
      ..dispose();
    disposeFinder();
    _companyController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  List<DiamondFinderSection> get finderVisibleSections => _visibleSections(
    diamondUsesMeleeFilters(ref.read(diamondSearchProvider), isLab: _isLab),
  );

  List<DiamondFinderSection> _visibleSections(bool melee) => [
    DiamondFinderSection.shape,
    DiamondFinderSection.listing,
    DiamondFinderSection.sizePrice,
    DiamondFinderSection.colorClarity,
    if (!melee) DiamondFinderSection.grading,
    if (!melee) DiamondFinderSection.inclusions,
    DiamondFinderSection.seller,
    DiamondFinderSection.measurements,
    if (!melee) DiamondFinderSection.proportions,
  ];

  void _commitPendingSearchFields() {
    final notifier = ref.read(diamondSearchProvider.notifier);
    final company = _companyController.text.trim();
    final location = _locationController.text.trim();
    if (company.isNotEmpty) {
      notifier.addCompanyName(company, exclude: _excludeCompany);
      _companyController.clear();
    }
    if (location.isNotEmpty) {
      notifier.addVendorLocation(location, exclude: _excludeLocation);
      _locationController.clear();
    }
  }

  void _onShowDiamonds() {
    _commitPendingSearchFields();
    // Drop cached pages so results always refetch with current filters.
    ref.invalidate(diamondListProvider);
    context.push(widget.resultsRoute);
  }

  void _resetAll() {
    final notifier = ref.read(diamondSearchProvider.notifier);
    final previous = ref.read(diamondSearchProvider);
    notifier.reset();
    _companyController.clear();
    _locationController.clear();
    showLuxeToast(
      context,
      context.tr(DiamondFlowL10n.filtersCleared),
      actionLabel: context.tr(DiamondFlowL10n.undo),
      onAction: () => notifier.replaceFilters(previous),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Keep text fields in sync when filters are reset from the results screen.
    ref.listen<DiamondFilterState>(diamondSearchProvider, (previous, next) {
      if (next.companyNames.isEmpty &&
          next.excludedCompanyNames.isEmpty &&
          _companyController.text.isNotEmpty) {
        _companyController.clear();
      }
      if (next.vendorLocations.isEmpty &&
          next.excludedVendorLocations.isEmpty &&
          _locationController.text.isNotEmpty) {
        _locationController.clear();
      }
    });

    return LuxeScope(
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) context.resetTo(AppRouteNames.home);
        },
        child: Builder(builder: _buildScaffold),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final melee = ref.watch(
      diamondSearchProvider.select(
        (s) => diamondUsesMeleeFilters(s, isLab: _isLab),
      ),
    );
    final summary = ref.watch(
      diamondSearchProvider.select(DiamondFilterSummary.of),
    );
    final sections = _visibleSections(melee);
    final background = AppColors.screenBgFor(context, melee: melee);

    return LuxeFinderScaffold<DiamondFinderSection>(
      eyebrow: context.tr(DiamondFlowL10n.finderEyebrow),
      title: widget.catalog.label,
      onBack: () => context.resetTo(AppRouteNames.home),
      actions: const [CatalogFlowActions()],
      background: background,
      intro: _intro(context),
      sections: sections,
      active: finderActive,
      labelOf: (s) => _title(context, s),
      countOf: summary.count,
      pillKeyOf: finderPillKey,
      onJump: finderJumpTo,
      navKey: catalogNavKey,
      sectionBuilder: (s) => _section(context, s, summary, melee),
      scrollController: catalogScrollController,
      scrollOffset: finderOffset,
      onScrollNotification: catalogHandleScrollNotification,
      actionBar: LuxeFinderActionBar(
        activeCount: summary.total,
        onReset: summary.total == 0 ? null : _resetAll,
        onShow: _onShowDiamonds,
        showLabel: context.tr(CatalogL10n.showDiamonds),
        resetLabel: context.tr(DiamondFlowL10n.reset),
      ),
    );
  }

  Widget _intro(BuildContext context) {
    return LuxeFinderIntro(
      headline: context.tr(
        _isLab
            ? DiamondFlowL10n.finderHeadlineLab
            : DiamondFlowL10n.finderHeadlineNatural,
      ),
      intro: context.tr(DiamondFlowL10n.finderIntro),
      controls: DiamondCatalogModeControls(
        showOriginToggle: !_isLab,
        isLabCatalog: _isLab,
      ),
    );
  }

  String _title(BuildContext context, DiamondFinderSection s) => context.tr(
    switch (s) {
      DiamondFinderSection.shape => DiamondFlowL10n.sectionShape,
      DiamondFinderSection.sizePrice => DiamondFlowL10n.sectionSizePrice,
      DiamondFinderSection.colorClarity => DiamondFlowL10n.sectionColorClarity,
      DiamondFinderSection.grading => DiamondFlowL10n.sectionGrading,
      DiamondFinderSection.inclusions => DiamondFlowL10n.sectionInclusions,
      DiamondFinderSection.listing => DiamondFlowL10n.sectionListing,
      DiamondFinderSection.seller => DiamondFlowL10n.sectionSeller,
      DiamondFinderSection.measurements => DiamondFlowL10n.sectionMeasurements,
      DiamondFinderSection.proportions => DiamondFlowL10n.sectionProportions,
    },
  );

  Widget _section(
    BuildContext context,
    DiamondFinderSection s,
    DiamondFilterSummary summary,
    bool melee,
  ) {
    final count = summary.count(s);
    final essential =
        s == DiamondFinderSection.shape ||
        s == DiamondFinderSection.listing ||
        s == DiamondFinderSection.sizePrice ||
        s == DiamondFinderSection.colorClarity;
    final (icon, child) = switch (s) {
      DiamondFinderSection.shape => (
        Icons.diamond_outlined,
        const DiamondShapePicker(),
      ),
      DiamondFinderSection.sizePrice => (
        Icons.scale_outlined,
        DiamondSizePriceFilters(isLabCatalog: _isLab),
      ),
      DiamondFinderSection.colorClarity => (
        Icons.palette_outlined,
        const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColorTabsSelector(),
            FilterSectionDivider(),
            ClarityCardsSection(),
          ],
        ),
      ),
      DiamondFinderSection.grading => (
        Icons.workspace_premium_outlined,
        const DiamondGradingFilters(),
      ),
      DiamondFinderSection.inclusions => (
        Icons.blur_on_rounded,
        const DiamondInclusionFilters(),
      ),
      DiamondFinderSection.listing => (
        Icons.tune_rounded,
        DiamondListingOptionsFilters(isLabCatalog: _isLab),
      ),
      DiamondFinderSection.seller => (
        Icons.storefront_outlined,
        _buildPreferenceFilters(),
      ),
      DiamondFinderSection.measurements => (
        Icons.straighten_rounded,
        _buildMeasurementFilters(),
      ),
      DiamondFinderSection.proportions => (
        Icons.change_history_rounded,
        _buildAdvancedFilters(),
      ),
    };

    return finderSection(
      s,
      title: _title(context, s),
      icon: icon,
      count: count,
      initiallyExpanded: essential,
      names: s == DiamondFinderSection.shape
          ? ref.read(diamondSearchProvider).shapes
          : const [],
      child: child,
    );
  }

  Widget _buildPreferenceFilters() {
    final state = ref.watch(diamondSearchProvider);
    final notifier = ref.read(diamondSearchProvider.notifier);

    final includeExcludeHelp = context.tr(CatalogL10n.includeExcludeHelp);
    return CatalogPreferencesFilters(
      locationField: CatalogSearchAddField(
        title: context.tr(CatalogL10n.vendorLocation),
        infoText:
            'Search for diamonds located in a specific city, state, or region. '
            '$includeExcludeHelp',
        hintText: context.tr(CatalogL10n.searchLocation),
        excludeHintText: context.tr(CatalogL10n.excludeLocationHint),
        controller: _locationController,
        clearOnAdd: true,
        values: state.vendorLocations,
        excludedValues: state.excludedVendorLocations,
        onAdd: notifier.addVendorLocation,
        onAddExcluded: (v) => notifier.addVendorLocation(v, exclude: true),
        onRemove: notifier.removeVendorLocation,
        excludeMode: _excludeLocation,
        onExcludeModeChanged: (v) => setState(() => _excludeLocation = v),
      ),
      originDropdown: _isLab
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilterSectionHeader(
                  title: context.tr(CatalogL10n.originCountry),
                  infoText: context.tr(CatalogL10n.diamondOriginCountryHelp),
                ),
                const SizedBox(height: 8),
                LuxeMultiSelectField(
                  options: DiamondFilterState.countries,
                  selected: state.selectedOrigins,
                  onChanged: notifier.setOrigins,
                  hint: context.tr(CatalogL10n.selectOriginCountries),
                  sheetTitle: context.tr(CatalogL10n.originCountry),
                  searchHint: context.tr(CatalogL10n.searchCountries),
                  leadingOf: (c) {
                    final flag = DiamondFilterState.countryFlags[c];
                    return flag == null
                        ? null
                        : Text(flag, style: const TextStyle(fontSize: 18));
                  },
                ),
              ],
            ),
      roughSourceOptions: _isLab ? null : DiamondFilterState.roughSources,
      selectedRoughSources: state.selectedRoughSources,
      onRoughSourcesChanged: _isLab ? null : notifier.setRoughSources,
      minSellerRating: state.minSellerRating,
      onSellerRatingChanged: notifier.updateSellerRating,
      companyField: CatalogSearchAddField(
        title: context.tr(CatalogL10n.companyName),
        infoText:
            '${context.tr(CatalogL10n.diamondCompanyHelp)} $includeExcludeHelp',
        hintText: context.tr(CatalogL10n.searchCompany),
        excludeHintText: context.tr(CatalogL10n.excludeCompanyHint),
        controller: _companyController,
        clearOnAdd: true,
        values: state.companyNames,
        excludedValues: state.excludedCompanyNames,
        onAdd: notifier.addCompanyName,
        onAddExcluded: (v) => notifier.addCompanyName(v, exclude: true),
        onRemove: notifier.removeCompanyName,
        excludeMode: _excludeCompany,
        onExcludeModeChanged: (v) => setState(() => _excludeCompany = v),
      ),
    );
  }

  Widget _buildMeasurementFilters() {
    final state = ref.watch(diamondSearchProvider);
    final notifier = ref.read(diamondSearchProvider.notifier);

    return CatalogMeasurementFilters(
      lengthMin: state.minLength,
      lengthMax: state.maxLength,
      onLengthMinChanged: (v) => notifier.updateLengthRange(v, state.maxLength),
      onLengthMaxChanged: (v) => notifier.updateLengthRange(state.minLength, v),
      widthMin: state.minWidth,
      widthMax: state.maxWidth,
      onWidthMinChanged: (v) => notifier.updateWidthRange(v, state.maxWidth),
      onWidthMaxChanged: (v) => notifier.updateWidthRange(state.minWidth, v),
      heightMin: state.minHeight,
      heightMax: state.maxHeight,
      onHeightMinChanged: (v) => notifier.updateHeightRange(v, state.maxHeight),
      onHeightMaxChanged: (v) => notifier.updateHeightRange(state.minHeight, v),
      ratioMin: state.minRatio,
      ratioMax: state.maxRatio,
      onRatioMinChanged: (v) => notifier.updateRatioRange(v, state.maxRatio),
      onRatioMaxChanged: (v) => notifier.updateRatioRange(state.minRatio, v),
      dimensionLimits: (
        DiamondFilterState.dimensionMin,
        DiamondFilterState.dimensionMax,
      ),
      ratioLimits: (
        DiamondFilterState.ratioMin,
        DiamondFilterState.ratioMax,
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    final state = ref.watch(diamondSearchProvider);
    final notifier = ref.read(diamondSearchProvider.notifier);

    return CatalogExpandableAdvancedFilters(
      expandAdvanced: true,
      ranges: [
        CatalogAdvancedRangeSpec(
          title: context.tr(CatalogL10n.tablePercentage),
          currentMin: state.minTable,
          currentMax: state.maxTable,
          minLimit: DiamondFilterState.tableMin,
          maxLimit: DiamondFilterState.tableMax,
          unit: '%',
          infoText:
              'Filter by table width percentage relative to total diameter.',
          infoDiagram: FilterProportionDiagramKind.table,
          onMinChanged: (v) => notifier.updateTableRange(v, state.maxTable),
          onMaxChanged: (v) => notifier.updateTableRange(state.minTable, v),
        ),
        CatalogAdvancedRangeSpec(
          title: context.tr(CatalogL10n.depthPercentage),
          currentMin: state.minDepth,
          currentMax: state.maxDepth,
          minLimit: DiamondFilterState.depthMin,
          maxLimit: DiamondFilterState.depthMax,
          unit: '%',
          infoText:
              'Filter by total depth percentage relative to total diameter.',
          infoDiagram: FilterProportionDiagramKind.depth,
          onMinChanged: (v) => notifier.updateDepthRange(v, state.maxDepth),
          onMaxChanged: (v) => notifier.updateDepthRange(state.minDepth, v),
        ),
        CatalogAdvancedRangeSpec(
          title: context.tr(CatalogL10n.crownAngleRange),
          currentMin: state.minCrownAngle,
          currentMax: state.maxCrownAngle,
          minLimit: DiamondFilterState.crownAngleMin,
          maxLimit: DiamondFilterState.crownAngleMax,
          unit: '°',
          infoText: context.tr(CatalogL10n.crownAngleHelp),
          infoDiagram: FilterProportionDiagramKind.crownAngle,
          onMinChanged: (v) =>
              notifier.updateCrownAngleRange(v, state.maxCrownAngle),
          onMaxChanged: (v) =>
              notifier.updateCrownAngleRange(state.minCrownAngle, v),
        ),
        CatalogAdvancedRangeSpec(
          title: context.tr(CatalogL10n.crownHeightRange),
          currentMin: state.minCrownHeight,
          currentMax: state.maxCrownHeight,
          minLimit: DiamondFilterState.crownHeightMin,
          maxLimit: DiamondFilterState.crownHeightMax,
          unit: '%',
          infoText: context.tr(CatalogL10n.crownHeightHelp),
          infoDiagram: FilterProportionDiagramKind.crownHeight,
          onMinChanged: (v) =>
              notifier.updateCrownHeightRange(v, state.maxCrownHeight),
          onMaxChanged: (v) =>
              notifier.updateCrownHeightRange(state.minCrownHeight, v),
        ),
        CatalogAdvancedRangeSpec(
          title: context.tr(CatalogL10n.pavilionAngleRange),
          currentMin: state.minPavilionAngle,
          currentMax: state.maxPavilionAngle,
          minLimit: DiamondFilterState.pavilionAngleMin,
          maxLimit: DiamondFilterState.pavilionAngleMax,
          unit: '°',
          infoText: context.tr(CatalogL10n.pavilionAngleHelp),
          infoDiagram: FilterProportionDiagramKind.pavilionAngle,
          onMinChanged: (v) =>
              notifier.updatePavilionAngleRange(v, state.maxPavilionAngle),
          onMaxChanged: (v) =>
              notifier.updatePavilionAngleRange(state.minPavilionAngle, v),
        ),
        CatalogAdvancedRangeSpec(
          title: context.tr(CatalogL10n.pavilionDepthRange),
          currentMin: state.minPavilionDepth,
          currentMax: state.maxPavilionDepth,
          minLimit: DiamondFilterState.pavilionDepthMin,
          maxLimit: DiamondFilterState.pavilionDepthMax,
          unit: '%',
          infoText: context.tr(CatalogL10n.pavilionDepthHelp),
          infoDiagram: FilterProportionDiagramKind.pavilionDepth,
          onMinChanged: (v) =>
              notifier.updatePavilionDepthRange(v, state.maxPavilionDepth),
          onMaxChanged: (v) =>
              notifier.updatePavilionDepthRange(state.minPavilionDepth, v),
        ),
      ],
      chipSections: [
        CatalogAdvancedChipSpec(
          title: context.tr(CatalogL10n.girdle),
          options: DiamondFilterState.girdles,
          selectedItems: state.selectedGirdles,
          onToggle: notifier.toggleGirdle,
          infoText: context.tr(CatalogL10n.girdleHelp),
          infoDiagram: FilterProportionDiagramKind.girdle,
        ),
        CatalogAdvancedChipSpec(
          title: context.tr(CatalogL10n.culetSize),
          options: DiamondFilterState.culets,
          selectedItems: state.selectedCulets,
          onToggle: notifier.toggleCulet,
          infoText: context.tr(CatalogL10n.culetHelp),
          infoDiagram: FilterProportionDiagramKind.culet,
        ),
      ],
    );
  }
}
