import 'package:flutter/material.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/global_search_bar.dart';
import '../../../../core/widgets/melee_background_shell.dart';
import '../../../../core/widgets/paired_showcase_carousel.dart';
import '../../../../core/widgets/search_action_bottom_bar.dart';
import '../../../../core/widgets/showcase_select_card.dart';
import '../../../../core/widgets/filters/catalog_expandable_advanced_filters.dart';
import '../../../../core/widgets/filters/catalog_measurement_filters.dart';
import '../../../../core/widgets/filters/catalog_preferences_filters.dart';
import '../../../../core/widgets/filters/catalog_search_add_field.dart';
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
  ConsumerState<DiamondSearchScreen> createState() => _DiamondSearchScreenState();
}

class _DiamondSearchScreenState extends ConsumerState<DiamondSearchScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  Section _activeSection = Section.basic;
  bool _expandAdvanced = false;

  final GlobalKey _basicKey = GlobalKey();
  final GlobalKey _prefKey = GlobalKey();
  final GlobalKey _measKey = GlobalKey();
  final GlobalKey _advancedKey = GlobalKey();
  final GlobalKey _navKey = GlobalKey();

  static const double _navHeight = 52.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  double _getNavBottom() {
    final navCtx = _navKey.currentContext;
    if (navCtx == null) return _navHeight;
    final navBox = navCtx.findRenderObject() as RenderBox?;
    if (navBox == null) return _navHeight;
    return navBox.localToGlobal(Offset(0, navBox.size.height)).dy;
  }

  void _onScroll() {
    final filterState = ref.read(diamondSearchProvider);
    final useMeleeFilters = _usesMeleeFilters(filterState);

    final sections = <(GlobalKey, Section)>[
      (_basicKey, Section.basic),
      (_prefKey, Section.preferences),
      (_measKey, Section.measurements),
      if (!useMeleeFilters) (_advancedKey, Section.advanced),
    ];

    final navBottom = _getNavBottom();
    Section? found;
    for (final entry in sections) {
      final ctx = entry.$1.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final pos = box.localToGlobal(Offset.zero);
      if (pos.dy <= navBottom + 4) {
        found = entry.$2;
      } else {
        break;
      }
    }

    final active = found ?? Section.basic;
    if (active != _activeSection) {
      setState(() => _activeSection = active);
    }
  }

  void _scrollToSection(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final pos = box.localToGlobal(Offset.zero);
    final navBottom = _getNavBottom();
    final target = _scrollController.offset + pos.dy - navBottom;
    _scrollController.animateTo(
      target.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool _usesMeleeFilters(DiamondFilterState state) {
    if (widget.catalog == DiamondCatalogType.labGrown) {
      return state.labCategory == 'Lab Melee';
    }
    return state.labNatural.usesMeleeFilters;
  }

  @override
  Widget build(BuildContext context) {
    final filterState = ref.watch(diamondSearchProvider);
    final useMeleeFilters = _usesMeleeFilters(filterState);

    if (useMeleeFilters && _activeSection == Section.advanced) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _activeSection = Section.basic);
      });
    }

    final bgFamily = widget.catalog.isLabGrown
        ? MeleeBgFamily.labGrown
        : MeleeBgFamily.natural;

    return MeleeBackgroundShell(
      isMelee: useMeleeFilters,
      family: bgFamily,
      child: AppScaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: Text(
            widget.title,
            style: AppTypography.title.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            const GlobalSearchBar(),
            Expanded(
              child: SafeArea(
                top: false,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        _buildStickyNav(useMeleeFilters),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            padding: const EdgeInsets.only(
                              left: AppSpacing.s16,
                              right: AppSpacing.s16,
                              bottom: 120.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildShapeCarousel(),
                                const SizedBox(height: AppSpacing.s24),
                                _buildSection(
                                  key: _basicKey,
                                  title: 'Basic',
                                  child: FilterCategoryBasic(
                                    sectionTitle: widget.catalog.label,
                                    showOriginToggle: widget.catalog ==
                                        DiamondCatalogType.natural,
                                    isLabCatalog: widget.catalog ==
                                        DiamondCatalogType.labGrown,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.s32),
                                _buildSection(
                                  key: _prefKey,
                                  title: 'Preferences',
                                  child: _buildPreferenceFilters(),
                                ),
                                const SizedBox(height: AppSpacing.s32),
                                _buildSection(
                                  key: _measKey,
                                  title: 'Measurements',
                                  child: _buildMeasurementFilters(),
                                ),
                                if (!useMeleeFilters) ...[
                                  const SizedBox(height: AppSpacing.s32),
                                  _buildSection(
                                    key: _advancedKey,
                                    title: 'Advanced',
                                    child: _buildAdvancedFilters(),
                                  ),
                                ],
                                const SizedBox(height: AppSpacing.s32),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: SearchActionBottomBar(
                        primaryLabel: 'SHOW DIAMONDS',
                        onPrimary: () =>
                            context.push(widget.resultsRoute),
                        clearLabel: 'CLEAR ALL',
                        onClear: () {
                          ref
                              .read(diamondSearchProvider.notifier)
                              .reset();
                          _companyController.clear();
                          _locationController.clear();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShapeCarousel() {
    final state = ref.watch(diamondSearchProvider);
    final notifier = ref.read(diamondSearchProvider.notifier);

    return PairedShowcaseCarousel(
      title: 'Select Diamond\nShapes',
      itemCount: kAllShapes.length,
      itemBuilder: (context, index) {
        final item = kAllShapes[index];
        final name = item['name']!;
        final imagePath = item['image'];
        final isSelected = state.shapes.contains(name);
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
        infoText:
            'Search for diamonds supplied by a specific company name.',
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
          onMinChanged: (v) =>
              notifier.updateTableRange(v, state.maxTable),
          onMaxChanged: (v) =>
              notifier.updateTableRange(state.minTable, v),
        ),
        CatalogAdvancedRangeSpec(
          title: 'Depth Percentage',
          currentMin: state.minDepth,
          currentMax: state.maxDepth,
          unit: '%',
          infoText:
              'Filter by total depth percentage relative to total diameter.',
          onMinChanged: (v) =>
              notifier.updateDepthRange(v, state.maxDepth),
          onMaxChanged: (v) =>
              notifier.updateDepthRange(state.minDepth, v),
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

  Widget _buildSection({
    required GlobalKey key,
    required String title,
    required Widget child,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.headline.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        child,
      ],
    );
  }

  Widget _buildStickyNav(bool useMeleeFilters) {
    final sections = [
      (Section.basic, 'Basic', Icons.diamond_outlined),
      (Section.preferences, 'PREF', Icons.tune),
      (Section.measurements, 'MEAS', Icons.straighten),
      if (!useMeleeFilters) (Section.advanced, 'ADV', Icons.add),
    ];

    return Container(
      key: _navKey,
      height: _navHeight,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: AppColors.warmBorder,
          ),
        ),
      ),
      child: Row(
        children: sections.map((entry) {
          final section = entry.$1;
          final label = entry.$2;
          final icon = entry.$3;
          final isSelected = _activeSection == section;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeSection = section;
                  if (section == Section.advanced) {
                    _expandAdvanced = true;
                  }
                });
                final key = section == Section.basic
                    ? _basicKey
                    : section == Section.preferences
                        ? _prefKey
                        : section == Section.measurements
                            ? _measKey
                            : _advancedKey;
                _scrollToSection(key);
                if (section == Section.advanced) {
                  Future.delayed(const Duration(milliseconds: 350), () {
                    setState(() => _expandAdvanced = false);
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? AppColors.bronze : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: isSelected
                          ? AppColors.bronze
                          : Colors.black38,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                        color: isSelected
                            ? AppColors.bronze
                            : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
