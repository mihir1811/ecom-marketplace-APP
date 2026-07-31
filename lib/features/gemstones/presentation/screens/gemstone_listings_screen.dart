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
import '../../../../core/widgets/catalog_list_loading.dart';
import '../../../../core/widgets/view_mode_toggle.dart';
import '../../../comparison/presentation/widgets/comparison_bottom_bar.dart';
import '../../application/gemstone_list_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(gemstoneListProvider);
    final viewMode = ref.watch(gemstoneViewModeProvider);
    final muted =
        AppColors.textSecondaryLight;

    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Gemstone Results',
          style: AppTypography.title.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.s8),
            child: ViewModeToggle(
              style: ViewModeToggleStyle.labeled,
              isGrid: viewMode == GemstoneViewMode.grid,
              onGrid: () => ref.read(gemstoneViewModeProvider.notifier).state =
                  GemstoneViewMode.grid,
              onList: () => ref.read(gemstoneViewModeProvider.notifier).state =
                  GemstoneViewMode.list,
            ),
          ),
        ],
      ),
      body: ComparisonTrayHost(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
              child: Row(
                children: [
                  stateAsync.whenOrNull(
                        data: (s) => Text(
                          '${s.totalCount} gemstones found',
                          style: AppTypography.caption.copyWith(color: muted),
                        ),
                      ) ??
                      const SizedBox.shrink(),
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        context.pushReplacement(AppRouteNames.gemstones),
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
                    return CatalogListLoading(
                      isGrid: viewMode == GemstoneViewMode.grid,
                    );
                  }
                  if (state.gemstones.isEmpty) {
                    return CatalogEmptyState(
                      icon: Icons.diamond_outlined,
                      title: 'No gemstones match your filters.',
                      message: 'Try adjusting your search criteria.',
                      actionLabel: 'Edit Filters',
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
