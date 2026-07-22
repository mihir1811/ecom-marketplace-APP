import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
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

    return Scaffold(
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
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.s8),
            decoration: BoxDecoration(
              color: AppColors.sandSurface,
              borderRadius: BorderRadius.circular(AppSpacing.r8),
              border: Border.all(
                color: AppColors.warmBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ModeBtn(
                  icon: Icons.grid_view,
                  label: 'Grid',
                  selected: viewMode == GemstoneViewMode.grid,
                  onTap: () => ref
                      .read(gemstoneViewModeProvider.notifier)
                      .state = GemstoneViewMode.grid,
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: AppColors.warmBorder,
                ),
                _ModeBtn(
                  icon: Icons.view_list,
                  label: 'List',
                  selected: viewMode == GemstoneViewMode.list,
                  onTap: () => ref
                      .read(gemstoneViewModeProvider.notifier)
                      .state = GemstoneViewMode.list,
                ),
              ],
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
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  if (state.gemstones.isEmpty) {
                    return Center(
                      child: Text(
                        'No gemstones match your filters.',
                        style: AppTypography.body.copyWith(color: muted),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(gemstoneListProvider.notifier).refresh(),
                    child: viewMode == GemstoneViewMode.grid
                        ? GridView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(AppSpacing.s16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: AppSpacing.s12,
                              mainAxisSpacing: AppSpacing.s12,
                              childAspectRatio: 0.72,
                            ),
                            itemCount: state.gemstones.length +
                                (state.isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= state.gemstones.length) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                );
                              }
                              final g = state.gemstones[index];
                              return GemstoneCardGrid(
                                key: ValueKey(g.id),
                                gemstone: g,
                              );
                            },
                          )
                        : ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(AppSpacing.s16),
                            itemCount: state.gemstones.length +
                                (state.isLoadingMore ? 1 : 0),
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSpacing.s12),
                            itemBuilder: (context, index) {
                              if (index >= state.gemstones.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(AppSpacing.s16),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              }
                              final g = state.gemstones[index];
                              return GemstoneCardList(
                                key: ValueKey(g.id),
                                gemstone: g,
                              );
                            },
                          ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (e, _) => Center(child: Text('$e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeBtn extends StatelessWidget {
  const _ModeBtn({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.bronze : Colors.transparent,
          borderRadius: selected ? BorderRadius.circular(AppSpacing.r8) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? AppColors.warmWhite : AppColors.textMutedLight,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color:
                    selected ? AppColors.warmWhite : AppColors.textMutedLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
