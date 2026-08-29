import 'package:flutter/material.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/catalog_empty_state.dart';
import '../../../../core/widgets/catalog_error_state.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/simple_sort_sheet.dart';
import '../../application/brand_watch_filter_provider.dart';
import '../../application/brand_watch_list_provider.dart';
import '../../domain/models/brand_watch_state.dart';
import '../widgets/watch_brand_assets.dart';
import '../widgets/watch_grid_view.dart';
import '../../../comparison/presentation/widgets/comparison_bottom_bar.dart';
import '../../../../core/utils/app_currency.dart';

class BrandWatchScreen extends ConsumerStatefulWidget {
  const BrandWatchScreen({required this.brandName, super.key});

  final String brandName;

  @override
  ConsumerState<BrandWatchScreen> createState() => _BrandWatchScreenState();
}

class _BrandWatchScreenState extends ConsumerState<BrandWatchScreen> {
  final _scrollController = ScrollController();
  final _priceMinController = TextEditingController();
  final _priceMaxController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final filters = ref.read(brandWatchFilterProvider);
    if (filters.priceMin.isNotEmpty) {
      _priceMinController.text = filters.priceMin;
    }
    if (filters.priceMax.isNotEmpty) {
      _priceMaxController.text = filters.priceMax;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(brandWatchListProvider.notifier).setBrandName(widget.brandName);
    });
  }

  @override
  void didUpdateWidget(covariant BrandWatchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.brandName != widget.brandName) {
      ref.read(brandWatchListProvider.notifier).setBrandName(widget.brandName);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _priceMinController.dispose();
    _priceMaxController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 240) {
      ref.read(brandWatchListProvider.notifier).loadNextPage();
    }
  }

  Future<void> _showFiltersSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final filters = ref.watch(brandWatchFilterProvider);
            final muted = AppColors.textMuted(context);
            final n = ref.read(brandWatchFilterProvider.notifier);

            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.s16,
                right: AppSpacing.s16,
                bottom:
                    MediaQuery.viewInsetsOf(context).bottom +
                    MediaQuery.paddingOf(context).bottom +
                    AppSpacing.s16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Filters',
                    style: AppTypography.title.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  Text(
                    'Style',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: muted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: AppSpacing.s8,
                      runSpacing: AppSpacing.s8,
                      children: BrandWatchFilterState.styleOptions.map((style) {
                        final selected = filters.selectedStyles.contains(style);
                        return _StyleChip(
                          label: style.toUpperCase(),
                          selected: selected,
                          onTap: () => n.toggleStyle(style),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s20),
                  Text(
                    'Price Range',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: muted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Row(
                    children: [
                      Expanded(
                        child: _PriceInput(
                          controller: _priceMinController,
                          hint: 'Min',
                          onChanged: n.setPriceMin,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s8,
                        ),
                        child: Text(
                          '—',
                          style: AppTypography.body.copyWith(color: muted),
                        ),
                      ),
                      Expanded(
                        child: _PriceInput(
                          controller: _priceMaxController,
                          hint: 'Max',
                          onChanged: n.setPriceMax,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            n.reset();
                            _priceMinController.clear();
                            _priceMaxController.clear();
                          },
                          child: Text(context.tr(CatalogL10n.reset)),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.charcoal,
                            foregroundColor: AppColors.warmWhite,
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(context.tr(CatalogL10n.apply)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showSortSheet() async {
    final current = ref.read(brandWatchFilterProvider).sort;
    final selected = await showSimpleSortSheet<BrandWatchSortOption>(
      context: context,
      options: BrandWatchSortOption.values,
      labelOf: (o) => o.label,
      current: current,
    );
    if (selected != null) {
      ref.read(brandWatchFilterProvider.notifier).setSort(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(brandWatchFilterProvider);
    final listAsync = ref.watch(brandWatchListProvider);
    final listState = listAsync.valueOrNull;
    final muted = AppColors.textMuted(context);
    final logo = WatchBrandAssets.logoPath(widget.brandName);

    return AppScaffold(
      appBar: AppTopBar(
        title: widget.brandName,
        titleWidget: Row(
          children: [
            if (logo != null)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.s8),
                child: Image.asset(
                  logo,
                  height: 28,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.watch,
                    size: 28,
                    color: AppColors.bronze,
                  ),
                ),
              ),
            Expanded(
              child: Text(
                widget.brandName,
                style: AppTypography.headline.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: ComparisonTrayHost(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s16,
                AppSpacing.s12,
                AppSpacing.s16,
                0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(AppSpacing.r12),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: _showSortSheet,
                          icon: const Icon(Icons.sort, size: 18),
                          label: Text(
                            'Sort: ${filters.sort.label}',
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textPrimary(context),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s12,
                              vertical: AppSpacing.s12,
                            ),
                            alignment: Alignment.centerLeft,
                          ),
                        ),
                      ),
                      Container(width: 1, color: AppColors.border(context)),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _showFiltersSheet,
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(AppSpacing.r12),
                          ),
                          child: SizedBox(
                            width: 52,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.tune,
                                  size: 22,
                                  color: AppColors.textPrimary(context),
                                ),
                                if (filters.hasActiveFilters)
                                  Positioned(
                                    top: 10,
                                    right: 12,
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
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s16,
                AppSpacing.s8,
                AppSpacing.s16,
                0,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  listState == null
                      ? 'Loading…'
                      : '${listState.totalCount} watches',
                  style: AppTypography.caption.copyWith(color: muted),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Expanded(
              child: listState == null || listState.isInitialLoading
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : listState.errorMessage != null && listState.watches.isEmpty
                  ? CatalogErrorState(
                      message: listState.errorMessage!,
                      onRetry: () =>
                          ref.read(brandWatchListProvider.notifier).refresh(),
                    )
                  : listState.watches.isEmpty
                  ? CatalogEmptyState(
                      icon: Icons.watch_outlined,
                      title:
                          'No ${widget.brandName} watches match your filters',
                      message: context.tr(CatalogL10n.adjustStyleOrPrice),
                      actionLabel: context.tr(CatalogL10n.clearAll),
                      onAction: () {
                        ref.read(brandWatchFilterProvider.notifier).reset();
                        _priceMinController.clear();
                        _priceMaxController.clear();
                      },
                    )
                  : CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        WatchGridSliver(
                          watches: listState.watches,
                          isLoadingMore: listState.isLoadingMore,
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: AppSpacing.s24),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StyleChip extends StatelessWidget {
  const _StyleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s12,
        ),
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
          style: AppTypography.caption.copyWith(
            color: selected
                ? AppColors.onSelected(context)
                : (AppColors.textPrimary(context)),
            fontWeight: FontWeight.w600,
            fontSize: 12,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

class _PriceInput extends StatelessWidget {
  const _PriceInput({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final borderColor = AppColors.border(context);

    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        onChanged: onChanged,
        style: AppTypography.caption.copyWith(fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: AppTypography.caption.copyWith(
            color: AppColors.textMuted(context),
            fontSize: 13,
          ),
          prefixText: AppCurrency.symbol,
          prefixStyle: AppTypography.caption.copyWith(fontSize: 13),
          filled: true,
          fillColor: AppColors.field(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.r8),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.r8),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.r8),
            borderSide: const BorderSide(color: AppColors.bronze),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s8,
            vertical: AppSpacing.s8,
          ),
        ),
      ),
    );
  }
}
