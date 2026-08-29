import 'package:flutter/material.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/catalog_listing_header_row.dart';
import '../../../../core/widgets/catalog_empty_state.dart';
import '../../../../core/widgets/catalog_error_state.dart';
import '../../../../core/widgets/catalog_list_loading.dart';
import '../../../../core/widgets/simple_sort_sheet.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../comparison/presentation/widgets/comparison_bottom_bar.dart';
import '../../application/gemstone_list_provider.dart';
import '../../domain/models/gemstone_sort_option.dart';
import '../widgets/gemstone_card.dart';

/// Grid/list results screen for gemstone search.
class GemstoneListingsScreen extends ConsumerStatefulWidget {
  const GemstoneListingsScreen({super.key});

  @override
  ConsumerState<GemstoneListingsScreen> createState() =>
      _GemstoneListingsScreenState();
}

class _GemstoneListingsScreenState
    extends ConsumerState<GemstoneListingsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(gemstoneListProvider.notifier).loadNextPage();
    }
  }

  Future<void> _openSortSheet(BuildContext context) async {
    final selected = await showSimpleSortSheet<GemstoneSortOption>(
      context: context,
      options: GemstoneSortOption.values,
      labelOf: (o) => o.label,
      current: ref.read(gemstoneSortProvider),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
    if (selected != null) {
      ref.read(gemstoneSortProvider.notifier).state = selected;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(gemstoneListProvider);
    final viewMode = ref.watch(gemstoneViewModeProvider);
    final sortOption = ref.watch(gemstoneSortProvider);
    final countLabel = stateAsync.when(
      data: (state) => state.isInitialLoading
          ? context.tr(CatalogL10n.loading)
          : context.tr(CatalogL10n.showingGemstones, {
              'count': '${state.totalCount}',
            }),
      loading: () => context.tr(CatalogL10n.loading),
      error: (_, __) => '',
    );

    return AppScaffold(
      appBar: AppTopBar(title: context.tr(CatalogL10n.gemstoneResults)),
      body: ComparisonTrayHost(
        child: Column(
          children: [
            CatalogListingHeaderRow(
              sortLabel: sortOption.label,
              onSortTap: () => _openSortSheet(context),
              isGrid: viewMode == GemstoneViewMode.grid,
              onGrid: () =>
                  ref.read(gemstoneViewModeProvider.notifier).state =
                      GemstoneViewMode.grid,
              onList: () =>
                  ref.read(gemstoneViewModeProvider.notifier).state =
                      GemstoneViewMode.list,
              countLabel: countLabel,
              onEditFilters: () =>
                  context.pushReplacement(AppRouteNames.gemstones),
            ),
            const Divider(height: 0),
            Expanded(
              child: stateAsync.when(
                data: (state) {
                  if (state.isInitialLoading) {
                    return CatalogListLoading(
                      isGrid: viewMode == GemstoneViewMode.grid,
                    );
                  }
                  if (state.gemstones.isEmpty) {
                    return CatalogEmptyState(
                      icon: Icons.diamond_outlined,
                      title: context.tr(CatalogL10n.noGemstones),
                      message: context.tr(CatalogL10n.adjustSearchCriteria),
                      actionLabel: context.tr(CatalogL10n.editFilters),
                      onAction: () =>
                          context.pushReplacement(AppRouteNames.gemstones),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(gemstoneListProvider.notifier).refresh(),
                    child: viewMode == GemstoneViewMode.grid
                        ? GemstoneGridView(
                            key: const ValueKey('gemstone-grid'),
                            gemstones: state.gemstones,
                            scrollController: _scrollController,
                            isLoadingMore: state.isLoadingMore,
                          )
                        : GemstoneListView(
                            key: const ValueKey('gemstone-list'),
                            gemstones: state.gemstones,
                            scrollController: _scrollController,
                            isLoadingMore: state.isLoadingMore,
                          ),
                  );
                },
                loading: () => CatalogListLoading(
                  isGrid: viewMode == GemstoneViewMode.grid,
                ),
                error: (e, _) => CatalogErrorState(
                  message: '$e',
                  onRetry: () =>
                      ref.read(gemstoneListProvider.notifier).refresh(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
