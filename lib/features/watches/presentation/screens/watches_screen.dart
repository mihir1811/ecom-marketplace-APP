import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_system_back_scope.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_layout.dart';
import '../../../../core/widgets/luxe/luxe_listing.dart';
import '../../../../core/widgets/luxe/luxe_toggle_sort_sheet.dart';
import '../../../../core/widgets/navigation/top_bar/top_bar_actions.dart';
import '../../domain/models/watch.dart';
import '../../../product_detail/presentation/transition/product_sheet_launch.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../application/watch_filter_provider.dart';
import '../../application/watch_list_provider.dart';
import '../../domain/models/watch_filter_state.dart';
import '../widgets/watch_brand_carousel.dart';
import '../widgets/watch_filter_labels.dart';
import '../widgets/watch_luxe_cards.dart';
import '../../../spotlight/domain/spotlight_models.dart';
import '../../../spotlight/presentation/widgets/spotlight_category_block.dart';

/// Luxury watch catalogue, built from the same luxe listing pieces as the
/// diamond and gemstone results.
///
/// Search, style chips and the brand carousel scroll away; the filter /
/// sort / view toolbar stays pinned. Cards enter with a short stagger,
/// skeletons cover loading, and empty / error states offer the next step.
class WatchesScreen extends ConsumerStatefulWidget {
  const WatchesScreen({super.key});

  @override
  ConsumerState<WatchesScreen> createState() => _WatchesScreenState();
}

class _WatchesScreenState extends ConsumerState<WatchesScreen>
    with LuxeListingMixin {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    initListing();
    final q = ref.read(watchFilterProvider).searchQuery;
    if (q.isNotEmpty) _searchController.text = q;
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
    final s = ref.read(watchListProvider).value;
    return s != null &&
        s.hasMore &&
        !s.isLoadingMore &&
        !s.isInitialLoading &&
        !s.isRefreshing;
  }

  @override
  Future<void> listingLoadMore() =>
      ref.read(watchListProvider.notifier).loadNextPage();

  @override
  int get listingItemCount =>
      ref.read(watchListProvider).value?.watches.length ?? 0;

  @override
  LuxeViewMode get listingViewMode =>
      ref.read(watchViewModeProvider) == WatchViewMode.grid
      ? LuxeViewMode.grid
      : LuxeViewMode.list;

  @override
  void listingApplyViewMode(LuxeViewMode mode) =>
      ref.read(watchViewModeProvider.notifier).state = mode == LuxeViewMode.grid
      ? WatchViewMode.grid
      : WatchViewMode.list;

  /// Debounced so typing does not refetch on every keystroke.
  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) ref.read(watchFilterProvider.notifier).setSearchQuery(value);
    });
  }

  void _onSearchSubmitted(String value) {
    _searchDebounce?.cancel();
    ref.read(watchFilterProvider.notifier).setSearchQuery(value);
  }

  void _openFilters() {
    // Flush a pending search first so the draft starts from it and a late
    // debounce can't overwrite the draft while the filters are open.
    if (_searchDebounce?.isActive ?? false) {
      _searchDebounce!.cancel();
      ref
          .read(watchFilterProvider.notifier)
          .setSearchQuery(_searchController.text);
    }
    ref.read(watchFilterDraftProvider.notifier).syncFromApplied();
    context.push(AppRouteNames.watchesFilters);
  }

  void _clearAll() {
    _searchDebounce?.cancel();
    ref.read(watchFilterProvider.notifier).reset();
    _searchController.clear();
  }

  Future<void> _openSort() => showLuxeToggleSortSheet<WatchSortOption>(
    context,
    title: context.tr(CatalogFlowL10n.watchSort),
    fields: watchSortFields(),
    current: ref.read(watchSortProvider),
    onChanged: (o) => ref.read(watchSortProvider.notifier).state = o,
  );

  @override
  Widget build(BuildContext context) {
    return AppSystemBackScope(
      child: LuxeScope(child: Builder(builder: _buildScaffold)),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final p = LuxePalette.of(context);
    return AppScaffold(
      // Runs on behind the floating dock; the scroll view clears it.
      safeBottom: false,
      backgroundColor: p.canvas,
      appBar: LuxeTopBar(
        title: '',
        subtitle: Consumer(
          builder: (context, ref, _) => WatchCountLine(
            total: ref.watch(
              watchListProvider.select((v) {
                final s = v.value;
                return s == null || s.isInitialLoading ? null : s.totalCount;
              }),
            ),
          ),
        ),
        scrollOffset: listingOffset,
        actions: const [TopBarActions()],
      ),
      body: LuxeListingScrollView(
        controller: listingScroll,
        offset: listingOffset,
        onRefresh: () => ref.read(watchListProvider.notifier).refresh(),
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
                  child: LuxeSearchField(
                    controller: _searchController,
                    hintText: context.tr(CatalogL10n.searchWatches),
                    onChanged: _onSearchChanged,
                    onSubmitted: _onSearchSubmitted,
                  ),
                ),
                const SpotlightCategoryBlock(
                  category: SpotlightCategory.watches,
                  topSpacing: 0,
                ),
                const WatchCategoryChips(),
                const SizedBox(height: 14),
                const WatchBrandCarousel(),
              ],
            ),
          ),
          LuxePinnedBar(
            child: Center(
              child: WatchListingToolbar(
                filters: watchFilterProvider,
                sort: watchSortProvider,
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
    final stateAsync = ref.watch(watchListProvider);
    final grid = ref.watch(watchViewModeProvider) == WatchViewMode.grid;
    final state = stateAsync.value;
    final error =
        stateAsync.whenOrNull(error: (e, _) => e.toString()) ??
        state?.errorMessage;
    final listed = state?.watches ?? const [];
    // Lets the detail sheet page in more results as the user swipes.
    final feed = ProductListFeed<Watch>(
      items: () => ref.read(watchListProvider).value?.watches ?? const [],
      loadMore: listingLoadMoreIfReady,
    );
    return luxeResultSlivers(
      context: context,
      initialLoading:
          !stateAsync.hasError && (state == null || state.isInitialLoading),
      error: error,
      items: listed,
      isLoadingMore: state?.isLoadingMore ?? false,
      viewMode: grid ? LuxeViewMode.grid : LuxeViewMode.list,
      idOf: (w) => w.id,
      cardOf: (w, mode) => mode == LuxeViewMode.grid
          ? WatchLuxeGridCard(
              watch: w,
              onTap: () =>
                  openWatchDetail(context, w, among: listed, feed: feed),
            )
          : WatchLuxeListCard(
              watch: w,
              onTap: () =>
                  openWatchDetail(context, w, among: listed, feed: feed),
            ),
      loadingMoreLabel: context.tr(DiamondFlowL10n.loadingMore),
      emptyView: LuxeStateView(
        icon: Icons.watch_outlined,
        title: context.tr(CatalogL10n.noWatches),
        message: context.tr(CatalogL10n.adjustWatchFilters),
        actionLabel: context.tr(DiamondFlowL10n.editFilters),
        onAction: _openFilters,
        secondaryLabel: context.tr(CatalogL10n.clearAll),
        onSecondary: _clearAll,
      ),
      errorView: (message) => LuxeStateView(
        icon: Icons.cloud_off_rounded,
        tone: LuxeTone.error,
        title: context.tr(CatalogFlowL10n.errorTitle),
        message: message,
        actionLabel: context.tr(CatalogL10n.retry),
        onAction: () => ref.read(watchListProvider.notifier).refresh(),
        secondaryLabel: context.tr(DiamondFlowL10n.editFilters),
        onSecondary: _openFilters,
      ),
    );
  }
}
