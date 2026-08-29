import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
// import '../../../../core/utils/app_currency.dart'; // Metal prices (AURUM) disabled
// import '../../../../core/utils/format_catalog_price.dart'; // Metal prices (AURUM) disabled
import '../../../../core/widgets/catalog_listing_header_row.dart';
import '../../../../core/widgets/catalog_screen_shell.dart';
import '../../../../core/widgets/catalog_empty_state.dart';
import '../../../../core/widgets/catalog_error_state.dart';
import '../../../../core/widgets/listing_search_filter_bar.dart';
import '../../../../core/widgets/simple_sort_sheet.dart';
import '../../application/bullions_filter_provider.dart';
import '../../application/bullions_list_provider.dart';
// import '../../application/metal_prices_provider.dart'; // Metal prices (AURUM) disabled
import '../../domain/models/bullions_filter_state.dart';
// import '../../domain/models/metal_spot_price.dart'; // Metal prices (AURUM) disabled
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
  // final _tickerController = ScrollController(); // Metal prices ticker disabled
  final _searchController = TextEditingController();
  // late final AnimationController _tickerAnimation; // Metal prices ticker disabled
  Timer? _searchDebounce;
  // double _lastTickerValue = 0; // Metal prices ticker disabled
  // int _tickerItemCount = 5; // Metal prices ticker disabled

  // static const _tickerCardWidth = 120.0;
  // static const _tickerSeparator = AppSpacing.s12;
  // double get _tickerLoopExtent =>
  //     _tickerItemCount * _tickerCardWidth +
  //     (_tickerItemCount - 1) * _tickerSeparator;

  @override
  void initState() {
    super.initState();
    // Metal prices ticker animation — disabled
    // _tickerAnimation = AnimationController(
    //   vsync: this,
    //   duration: const Duration(seconds: 18),
    // )..addListener(_advanceTicker);
    _scrollController.addListener(_onScroll);
    final q = ref.read(bullionsFilterProvider).searchQuery;
    if (q.isNotEmpty) _searchController.text = q;
    // WidgetsBinding.instance.addPostFrameCallback((_) => _startTicker());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    // _tickerController.dispose();
    // _tickerAnimation
    //   ..removeListener(_advanceTicker)
    //   ..dispose();
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // void _startTicker() {
  //   _lastTickerValue = 0;
  //   _tickerAnimation
  //     ..reset()
  //     ..repeat();
  // }

  // void _advanceTicker() {
  //   if (!_tickerController.hasClients) return;
  //   final loop = _tickerLoopExtent;
  //   if (loop <= 0) return;
  //   final value = _tickerAnimation.value;
  //   final rawDelta = value - _lastTickerValue;
  //   _lastTickerValue = value;
  //   final normalizedDelta = rawDelta >= 0 ? rawDelta : rawDelta + 1;
  //   final next = (_tickerController.offset + (normalizedDelta * loop)) % loop;
  //   _tickerController.jumpTo(next);
  // }

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
    // Metal prices provider listen (would trigger AURUM fetch) — disabled
    // ref.listen(metalSpotPricesProvider, (_, next) {
    //   final count = next.valueOrNull?.length ?? 0;
    //   if (count > 0 && count != _tickerItemCount) {
    //     setState(() => _tickerItemCount = count);
    //   }
    // });

    return CatalogScreenShell(
      scaffoldKey: _scaffoldKey,
      endDrawer: const BullionsFilterDrawer(),
      title: context.tr(CatalogL10n.bullions),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.s8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
            child: _BullionsSearchBar(
              searchController: _searchController,
              onSearchChanged: _onSearchChanged,
              onOpenFilters: _openFilters,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                const SliverToBoxAdapter(child: _BullionsPresetsSection()),
                const SliverToBoxAdapter(child: _BullionsHeaderRow()),
                _BullionsBody(
                  onRetry: () =>
                      ref.read(bullionsListProvider.notifier).refresh(),
                  onClear: _clearFilters,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BullionsBody extends ConsumerWidget {
  const _BullionsBody({required this.onRetry, required this.onClear});
  final VoidCallback onRetry;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(bullionsListProvider);
    final viewMode = ref.watch(bullionsViewModeProvider);
    final listState = listAsync.valueOrNull;

    if (listState == null || listState.isInitialLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (listState.errorMessage != null && listState.bullions.isEmpty) {
      return SliverFillRemaining(
        child: CatalogErrorState(
          message: listState.errorMessage!,
          onRetry: onRetry,
        ),
      );
    }

    if (listState.bullions.isEmpty) {
      return SliverFillRemaining(
        child: CatalogEmptyState(
          icon: Icons.account_balance_wallet_outlined,
          title: context.tr(CatalogL10n.noBullions),
          message: context.tr(CatalogL10n.adjustBullionFilters),
          actionLabel: context.tr(CatalogL10n.clearAll),
          onAction: onClear,
        ),
      );
    }

    return SliverMainAxisGroup(
      slivers: [
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
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s24)),
      ],
    );
  }
}

class _BullionsSearchBar extends ConsumerWidget {
  const _BullionsSearchBar({
    required this.searchController,
    required this.onSearchChanged,
    required this.onOpenFilters,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilterCount = ref.watch(
      bullionsFilterProvider.select((s) => s.activeCount),
    );
    final muted = AppColors.textMuted(context);

    return ListingSearchFilterBar(
      controller: searchController,
      hintText: context.tr(CatalogL10n.searchBullions),
      mutedColor: muted,
      activeFilterCount: activeFilterCount,
      onFilterTap: onOpenFilters,
      onChanged: onSearchChanged,
    );
  }
}

class _BullionsPresetsSection extends ConsumerWidget {
  const _BullionsPresetsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(bullionsFilterProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Column(
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
                  onTap: () => ref
                      .read(bullionsFilterProvider.notifier)
                      .setMetalFilter(value),
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
                    onTap: () => ref
                        .read(bullionsFilterProvider.notifier)
                        .setSelectedVariant(
                          filter.selectedVariant == variant ? null : variant,
                        ),
                  ),
              ],
            ),
          ],
        ],
      ),
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

class _BullionsHeaderRow extends ConsumerWidget {
  const _BullionsHeaderRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortLabel = ref.watch(bullionsSortProvider.select((s) => s.label));
    final isGrid = ref.watch(
      bullionsViewModeProvider.select((mode) => mode == BullionsViewMode.grid),
    );
    final countLabel = ref.watch(
      bullionsListProvider.select((value) {
        final listState = value.valueOrNull;
        return listState == null || listState.isInitialLoading
            ? context.tr(CatalogL10n.loading)
            : context.tr(CatalogL10n.showingProducts, {
                'count': listState.totalCount,
              });
      }),
    );

    return CatalogListingHeaderRow(
      sortLabel: sortLabel,
      onSortTap: () => showSimpleSortSheet<BullionsSortOption>(
        context: context,
        options: BullionsSortOption.values,
        labelOf: (o) => o.label,
        current: ref.read(bullionsSortProvider),
      ).then((selected) {
        if (selected != null) {
          ref.read(bullionsSortProvider.notifier).state = selected;
        }
      }),
      isGrid: isGrid,
      onGrid: () =>
          ref.read(bullionsViewModeProvider.notifier).state = BullionsViewMode.grid,
      onList: () =>
          ref.read(bullionsViewModeProvider.notifier).state = BullionsViewMode.list,
      countLabel: countLabel,
    );
  }
}

/* Metal prices UI (AURUM) — disabled; restore with section above.
class _MetalPricesTicker extends ConsumerWidget {
  const _MetalPricesTicker({required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pricesAsync = ref.watch(metalSpotPricesProvider);
    final items = pricesAsync.valueOrNull ?? const <MetalSpotPrice>[];
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
                const Spacer(),
                if (pricesAsync.isLoading)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppColors.bronze,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 92,
            child: items.isEmpty
                ? Center(
                    child: pricesAsync.hasError
                        ? TextButton.icon(
                            onPressed: () => ref
                                .read(metalSpotPricesProvider.notifier)
                                .retry(),
                            icon: const Icon(Icons.refresh, size: 16),
                    label: Text(context.tr(CatalogL10n.retryLivePrices)),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.bronze,
                              textStyle: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : Text(
                            'Loading live prices…',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textMuted(context),
                            ),
                          ),
                  )
                : ListView.separated(
                    controller: controller,
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s12,
                      vertical: AppSpacing.s8,
                    ),
                    itemBuilder: (context, index) => _MetalPriceCard(
                      item: items[index % items.length],
                    ),
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.s12),
                    itemCount: items.length * loopCount,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s12,
              0,
              AppSpacing.s12,
              AppSpacing.s12,
            ),
            child: Text(
              'Approximate live spot prices — actual market prices may vary slightly.',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted(context),
                fontSize: 10,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetalPriceCard extends StatelessWidget {
  const _MetalPriceCard({required this.item});

  final MetalSpotPrice item;

  @override
  Widget build(BuildContext context) {
    final accent = _metalAccent(item.id);
    final changePositive = item.changePercent >= 0;
    final changeLabel =
        '${changePositive ? '+' : ''}${item.changePercent.toStringAsFixed(2)}%';
    final priceLabel =
        '${AppCurrency.format(formatGroupedPrice(item.priceUsd))}${item.unitLabel}';

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 3,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(AppSpacing.circular),
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: AppTypography.label.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      item.code,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted(context),
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  priceLabel,
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  changeLabel,
                  style: AppTypography.caption.copyWith(
                    color: changePositive ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _metalAccent(String id) {
    return switch (id) {
      'gold' => const Color(0xFFFFC94D),
      'silver' => const Color(0xFF8EA4C8),
      'platinum' => const Color(0xFFC6B28A),
      'palladium' => const Color(0xFF4AB5FF),
      'copper' => const Color(0xFFDD915E),
      _ => AppColors.bronze,
    };
  }
}

*/

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
        itemBuilder: (context, index) =>
            Align(alignment: Alignment.center, child: children[index]),
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
          height: 32,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.selectedFill(context)
                : AppColors.card(context),
            borderRadius: BorderRadius.circular(AppSpacing.r8),
            border: Border.all(
              color: selected ? accent : AppColors.border(context),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.label.copyWith(
              color: selected
                  ? AppColors.onSelected(context)
                  : AppColors.textPrimary(context),
              fontWeight: FontWeight.w700,
              height: 1.0,
              leadingDistribution: TextLeadingDistribution.even,
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
          height: 32,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.selectedFill(context)
                : AppColors.card(context),
            borderRadius: BorderRadius.circular(AppSpacing.r8),
            border: Border.all(
              color: selected
                  ? AppColors.selectedFill(context)
                  : AppColors.border(context),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: selected
                  ? AppColors.onSelected(context)
                  : AppColors.textPrimary(context),
              fontWeight: FontWeight.w700,
              height: 1.0,
              leadingDistribution: TextLeadingDistribution.even,
            ),
          ),
        ),
      ),
    );
  }
}
