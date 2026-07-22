import 'package:flutter/material.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/catalog_empty_state.dart';
import '../../../../core/widgets/catalog_error_state.dart';
import '../../../../core/widgets/listing_search_filter_bar.dart';
import '../../../../core/widgets/simple_sort_sheet.dart';
import '../../../../core/widgets/view_mode_toggle.dart';
import '../../application/watch_filter_provider.dart';
import '../../application/watch_list_provider.dart';
import '../../domain/models/watch_filter_state.dart';
import '../widgets/watch_brand_carousel.dart';
import '../widgets/watch_filter_drawer.dart';
import '../widgets/watch_grid_view.dart';
import '../../../comparison/presentation/widgets/comparison_bottom_bar.dart';

class WatchesScreen extends ConsumerStatefulWidget {
  const WatchesScreen({super.key});

  @override
  ConsumerState<WatchesScreen> createState() => _WatchesScreenState();
}

class _WatchesScreenState extends ConsumerState<WatchesScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final q = ref.read(watchFilterProvider).searchQuery;
    if (q.isNotEmpty) _searchController.text = q;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 240) {
      ref.read(watchListProvider.notifier).loadNextPage();
    }
  }

  void _openFilters() {
    ref.read(watchFilterDraftProvider.notifier).syncFromApplied();
    _scaffoldKey.currentState?.openEndDrawer();
  }

  Future<void> _showSortSheet() async {
    final current = ref.read(watchSortProvider);
    final selected = await showSimpleSortSheet<WatchSortOption>(
      context: context,
      options: WatchSortOption.values,
      labelOf: (o) => o.label,
      current: current,
    );
    if (selected != null) {
      ref.read(watchSortProvider.notifier).state = selected;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(watchFilterProvider);
    final sort = ref.watch(watchSortProvider);
    final viewMode = ref.watch(watchViewModeProvider);
    final listAsync = ref.watch(watchListProvider);
    final listState = listAsync.valueOrNull;
    final muted =
        AppColors.textMutedLight;

    return AppScaffold(
      scaffoldKey: _scaffoldKey,
      endDrawer: const WatchFilterDrawer(),
      endDrawerEnableOpenDragGesture: false,
      appBar: AppBar(
        automaticallyImplyActions: false,
        title: Text(
          'Luxury Watches',
          style: AppTypography.headline.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        actions: const [],
      ),
      body: ComparisonTrayHost(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.s8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
            child: ListingSearchFilterBar(
              controller: _searchController,
              hintText: 'Search for luxury watches...',
              mutedColor: muted,
              activeFilterCount: filters.activeCount,
              onFilterTap: _openFilters,
              onChanged: (v) =>
                  ref.read(watchFilterProvider.notifier).setSearchQuery(v),
              onSubmitted: (v) =>
                  ref.read(watchFilterProvider.notifier).setSearchQuery(v),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                const SliverToBoxAdapter(child: WatchBrandCarousel()),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyControlsDelegate(
                    height: 104,
                    child: ColoredBox(
                      color: AppColors.creamBg,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSpacing.s12,
                            ),
                            child: WatchCategoryChips(),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.s16,
                              0,
                              AppSpacing.s16,
                              AppSpacing.s8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton.icon(
                                  onPressed: _showSortSheet,
                                  icon: const Icon(Icons.sort, size: 18),
                                  label: Text(
                                    'Sort by: ${sort.label}',
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.caption.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimaryLight,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.textPrimaryLight,
                                    padding: EdgeInsets.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                ViewModeToggle(
                                  isGrid: viewMode == WatchViewMode.grid,
                                  onGrid: () => ref
                                      .read(watchViewModeProvider.notifier)
                                      .state = WatchViewMode.grid,
                                  onList: () => ref
                                      .read(watchViewModeProvider.notifier)
                                      .state = WatchViewMode.list,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (listState == null || listState.isInitialLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (listState.errorMessage != null &&
                    listState.watches.isEmpty)
                  SliverFillRemaining(
                    child: CatalogErrorState(
                      message: listState.errorMessage!,
                      onRetry: () =>
                          ref.read(watchListProvider.notifier).refresh(),
                    ),
                  )
                else if (listState.watches.isEmpty)
                  SliverFillRemaining(
                    child: CatalogEmptyState(
                      icon: Icons.watch_outlined,
                      title: 'No watches match your filters',
                      message: 'Try adjusting brand, price, or style filters.',
                      actionLabel: 'Clear filters',
                      onAction: () {
                        ref.read(watchFilterProvider.notifier).reset();
                        _searchController.clear();
                      },
                    ),
                  )
                else if (viewMode == WatchViewMode.grid)
                  WatchGridSliver(
                    watches: listState.watches,
                    isLoadingMore: listState.isLoadingMore,
                  )
                else
                  WatchListSliver(
                    watches: listState.watches,
                    isLoadingMore: listState.isLoadingMore,
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.s24),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _StickyControlsDelegate extends SliverPersistentHeaderDelegate {
  const _StickyControlsDelegate({
    required this.height,
    required this.child,
  });

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _StickyControlsDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}
