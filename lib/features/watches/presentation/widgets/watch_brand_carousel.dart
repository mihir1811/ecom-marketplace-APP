import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/keyboard_aware.dart';
import '../../application/watch_filter_provider.dart';
import '../../domain/models/watch_brand_categories.dart';
import '../../domain/models/watch_filter_state.dart';
import 'watch_brand_assets.dart';

/// Featured brand strip with infinite auto-scroll (same pattern as diamond
/// filter [PairedShowcaseCarousel]: unbounded PageView + timer).
class WatchBrandCarousel extends ConsumerStatefulWidget {
  const WatchBrandCarousel({super.key});

  @override
  ConsumerState<WatchBrandCarousel> createState() => _WatchBrandCarouselState();
}

class _WatchBrandCarouselState extends ConsumerState<WatchBrandCarousel>
    with WidgetsBindingObserver {
  static const _brands = WatchBrandAssets.featuredBrands;
  static const _cardWidth = 140.0;
  static const _gap = AppSpacing.s12;
  static const _height = 88.0;
  static const _autoScrollInterval = Duration(seconds: 3);
  static const _listPad = AppSpacing.s16;

  PageController? _pageController;
  Timer? _autoScrollTimer;
  double? _viewportFraction;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _autoScrollTimer?.cancel();
    } else if (state == AppLifecycleState.resumed && mounted) {
      _startAutoScroll();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoScrollTimer?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  void _ensurePageController(double maxWidth) {
    if (maxWidth <= 0 || _brands.isEmpty) return;
    final nextFraction =
        ((_cardWidth + _gap) / maxWidth).clamp(0.2, 0.85);
    if (_pageController != null &&
        _viewportFraction != null &&
        (_viewportFraction! - nextFraction).abs() < 0.01) {
      return;
    }

    final initialPage = _pageController?.hasClients == true
        ? (_pageController!.page ?? (_brands.length * 100).toDouble()).round()
        : _brands.length * 100;

    _autoScrollTimer?.cancel();
    _pageController?.dispose();
    _viewportFraction = nextFraction;
    _pageController = PageController(
      initialPage: initialPage,
      viewportFraction: nextFraction,
    );
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (_brands.isEmpty || _pageController == null) return;
    _autoScrollTimer = Timer.periodic(_autoScrollInterval, (_) {
      final controller = _pageController;
      if (!mounted || controller == null || !controller.hasClients) return;
      final page = controller.page ?? 0;
      controller.animateToPage(
        page.round() + 1,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(watchFilterProvider.select((s) => s.brands));

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shop by Brand',
                        style: AppTypography.title.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      Text(
                        'Select one or more luxury houses',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted(context),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => showWatchBrandsDirectory(context),
                  child: Text(
                    'View All Brands',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.bronze,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          SizedBox(
            height: _height,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final controller = _pageController;
                final fraction = _viewportFraction;
                final needsSync = controller == null ||
                    fraction == null ||
                    (((_cardWidth + _gap) / width).clamp(0.2, 0.85) - fraction)
                            .abs() >=
                        0.01;

                if (needsSync) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    _ensurePageController(width);
                    setState(() {});
                  });
                }

                if (controller == null) {
                  return const SizedBox.shrink();
                }

                return NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollStartNotification &&
                        notification.dragDetails != null) {
                      _autoScrollTimer?.cancel();
                    } else if (notification is ScrollEndNotification) {
                      _startAutoScroll();
                    }
                    return false;
                  },
                  child: PageView.builder(
                    controller: controller,
                    padEnds: false,
                    itemBuilder: (context, index) {
                      final brand = _brands[index % _brands.length];
                      final isSelected = selected.contains(brand);
                      return Padding(
                        padding: const EdgeInsets.only(
                          left: _listPad / 2,
                          right: _gap / 2,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _BrandLogoCard(
                            brand: brand,
                            isSelected: isSelected,
                            onTap: () => ref
                                .read(watchFilterProvider.notifier)
                                .toggleBrand(brand),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandLogoCard extends StatelessWidget {
  const _BrandLogoCard({
    required this.brand,
    required this.isSelected,
    required this.onTap,
  });

  final String brand;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final logo = WatchBrandAssets.logoPath(brand);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: _WatchBrandCarouselState._cardWidth,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s12,
        ),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(AppSpacing.r12),
          border: Border.all(
            color: isSelected ? AppColors.bronze : AppColors.border(context),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: logo != null
            ? ColorFiltered(
                colorFilter: AppColors.isDark(context)
                    ? const ColorFilter.matrix(<double>[
                        -1,
                        0,
                        0,
                        0,
                        255,
                        0,
                        -1,
                        0,
                        0,
                        255,
                        0,
                        0,
                        -1,
                        0,
                        255,
                        0,
                        0,
                        0,
                        1,
                        0,
                      ])
                    : const ColorFilter.mode(
                        Colors.transparent,
                        BlendMode.dst,
                      ),
                child: Image.asset(
                  logo,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => _BrandFallback(brand: brand),
                ),
              )
            : _BrandFallback(brand: brand),
      ),
    );
  }
}

class _BrandFallback extends StatelessWidget {
  const _BrandFallback({required this.brand});

  final String brand;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        brand,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.label.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Category chips shown directly under the search bar.
class WatchCategoryChips extends ConsumerWidget {
  const WatchCategoryChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(watchFilterProvider.select((s) => s.categories));
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
        itemCount: WatchFilterState.categoryOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.s8),
        itemBuilder: (context, index) {
          final category = WatchFilterState.categoryOptions[index];
          return _CategoryChip(
            label: category.toUpperCase(),
            selected: selected.contains(category),
            onTap: () =>
                ref.read(watchFilterProvider.notifier).toggleCategory(category),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
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
          vertical: 8,
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
        child: Center(
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: selected
                  ? AppColors.onSelected(context)
                  : AppColors.textPrimary(context),
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showWatchBrandsDirectory(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.bg(context),
    builder: (context) => const WatchBrandsDirectorySheet(),
  );
}

class WatchBrandsDirectorySheet extends ConsumerStatefulWidget {
  const WatchBrandsDirectorySheet({super.key});

  @override
  ConsumerState<WatchBrandsDirectorySheet> createState() =>
      _WatchBrandsDirectorySheetState();
}

class _WatchBrandsDirectorySheetState
    extends ConsumerState<WatchBrandsDirectorySheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(watchFilterProvider.select((s) => s.brands));
    final muted = AppColors.textMuted(context);

    final filtered = _query.isEmpty
        ? watchBrandCategories
        : watchBrandCategories
              .map(
                (g) => WatchBrandLetterGroup(
                  letter: g.letter,
                  brands: g.brands
                      .where(
                        (b) => b.toLowerCase().contains(_query.toLowerCase()),
                      )
                      .toList(),
                ),
              )
              .where((g) => g.brands.isNotEmpty)
              .toList();

    return AppKeyboardInset(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            height: constraints.maxHeight * 0.92,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s20,
                    AppSpacing.s16,
                    AppSpacing.s8,
                    AppSpacing.s8,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Watch Brands',
                              style: AppTypography.headline.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.s4),
                            Text(
                              'Search and select brands.',
                              style: AppTypography.body.copyWith(
                                fontSize: 14,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s20,
                  ),
                  child: SizedBox(
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.field(context),
                        borderRadius: BorderRadius.circular(AppSpacing.r12),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        textAlignVertical: TextAlignVertical.center,
                        onChanged: (v) => setState(() => _query = v),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: context.tr(CatalogL10n.searchBrands),
                          prefixIcon: Icon(
                            Icons.search,
                            color: muted,
                            size: 20,
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 44,
                          ),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                  icon: Icon(
                                    Icons.clear,
                                    color: muted,
                                    size: 18,
                                  ),
                                )
                              : null,
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
                if (selected.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s8),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s20,
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${selected.length} selected',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.bronze,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => ref
                              .read(watchFilterProvider.notifier)
                              .clearBrands(),
                          child: Text(context.tr(CatalogL10n.clear)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.s4),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No brands match "$_query"',
                            style: AppTypography.body.copyWith(color: muted),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.s40,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final group = filtered[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  width: double.infinity,
                                  color: AppColors.surface(context),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.s8,
                                  ),
                                  child: Text(
                                    group.letter,
                                    textAlign: TextAlign.center,
                                    style: AppTypography.label.copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                for (final brand in group.brands)
                                  ListTile(
                                    title: Text(
                                      brand,
                                      style: AppTypography.label.copyWith(
                                        fontSize: 14,
                                      ),
                                    ),
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 14,
                                      color: AppColors.bronze,
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      final encodedBrand = Uri.encodeComponent(
                                        brand,
                                      );
                                      context.push(
                                        '/watches/brand/$encodedBrand',
                                      );
                                    },
                                  ),
                              ],
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s16,
                    AppSpacing.s8,
                    AppSpacing.s16,
                    AppSpacing.s16,
                  ),
                  child: SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.charcoal,
                        foregroundColor: AppColors.warmWhite,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        selected.isEmpty
                            ? context.tr(CatalogL10n.done)
                            : context.tr(CatalogL10n.applyBrandCount, {
                                'count': selected.length,
                                'brandLabel': context.tr(
                                  selected.length == 1
                                      ? CatalogL10n.brand
                                      : CatalogL10n.brands,
                                ),
                              }),
                        style: AppTypography.label.copyWith(
                          color: AppColors.warmWhite,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
