import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../../ai_chat/application/ai_chat_back_navigation.dart';
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
    final filters = ref.read(diamondSearchProvider);
    _companyController.text = filters.companyNameSearch ?? '';
    _locationController.text = filters.vendorLocationSearch ?? '';
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
    final filterState = ref.read(diamondSearchProvider);
    final useMeleeFilters = _usesMeleeFilters(filterState);
    final active = catalogActiveSectionFromScroll([
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
    // Use '' (not null) so copyWith can clear a previous company/location filter.
    notifier.updateCompanyNameSearch(company);
    notifier.updateVendorLocationSearch(location);
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
      final company = next.companyNameSearch ?? '';
      final location = next.vendorLocationSearch ?? '';
      if (_companyController.text != company) {
        _companyController.text = company;
      }
      if (_locationController.text != location) {
        _locationController.text = location;
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
        label: 'Basic',
        icon: Icons.diamond_outlined,
        key: _basicKey,
      ),
      CatalogSearchNavSection(
        id: Section.preferences,
        label: 'PREF',
        icon: Icons.tune,
        key: _prefKey,
      ),
      CatalogSearchNavSection(
        id: Section.measurements,
        label: 'MEAS',
        icon: Icons.straighten,
        key: _measKey,
      ),
      if (!useMeleeFilters)
        CatalogSearchNavSection(
          id: Section.advanced,
          label: 'ADV',
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
      onBack: () {
        if (AiChatBackNavigation.handleListingBack(context, ref)) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRouteNames.home);
        }
      },
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
      primaryLabel: 'SHOW DIAMONDS',
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
          title: 'Basic',
          child: FilterCategoryBasic(
            sectionTitle: widget.catalog.label,
            showOriginToggle: widget.catalog == DiamondCatalogType.natural,
            isLabCatalog: widget.catalog == DiamondCatalogType.labGrown,
          ),
        ),
        const SizedBox(height: AppSpacing.s32),
        CatalogSearchSection(
          sectionKey: _prefKey,
          title: 'Preferences',
          child: _buildPreferenceFilters(),
        ),
        const SizedBox(height: AppSpacing.s32),
        CatalogSearchSection(
          sectionKey: _measKey,
          title: 'Measurements',
          child: _buildMeasurementFilters(),
        ),
        if (!useMeleeFilters) ...[
          const SizedBox(height: AppSpacing.s32),
          CatalogSearchSection(
            sectionKey: _advancedKey,
            title: 'Advanced',
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
      title: 'Select Diamond\nShapes',
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
        title: "Vendor's Location",
        infoText:
            'Search for diamonds located in a specific city, state, or region.',
        hintText: 'Search by location (City, State, Country)',
        controller: _locationController,
        onAdd: () =>
            notifier.updateVendorLocationSearch(_locationController.text),
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
        title: 'Company Name',
        infoText: 'Search for diamonds supplied by a specific company name.',
        hintText: 'Search by company name',
        controller: _companyController,
        onAdd: () =>
            notifier.updateCompanyNameSearch(_companyController.text),
      ),
    );
  }

  Widget _buildMeasurementFilters() {
    final state = ref.watch(diamondSearchProvider);
    final notifier = ref.read(diamondSearchProvider.notifier);

    return CatalogMeasurementFilters(
      lengthMin: state.minLength,
      lengthMax: state.maxLength,
      onLengthMinChanged: (v) =>
          notifier.updateLengthRange(v, state.maxLength),
      onLengthMaxChanged: (v) =>
          notifier.updateLengthRange(state.minLength, v),
      widthMin: state.minWidth,
      widthMax: state.maxWidth,
      onWidthMinChanged: (v) => notifier.updateWidthRange(v, state.maxWidth),
      onWidthMaxChanged: (v) => notifier.updateWidthRange(state.minWidth, v),
      heightMin: state.minHeight,
      heightMax: state.maxHeight,
      onHeightMinChanged: (v) =>
          notifier.updateHeightRange(v, state.maxHeight),
      onHeightMaxChanged: (v) =>
          notifier.updateHeightRange(state.minHeight, v),
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
          title: 'Table Percentage',
          currentMin: state.minTable,
          currentMax: state.maxTable,
          unit: '%',
          infoText:
              'Filter by table width percentage relative to total diameter.',
          onMinChanged: (v) => notifier.updateTableRange(v, state.maxTable),
          onMaxChanged: (v) => notifier.updateTableRange(state.minTable, v),
        ),
        CatalogAdvancedRangeSpec(
          title: 'Depth Percentage',
          currentMin: state.minDepth,
          currentMax: state.maxDepth,
          unit: '%',
          infoText:
              'Filter by total depth percentage relative to total diameter.',
          onMinChanged: (v) => notifier.updateDepthRange(v, state.maxDepth),
          onMaxChanged: (v) => notifier.updateDepthRange(state.minDepth, v),
        ),
        CatalogAdvancedRangeSpec(
          title: 'Crown Angle Range',
          currentMin: state.minCrownAngle,
          currentMax: state.maxCrownAngle,
          unit: '°',
          infoText: 'Filter by average crown facet angle.',
          onMinChanged: (v) =>
              notifier.updateCrownAngleRange(v, state.maxCrownAngle),
          onMaxChanged: (v) =>
              notifier.updateCrownAngleRange(state.minCrownAngle, v),
        ),
        CatalogAdvancedRangeSpec(
          title: 'Crown Height Range',
          currentMin: state.minCrownHeight,
          currentMax: state.maxCrownHeight,
          unit: '%',
          infoText: 'Filter by crown height relative to total depth.',
          onMinChanged: (v) =>
              notifier.updateCrownHeightRange(v, state.maxCrownHeight),
          onMaxChanged: (v) =>
              notifier.updateCrownHeightRange(state.minCrownHeight, v),
        ),
        CatalogAdvancedRangeSpec(
          title: 'Pavilion Angle Range',
          currentMin: state.minPavilionAngle,
          currentMax: state.maxPavilionAngle,
          unit: '°',
          infoText: 'Filter by average pavilion facet angle.',
          onMinChanged: (v) =>
              notifier.updatePavilionAngleRange(v, state.maxPavilionAngle),
          onMaxChanged: (v) =>
              notifier.updatePavilionAngleRange(state.minPavilionAngle, v),
        ),
        CatalogAdvancedRangeSpec(
          title: 'Pavilion Depth Range',
          currentMin: state.minPavilionDepth,
          currentMax: state.maxPavilionDepth,
          unit: '%',
          infoText: 'Filter by pavilion depth relative to total depth.',
          onMinChanged: (v) =>
              notifier.updatePavilionDepthRange(v, state.maxPavilionDepth),
          onMaxChanged: (v) =>
              notifier.updatePavilionDepthRange(state.minPavilionDepth, v),
        ),
      ],
      chipSections: [
        CatalogAdvancedChipSpec(
          title: 'Girdle',
          options: DiamondFilterState.girdles,
          selectedItems: state.selectedGirdles,
          onToggle: notifier.toggleGirdle,
          infoText: 'Filter by thickness of the girdle rim.',
        ),
        CatalogAdvancedChipSpec(
          title: 'Culet Size',
          options: DiamondFilterState.culets,
          selectedItems: state.selectedCulets,
          onToggle: notifier.toggleCulet,
          infoText: 'Filter by size of the culet facet.',
        ),
      ],
    );
  }
}
