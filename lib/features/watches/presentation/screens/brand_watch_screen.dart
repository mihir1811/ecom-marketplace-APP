import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/brand_watch_filter_provider.dart';
import '../../application/brand_watch_list_provider.dart';
import '../../domain/models/brand_watch_state.dart';
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
    // Set the brand name for the list provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(brandWatchListProvider.notifier).setBrandName(widget.brandName);
    });
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
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final filters = ref.watch(brandWatchFilterProvider);
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final muted = isDark
                ? AppColors.textMutedDark
                : AppColors.textMutedLight;
            final n = ref.read(brandWatchFilterProvider.notifier);

            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.s16,
                right: AppSpacing.s16,
                bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.s16,
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
                      children:
                          BrandWatchFilterState.styleOptions.map((style) {
                        final selected =
                            filters.selectedStyles.contains(style);
                        return _StyleChip(
                          label: style.toUpperCase(),
                          selected: selected,
                          isDark: isDark,
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
                          isDark: isDark,
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
                          isDark: isDark,
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
                          child: const Text('Reset'),
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
                          child: const Text('Apply'),
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
    final selected = await showModalBottomSheet<BrandWatchSortOption>(
      context: context,
      showDragHandle: true,
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
              for (final option in BrandWatchSortOption.values)
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
      ref.read(brandWatchFilterProvider.notifier).setSort(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filters = ref.watch(brandWatchFilterProvider);
    final listAsync = ref.watch(brandWatchListProvider);
    final listState = listAsync.valueOrNull;
    final muted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final logo = WatchBrandAssets.logoPath(widget.brandName);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyActions: false,
        title: Row(
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: Column(
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
                color: isDark ? AppColors.slateSurface : AppColors.warmWhite,
                borderRadius: BorderRadius.circular(AppSpacing.r12),
                border: Border.all(
                  color: isDark ? AppColors.slateBorder : AppColors.warmBorder,
                ),
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
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s12,
                            vertical: AppSpacing.s12,
                          ),
                          alignment: Alignment.centerLeft,
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      color: isDark
                          ? AppColors.slateBorder
                          : AppColors.warmBorder,
                    ),
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
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
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

          // Watch list
          Expanded(
            child: listState == null || listState.isInitialLoading
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : listState.errorMessage != null && listState.watches.isEmpty
                    ? _ErrorView(
                        message: listState.errorMessage!,
                        onRetry: () => ref
                            .read(brandWatchListProvider.notifier)
                            .refresh(),
                      )
                    : listState.watches.isEmpty
                        ? _EmptyView(
                            brandName: widget.brandName,
                            onClear: () {
                              ref
                                  .read(brandWatchFilterProvider.notifier)
                                  .reset();
                              _priceMinController.clear();
                              _priceMaxController.clear();
                            },
                          )
                        : WatchGridSliver(
                            watches: listState.watches,
                            isLoadingMore: listState.isLoadingMore,
                          ),
          ),
        ],
      ),
    );
  }
}

class _StyleChip extends StatelessWidget {
  const _StyleChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isDark;
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
              ? AppColors.charcoal
              : (isDark ? AppColors.slateSurface : AppColors.warmWhite),
          borderRadius: BorderRadius.circular(AppSpacing.r8),
          border: Border.all(
            color: selected
                ? AppColors.charcoal
                : (isDark ? AppColors.slateBorder : AppColors.warmBorder),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: selected
                ? AppColors.warmWhite
                : (isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight),
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
    required this.isDark,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final bool isDark;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.slateBorder : AppColors.warmBorder;

    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        onChanged: onChanged,
        style: AppTypography.caption.copyWith(
          fontSize: 13,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: AppTypography.caption.copyWith(
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            fontSize: 13,
          ),
          prefixText: '\$',
          prefixStyle: AppTypography.caption.copyWith(
            fontSize: 13,
          ),
          filled: true,
          fillColor:
              isDark ? AppColors.slateSurface : AppColors.warmWhite,
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

class _EmptyView extends StatelessWidget {
  const _EmptyView({
    required this.brandName,
    required this.onClear,
  });

  final String brandName;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.watch_outlined, size: 48, color: AppColors.bronze),
            const SizedBox(height: AppSpacing.s16),
            Text(
              'No $brandName watches match your filters',
              style:
                  AppTypography.title.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Try adjusting style or price range.',
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
