import 'package:flutter/material.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/catalog_empty_state.dart';
import '../../../../core/widgets/catalog_list_loading.dart';
import '../../../../core/widgets/view_mode_toggle.dart';
import '../../../comparison/presentation/widgets/comparison_bottom_bar.dart';
import '../../application/diamond_list_provider.dart';
import '../../application/diamond_search_provider.dart';
import '../../../ai_chat/application/ai_chat_back_navigation.dart';
import '../../../ai_chat/application/ai_pending_filters.dart';
import '../widgets/diamond_cards.dart';
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
  ConsumerState<DiamondListingsScreen> createState() => _DiamondListingsScreenState();
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyPendingAiFilters());
  }

  void _applyPendingAiFilters() {
    if (!mounted) return;
    final pending = ref.read(aiPendingDiamondFiltersProvider);
    if (pending == null) return;
    final isLabRoute =
        widget.searchRoute == AppRouteNames.labGrownDiamonds;
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
          WidgetsBinding.instance
              .addPostFrameCallback((_) => tryJump(attempt + 1));
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
    const mutedColor = AppColors.textSecondaryLight;

    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (AiChatBackNavigation.handleListingBack(context, ref)) return;
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRouteNames.home);
            }
          },
        ),
        title: Text(
          widget.title,
          style: AppTypography.title.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.s8),
            child: ViewModeToggle(
              style: ViewModeToggleStyle.labeled,
              isGrid: viewMode == ViewMode.grid,
              onGrid: () => _switchViewMode(ViewMode.grid),
              onList: () => _switchViewMode(ViewMode.list),
            ),
          ),
        ],
      ),
      body: ComparisonTrayHost(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s16,
                vertical: 0,
              ),
              child: Row(
                children: [
                  stateAsync.whenOrNull(
                    data: (state) => Text(
                      '${_formatCount(state.totalCount)} diamonds found',
                      style: AppTypography.caption.copyWith(color: mutedColor),
                    ),
                  ) ??
                      const SizedBox.shrink(),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => DiamondSortingBottomSheet.show(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s8,
                        vertical: AppSpacing.s4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppSpacing.r8),
                        border: Border.all(
                          color: AppColors.warmBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sort, size: 14, color: mutedColor),
                          const SizedBox(width: AppSpacing.s4),
                          Text(
                            'Sort',
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  TextButton(
                    onPressed: () {
                      // Keep applied filters; just return to the finder.
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(widget.searchRoute);
                      }
                    },
                    child: const Text('Edit Filters'),
                  ),
                ],
              ),
            ),
            const Divider(height: 0),
            Expanded(
              child: stateAsync.when(
                data: (state) {
                  if (state.isInitialLoading) {
                    return CatalogListLoading(isGrid: viewMode == ViewMode.grid);
                  }
                  if (state.errorMessage != null && state.diamonds.isEmpty) {
                    return _buildError(state.errorMessage!);
                  }
                  if (state.diamonds.isEmpty) {
                    return CatalogEmptyState(
                      icon: Icons.diamond_outlined,
                      iconSize: 72,
                      iconColor: AppColors.textMutedLight.withValues(alpha: 0.4),
                      title: 'No Diamonds Found',
                      message:
                          'Try adjusting your filters or search criteria to find matching diamonds.',
                      padding: const EdgeInsets.all(AppSpacing.s48),
                      titleStyle: AppTypography.headline.copyWith(
                        color: AppColors.textPrimaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                      actionLabel: 'Reset Filters',
                      onAction: () {
                        ref
                            .read(diamondListProvider.notifier)
                            .resetFiltersAndReload();
                      },
                      actionIcon: Icons.refresh,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(diamondListProvider.notifier).refresh(),
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
                loading: () =>
                    CatalogListLoading(isGrid: viewMode == ViewMode.grid),
                error: (error, _) => _buildError(error.toString()),
              ),
            ),
          ],
        ),
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
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(count >= 10000 ? 0 : 1)}K';
    }
    return count.toString();
  }
}
