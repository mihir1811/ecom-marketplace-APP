import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_system_back_scope.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_layout.dart';
import '../../../../core/widgets/luxe/luxe_listing.dart';
import '../../../../core/widgets/luxe/luxe_toggle_sort_sheet.dart';
import '../../../../core/widgets/navigation/top_bar/top_bar_actions.dart';
import '../../../product_detail/presentation/transition/product_sheet_launch.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../application/rough_filter_provider.dart';
import '../../application/rough_list_provider.dart';
import '../../domain/models/rough_filter_state.dart';
import '../../domain/models/rough_parcel.dart';
import '../../domain/models/rough_sort_option.dart';
import '../widgets/rough_luxe_cards.dart';

/// Rough diamond catalogue on the shared luxe listing pieces: natural /
/// lab-grown tabs and search scroll away; the filter / sort / view toolbar
/// stays pinned; 24 parcels per page load as the buyer scrolls.
class RoughDiamondsScreen extends ConsumerStatefulWidget {
  const RoughDiamondsScreen({super.key, this.initialType});

  /// Tab from a `?type=` link; null keeps the current tab.
  final RoughDiamondType? initialType;

  @override
  ConsumerState<RoughDiamondsScreen> createState() =>
      _RoughDiamondsScreenState();
}

class _RoughDiamondsScreenState extends ConsumerState<RoughDiamondsScreen>
    with LuxeListingMixin {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    initListing();
    final applied = ref.read(roughFilterProvider);
    _searchController.text = applied.search;
    final type = widget.initialType;
    if (type != null && type != applied.diamondType) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(roughFilterProvider.notifier).setType(type);
      });
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    disposeListing();
    super.dispose();
  }

  @override
  bool get listingCanLoadMore {
    final s = ref.read(roughListProvider).value;
    return s != null &&
        s.hasMore &&
        !s.isLoadingMore &&
        !s.isInitialLoading &&
        !s.isRefreshing;
  }

  @override
  Future<void> listingLoadMore() =>
      ref.read(roughListProvider.notifier).loadNextPage();

  @override
  int get listingItemCount =>
      ref.read(roughListProvider).value?.items.length ?? 0;

  @override
  LuxeViewMode get listingViewMode =>
      ref.read(roughViewModeProvider) == RoughViewMode.grid
      ? LuxeViewMode.grid
      : LuxeViewMode.list;

  @override
  void listingApplyViewMode(LuxeViewMode mode) =>
      ref.read(roughViewModeProvider.notifier).state = mode == LuxeViewMode.grid
      ? RoughViewMode.grid
      : RoughViewMode.list;

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) ref.read(roughFilterProvider.notifier).setSearch(value);
    });
  }

  void _onSearchSubmitted(String value) {
    _searchDebounce?.cancel();
    ref.read(roughFilterProvider.notifier).setSearch(value);
  }

  void _flushSearch() {
    if (_searchDebounce?.isActive ?? false) {
      _searchDebounce!.cancel();
      ref.read(roughFilterProvider.notifier).setSearch(_searchController.text);
    }
  }

  void _openFilters() {
    // A late debounce must not overwrite the draft while filters are open.
    _flushSearch();
    ref.read(roughFilterDraftProvider.notifier).syncFromApplied();
    context.push(AppRouteNames.roughDiamondsFilters);
  }

  void _clearAll() {
    _searchDebounce?.cancel();
    _searchController.clear();
    final notifier = ref.read(roughFilterProvider.notifier);
    notifier.replaceWith(
      RoughFilterState(diamondType: ref.read(roughFilterProvider).diamondType),
    );
  }

  void _setType(RoughDiamondType type) {
    AppHaptics.selection();
    _flushSearch();
    ref.read(roughFilterProvider.notifier).setType(type);
  }

  Future<void> _openSort() {
    String dir(RoughSortOption o) => context.tr(switch (o) {
      RoughSortOption.newest => RoughFlowL10n.newest,
      RoughSortOption.oldest => RoughFlowL10n.oldest,
      RoughSortOption.priceAsc ||
      RoughSortOption.ppcAsc ||
      RoughSortOption.caratAsc => RoughFlowL10n.lowToHigh,
      RoughSortOption.priceDesc ||
      RoughSortOption.ppcDesc ||
      RoughSortOption.caratDesc => RoughFlowL10n.highToLow,
    });
    return showLuxeToggleSortSheet<RoughSortOption>(
      context,
      title: context.tr(RoughFlowL10n.sortTitle),
      fields: [
        LuxeSortField(
          label: context.tr(RoughFlowL10n.sortArrivals),
          options: const [RoughSortOption.newest, RoughSortOption.oldest],
          directionLabelOf: dir,
        ),
        LuxeSortField(
          label: context.tr(RoughFlowL10n.sortPrice),
          options: const [RoughSortOption.priceAsc, RoughSortOption.priceDesc],
          directionLabelOf: dir,
        ),
        LuxeSortField(
          label: context.tr(RoughFlowL10n.sortPpc),
          options: const [RoughSortOption.ppcAsc, RoughSortOption.ppcDesc],
          directionLabelOf: dir,
        ),
        LuxeSortField(
          label: context.tr(RoughFlowL10n.sortCarat),
          options: const [RoughSortOption.caratAsc, RoughSortOption.caratDesc],
          directionLabelOf: dir,
        ),
      ],
      current: ref.read(roughSortProvider),
      onChanged: (o) => ref.read(roughSortProvider.notifier).state = o,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppSystemBackScope(
      child: LuxeScope(child: Builder(builder: _buildScaffold)),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final p = LuxePalette.of(context);
    final type = ref.watch(roughFilterProvider.select((s) => s.diamondType));
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
        onRefresh: () => ref.read(roughListProvider.notifier).refresh(),
        onBackToTop: listingBackToTop,
        backToTopLabel: context.tr(DiamondFlowL10n.backToTop),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              key: listingHeaderKey,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 5, 12, 10),
                  child: LuxeSegmented<RoughDiamondType>(
                    options: RoughDiamondType.values,
                    selected: type,
                    onChanged: _setType,
                    labelOf: (t) => context.tr(
                      t == RoughDiamondType.lab
                          ? RoughFlowL10n.lab
                          : RoughFlowL10n.natural,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: LuxeSearchField(
                    controller: _searchController,
                    hintText: context.tr(RoughFlowL10n.searchHint),
                    onChanged: _onSearchChanged,
                    onSubmitted: _onSearchSubmitted,
                  ),
                ),
              ],
            ),
          ),
          LuxePinnedBar(
            child: Center(
              child: _Toolbar(
                onFilters: _openFilters,
                onSort: _openSort,
                onViewMode: switchListingViewMode,
              ),
            ),
          ),
          ..._content(context),
        ],
      ),
    );
  }

  List<Widget> _content(BuildContext context) {
    final stateAsync = ref.watch(roughListProvider);
    final grid = ref.watch(roughViewModeProvider) == RoughViewMode.grid;
    final state = stateAsync.value;
    final error =
        stateAsync.whenOrNull(error: (e, _) => e.toString()) ??
        state?.errorMessage;
    final listed = state?.items ?? const <RoughParcel>[];
    // Lets the detail sheet page in more results as the user swipes.
    final feed = ProductListFeed<RoughParcel>(
      items: () => ref.read(roughListProvider).value?.items ?? const [],
      loadMore: listingLoadMoreIfReady,
    );
    void open(RoughParcel r) =>
        openRoughDetail(context, r, among: listed, feed: feed);
    return luxeResultSlivers(
      context: context,
      initialLoading:
          !stateAsync.hasError && (state == null || state.isInitialLoading),
      error: error,
      items: listed,
      isLoadingMore: state?.isLoadingMore ?? false,
      viewMode: grid ? LuxeViewMode.grid : LuxeViewMode.list,
      idOf: (r) => r.id,
      cardOf: (r, mode) => mode == LuxeViewMode.grid
          ? RoughLuxeGridCard(parcel: r, onTap: () => open(r))
          : RoughLuxeListCard(parcel: r, onTap: () => open(r)),
      loadingMoreLabel: context.tr(DiamondFlowL10n.loadingMore),
      emptyView: LuxeStateView(
        icon: Icons.landscape_outlined,
        title: context.tr(RoughFlowL10n.emptyTitle),
        message: context.tr(RoughFlowL10n.emptyBody),
        actionLabel: context.tr(DiamondFlowL10n.editFilters),
        onAction: _openFilters,
        secondaryLabel: context.tr(CatalogL10n.clearAll),
        onSecondary: _clearAll,
      ),
      errorView: (message) => LuxeStateView(
        icon: Icons.cloud_off_rounded,
        tone: LuxeTone.error,
        title: context.tr(RoughFlowL10n.errorTitle),
        message: message,
        actionLabel: context.tr(CatalogL10n.retry),
        onAction: () => ref.read(roughListProvider.notifier).refresh(),
        secondaryLabel: context.tr(DiamondFlowL10n.editFilters),
        onSecondary: _openFilters,
      ),
    );
  }
}

/// "91 rough parcels" (or "Searching…") under the title.
class _CountLine extends ConsumerWidget {
  const _CountLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(
      roughListProvider.select((v) {
        final s = v.value;
        return s == null || s.isInitialLoading ? null : s.totalCount;
      }),
    );
    return LuxeCountLine(
      text: total == null
          ? context.tr(DiamondFlowL10n.searching)
          : context.tr(RoughFlowL10n.resultsCount, {
              'count': formatGroupedWhole(total.toDouble()),
            }),
    );
  }
}

class _Toolbar extends ConsumerWidget {
  const _Toolbar({
    required this.onFilters,
    required this.onSort,
    required this.onViewMode,
  });

  final VoidCallback onFilters;
  final VoidCallback onSort;
  final ValueChanged<LuxeViewMode> onViewMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grid = ref.watch(
      roughViewModeProvider.select((m) => m == RoughViewMode.grid),
    );
    final active = ref.watch(
      roughFilterProvider.select((s) => RoughFilterSummary.of(s).total),
    );
    return LuxeListingToolbar(
      filtersLabel: context.tr(DiamondFlowL10n.filters),
      activeFilters: active,
      onFilters: onFilters,
      onSort: onSort,
      viewMode: grid ? LuxeViewMode.grid : LuxeViewMode.list,
      onViewMode: onViewMode,
      gridLabel: context.tr(DiamondFlowL10n.grid),
      listLabel: context.tr(DiamondFlowL10n.list),
    );
  }
}
