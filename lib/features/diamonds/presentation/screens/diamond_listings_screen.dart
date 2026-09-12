import 'package:flutter/material.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/catalog_listing_header_row.dart';
import '../../../../core/widgets/catalog_empty_state.dart';
import '../../../../core/widgets/catalog_list_loading.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../comparison/presentation/widgets/comparison_bottom_bar.dart';
import '../../../diamond_projects/presentation/widgets/diamond_project_listing_actions.dart';
import '../../../diamond_projects/presentation/widgets/diamond_project_pick_bottom_bar.dart';
import '../../application/diamond_list_provider.dart';
import '../../application/diamond_search_provider.dart';
import '../../../ai_chat/application/ai_pending_filters.dart';
import '../widgets/diamond_cards.dart';
import '../widgets/diamond_listing_stats_bar.dart';
import '../widgets/diamond_sorting_bottom_sheet.dart';

class DiamondListingsScreen extends ConsumerStatefulWidget {
  const DiamondListingsScreen({
    super.key,
    this.title = 'Diamond Results',
    this.searchRoute = AppRouteNames.diamonds,
  });

  final String title;
  final String searchRoute;

  @override
  ConsumerState<DiamondListingsScreen> createState() =>
      _DiamondListingsScreenState();
}

class _DiamondListingsScreenState extends ConsumerState<DiamondListingsScreen> {
  final ScrollController _scrollController = ScrollController();

  /// Grid is 2 columns of content-sized cards (see [DiamondGridView]).
  static const int _gridCrossAxisCount = 2;

  /// Approximate list-card stride (card + bottom gap) for index ↔ offset.
  static const double _listItemStride = 200;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _applyPendingAiFilters(),
    );
  }

  void _applyPendingAiFilters() {
    if (!mounted) return;
    final pending = ref.read(aiPendingDiamondFiltersProvider);
    if (pending == null) return;
    final isLabRoute = widget.searchRoute == AppRouteNames.labGrownDiamonds;
    if (pending.isLabGrown != isLabRoute) return;

    ref.read(diamondSearchProvider.notifier).replaceFilters(pending.filters);
    ref.read(aiPendingDiamondFiltersProvider.notifier).state = null;
    ref.invalidate(diamondListProvider);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final listState = ref.read(diamondListProvider).valueOrNull;
    if (listState == null ||
        !listState.hasMore ||
        listState.isLoadingMore ||
        listState.isInitialLoading ||
        listState.isRefreshing) {
      return;
    }

    final position = _scrollController.position;
    // Prefetch ~1 viewport before the end so the next page arrives seamlessly.
    final prefetchExtent = position.viewportDimension;
    if (position.pixels >= position.maxScrollExtent - prefetchExtent) {
      ref.read(diamondListProvider.notifier).loadNextPage();
    }
  }

  double _gridRowStride(double viewportWidth) {
    return diamondGridRowStride(context, viewportWidth);
  }

  int _estimateVisibleIndex(ViewMode mode) {
    if (!_scrollController.hasClients) return 0;
    final offset = _scrollController.offset;
    final count =
        ref.read(diamondListProvider).valueOrNull?.diamonds.length ?? 0;
    if (count == 0) return 0;

    if (mode == ViewMode.grid) {
      final stride = _gridRowStride(MediaQuery.sizeOf(context).width);
      if (stride <= 0) return 0;
      final row = (offset / stride).floor();
      return (row * _gridCrossAxisCount).clamp(0, count - 1);
    }

    return (offset / _listItemStride).floor().clamp(0, count - 1);
  }

  double _offsetForIndex(ViewMode mode, int index) {
    if (mode == ViewMode.grid) {
      final stride = _gridRowStride(MediaQuery.sizeOf(context).width);
      final row = index ~/ _gridCrossAxisCount;
      return row * stride;
    }
    return index * _listItemStride;
  }

  void _restoreScroll(ViewMode mode, int index) {
    void tryJump([int attempt = 0]) {
      if (!mounted) return;
      if (!_scrollController.hasClients) {
        if (attempt < 6) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => tryJump(attempt + 1),
          );
        }
        return;
      }
      final max = _scrollController.position.maxScrollExtent;
      final target = _offsetForIndex(mode, index).clamp(0.0, max);
      _scrollController.jumpTo(target);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => tryJump());
  }

  void _switchViewMode(ViewMode next) {
    final current = ref.read(diamondViewModeProvider);
    if (current == next) return;
    final index = _estimateVisibleIndex(current);
    ref.read(diamondViewModeProvider.notifier).state = next;
    _restoreScroll(next, index);
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(diamondListProvider);
    final viewMode = ref.watch(diamondViewModeProvider);

    return AppScaffold(
      appBar: AppTopBar(title: widget.title),
      body: Column(
        children: [
          Expanded(
            child: ComparisonTrayHost(
              child: Column(
                children: [
                  const DiamondListingStatsBar(),
                  _DiamondListingHeader(
                    searchRoute: widget.searchRoute,
                    onSwitchViewMode: _switchViewMode,
                  ),
                  const DiamondProjectListingActions(),
                  const Divider(height: 0),
                  Expanded(
                    child: stateAsync.when(
                      data: (state) {
                        if (state.isInitialLoading) {
                          return CatalogListLoading(
                            isGrid: viewMode == ViewMode.grid,
                          );
                        }
                        if (state.errorMessage != null &&
                            state.diamonds.isEmpty) {
                          return _buildError(state.errorMessage!);
                        }
                        if (state.diamonds.isEmpty) {
                          return CatalogEmptyState(
                            icon: Icons.diamond_outlined,
                            iconSize: 72,
                            iconColor: AppColors.textMuted(
                              context,
                            ).withValues(alpha: 0.4),
                            title: context.tr(CatalogL10n.noDiamonds),
                            message:
                                'Try adjusting your filters or search criteria to find matching diamonds.',
                            padding: const EdgeInsets.all(AppSpacing.s48),
                            titleStyle: AppTypography.headline.copyWith(
                              color: AppColors.textPrimary(context),
                              fontWeight: FontWeight.bold,
                            ),
                            actionLabel: context.tr(CatalogL10n.resetFilters),
                            onAction: () {
                              ref
                                  .read(diamondListProvider.notifier)
                                  .resetFiltersAndReload();
                            },
                            actionIcon: Icons.refresh,
                          );
                        }
                        return RefreshIndicator(
                          onRefresh: () => ref
                              .read(diamondListProvider.notifier)
                              .refresh(),
                          child: viewMode == ViewMode.grid
                              ? DiamondGridView(
                                  key: const ValueKey('diamond-grid'),
                                  diamonds: state.diamonds,
                                  scrollController: _scrollController,
                                  isLoadingMore: state.isLoadingMore,
                                )
                              : DiamondListView(
                                  key: const ValueKey('diamond-list'),
                                  diamonds: state.diamonds,
                                  scrollController: _scrollController,
                                  isLoadingMore: state.isLoadingMore,
                                ),
                        );
                      },
                      loading: () => CatalogListLoading(
                        isGrid: viewMode == ViewMode.grid,
                      ),
                      error: (error, _) => _buildError(error.toString()),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const DiamondProjectPickBottomBar(),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.terracotta,
            ),
            const SizedBox(height: AppSpacing.s24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: AppColors.terracotta),
            ),
            const SizedBox(height: AppSpacing.s24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(diamondListProvider.notifier).applyFiltersAndSort();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(context.tr(CatalogL10n.retry)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiamondListingHeader extends ConsumerWidget {
  const _DiamondListingHeader({
    required this.searchRoute,
    required this.onSwitchViewMode,
  });

  final String searchRoute;
  final void Function(ViewMode mode) onSwitchViewMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(diamondViewModeProvider);
    final sorting = ref.watch(diamondSortingProvider);
    final sortLabel = sorting.isEmpty
        ? context.tr(CatalogL10n.defaultSorting)
        : ([...sorting]..sort((a, b) => a.priority.compareTo(b.priority)))
              .first
              .displayName;
    final countLabel = ref.watch(
      diamondListProvider.select((value) {
        final listState = value.valueOrNull;
        if (listState == null || listState.isInitialLoading) {
          return context.tr(CatalogL10n.loading);
        }
        return context.tr(CatalogL10n.showingDiamonds, {
          'count': '${listState.totalCount}',
        });
      }),
    );

    return CatalogListingHeaderRow(
      sortLabel: sortLabel,
      onSortTap: () => DiamondSortingBottomSheet.show(context),
      isGrid: viewMode == ViewMode.grid,
      onGrid: () => onSwitchViewMode(ViewMode.grid),
      onList: () => onSwitchViewMode(ViewMode.list),
      countLabel: countLabel,
      onEditFilters: () {
        if (context.canPop()) {
          context.goBack();
        } else {
          context.openRoute(searchRoute);
        }
      },
    );
  }
}
