import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/watch_filter_provider.dart';
import '../../domain/models/watch_brand_categories.dart';
import '../../domain/models/watch_filter_state.dart';
import 'watch_brand_assets.dart';

class WatchBrandCarousel extends ConsumerWidget {
  const WatchBrandCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(watchFilterProvider.select((s) => s.brands));
    return Column(
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
                      ),
                    ),
                    Text(
                      'Select one or more luxury houses',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMutedLight,
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
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
            itemCount: WatchBrandAssets.featuredBrands.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.s12),
            itemBuilder: (context, index) {
              final brand = WatchBrandAssets.featuredBrands[index];
              final logo = WatchBrandAssets.logoPath(brand);
              final isSelected = selected.contains(brand);

              return GestureDetector(
                onTap: () =>
                    ref.read(watchFilterProvider.notifier).toggleBrand(brand),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 140,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s16,
                    vertical: AppSpacing.s12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warmWhite,
                    borderRadius: BorderRadius.circular(AppSpacing.r12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.bronze
                          : (AppColors.warmBorder),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: logo != null
                      ? Image.asset(
                          logo,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              _BrandFallback(brand: brand),
                        )
                      : _BrandFallback(brand: brand),
                ),
              );
            },
          ),
        ),
      ],
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
    final selected =
        ref.watch(watchFilterProvider.select((s) => s.categories));
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
            onTap: () => ref
                .read(watchFilterProvider.notifier)
                .toggleCategory(category),
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
          vertical: AppSpacing.s12,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.charcoal
              : (AppColors.warmWhite),
          borderRadius: BorderRadius.circular(AppSpacing.r8),
          border: Border.all(
            color: selected
                ? AppColors.charcoal
                : (AppColors.warmBorder),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: selected
                ? AppColors.warmWhite
                : (AppColors.textPrimaryLight),
            fontWeight: FontWeight.w600,
            fontSize: 12,
            letterSpacing: 0.4,
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
    backgroundColor: AppColors.creamBg,
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
    final height = MediaQuery.sizeOf(context).height * 0.92;
    final muted =
        AppColors.textMutedLight;

    final filtered = _query.isEmpty
        ? watchBrandCategories
        : watchBrandCategories
            .map((g) => WatchBrandLetterGroup(
                  letter: g.letter,
                  brands: g.brands
                      .where((b) =>
                          b.toLowerCase().contains(_query.toLowerCase()))
                      .toList(),
                ))
            .where((g) => g.brands.isNotEmpty)
            .toList();

    return SizedBox(
      height: height,
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
                          color: AppColors.textSecondaryLight,
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
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
            child: SizedBox(
              height: 44,
              child: Container(
                decoration: BoxDecoration(
                  color:
                      AppColors.warmWhite,
                  borderRadius: BorderRadius.circular(AppSpacing.r12),
                  border: Border.all(
                    color: AppColors.warmBorder,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  textAlignVertical: TextAlignVertical.center,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search brands...',
                    prefixIcon:
                        Icon(Icons.search, color: muted, size: 20),
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
                            icon: Icon(Icons.clear, color: muted, size: 18),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
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
                    child: const Text('Clear'),
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
                    padding: const EdgeInsets.only(bottom: AppSpacing.s40),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final group = filtered[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            width: double.infinity,
                            color: AppColors.sandSurface,
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
                                style: AppTypography.label
                                    .copyWith(fontSize: 14),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: AppColors.bronze,
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                final encodedBrand = Uri.encodeComponent(brand);
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
                      ? 'Done'
                      : 'Apply ${selected.length} brand${selected.length == 1 ? '' : 's'}',
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
  }
}
