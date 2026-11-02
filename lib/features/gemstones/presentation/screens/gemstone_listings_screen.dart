import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/utils/active_filter_labels.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_layout.dart';
import '../../../../core/widgets/luxe/luxe_listing.dart';
import '../../../../core/widgets/luxe/luxe_toggle_sort_sheet.dart';
import '../../../../core/widgets/navigation/top_bar/top_bar_actions.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../application/gemstone_list_provider.dart';
import '../../application/gemstone_search_provider.dart';
import '../../domain/models/gemstone_filter_state.dart';
import '../../domain/models/gemstone_filter_summary.dart';
import '../../domain/models/gemstone_sort_option.dart';
import '../widgets/gemstone_luxe_cards.dart';
import '../../../spotlight/domain/spotlight_models.dart';
import '../../../spotlight/presentation/widgets/spotlight_category_block.dart';

/// Gemstone results, built from the same luxe listing pieces as diamonds.
///
/// Active-filter pills scroll away; the filter / sort / view toolbar stays
/// pinned. Cards enter with a short stagger on first load, skeletons cover
/// loading, and empty / error states offer the next step.
class GemstoneListingsScreen extends ConsumerStatefulWidget {
  const GemstoneListingsScreen({super.key});

  @override
  ConsumerState<GemstoneListingsScreen> createState() =>
      _GemstoneListingsScreenState();
}

class _GemstoneListingsScreenState extends ConsumerState<GemstoneListingsScreen>
    with LuxeListingMixin {
  @override
  void initState() {
    super.initState();
    initListing();
  }

  @override
  void dispose() {
    disposeListing();
    super.dispose();
  }

  @override
  bool get listingCanLoadMore {
    final s = ref.read(gemstoneListProvider).valueOrNull;
    return s != null &&
        s.hasMore &&
        !s.isLoadingMore &&
        !s.isInitialLoading &&
        !s.isRefreshing;
  }

  @override
  void listingLoadMore() =>
      ref.read(gemstoneListProvider.notifier).loadNextPage();

  @override
  int get listingItemCount =>
      ref.read(gemstoneListProvider).valueOrNull?.gemstones.length ?? 0;

  @override
  LuxeViewMode get listingViewMode =>
      ref.read(gemstoneViewModeProvider) == GemstoneViewMode.grid
      ? LuxeViewMode.grid
      : LuxeViewMode.list;

  @override
  void listingApplyViewMode(LuxeViewMode mode) =>
      ref
          .read(gemstoneViewModeProvider.notifier)
          .state = mode == LuxeViewMode.grid
      ? GemstoneViewMode.grid
      : GemstoneViewMode.list;

  void _editFilters() => context.resetTo(AppRouteNames.gemstones);

  Future<void> _resetFilters() async {
    ref.read(gemstoneSearchProvider.notifier).reset();
    await ref.read(gemstoneListProvider.notifier).applyFiltersAndReload();
  }

  Future<void> _openSort(BuildContext context) {
    String dir(GemstoneSortOption o) => switch (o) {
      GemstoneSortOption.newest => 'Newest',
      GemstoneSortOption.oldest => 'Oldest',
      GemstoneSortOption.priceAsc ||
      GemstoneSortOption.caratAsc => 'Low to High',
      GemstoneSortOption.priceDesc ||
      GemstoneSortOption.caratDesc => 'High to Low',
      GemstoneSortOption.typeAsc => 'A–Z',
      GemstoneSortOption.typeDesc => 'Z–A',
    };
    return showLuxeToggleSortSheet<GemstoneSortOption>(
      context,
      title: context.tr(GemstoneFlowL10n.sortTitle),
      fields: [
        LuxeSortField(
          label: 'Arrivals',
          options: const [GemstoneSortOption.newest, GemstoneSortOption.oldest],
          directionLabelOf: dir,
        ),
        LuxeSortField(
          label: 'Price',
          options: const [
            GemstoneSortOption.priceAsc,
            GemstoneSortOption.priceDesc,
          ],
          directionLabelOf: dir,
        ),
        LuxeSortField(
          label: 'Carat',
          options: const [
            GemstoneSortOption.caratAsc,
            GemstoneSortOption.caratDesc,
          ],
          directionLabelOf: dir,
        ),
        LuxeSortField(
          label: 'Type',
          options: const [
            GemstoneSortOption.typeAsc,
            GemstoneSortOption.typeDesc,
          ],
          directionLabelOf: dir,
        ),
      ],
      current: ref.read(gemstoneSortProvider),
      onChanged: (o) => ref.read(gemstoneSortProvider.notifier).state = o,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LuxeScope(child: Builder(builder: _buildScaffold));
  }

  Widget _buildScaffold(BuildContext context) {
    final p = LuxePalette.of(context);
    return AppScaffold(
      // Runs on behind the floating dock; the scroll view clears it.
      safeBottom: false,
      backgroundColor: p.canvas,
      appBar: LuxeTopBar(
        title: '',
        subtitle: const _CountLine(),
        scrollOffset: listingOffset,
        actions: const [TopBarActions()],
      ),
      body: LuxeListingScrollView(
        controller: listingScroll,
        offset: listingOffset,
        onRefresh: () => ref.read(gemstoneListProvider.notifier).refresh(),
        onBackToTop: listingBackToTop,
        backToTopLabel: context.tr(DiamondFlowL10n.backToTop),
        slivers: [
          SliverToBoxAdapter(
            child: KeyedSubtree(
              key: listingHeaderKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SpotlightCategoryBlock(
                    category: SpotlightCategory.gemstones,
                  ),
                  _ActiveFilterPills(
                    onEdit: _editFilters,
                    onResetAll: _resetFilters,
                  ),
                ],
              ),
            ),
          ),
          LuxePinnedBar(
            child: Center(
              child: _Toolbar(
                onEditFilters: _editFilters,
                onSort: () => _openSort(context),
                onSwitchViewMode: switchListingViewMode,
              ),
            ),
          ),
          ..._content(context),
        ],
      ),
    );
  }

  List<Widget> _content(BuildContext context) {
    final stateAsync = ref.watch(gemstoneListProvider);
    final grid = ref.watch(gemstoneViewModeProvider) == GemstoneViewMode.grid;
    final state = stateAsync.valueOrNull;
    final error =
        stateAsync.whenOrNull(error: (e, _) => e.toString()) ??
        state?.errorMessage;
    final listed = state?.gemstones ?? const [];
    return luxeResultSlivers(
      context: context,
      initialLoading:
          !stateAsync.hasError && (state == null || state.isInitialLoading),
      error: error,
      items: listed,
      isLoadingMore: state?.isLoadingMore ?? false,
      viewMode: grid ? LuxeViewMode.grid : LuxeViewMode.list,
      idOf: (g) => g.id,
      cardOf: (g, mode) => mode == LuxeViewMode.grid
          ? GemstoneLuxeGridCard(
              gemstone: g,
              onTap: () => openGemstoneDetail(context, g, among: listed),
            )
          : GemstoneLuxeListCard(
              gemstone: g,
              onTap: () => openGemstoneDetail(context, g, among: listed),
            ),
      entered: listingEntered,
      loadingMoreLabel: context.tr(DiamondFlowL10n.loadingMore),
      emptyView: LuxeStateView(
        icon: Icons.auto_awesome_outlined,
        title: context.tr(GemstoneFlowL10n.emptyTitle),
        message: context.tr(DiamondFlowL10n.emptyBody),
        actionLabel: context.tr(DiamondFlowL10n.editFilters),
        onAction: _editFilters,
        secondaryLabel: context.tr(CatalogL10n.resetFilters),
        onSecondary: _resetFilters,
      ),
      errorView: (message) => LuxeStateView(
        icon: Icons.cloud_off_rounded,
        tone: LuxeTone.error,
        title: context.tr(GemstoneFlowL10n.errorTitle),
        message: message,
        actionLabel: context.tr(CatalogL10n.retry),
        onAction: () =>
            ref.read(gemstoneListProvider.notifier).applyFiltersAndReload(),
        secondaryLabel: context.tr(DiamondFlowL10n.editFilters),
        onSecondary: _editFilters,
      ),
    );
  }
}

/// "1,284 gemstones" (or "Searching…") under the title, cross-fading.
class _CountLine extends ConsumerWidget {
  const _CountLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(
      gemstoneListProvider.select((v) {
        final s = v.valueOrNull;
        if (s == null || s.isInitialLoading) return null;
        return s.totalCount;
      }),
    );
    return LuxeCountLine(
      text: total == null
          ? context.tr(DiamondFlowL10n.searching)
          : context.tr(GemstoneFlowL10n.resultsCount, {
              'count': formatGroupedWhole(total.toDouble()),
            }),
    );
  }
}

/// Pills summarising which finder sections hold filters; tapping edits.
class _ActiveFilterPills extends ConsumerWidget {
  const _ActiveFilterPills({required this.onEdit, required this.onResetAll});

  final VoidCallback onEdit;
  final VoidCallback onResetAll;

  static String _label(
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(gemstoneSearchProvider);
    final summary = GemstoneFilterSummary.of(f);
    const d = GemstoneFilterState();
    // Applied values first (also what Gem Agent set), then counts for the rest.
    final pills = ActiveFilterLabels<GemstoneFinderSection>()
      ..values(GemstoneFinderSection.gemType, f.selectedGemstoneTypes)
      ..values(GemstoneFinderSection.gemType, f.selectedBirthstoneMonths)
      ..values(GemstoneFinderSection.shape, f.selectedShapes);
    if (f.minTotalCarat != d.minTotalCarat ||
        f.maxTotalCarat != d.maxTotalCarat) {
      pills.add(
        GemstoneFinderSection.sizePrice,
        '${ActiveFilterLabels.number(f.minTotalCarat)}–'
        '${ActiveFilterLabels.number(f.maxTotalCarat)} ct',
      );
    }
    if (f.minTotalPrice != d.minTotalPrice ||
        f.maxTotalPrice != d.maxTotalPrice) {
      pills.add(
        GemstoneFinderSection.sizePrice,
        '${_price(f.minTotalPrice)}–${_price(f.maxTotalPrice)}',
      );
    }
    pills
      ..values(GemstoneFinderSection.colorQuality, f.selectedColors)
      ..values(GemstoneFinderSection.colorQuality, f.selectedClarities)
      ..values(GemstoneFinderSection.grading, f.selectedCutGrades, name: 'Cut')
      ..values(GemstoneFinderSection.grading, f.selectedCertifications)
      ..values(GemstoneFinderSection.grading, f.selectedTreatments)
      ..values(GemstoneFinderSection.seller, f.selectedOriginCountries);
    if (f.selectedQualityGrade != null) {
      pills.add(GemstoneFinderSection.colorQuality, f.selectedQualityGrade!);
    }
    return LuxeActiveFilterPills(
      labels: pills.build(
        sections: GemstoneFinderSection.values,
        count: summary.count,
        title: (s) => _label(context, s),
      ),
      onEdit: onEdit,
      onReset: onResetAll,
      resetLabel: context.tr(DiamondFlowL10n.reset),
    );
  }
}

/// Pinned row: Filters (with count), Sort (current key) and view toggle.
class _Toolbar extends ConsumerWidget {
  const _Toolbar({
    required this.onEditFilters,
    required this.onSort,
    required this.onSwitchViewMode,
  });

  final VoidCallback onEditFilters;
  final VoidCallback onSort;
  final ValueChanged<LuxeViewMode> onSwitchViewMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(gemstoneViewModeProvider);
    final active = ref.watch(
      gemstoneSearchProvider.select((s) => GemstoneFilterSummary.of(s).total),
    );
    return LuxeListingToolbar(
      filtersLabel: context.tr(DiamondFlowL10n.filters),
      activeFilters: active,
      onFilters: onEditFilters,
      onSort: onSort,
      viewMode: viewMode == GemstoneViewMode.grid
          ? LuxeViewMode.grid
          : LuxeViewMode.list,
      onViewMode: onSwitchViewMode,
      gridLabel: context.tr(DiamondFlowL10n.grid),
      listLabel: context.tr(DiamondFlowL10n.list),
    );
  }
}

String _price(double v) => AppCurrency.format(formatCatalogPriceWholeK(v));
