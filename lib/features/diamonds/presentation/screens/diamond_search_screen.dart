import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/catalog_search_filter_layout.dart';
import '../../../../core/widgets/catalog_search_filter_shell.dart';
import '../../../../core/widgets/paired_showcase_carousel.dart';
import '../../../../core/widgets/showcase_select_card.dart';
import '../../../../core/widgets/filters/catalog_expandable_advanced_filters.dart';
import '../../../../core/widgets/filters/catalog_measurement_filters.dart';
import '../../../../core/widgets/filters/catalog_preferences_filters.dart';
import '../../../../core/widgets/filters/catalog_search_add_field.dart';
import '../../application/diamond_list_provider.dart';
import '../../application/diamond_search_provider.dart';
import '../../domain/models/diamond_catalog_type.dart';
import '../../domain/models/diamond_filter_state.dart';
import '../widgets/diamond_svg_data.dart';
import '../widgets/filter_category_basic.dart';
import '../widgets/filter_origin_dropdown.dart';

enum Section { basic, preferences, measurements, advanced }

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
    with CatalogSearchScrollMixin {
  @override
  final ScrollController catalogScrollController = ScrollController();
  @override
  final GlobalKey catalogNavKey = GlobalKey();

  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  Section _activeSection = Section.basic;
  bool _expandAdvanced = false;

  final GlobalKey _basicKey = GlobalKey();
  final GlobalKey _prefKey = GlobalKey();
  final GlobalKey _measKey = GlobalKey();
  final GlobalKey _advancedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    catalogScrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    catalogScrollController.removeListener(_onScroll);
    catalogScrollController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (catalogSpyLocked) return;
    final filterState = ref.read(diamondSearchProvider);
    final useMeleeFilters = _usesMeleeFilters(filterState);
    final active =
        catalogActiveSectionFromScroll([
          (_basicKey, Section.basic),
          (_prefKey, Section.preferences),
          (_measKey, Section.measurements),
          if (!useMeleeFilters) (_advancedKey, Section.advanced),
        ]) ??
        Section.basic;
    if (active != _activeSection) {
      setState(() => _activeSection = active);
    }
  }

  bool _usesMeleeFilters(DiamondFilterState state) {
    if (widget.catalog == DiamondCatalogType.labGrown) {
      return state.labCategory == 'Lab Melee';
    }
    return state.labNatural.usesMeleeFilters;
  }

  void _commitPendingSearchFields() {
    final notifier = ref.read(diamondSearchProvider.notifier);
    final company = _companyController.text.trim();
    final location = _locationController.text.trim();
    if (company.isNotEmpty) {
      notifier.addCompanyName(company);
      _companyController.clear();
    }
    if (location.isNotEmpty) {
      notifier.addVendorLocation(location);
      _locationController.clear();
    }
  }

  void _onShowDiamonds() {
    _commitPendingSearchFields();
    // Drop any cached pages so results always refetch with current filters.
    ref.invalidate(diamondListProvider);
    context.push(widget.resultsRoute);
  }

  @override
  Widget build(BuildContext context) {
    // Keep text fields in sync when filters are reset from the results screen.
    ref.listen<DiamondFilterState>(diamondSearchProvider, (previous, next) {
      if (next.companyNames.isEmpty && _companyController.text.isNotEmpty) {
        _companyController.clear();
      }
      if (next.vendorLocations.isEmpty && _locationController.text.isNotEmpty) {
        _locationController.clear();
      }
    });

    final useMeleeFilters = ref.watch(
      diamondSearchProvider.select(_usesMeleeFilters),
    );

    if (useMeleeFilters && _activeSection == Section.advanced) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _activeSection = Section.basic);
      });
    }

    final sections = <CatalogSearchNavSection<Section>>[
      CatalogSearchNavSection(
        id: Section.basic,
        label: context.tr(CatalogL10n.basic),
        icon: Icons.diamond_outlined,
        key: _basicKey,
      ),
      CatalogSearchNavSection(
        id: Section.preferences,
        label: context.tr(CatalogL10n.prefShort),
        icon: Icons.tune,
        key: _prefKey,
      ),
      CatalogSearchNavSection(
        id: Section.measurements,
        label: context.tr(CatalogL10n.measurementsShort),
        icon: Icons.straighten,
        key: _measKey,
      ),
      if (!useMeleeFilters)
        CatalogSearchNavSection(
          id: Section.advanced,
          label: context.tr(CatalogL10n.advancedShort),
          icon: Icons.add,
          key: _advancedKey,
        ),
    ];

    return CatalogSearchFilterShell(
      title: widget.title,
      isMelee: useMeleeFilters,
      meleeFamily: widget.catalog.isLabGrown
          ? MeleeBgFamily.labGrown
          : MeleeBgFamily.natural,
      onScrollNotification: catalogHandleScrollNotification,
      stickyNav: CatalogSearchSectionNav<Section>(
        navKey: catalogNavKey,
        sections: sections,
        activeId: _activeSection,
        onSectionTap: (section) {
          setState(() {
            _activeSection = section.id;
            if (section.id == Section.advanced) {
              _expandAdvanced = true;
            }
          });
          catalogScrollToSection(section.key);
          if (section.id == Section.advanced) {
            Future.delayed(const Duration(milliseconds: 350), () {
              if (mounted) setState(() => _expandAdvanced = false);
            });
          }
        },
      ),
      scrollController: catalogScrollController,
      primaryLabel: context.tr(CatalogL10n.showDiamonds),
      onPrimary: _onShowDiamonds,
      onClear: () {
        ref.read(diamondSearchProvider.notifier).reset();
        _companyController.clear();
        _locationController.clear();
      },
      bodyChildren: [
        _buildShapeCarousel(),
        const SizedBox(height: AppSpacing.s24),
        CatalogSearchSection(
          sectionKey: _basicKey,
          title: context.tr(CatalogL10n.basic),
          child: FilterCategoryBasic(
            sectionTitle: widget.catalog.label,
            showOriginToggle: widget.catalog == DiamondCatalogType.natural,
            isLabCatalog: widget.catalog == DiamondCatalogType.labGrown,
          ),
        ),
        const SizedBox(height: AppSpacing.s32),
        CatalogSearchSection(
          sectionKey: _prefKey,
          title: context.tr(CatalogL10n.preferences),
          child: _buildPreferenceFilters(),
        ),
        const SizedBox(height: AppSpacing.s32),
        CatalogSearchSection(
          sectionKey: _measKey,
          title: context.tr(CatalogL10n.measurements),
          child: _buildMeasurementFilters(),
        ),
        if (!useMeleeFilters) ...[
          const SizedBox(height: AppSpacing.s32),
          CatalogSearchSection(
            sectionKey: _advancedKey,
            title: context.tr(CatalogL10n.advanced),
            child: _buildAdvancedFilters(),
          ),
        ],
        const SizedBox(height: AppSpacing.s32),
      ],
    );
  }

  Widget _buildShapeCarousel() {
    final shapes = ref.watch(diamondSearchProvider.select((s) => s.shapes));
    final notifier = ref.read(diamondSearchProvider.notifier);

    return PairedShowcaseCarousel(
      title: context.tr(CatalogL10n.selectDiamondShapes),
      itemCount: kAllShapes.length,
      itemBuilder: (context, index) {
        final item = kAllShapes[index];
        final name = item['name']!;
        final imagePath = item['image'];
        final isSelected = shapes.contains(name);
        final fallback = renderShapeSvg(
          name,
          size: 48,
          color: isSelected ? AppColors.bronze : AppColors.bronzeLight,
        );

        return ShowcaseSelectCard(
          name: name,
          isSelected: isSelected,
          onTap: () => notifier.toggleShape(name),
          media: imagePath != null
              ? Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => fallback,
                )
              : fallback,
        );
      },
    );
  }

  Widget _buildPreferenceFilters() {
    final state = ref.watch(diamondSearchProvider);
    final notifier = ref.read(diamondSearchProvider.notifier);

    return CatalogPreferencesFilters(
      locationField: CatalogSearchAddField(
        title: context.tr(CatalogL10n.vendorLocation),
        infoText:
            'Search for diamonds located in a specific city, state, or region.',
        hintText: context.tr(CatalogL10n.searchLocation),
        controller: _locationController,
        clearOnAdd: true,
        values: state.vendorLocations,
        onAdd: notifier.addVendorLocation,
        onRemove: notifier.removeVendorLocation,
      ),
      originDropdown: FilterOriginDropdown(
        selectedOrigin: state.selectedOrigin,
        onSelected: notifier.updateOriginCountry,
      ),
      roughSourceOptions: DiamondFilterState.roughSources,
      selectedRoughSource: state.selectedRoughSource,
      onRoughSourceChanged: notifier.updateRoughSource,
      minSellerRating: state.minSellerRating,
      onSellerRatingChanged: notifier.updateSellerRating,
      companyField: CatalogSearchAddField(
        title: context.tr(CatalogL10n.companyName),
        infoText: context.tr(CatalogL10n.diamondCompanyHelp),
        hintText: context.tr(CatalogL10n.searchCompany),
        controller: _companyController,
        clearOnAdd: true,
        values: state.companyNames,
        onAdd: notifier.addCompanyName,
        onRemove: notifier.removeCompanyName,
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
    );
  }

  Widget _buildAdvancedFilters() {
    final state = ref.watch(diamondSearchProvider);
    final notifier = ref.read(diamondSearchProvider.notifier);

    return CatalogExpandableAdvancedFilters(
      expandAdvanced: _expandAdvanced,
      ranges: [
        CatalogAdvancedRangeSpec(
          title: context.tr(CatalogL10n.tablePercentage),
          currentMin: state.minTable,
          currentMax: state.maxTable,
          unit: '%',
          infoText:
              'Filter by table width percentage relative to total diameter.',
          onMinChanged: (v) => notifier.updateTableRange(v, state.maxTable),
          onMaxChanged: (v) => notifier.updateTableRange(state.minTable, v),
        ),
        CatalogAdvancedRangeSpec(
          title: context.tr(CatalogL10n.depthPercentage),
          currentMin: state.minDepth,
          currentMax: state.maxDepth,
          unit: '%',
          infoText:
              'Filter by total depth percentage relative to total diameter.',
          onMinChanged: (v) => notifier.updateDepthRange(v, state.maxDepth),
          onMaxChanged: (v) => notifier.updateDepthRange(state.minDepth, v),
        ),
        CatalogAdvancedRangeSpec(
          title: context.tr(CatalogL10n.crownAngleRange),
          currentMin: state.minCrownAngle,
          currentMax: state.maxCrownAngle,
          unit: '°',
          infoText: context.tr(CatalogL10n.crownAngleHelp),
          onMinChanged: (v) =>
              notifier.updateCrownAngleRange(v, state.maxCrownAngle),
          onMaxChanged: (v) =>
              notifier.updateCrownAngleRange(state.minCrownAngle, v),
        ),
        CatalogAdvancedRangeSpec(
          title: context.tr(CatalogL10n.crownHeightRange),
          currentMin: state.minCrownHeight,
          currentMax: state.maxCrownHeight,
          unit: '%',
          infoText: context.tr(CatalogL10n.crownHeightHelp),
          onMinChanged: (v) =>
              notifier.updateCrownHeightRange(v, state.maxCrownHeight),
          onMaxChanged: (v) =>
              notifier.updateCrownHeightRange(state.minCrownHeight, v),
        ),
        CatalogAdvancedRangeSpec(
          title: context.tr(CatalogL10n.pavilionAngleRange),
          currentMin: state.minPavilionAngle,
          currentMax: state.maxPavilionAngle,
          unit: '°',
          infoText: context.tr(CatalogL10n.pavilionAngleHelp),
          onMinChanged: (v) =>
              notifier.updatePavilionAngleRange(v, state.maxPavilionAngle),
          onMaxChanged: (v) =>
              notifier.updatePavilionAngleRange(state.minPavilionAngle, v),
        ),
        CatalogAdvancedRangeSpec(
          title: context.tr(CatalogL10n.pavilionDepthRange),
          currentMin: state.minPavilionDepth,
          currentMax: state.maxPavilionDepth,
          unit: '%',
          infoText: context.tr(CatalogL10n.pavilionDepthHelp),
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
        ),
        CatalogAdvancedChipSpec(
          title: context.tr(CatalogL10n.culetSize),
          options: DiamondFilterState.culets,
          selectedItems: state.selectedCulets,
          onToggle: notifier.toggleCulet,
          infoText: context.tr(CatalogL10n.culetHelp),
        ),
      ],
    );
  }
}
