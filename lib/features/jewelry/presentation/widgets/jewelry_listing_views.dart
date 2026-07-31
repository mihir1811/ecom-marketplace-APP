import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../domain/models/jewelry.dart';
import 'jewelry_product_card.dart';

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
            onTap: () => openJewelryDetail(context, item),
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
          childAspectRatio: 0.68,
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
              onTap: () => openJewelryDetail(context, item),
            );
          },
          childCount: items.length + (isLoadingMore ? 1 : 0),
        ),
      ),
    );
  }
}
