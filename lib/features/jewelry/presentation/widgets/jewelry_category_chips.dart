import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/jewelry_filter_provider.dart';
import '../../domain/models/jewelry.dart';
import 'jewelry_product_card.dart';

class JewelryActiveFilterChips extends ConsumerWidget {
  const JewelryActiveFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(jewelryFilterProvider);
    final labels = filters.summaryLabels;
    if (labels.isEmpty) return const SizedBox.shrink();
    final border = AppColors.warmBorder;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
        itemCount: labels.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.s8),
        itemBuilder: (context, index) {
          if (index == labels.length) {
            return GestureDetector(
              onTap: () => ref.read(jewelryFilterProvider.notifier).reset(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.bronze),
                ),
                child: Text(
                  'Clear All',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.bronze,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }
          final label = labels[index];
          return Container(
            padding: const EdgeInsets.only(left: 12, right: 6),
            decoration: BoxDecoration(
              color: AppColors.warmWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  icon: const Icon(Icons.close, size: 14),
                  onPressed: () => ref
                      .read(jewelryFilterProvider.notifier)
                      .removeSummaryLabel(label),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class JewelryListSliver extends StatelessWidget {
  const JewelryListSliver({
    required this.items,
    this.isLoadingMore = false,
    super.key,
  });

  final List<Jewelry> items;
  final bool isLoadingMore;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      sliver: SliverList.separated(
        itemCount: items.length + (isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s16),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.s16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          final item = items[index];
          return JewelryProductListCard(
            key: ValueKey(item.id),
            item: item,
          );
        },
      ),
    );
  }
}

class JewelryGridSliver extends StatelessWidget {
  const JewelryGridSliver({
    required this.items,
    this.isLoadingMore = false,
    super.key,
  });

  final List<Jewelry> items;
  final bool isLoadingMore;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.s12,
          mainAxisSpacing: AppSpacing.s12,
          childAspectRatio: 0.62,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index >= items.length) {
              return const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            final item = items[index];
            return JewelryProductCard(
              key: ValueKey('grid-${item.id}'),
              item: item,
              compact: true,
            );
          },
          childCount: items.length + (isLoadingMore ? 1 : 0),
        ),
      ),
    );
  }
}
