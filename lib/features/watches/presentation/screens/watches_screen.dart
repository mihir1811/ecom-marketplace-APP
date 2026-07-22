import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
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
    final selected = await showModalBottomSheet<WatchSortOption>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: Text(
                  'Sort by',
                  style:
                      AppTypography.title.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              for (final option in WatchSortOption.values)
                ListTile(
                  title: Text(option.label),
                  trailing: current == option
                      ? const Icon(Icons.check, color: AppColors.bronze)
                      : null,
                  onTap: () => Navigator.pop(context, option),
                ),
              const SizedBox(height: AppSpacing.s12),
            ],
          ),
        );
      },
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

    return Scaffold(
      key: _scaffoldKey,
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
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.warmWhite,
                        borderRadius: BorderRadius.circular(AppSpacing.r12),
                        border: Border.all(
                          color: AppColors.warmBorder,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        textAlignVertical: TextAlignVertical.center,
                        onChanged: (v) => ref
                            .read(watchFilterProvider.notifier)
                            .setSearchQuery(v),
                        onSubmitted: (v) => ref
                            .read(watchFilterProvider.notifier)
                            .setSearchQuery(v),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Search for luxury watches...',
                          prefixIcon: Icon(Icons.search, color: muted, size: 22),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 48,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s8,
                            vertical: 0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                Material(
                  color: AppColors.charcoal,
                  borderRadius: BorderRadius.circular(AppSpacing.r12),
                  child: InkWell(
                    onTap: _openFilters,
                    borderRadius: BorderRadius.circular(AppSpacing.r12),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.tune,
                            color: AppColors.warmWhite,
                            size: 22,
                          ),
                          if (filters.activeCount > 0)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.bronze,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
                                _ViewModeToggle(
                                  mode: viewMode,
                                  onChanged: (mode) => ref
                                      .read(watchViewModeProvider.notifier)
                                      .state = mode,
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
                    child: _ErrorView(
                      message: listState.errorMessage!,
                      onRetry: () =>
                          ref.read(watchListProvider.notifier).refresh(),
                    ),
                  )
                else if (listState.watches.isEmpty)
                  SliverFillRemaining(
                    child: _EmptyView(
                      onClear: () {
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

class _ViewModeToggle extends StatelessWidget {
  const _ViewModeToggle({
    required this.mode,
    required this.onChanged,
  });

  final WatchViewMode mode;
  final ValueChanged<WatchViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final border =
        AppColors.warmBorder;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.r8),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleBtn(
            icon: Icons.grid_view,
            selected: mode == WatchViewMode.grid,
            onTap: () => onChanged(WatchViewMode.grid),
          ),
          Container(width: 1, height: 28, color: border),
          _ToggleBtn(
            icon: Icons.view_agenda_outlined,
            selected: mode == WatchViewMode.list,
            onTap: () => onChanged(WatchViewMode.list),
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  const _ToggleBtn({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s8),
        color: selected
            ? (AppColors.sandSurface)
            : Colors.transparent,
        child: Icon(
          icon,
          size: 18,
          color: selected
              ? AppColors.bronze
              : (AppColors.textMutedLight),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.watch_outlined, size: 48, color: AppColors.bronze),
            const SizedBox(height: AppSpacing.s16),
            Text(
              'No watches match your filters',
              style: AppTypography.title.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Try adjusting brand, price, or style filters.',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondaryLight,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s20),
            OutlinedButton(
              onPressed: onClear,
              child: const Text('Clear filters'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.s16),
            Text(
              message,
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s20),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
