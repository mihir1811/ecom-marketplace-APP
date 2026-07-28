import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
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
            return BullionCard(
              key: ValueKey(bullion.id),
              bullion: bullion,
              layout: BullionCardLayout.grid,
              onTap: () => openBullionDetail(context, bullion),
            );
          },
          childCount: bullions.length + (isLoadingMore ? 1 : 0),
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      sliver: SliverList.separated(
        itemCount: bullions.length + (isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s12),
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
          return BullionCard(
            key: ValueKey('list-${bullion.id}'),
            bullion: bullion,
            layout: BullionCardLayout.list,
            onTap: () => openBullionDetail(context, bullion),
          );
        },
      ),
    );
  }
}

