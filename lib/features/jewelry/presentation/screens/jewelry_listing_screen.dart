import 'package:flutter/material.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
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

  Future<void> _showSortSheet() async {
    final current = ref.read(jewelrySortProvider);
    final selected = await showSimpleSortSheet<JewelrySortOption>(
      context: context,
      options: JewelrySortOption.values,
      labelOf: (o) => o.label,
      current: current,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
    if (selected != null) {
      ref.read(jewelrySortProvider.notifier).state = selected;
    }
  }

  void _openFilters() {
    ref.read(jewelryFilterDraftProvider.notifier).syncFromApplied();
    context.push(AppRouteNames.jewelryFilters);
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(jewelryFilterProvider);
    final sort = ref.watch(jewelrySortProvider);
    final viewMode = ref.watch(jewelryViewModeProvider);
    final listAsync = ref.watch(jewelryListProvider);
    final listState = listAsync.valueOrNull;
    final muted = AppColors.textMutedLight;
    final title = filters.category ?? 'Accessories';
    final hasActiveFilters = filters.activeCount > 0;

    return AppScaffold(
      backgroundColor: AppColors.creamBg,
      appBar: AppBar(
        automaticallyImplyActions: false,
        title: Text(
          title == 'All Accessories' ? 'Accessories' : title,
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
              context.go(AppRouteNames.jewelry);
            }
          },
        ),
        actions: const [],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.s8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
            child: ListingSearchFilterBar(
              controller: _searchController,
              hintText: 'Search by name, SKU, metal, stone...',
              mutedColor: muted,
              activeFilterCount: hasActiveFilters ? 1 : 0,
              onFilterTap: _openFilters,
              onChanged: (v) =>
                  ref.read(jewelryFilterProvider.notifier).setSearchQuery(v),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          const JewelryCategoryChips(),
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
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                ViewModeToggle(
                  isGrid: viewMode == JewelryViewMode.grid,
                  onGrid: () => ref
                      .read(jewelryViewModeProvider.notifier)
                      .state = JewelryViewMode.grid,
                  onList: () => ref
                      .read(jewelryViewModeProvider.notifier)
                      .state = JewelryViewMode.list,
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
                listState == null || listState.isInitialLoading
                    ? 'Loading…'
                    : 'Showing ${listState.totalCount} Products',
                style: AppTypography.caption.copyWith(color: muted),
              ),
            ),
          ),
          Expanded(
            child: listState == null || listState.isInitialLoading
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : listState.errorMessage != null && listState.items.isEmpty
                    ? CatalogErrorState(
                        message:
                            listState.errorMessage ?? 'Something went wrong',
                        onRetry: () =>
                            ref.read(jewelryListProvider.notifier).refresh(),
                      )
                    : listState.items.isEmpty
                        ? CatalogEmptyState(
                            icon: Icons.diamond_outlined,
                            title: 'No products found',
                            message:
                                'Try clearing filters or adjusting search.',
                            actionLabel: 'Clear Filters',
                            onAction: () {
                              ref.read(jewelryFilterProvider.notifier).reset();
                              _searchController.clear();
                            },
                          )
                        : RefreshIndicator(
                            onRefresh: () => ref
                                .read(jewelryListProvider.notifier)
                                .refresh(),
                            child: CustomScrollView(
                              controller: _scrollController,
                              slivers: [
                                if (viewMode == JewelryViewMode.grid)
                                  JewelryGridSliver(
                                    items: listState.items,
                                    isLoadingMore: listState.isLoadingMore,
                                  )
                                else
                                  JewelryListSliver(
                                    items: listState.items,
                                    isLoadingMore: listState.isLoadingMore,
                                  ),
                                const SliverToBoxAdapter(
                                  child: SizedBox(height: AppSpacing.s24),
                                ),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

