import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/catalog_empty_state.dart';
import '../../../../core/widgets/catalog_error_state.dart';
import '../../../../core/widgets/simple_sort_sheet.dart';
import '../../../comparison/presentation/widgets/comparison_bottom_bar.dart';
import '../../application/brand_watch_filter_provider.dart';
import '../../application/brand_watch_list_provider.dart';
import '../../domain/models/watch_filter_state.dart';
import '../widgets/watch_brand_assets.dart';
import '../widgets/watch_grid_view.dart';

class BrandWatchScreen extends ConsumerStatefulWidget {
  const BrandWatchScreen({required this.brandName, super.key});

  final String brandName;

  @override
  ConsumerState<BrandWatchScreen> createState() => _BrandWatchScreenState();
}

class _BrandWatchScreenState extends ConsumerState<BrandWatchScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 240) {
      ref.read(brandWatchListProvider.notifier).loadNextPage();
    }
  }

  void _openFilters() {
    ref.read(brandWatchFilterDraftProvider.notifier).syncFromApplied();
    context.push(AppRouteNames.brandWatchFiltersPath(widget.brandName));
  }

  Future<void> _showSortSheet() async {
    final current = ref.read(brandWatchSortProvider);
    final selected = await showSimpleSortSheet<WatchSortOption>(
      context: context,
      options: brandWatchSortOptions,
      labelOf: (o) => o.label,
      current: current,
    );
    if (selected != null) {
      ref.read(brandWatchSortProvider.notifier).state = selected;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(brandWatchFilterProvider);
    final sort = ref.watch(brandWatchSortProvider);
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
                            'Sort: ${sort.label}',
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
                          onTap: _openFilters,
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
                          onRetry: () => ref
                              .read(brandWatchListProvider.notifier)
                              .refresh(),
                        )
                      : listState.watches.isEmpty
                          ? CatalogEmptyState(
                              icon: Icons.watch_outlined,
                              title:
                                  'No ${widget.brandName} watches match your filters',
                              message:
                                  context.tr(CatalogL10n.adjustWatchFilters),
                              actionLabel: context.tr(CatalogL10n.clearAll),
                              onAction: () {
                                ref
                                    .read(brandWatchFilterProvider.notifier)
                                    .reset();
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
