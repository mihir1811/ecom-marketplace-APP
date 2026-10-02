import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/catalog_search_filter_shell.dart';
import '../../../../core/widgets/filters/catalog_expandable_advanced_filters.dart';
import '../../../../core/widgets/filters/catalog_measurement_filters.dart';
import '../../../../core/widgets/filters/catalog_preferences_filters.dart';
import '../../../../core/widgets/filters/catalog_search_add_field.dart';
import '../../../../core/widgets/filters/filter_proportion_diagram.dart';
import '../../../../core/widgets/luxe/luxe_button.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_layout.dart';
import '../../application/diamond_list_provider.dart';
import '../../application/diamond_search_provider.dart';
import '../../domain/models/diamond_catalog_type.dart';
import '../../domain/models/diamond_filter_state.dart';
import '../../domain/models/diamond_filter_summary.dart';
import '../widgets/diamond_flow_actions.dart';
import '../widgets/diamond_shape_picker.dart';
import '../widgets/filter_category_basic.dart';
import '../widgets/filter_color_selector.dart';
import '../widgets/filter_origin_dropdown.dart';

/// Diamond finder (natural and lab grown).
///
/// Layout: editorial header with the catalog mode switch → pinned section
/// index → the essentials (shape, size & price, colour & clarity) open by
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
    with CatalogSearchScrollMixin {
  @override
  final ScrollController catalogScrollController = ScrollController();
  @override
  final GlobalKey catalogNavKey = GlobalKey();
  @override
  double get catalogNavHeight => 56;

  final _offset = ValueNotifier<double>(0);
  final _companyController = TextEditingController();
  final _locationController = TextEditingController();
  final _sectionKeys = {
    for (final s in DiamondFinderSection.values)
      s: GlobalKey<LuxeSectionState>(),
  };
  final _pillKeys = {
    for (final s in DiamondFinderSection.values) s: GlobalKey(),
  };
  DiamondFinderSection _active = DiamondFinderSection.shape;

  bool get _isLab => widget.catalog == DiamondCatalogType.labGrown;

  @override
  void initState() {
    super.initState();
    catalogScrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    catalogScrollController
      ..removeListener(_onScroll)
      ..dispose();
    _offset.dispose();
    _companyController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  List<DiamondFinderSection> _visibleSections(bool melee) => [
    DiamondFinderSection.shape,
    DiamondFinderSection.sizePrice,
    DiamondFinderSection.colorClarity,
    if (!melee) DiamondFinderSection.grading,
    if (!melee) DiamondFinderSection.inclusions,
    DiamondFinderSection.listing,
    DiamondFinderSection.seller,
    DiamondFinderSection.measurements,
    if (!melee) DiamondFinderSection.proportions,
  ];

  void _onScroll() {
    _offset.value = catalogScrollController.offset;
    if (catalogSpyLocked) return;
    final melee = diamondUsesMeleeFilters(
      ref.read(diamondSearchProvider),
      isLab: _isLab,
    );
    final active =
        catalogActiveSectionFromScroll([
          for (final s in _visibleSections(melee)) (_sectionKeys[s]!, s),
        ]) ??
        DiamondFinderSection.shape;
    _setActive(active);
  }

  void _setActive(DiamondFinderSection section) {
    if (section == _active) return;
    setState(() => _active = section);
    final pill = _pillKeys[section]!.currentContext;
    if (pill != null) {
      Scrollable.ensureVisible(
        pill,
        alignment: 0.5,
        duration: LuxeMotion.medium,
        curve: LuxeMotion.settle,
      );
    }
  }

  void _jumpTo(DiamondFinderSection section) {
    AppHaptics.selection();
    _setActive(section);
    _sectionKeys[section]!.currentState?.expand();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => catalogScrollToSection(_sectionKeys[section]!),
    );
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
      if (next.companyNames.isEmpty && _companyController.text.isNotEmpty) {
        _companyController.clear();
      }
      if (next.vendorLocations.isEmpty && _locationController.text.isNotEmpty) {
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
    final p = LuxePalette.of(context);
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

    return AppScaffold(
      backgroundColor: background,
      appBar: LuxeTopBar(
        eyebrow: context.tr(DiamondFlowL10n.finderEyebrow),
        title: widget.catalog.label,
        scrollOffset: _offset,
        onBack: () => context.resetTo(AppRouteNames.home),
        actions: const [DiamondFlowActions()],
      ),
      bottomNavigationBar: _FinderActionBar(
        activeCount: summary.total,
        onReset: summary.total == 0 ? null : _resetAll,
        onShow: _onShowDiamonds,
      ),
      body: AnimatedContainer(
        duration: AppColors.meleeBgDuration,
        curve: Curves.easeInOut,
        color: background,
        child: NotificationListener<ScrollNotification>(
          onNotification: catalogHandleScrollNotification,
          child: CustomScrollView(
            controller: catalogScrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(child: _intro(context)),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SectionIndexDelegate(
                  background: background,
                  hairline: p.hairline,
                  child: _SectionIndex(
                    key: catalogNavKey,
                    sections: sections,
                    active: _active,
                    summary: summary,
                    pillKeys: _pillKeys,
                    labelOf: (s) => _title(context, s),
                    onTap: _jumpTo,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                sliver: SliverList.list(
                  children: [
                    for (final s in sections)
                      _section(context, s, summary, melee),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _intro(BuildContext context) {
    final p = LuxePalette.of(context);
    final animate = !MediaQuery.disableAnimationsOf(context);
    Widget headline = Text(
      context.tr(
        _isLab
            ? DiamondFlowL10n.finderHeadlineLab
            : DiamondFlowL10n.finderHeadlineNatural,
      ),
      style: LuxeType.display(36, p.ink),
    );
    if (animate) {
      headline = headline
          .animate()
          .fadeIn(duration: 600.ms)
          .moveY(begin: 14, end: 0, duration: 800.ms, curve: LuxeMotion.settle);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          headline,
          const SizedBox(height: 8),
          Text(
            context.tr(DiamondFlowL10n.finderIntro),
            style: LuxeType.body(p.inkMuted, size: 14),
          ),
          const SizedBox(height: 18),
          DiamondCatalogModeControls(
            showOriginToggle: !_isLab,
            isLabCatalog: _isLab,
          ),
        ],
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
          children: [ColorTabsSelector(), ClarityCardsSection()],
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

    final summaryText = count == 0
        ? context.tr(DiamondFlowL10n.any)
        : s == DiamondFinderSection.shape
        ? ref.read(diamondSearchProvider).shapes.join(' · ')
        : context.tr(DiamondFlowL10n.selectedCount, {'count': count});

    return LuxeSection(
      key: _sectionKeys[s],
      title: _title(context, s),
      icon: icon,
      summary: summaryText,
      activeCount: count,
      initiallyExpanded: essential,
      child: child,
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
      originDropdown: _isLab
          ? null
          : FilterOriginDropdown(
              selectedOrigin: state.selectedOrigin,
              onSelected: notifier.updateOriginCountry,
            ),
      roughSourceOptions: _isLab ? null : DiamondFilterState.roughSources,
      selectedRoughSource: _isLab ? null : state.selectedRoughSource,
      onRoughSourceChanged: _isLab ? null : notifier.updateRoughSource,
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
      expandAdvanced: true,
      ranges: [
        CatalogAdvancedRangeSpec(
          title: context.tr(CatalogL10n.tablePercentage),
          currentMin: state.minTable,
          currentMax: state.maxTable,
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

/// Pinned, horizontally scrolling index of finder sections. Pills carry a
/// dot when their section holds active filters.
class _SectionIndex extends StatelessWidget {
  const _SectionIndex({
    required this.sections,
    required this.active,
    required this.summary,
    required this.pillKeys,
    required this.labelOf,
    required this.onTap,
    super.key,
  });

  final List<DiamondFinderSection> sections;
  final DiamondFinderSection active;
  final DiamondFilterSummary summary;
  final Map<DiamondFinderSection, GlobalKey> pillKeys;
  final String Function(DiamondFinderSection) labelOf;
  final ValueChanged<DiamondFinderSection> onTap;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: sections.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, i) {
        final s = sections[i];
        final selected = s == active;
        final hasActive = summary.count(s) > 0;
        return Semantics(
          button: true,
          selected: selected,
          label: labelOf(s),
          excludeSemantics: true,
          child: GestureDetector(
            key: pillKeys[s],
            onTap: () => onTap(s),
            child: AnimatedContainer(
              duration: LuxeMotion.medium,
              curve: LuxeMotion.settle,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: selected ? p.ink : p.surface,
                shape: StadiumBorder(
                  side: BorderSide(color: selected ? p.ink : p.hairline),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    labelOf(s),
                    style: LuxeType.label(
                      selected ? p.canvas : p.inkMuted,
                      size: 12.5,
                    ),
                  ),
                  if (hasActive) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.accent,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionIndexDelegate extends SliverPersistentHeaderDelegate {
  _SectionIndexDelegate({
    required this.child,
    required this.background,
    required this.hairline,
  });

  final Widget child;
  final Color background;
  final Color hairline;

  @override
  double get minExtent => 56;
  @override
  double get maxExtent => 56;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background.withValues(alpha: 0.88),
            border: Border(
              bottom: BorderSide(
                color: overlaps ? hairline : Colors.transparent,
                width: 0.6,
              ),
            ),
          ),
          child: SizedBox.expand(child: child),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_SectionIndexDelegate old) =>
      old.child != child || old.background != background;
}

/// Sticky footer: reset (when anything is set) and the primary search.
class _FinderActionBar extends StatelessWidget {
  const _FinderActionBar({
    required this.activeCount,
    required this.onReset,
    required this.onShow,
  });

  final int activeCount;
  final VoidCallback? onReset;
  final VoidCallback onShow;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.hairline, width: 0.6)),
      ),
      child: Row(
        children: [
          AnimatedSize(
            duration: LuxeMotion.medium,
            curve: LuxeMotion.settle,
            child: onReset == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: LuxeButton(
                      label: context.tr(DiamondFlowL10n.reset),
                      onPressed: onReset,
                      variant: LuxeButtonVariant.secondary,
                    ),
                  ),
          ),
          Expanded(
            child: LuxeButton(
              label: context.tr(CatalogL10n.showDiamonds),
              onPressed: onShow,
              expand: true,
              badge: activeCount,
              trailingIcon: Icons.arrow_forward_rounded,
            ),
          ),
        ],
      ),
    );
  }
}
