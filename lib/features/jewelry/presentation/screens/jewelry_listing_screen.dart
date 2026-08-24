import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/catalog_screen_shell.dart';
import '../../../../core/widgets/catalog_empty_state.dart';
import '../../../../core/widgets/catalog_error_state.dart';
import '../../../../core/widgets/listing_search_filter_bar.dart';
import '../../../../core/widgets/simple_sort_sheet.dart';
import '../../../../core/widgets/view_mode_toggle.dart';
import '../../application/jewelry_filter_provider.dart';
import '../../application/jewelry_list_provider.dart';
import '../../domain/models/jewelry_filter_state.dart';
import '../widgets/jewelry_listing_views.dart';
import '../widgets/jewelry_sub_category_chips.dart';

class JewelryListingScreen extends ConsumerStatefulWidget {
  const JewelryListingScreen({this.initialCategory, super.key});

  final String? initialCategory;

  @override
  ConsumerState<JewelryListingScreen> createState() =>
      _JewelryListingScreenState();
}

class _JewelryListingScreenState extends ConsumerState<JewelryListingScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final q = ref.read(jewelryFilterProvider).searchQuery;
    if (q.isNotEmpty) _searchController.text = q;
    final initial = widget.initialCategory;
    if (initial != null && initial.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(jewelryFilterProvider.notifier).setCategory(initial);
      });
    }
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
      ref.read(jewelryListProvider.notifier).loadNextPage();
    }
  }

  void _openFilters() {
    ref.read(jewelryFilterDraftProvider.notifier).syncFromApplied();
    context.push(AppRouteNames.jewelryFilters);
  }

  @override
  Widget build(BuildContext context) {
    final title = ref.watch(
      jewelryFilterProvider.select((s) => s.category ?? 'Jewelry'),
    );
    final displayTitle = switch (title) {
      'All Accessories' => 'Accessories',
      _ => title,
    };

    return CatalogScreenShell(
      title: displayTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.s8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
              child: _JewelrySearchBar(
                searchController: _searchController,
                onOpenFilters: _openFilters,
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            Expanded(
              child: _JewelryResultsView(
                scrollController: _scrollController,
                searchController: _searchController,
              ),
            ),
          ],
        ),
    );
  }
}

class _JewelrySearchBar extends ConsumerWidget {
  const _JewelrySearchBar({
    required this.searchController,
    required this.onOpenFilters,
  });

  final TextEditingController searchController;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilterCount = ref.watch(
      jewelryFilterProvider.select((s) => s.activeCount > 0 ? 1 : 0),
    );

    return ListingSearchFilterBar(
      controller: searchController,
      hintText: 'Search by name, SKU, metal, stone...',
      mutedColor: AppColors.textMuted(context),
      activeFilterCount: activeFilterCount,
      onFilterTap: onOpenFilters,
      onChanged: (v) =>
          ref.read(jewelryFilterProvider.notifier).setSearchQuery(v),
    );
  }
}

class _JewelryHeaderRow extends ConsumerWidget {
  const _JewelryHeaderRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortLabel = ref.watch(jewelrySortProvider.select((s) => s.label));
    final isGrid = ref.watch(
      jewelryViewModeProvider.select((mode) => mode == JewelryViewMode.grid),
    );
    final countLabel = ref.watch(
      jewelryListProvider.select((value) {
        final listState = value.valueOrNull;
        return listState == null || listState.isInitialLoading
            ? 'Loading…'
            : 'Showing ${listState.totalCount} Products';
      }),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16,
            AppSpacing.s8,
            AppSpacing.s16,
            AppSpacing.s4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: TextButton.icon(
                  onPressed: () =>
                      showSimpleSortSheet<JewelrySortOption>(
                        context: context,
                        options: JewelrySortOption.values,
                        labelOf: (o) => o.label,
                        current: ref.read(jewelrySortProvider),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                      ).then((selected) {
                        if (selected != null) {
                          ref.read(jewelrySortProvider.notifier).state =
                              selected;
                        }
                      }),
                  icon: const Icon(Icons.sort, size: 18),
                  label: Text(
                    'Sort by: $sortLabel',
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textPrimary(context),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
              ViewModeToggle(
                isGrid: isGrid,
                onGrid: () => ref.read(jewelryViewModeProvider.notifier).state =
                    JewelryViewMode.grid,
                onList: () => ref.read(jewelryViewModeProvider.notifier).state =
                    JewelryViewMode.list,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16,
            0,
            AppSpacing.s16,
            AppSpacing.s8,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              countLabel,
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted(context),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _JewelryResultsView extends ConsumerWidget {
  const _JewelryResultsView({
    required this.scrollController,
    required this.searchController,
  });

  final ScrollController scrollController;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listState = ref.watch(jewelryListProvider).valueOrNull;
    final isGrid = ref.watch(
      jewelryViewModeProvider.select((mode) => mode == JewelryViewMode.grid),
    );

    if (listState == null || listState.isInitialLoading) {
      return CustomScrollView(
        controller: scrollController,
        slivers: const [
          SliverToBoxAdapter(child: JewelryCategoryChips()),
          SliverToBoxAdapter(child: _JewelryHeaderRow()),
          SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ],
      );
    }

    if (listState.errorMessage != null && listState.items.isEmpty) {
      return CustomScrollView(
        controller: scrollController,
        slivers: [
          const SliverToBoxAdapter(child: JewelryCategoryChips()),
          const SliverToBoxAdapter(child: _JewelryHeaderRow()),
          SliverFillRemaining(
            child: CatalogErrorState(
              message: listState.errorMessage ?? 'Something went wrong',
              onRetry: () => ref.read(jewelryListProvider.notifier).refresh(),
            ),
          ),
        ],
      );
    }

    if (listState.items.isEmpty) {
      return CustomScrollView(
        controller: scrollController,
        slivers: [
          const SliverToBoxAdapter(child: JewelryCategoryChips()),
          const SliverToBoxAdapter(child: _JewelryHeaderRow()),
          SliverFillRemaining(
            child: CatalogEmptyState(
              icon: Icons.diamond_outlined,
              title: 'No products found',
              message: 'Try clearing filters or adjusting search.',
              actionLabel: 'Clear Filters',
              onAction: () {
                ref.read(jewelryFilterProvider.notifier).reset();
                searchController.clear();
              },
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(jewelryListProvider.notifier).refresh(),
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          const SliverToBoxAdapter(child: JewelryCategoryChips()),
          const SliverToBoxAdapter(child: _JewelryHeaderRow()),
          if (isGrid)
            JewelryGridSliver(
              items: listState.items,
              isLoadingMore: listState.isLoadingMore,
            )
          else
            JewelryListSliver(
              items: listState.items,
              isLoadingMore: listState.isLoadingMore,
            ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s24)),
        ],
      ),
    );
  }
}
