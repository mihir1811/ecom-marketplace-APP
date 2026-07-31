import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/catalog_content_sized_grid.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../domain/models/billion.dart';
import 'billion_card.dart';

class BullionsGridSliver extends StatelessWidget {
  const BullionsGridSliver({
    required this.bullions,
    this.isLoadingMore = false,
    super.key,
  });

  final List<Bullion> bullions;
  final bool isLoadingMore;

  @override
  Widget build(BuildContext context) {
    return CatalogContentSizedGridSliver(
      itemCount: bullions.length,
      isLoadingMore: isLoadingMore,
      itemBuilder: (context, index) {
        final bullion = bullions[index];
        return BullionCardGrid(
          key: ValueKey(bullion.id),
          bullion: bullion,
          onTap: () => openBullionDetail(context, bullion),
        );
      },
    );
  }
}

class BullionsListSliver extends StatelessWidget {
  const BullionsListSliver({
    required this.bullions,
    this.isLoadingMore = false,
    super.key,
  });

  final List<Bullion> bullions;
  final bool isLoadingMore;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
      sliver: SliverList.separated(
        itemCount: bullions.length + (isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s16),
        itemBuilder: (context, index) {
          if (index >= bullions.length) {
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
          final bullion = bullions[index];
          return BullionCardList(
            key: ValueKey('list-${bullion.id}'),
            bullion: bullion,
            onTap: () => openBullionDetail(context, bullion),
          );
        },
      ),
    );
  }
}
