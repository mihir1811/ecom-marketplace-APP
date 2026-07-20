import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/bullions_filter_provider.dart';
import '../../application/bullions_list_provider.dart';
import '../../domain/models/bullions_filter_state.dart';
import '../widgets/bullions_filter_drawer.dart';
import '../widgets/bullions_grid_view.dart';

class BullionsScreen extends ConsumerStatefulWidget {
  const BullionsScreen({super.key});

  @override
  ConsumerState<BullionsScreen> createState() => _BullionsScreenState();
}

class _BullionsScreenState extends ConsumerState<BullionsScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scrollController = ScrollController();
  final _tickerController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  Timer? _tickerTimer;

  static const _metalPriceItems = [
    _MetalPriceItem('Gold', 'XAU', '₹63,678', '+0.42%', Color(0xFFFFC94D)),
    _MetalPriceItem('Silver', 'XAG', '₹744', '+0.18%', Color(0xFF8EA4C8)),
    _MetalPriceItem('Palladium', 'XPD', '₹81,556', '+0.27%', Color(0xFF4AB5FF)),
    _MetalPriceItem('Copper', 'HG', '₹811', '+0.14%', Color(0xFFDD915E)),
    _MetalPriceItem('Platinum', 'XPT', '₹34,285', '+0.21%', Color(0xFFC6B28A)),
  ];

  static const _tickerCardWidth = 120.0;
  static const _tickerSeparator = AppSpacing.s12;

  static double get _tickerLoopExtent =>
      _metalPriceItems.length * _tickerCardWidth +
      (_metalPriceItems.length - 1) * _tickerSeparator;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final q = ref.read(bullionsFilterProvider).searchQuery;
    if (q.isNotEmpty) _searchController.text = q;
    WidgetsBinding.instance.addPostFrameCallback((_) => _startTicker());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tickerController.dispose();
    _searchDebounce?.cancel();
    _tickerTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _startTicker() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_tickerController.hasClients) return;
      final loop = _tickerLoopExtent;
      if (loop <= 0) return;
      var next = _tickerController.offset + 0.45;
      if (next >= loop) {
        next -= loop;
      }
      _tickerController.jumpTo(next);
    });
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(bullionsFilterProvider.notifier).setSearchQuery(value);
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 240) {
      ref.read(bullionsListProvider.notifier).loadNextPage();
    }
  }

  void _onBackPressed() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  void _openFilters() {
    ref.read(bullionsFilterDraftProvider.notifier).syncFromApplied();
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _clearFilters() {
    ref.read(bullionsFilterProvider.notifier).reset();
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filter = ref.watch(bullionsFilterProvider);
    final listAsync = ref.watch(bullionsListProvider);
    final viewMode = ref.watch(bullionsViewModeProvider);
    final variants = filter.availableVariants;

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const BullionsFilterDrawer(),
      endDrawerEnableOpenDragGesture: false,
      appBar: AppBar(
        automaticallyImplyActions: false,
        title: Text(
          'Bullions',
          style: AppTypography.headline.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _onBackPressed,
        ),
        actions: const [],
      ),
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16,
                  AppSpacing.s12,
                  AppSpacing.s16,
                  AppSpacing.s12,
                ),
                child: _MetalPricesTicker(controller: _tickerController),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _PinnedHeaderDelegate(
                  height: variants.isEmpty ? 122 : 164,
                  child: Container(
                  color: isDark ? AppColors.obsidianBg : AppColors.creamBg,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s16,
                    0,
                    AppSpacing.s16,
                    0,
                  ),
                  child: _PinnedControls(
                    filter: filter,
                    searchController: _searchController,
                    onSearchChanged: _onSearchChanged,
                    onOpenFilters: _openFilters,
                    onMetalSelected: (value) => ref
                        .read(bullionsFilterProvider.notifier)
                        .setMetalFilter(value),
                    onVariantSelected: (value) => ref
                        .read(bullionsFilterProvider.notifier)
                        .setSelectedVariant(value),
                  ),
                ),
              ),
            ),
            _BullionsBody(
              isDark: isDark,
              listAsync: listAsync,
              viewMode: viewMode,
              onRetry: () => ref.read(bullionsListProvider.notifier).refresh(),
              onClear: _clearFilters,
              onViewModeChanged: (mode) =>
                  ref.read(bullionsViewModeProvider.notifier).state = mode,
            ),
          ],
        ),
      ),
    );
  }
}

class _BullionsBody extends StatelessWidget {
  const _BullionsBody({
    required this.isDark,
    required this.listAsync,
    required this.viewMode,
    required this.onRetry,
    required this.onClear,
    required this.onViewModeChanged,
  });

  final bool isDark;
  final AsyncValue<BullionsListState> listAsync;
  final BullionsViewMode viewMode;
  final VoidCallback onRetry;
  final VoidCallback onClear;
  final ValueChanged<BullionsViewMode> onViewModeChanged;

  @override
  Widget build(BuildContext context) {
    final listState = listAsync.valueOrNull;
    final muted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    if (listState == null || listState.isInitialLoading) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (listState.errorMessage != null && listState.bullions.isEmpty) {
      return SliverFillRemaining(
        child: _ErrorView(message: listState.errorMessage!, onRetry: onRetry),
      );
    }

    if (listState.bullions.isEmpty) {
      return SliverFillRemaining(
        child: _EmptyView(onClear: onClear),
      );
    }

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s16,
              AppSpacing.s4,
              AppSpacing.s16,
              AppSpacing.s4,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Showing ${listState.bullions.length} of ${listState.totalCount} bullions',
                    style: AppTypography.caption.copyWith(
                      color: muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _ViewModeToggle(
                  mode: viewMode,
                  isDark: isDark,
                  onChanged: onViewModeChanged,
                ),
              ],
            ),
          ),
        ),
        if (viewMode == BullionsViewMode.grid)
          BullionsGridSliver(
            bullions: listState.bullions,
            isLoadingMore: listState.isLoadingMore,
          )
        else
          BullionsListSliver(
            bullions: listState.bullions,
            isLoadingMore: listState.isLoadingMore,
          ),
        const SliverToBoxAdapter(
          child: SizedBox(height: AppSpacing.s24),
        ),
      ],
    );
  }
}

class _PinnedControls extends StatelessWidget {
  const _PinnedControls({
    required this.filter,
    required this.searchController,
    required this.onSearchChanged,
    required this.onOpenFilters,
    required this.onMetalSelected,
    required this.onVariantSelected,
  });

  final BullionsFilterState filter;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onOpenFilters;
  final ValueChanged<BullionsMetalFilter> onMetalSelected;
  final ValueChanged<String?> onVariantSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRESETS:',
          style: AppTypography.caption.copyWith(
            color: AppColors.bronzeDark,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        _HorizontalChipRow(
          children: [
              for (final value in const [
              BullionsMetalFilter.all,
              BullionsMetalFilter.gold,
              BullionsMetalFilter.silver,
              BullionsMetalFilter.platinum,
              BullionsMetalFilter.palladium,
              BullionsMetalFilter.copper,
            ])
              _PresetChip(
                label: value.label,
                selected: filter.metalFilter == value,
                accent: _metalAccent(value),
                onTap: () => onMetalSelected(value),
              ),
          ],
        ),
        if (filter.availableVariants.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s8),
          _HorizontalChipRow(
            children: [
              for (final variant in filter.availableVariants)
                _VariantFilterChip(
                  label: variant,
                  selected: filter.selectedVariant == variant,
                  onTap: () => onVariantSelected(
                    filter.selectedVariant == variant ? null : variant,
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.s8),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.slateSurface : AppColors.warmWhite,
                    borderRadius: BorderRadius.circular(AppSpacing.r12),
                    border: Border.all(
                      color:
                          isDark ? AppColors.slateBorder : AppColors.warmBorder,
                    ),
                  ),
                  child: TextField(
                    controller: searchController,
                    textAlignVertical: TextAlignVertical.center,
                    onChanged: onSearchChanged,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search bullions...',
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
            _FilterButton(
              activeCount: filter.activeCount,
              onTap: onOpenFilters,
            ),
          ],
        ),
      ],
    );
  }

  Color _metalAccent(BullionsMetalFilter filter) {
    return switch (filter) {
      BullionsMetalFilter.all => AppColors.charcoal,
      BullionsMetalFilter.gold => const Color(0xFFFFC94D),
      BullionsMetalFilter.silver => const Color(0xFF8EA4C8),
      BullionsMetalFilter.platinum => const Color(0xFFC6B28A),
      BullionsMetalFilter.palladium => const Color(0xFF4AB5FF),
      BullionsMetalFilter.copper => const Color(0xFFDD915E),
    };
  }
}

class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _PinnedHeaderDelegate({
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
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}

class _MetalPricesTicker extends StatelessWidget {
  const _MetalPricesTicker({required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    const items = _BullionsScreenState._metalPriceItems;
    const loopCount = 2;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        border: Border.all(color: AppColors.warmBorder),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s16,
              vertical: AppSpacing.s12,
            ),
            decoration: const BoxDecoration(
              color: AppColors.charcoal,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.r12),
                topRight: Radius.circular(AppSpacing.r12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.show_chart, size: 16, color: AppColors.bronze),
                const SizedBox(width: AppSpacing.s8),
                Text(
                  'METAL PRICES',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.warmWhite,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 92,
            child: ListView.separated(
              controller: controller,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s12,
                vertical: AppSpacing.s8,
              ),
              itemBuilder: (context, index) =>
                  _MetalPriceCard(item: items[index % items.length]),
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.s12),
              itemCount: items.length * loopCount,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetalPriceItem {
  const _MetalPriceItem(
    this.name,
    this.code,
    this.price,
    this.change,
    this.border,
  );

  final String name;
  final String code;
  final String price;
  final String change;
  final Color border;
}

class _MetalPriceCard extends StatelessWidget {
  const _MetalPriceCard({required this.item});

  final _MetalPriceItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        border: Border.all(color: AppColors.warmBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            decoration: BoxDecoration(
              color: item.border,
              borderRadius: BorderRadius.circular(AppSpacing.circular),
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: AppTypography.label.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      item.code,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  item.price,
                  style: AppTypography.label.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  item.change,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HorizontalChipRow extends StatelessWidget {
  const _HorizontalChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox.shrink(),
        itemBuilder: (context, index) => children[index],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.s8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.r8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s4,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.charcoal : AppColors.warmWhite,
            borderRadius: BorderRadius.circular(AppSpacing.r8),
            border: Border.all(color: selected ? accent : AppColors.warmBorder),
          ),
          child: Text(
            label,
            style: AppTypography.label.copyWith(
              color: selected
                  ? AppColors.warmWhite
                  : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

class _VariantFilterChip extends StatelessWidget {
  const _VariantFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.s8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.r8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12,
            vertical: AppSpacing.s4,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.charcoal : AppColors.warmWhite,
            borderRadius: BorderRadius.circular(AppSpacing.r8),
            border: Border.all(
              color: selected ? AppColors.charcoal : AppColors.warmBorder,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: selected
                  ? AppColors.warmWhite
                  : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.activeCount,
    required this.onTap,
  });

  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.charcoal,
      borderRadius: BorderRadius.circular(AppSpacing.r12),
      child: InkWell(
        onTap: onTap,
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
              if (activeCount > 0)
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
    );
  }
}

class _ViewModeToggle extends StatelessWidget {
  const _ViewModeToggle({
    required this.mode,
    required this.isDark,
    required this.onChanged,
  });

  final BullionsViewMode mode;
  final bool isDark;
  final ValueChanged<BullionsViewMode> onChanged;

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
            selected: mode == BullionsViewMode.grid,
            isDark: isDark,
            onTap: () => onChanged(BullionsViewMode.grid),
          ),
          Container(width: 1, height: 28, color: border),
          _ToggleBtn(
            icon: Icons.view_agenda_outlined,
            selected: mode == BullionsViewMode.list,
            isDark: isDark,
            onTap: () => onChanged(BullionsViewMode.list),
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
            const Icon(Icons.account_balance_wallet_outlined,
                size: 48, color: AppColors.bronze),
            const SizedBox(height: AppSpacing.s16),
            Text(
              'No bullions match your filters',
              style: AppTypography.title.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Try adjusting metal type or search keywords.',
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

