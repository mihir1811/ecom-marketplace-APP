import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../spotlight/domain/spotlight_models.dart';
import '../../../spotlight/presentation/widgets/spotlight_category_block.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/widgets/catalog_search_filter_shell.dart';
import '../../../../core/widgets/filters/catalog_measurement_filters.dart';
import '../../../../core/widgets/filters/catalog_preferences_filters.dart';
import '../../../../core/widgets/filters/catalog_search_add_field.dart';
import '../../../../core/widgets/filters/filter_section_header.dart';
import '../../../../core/widgets/luxe/luxe_multi_select_field.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_finder.dart';
import '../../../../core/widgets/navigation/top_bar/top_bar_actions.dart';
import '../../application/gemstone_list_provider.dart';
import '../../application/gemstone_search_provider.dart';
import '../../domain/models/gemstone_filter_state.dart';
import '../../domain/models/gemstone_filter_summary.dart';
import '../widgets/gemstone_filter_category_quality.dart';
import '../widgets/gemstone_finder_filters.dart';

/// Gemstone finder, built from the same luxe finder pieces as diamonds.
///
/// Layout: editorial header with natural / lab and single / melee switches
/// → pinned section index → the essentials (gem, shape, size & price,
/// colour & quality) open by default → refinements in collapsible sections
/// that report how many filters each holds → sticky "Search gemstones" bar
/// with the active count.
class GemstoneSearchScreen extends ConsumerStatefulWidget {
  const GemstoneSearchScreen({super.key});

  @override
  ConsumerState<GemstoneSearchScreen> createState() =>
      _GemstoneSearchScreenState();
}

class _GemstoneSearchScreenState extends ConsumerState<GemstoneSearchScreen>
    with
        CatalogSearchScrollMixin,
        LuxeFinderMixin<GemstoneSearchScreen, GemstoneFinderSection> {
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
  List<GemstoneFinderSection> get finderVisibleSections =>
      _visibleSections(gemstoneIsMelee(ref.read(gemstoneSearchProvider)));

  List<GemstoneFinderSection> _visibleSections(bool melee) => [
    GemstoneFinderSection.gemType,
    GemstoneFinderSection.shape,
    GemstoneFinderSection.listing,
    GemstoneFinderSection.sizePrice,
    GemstoneFinderSection.colorQuality,
    if (!melee) GemstoneFinderSection.grading,
    GemstoneFinderSection.seller,
    GemstoneFinderSection.measurements,
  ];

  void _commitPendingSearchFields() {
    final notifier = ref.read(gemstoneSearchProvider.notifier);
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

  void _onShowGemstones() {
    _commitPendingSearchFields();
    // Drop cached pages so results always refetch with current filters.
    ref.invalidate(gemstoneListProvider);
    context.push(AppRouteNames.gemstoneResults);
  }

  void _resetAll() {
    final notifier = ref.read(gemstoneSearchProvider.notifier);
    final previous = ref.read(gemstoneSearchProvider);
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
    ref.listen<GemstoneFilterState>(gemstoneSearchProvider, (previous, next) {
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
    final melee = ref.watch(gemstoneSearchProvider.select(gemstoneIsMelee));
    final summary = ref.watch(
      gemstoneSearchProvider.select(GemstoneFilterSummary.of),
    );
    final sections = _visibleSections(melee);

    return LuxeFinderScaffold<GemstoneFinderSection>(
      title: '',
      onBack: () => context.resetTo(AppRouteNames.home),
      actions: const [TopBarActions()],
      header: const SpotlightCategoryBlock(
        category: SpotlightCategory.gemstones,
        topSpacing: 8,
        bottomSpacing: 10,
      ),
      controls: const GemstoneCatalogModeControls(),
      sections: sections,
      active: finderActive,
      labelOf: (s) => _title(context, s),
      countOf: summary.count,
      pillKeyOf: finderPillKey,
      onJump: finderJumpTo,
      navKey: catalogNavKey,
      sectionBuilder: (s) => _section(context, s, summary),
      scrollController: catalogScrollController,
      scrollOffset: finderOffset,
      onScrollNotification: catalogHandleScrollNotification,
      actionBar: LuxeFinderActionBar(
        activeCount: summary.total,
        onReset: summary.total == 0 ? null : _resetAll,
        onShow: _onShowGemstones,
        showLabel: context.tr(CatalogL10n.searchGemstones),
        resetLabel: context.tr(DiamondFlowL10n.reset),
      ),
    );
  }

  String _title(
    BuildContext context,
    GemstoneFinderSection s,
  ) => context.tr(switch (s) {
    GemstoneFinderSection.gemType => GemstoneFlowL10n.sectionGemType,
    GemstoneFinderSection.shape => DiamondFlowL10n.sectionShape,
    GemstoneFinderSection.sizePrice => DiamondFlowL10n.sectionSizePrice,
    GemstoneFinderSection.colorQuality => GemstoneFlowL10n.sectionColorQuality,
    GemstoneFinderSection.grading => GemstoneFlowL10n.sectionGrading,
    GemstoneFinderSection.listing => DiamondFlowL10n.sectionListing,
    GemstoneFinderSection.seller => DiamondFlowL10n.sectionSeller,
    GemstoneFinderSection.measurements => DiamondFlowL10n.sectionMeasurements,
  });

  Widget _section(
    BuildContext context,
    GemstoneFinderSection s,
    GemstoneFilterSummary summary,
  ) {
    final count = summary.count(s);
    final essential =
        s == GemstoneFinderSection.gemType ||
        s == GemstoneFinderSection.shape ||
        s == GemstoneFinderSection.listing ||
        s == GemstoneFinderSection.sizePrice ||
        s == GemstoneFinderSection.colorQuality;
    final (icon, child) = switch (s) {
      GemstoneFinderSection.gemType => (
        Icons.auto_awesome_outlined,
        const GemstoneTypeFilters(),
      ),
      GemstoneFinderSection.shape => (
        Icons.diamond_outlined,
        const GemstoneShapePicker(),
      ),
      GemstoneFinderSection.sizePrice => (
        Icons.scale_outlined,
        const GemstoneSizePriceFilters(),
      ),
      GemstoneFinderSection.colorQuality => (
        Icons.palette_outlined,
        const GemstoneFilterCategoryQuality(wrapWithCard: false),
      ),
      GemstoneFinderSection.grading => (
        Icons.workspace_premium_outlined,
        const GemstoneGradingFilters(),
      ),
      GemstoneFinderSection.listing => (
        Icons.tune_rounded,
        const GemstoneListingOptionsFilters(),
      ),
      GemstoneFinderSection.seller => (
        Icons.storefront_outlined,
        _buildPreferenceFilters(),
      ),
      GemstoneFinderSection.measurements => (
        Icons.straighten_rounded,
        _buildMeasurementFilters(),
      ),
    };

    final state = ref.read(gemstoneSearchProvider);
    return finderSection(
      s,
      title: _title(context, s),
      icon: icon,
      count: count,
      initiallyExpanded: essential,
      names: switch (s) {
        GemstoneFinderSection.gemType => state.selectedGemstoneTypes,
        GemstoneFinderSection.shape => state.selectedShapes,
        _ => const <String>[],
      },
      child: child,
    );
  }

  Widget _buildPreferenceFilters() {
    final state = ref.watch(gemstoneSearchProvider);
    final notifier = ref.read(gemstoneSearchProvider.notifier);
    final isLab = (state.stoneType ?? '').toLowerCase().contains('lab');

    final includeExcludeHelp = context.tr(CatalogL10n.includeExcludeHelp);
    return CatalogPreferencesFilters(
      locationField: CatalogSearchAddField(
        title: context.tr(CatalogL10n.vendorLocation),
        infoText:
            'Search for gemstones located in a specific city, state, or region. '
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
      originDropdown: isLab
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilterSectionHeader(
                  title: context.tr(CatalogL10n.originCountry),
                  infoText: context.tr(CatalogL10n.originCountryHelp),
                ),
                const SizedBox(height: 8),
                LuxeMultiSelectField(
                  options: GemstoneFilterState.origins,
                  selected: state.selectedOriginCountries,
                  onChanged: notifier.setOriginCountries,
                  hint: context.tr(CatalogL10n.selectOriginCountries),
                  sheetTitle: context.tr(CatalogL10n.originCountry),
                  searchHint: context.tr(CatalogL10n.searchCountries),
                  leadingOf: (c) {
                    final flag = GemstoneFilterState.originFlags[c];
                    return flag == null
                        ? null
                        : Text(flag, style: const TextStyle(fontSize: 18));
                  },
                ),
              ],
            ),
      companyField: CatalogSearchAddField(
        title: context.tr(CatalogL10n.companyName),
        infoText:
            '${context.tr(CatalogL10n.gemstoneCompanyHelp)} $includeExcludeHelp',
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
    final state = ref.watch(gemstoneSearchProvider);
    final notifier = ref.read(gemstoneSearchProvider.notifier);

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
        GemstoneFilterState.dimensionMin,
        GemstoneFilterState.dimensionMax,
      ),
      ratioLimits: (GemstoneFilterState.ratioMin, GemstoneFilterState.ratioMax),
    );
  }
}
