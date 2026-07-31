import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../domain/models/watch.dart';
import 'watch_card_grid.dart';

class WatchGridSliver extends StatelessWidget {
  const WatchGridSliver({
    required this.watches,
    this.isLoadingMore = false,
    super.key,
  });

  final List<Watch> watches;
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
            if (index >= watches.length) {
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
            final watch = watches[index];
            return WatchCardGrid(
              key: ValueKey(watch.id),
              watch: watch,
              onTap: () => openWatchDetail(context, watch),
            );
          },
          childCount: watches.length + (isLoadingMore ? 1 : 0),
        ),
      ),
    );
  }
}

class WatchListSliver extends StatelessWidget {
  const WatchListSliver({
    required this.watches,
    this.isLoadingMore = false,
    super.key,
  });

  final List<Watch> watches;
  final bool isLoadingMore;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
      sliver: SliverList.separated(
        itemCount: watches.length + (isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s16),
        itemBuilder: (context, index) {
          if (index >= watches.length) {
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
          final watch = watches[index];
          return WatchCardList(
            key: ValueKey('list-${watch.id}'),
            watch: watch,
            onTap: () => openWatchDetail(context, watch),
          );
        },
      ),
    );
  }
}
