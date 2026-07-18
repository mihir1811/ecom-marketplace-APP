import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/router/route_names.dart';
import '../../application/diamond_list_provider.dart';
import '../../application/diamond_search_provider.dart';
import '../widgets/diamond_sorting_bottom_sheet.dart';
import '../widgets/diamond_grid_view.dart';
import '../widgets/diamond_list_view.dart';
import '../widgets/diamond_list_empty_state.dart';
import '../widgets/diamond_list_loading.dart';

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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(diamondListProvider.notifier).loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(diamondListProvider);
    final viewMode = ref.watch(diamondViewModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.title,
          style: AppTypography.title.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.s8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slateSurface : AppColors.sandSurface,
              borderRadius: BorderRadius.circular(AppSpacing.r8),
              border: Border.all(
                color: isDark ? AppColors.slateBorder : AppColors.warmBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ViewModeButton(
                  icon: Icons.grid_view,
                  label: 'Grid',
                  isSelected: viewMode == ViewMode.grid,
                  onTap: () => ref.read(diamondViewModeProvider.notifier).state = ViewMode.grid,
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: isDark ? AppColors.slateBorder : AppColors.warmBorder,
                ),
                _ViewModeButton(
                  icon: Icons.view_list,
                  label: 'List',
                  isSelected: viewMode == ViewMode.list,
                  onTap: () => ref.read(diamondViewModeProvider.notifier).state = ViewMode.list,
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
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
                ) ?? const SizedBox.shrink(),
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
                        color: isDark ? AppColors.slateBorder : AppColors.warmBorder,
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
                  onPressed: () =>
                      context.pushReplacement(widget.searchRoute),
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
                  return DiamondListLoading(isGrid: viewMode == ViewMode.grid);
                }
                if (state.errorMessage != null && state.diamonds.isEmpty) {
                  return _buildError(state.errorMessage!);
                }
                if (state.diamonds.isEmpty) {
                  return DiamondListEmptyState(
                    onResetFilters: () {
                      ref.read(diamondSearchProvider.notifier).reset();
                    },
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.read(diamondListProvider.notifier).refresh(),
                  child: viewMode == ViewMode.grid
                      ? DiamondGridView(
                          diamonds: state.diamonds,
                          scrollController: _scrollController,
                          isLoadingMore: state.isLoadingMore,
                        )
                      : DiamondListView(
                          diamonds: state.diamonds,
                          scrollController: _scrollController,
                          isLoadingMore: state.isLoadingMore,
                        ),
                );
              },
              loading: () => DiamondListLoading(isGrid: viewMode == ViewMode.grid),
              error: (error, _) => _buildError(error.toString()),
            ),
          ),
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

class _ViewModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewModeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.bronze : Colors.transparent,
          borderRadius: isSelected ? BorderRadius.circular(AppSpacing.r8) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.warmWhite : AppColors.textMutedLight,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.warmWhite : AppColors.textMutedLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
