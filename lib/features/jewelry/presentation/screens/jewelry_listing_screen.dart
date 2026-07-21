import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/jewelry_filter_provider.dart';
import '../../application/jewelry_list_provider.dart';
import '../../domain/models/jewelry_filter_state.dart';
import '../widgets/jewelry_category_chips.dart';
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
    final selected = await showModalBottomSheet<JewelrySortOption>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
              for (final option in JewelrySortOption.values)
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
      ref.read(jewelrySortProvider.notifier).state = selected;
    }
  }

  void _openFilters() {
    ref.read(jewelryFilterDraftProvider.notifier).syncFromApplied();
    context.push(AppRouteNames.jewelryFilters);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filters = ref.watch(jewelryFilterProvider);
    final sort = ref.watch(jewelrySortProvider);
    final viewMode = ref.watch(jewelryViewModeProvider);
    final listAsync = ref.watch(jewelryListProvider);
    final listState = listAsync.valueOrNull;
    final muted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final title = filters.category ?? 'Accessories';
    final hasActiveFilters = filters.activeCount > 0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.obsidianBg : AppColors.creamBg,
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
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.slateSurface
                            : AppColors.warmWhite,
                        borderRadius: BorderRadius.circular(AppSpacing.r12),
                        border: Border.all(
                          color: isDark
                              ? AppColors.slateBorder
                              : AppColors.warmBorder,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        textAlignVertical: TextAlignVertical.center,
                        onChanged: (v) => ref
                            .read(jewelryFilterProvider.notifier)
                            .setSearchQuery(v),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Search by name, SKU, metal, stone...',
                          prefixIcon:
                              Icon(Icons.search, color: muted, size: 22),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 48,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s8,
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
                          if (hasActiveFilters)
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
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                _ViewModeToggle(
                  mode: viewMode,
                  isDark: isDark,
                  onChanged: (mode) =>
                      ref.read(jewelryViewModeProvider.notifier).state = mode,
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
                    ? _MessageView(
                        icon: Icons.error_outline,
                        iconColor: AppColors.error,
                        title: listState.errorMessage ?? 'Something went wrong',
                        actionLabel: 'Retry',
                        onAction: () =>
                            ref.read(jewelryListProvider.notifier).refresh(),
                      )
                    : listState.items.isEmpty
                        ? _MessageView(
                            icon: Icons.diamond_outlined,
                            iconColor: AppColors.bronze,
                            title: 'No products found',
                            subtitle:
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

class _ViewModeToggle extends StatelessWidget {
  const _ViewModeToggle({
    required this.mode,
    required this.isDark,
    required this.onChanged,
  });

  final JewelryViewMode mode;
  final bool isDark;
  final ValueChanged<JewelryViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final border = isDark ? AppColors.slateBorder : AppColors.warmBorder;
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
            selected: mode == JewelryViewMode.grid,
            isDark: isDark,
            onTap: () => onChanged(JewelryViewMode.grid),
          ),
          Container(width: 1, height: 28, color: border),
          _ToggleBtn(
            icon: Icons.view_agenda_outlined,
            selected: mode == JewelryViewMode.list,
            isDark: isDark,
            onTap: () => onChanged(JewelryViewMode.list),
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
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s8),
        color: selected
            ? (isDark ? AppColors.slateSurface : AppColors.sandSurface)
            : Colors.transparent,
        child: Icon(
          icon,
          size: 18,
          color: selected
              ? AppColors.bronze
              : (isDark
                  ? AppColors.textMutedDark
                  : AppColors.textMutedLight),
        ),
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: iconColor),
            const SizedBox(height: AppSpacing.s16),
            Text(
              title,
              style: AppTypography.title.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.s8),
              Text(
                subtitle!,
                style: AppTypography.body.copyWith(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppSpacing.s20),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
