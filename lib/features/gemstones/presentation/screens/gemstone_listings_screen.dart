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
import '../../../../core/widgets/simple_sort_sheet.dart';
import '../../../../core/widgets/view_mode_toggle.dart';
import '../../../../core/widgets/dark_theme_scope.dart';
import '../../../ai_chat/application/ai_chat_back_navigation.dart';
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
    final muted = AppColors.textSecondary(context);

    return DarkThemeScope(
      child: AppScaffold(
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
            'Gemstone Results',
            style: AppTypography.title.copyWith(fontWeight: FontWeight.bold),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.s8),
              child: ViewModeToggle(
                style: ViewModeToggleStyle.labeled,
                isGrid: viewMode == GemstoneViewMode.grid,
                onGrid: () =>
                    ref.read(gemstoneViewModeProvider.notifier).state =
                        GemstoneViewMode.grid,
                onList: () =>
                    ref.read(gemstoneViewModeProvider.notifier).state =
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
                    Flexible(
                      child:
                          stateAsync.whenOrNull(
                            data: (s) => Text(
                              '${s.totalCount} gemstones found',
                              style: AppTypography.caption.copyWith(
                                color: muted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ) ??
                          const SizedBox.shrink(),
                    ),
                    TextButton(
                      onPressed: () =>
                          context.pushReplacement(AppRouteNames.gemstones),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Edit Filters'),
                    ),
                    TextButton.icon(
                      onPressed: () => _openSortSheet(context),
                      icon: const Icon(Icons.sort, size: 18),
                      label: Text(
                        ref.watch(
                          gemstoneSortProvider.select((s) => s.shortLabel),
                        ),
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textPrimary(context),
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.only(left: AppSpacing.s4),
                      ),
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
      ),
    );
  }
}
