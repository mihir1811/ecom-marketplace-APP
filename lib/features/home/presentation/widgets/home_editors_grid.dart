import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../home_feed_data.dart';

/// Sparse 2-up editorial product cards (distinct from rail cards).
class HomeEditorsGrid extends StatelessWidget {
  const HomeEditorsGrid({
    required this.title,
    required this.items,
    required this.onItemTap,
    super.key,
  });

  final String title;
  final List<HomeProductItem> items;
  final ValueChanged<HomeProductItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    final shown = items.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.title.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const gap = AppSpacing.s12;
              final cardW = (constraints.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: AppSpacing.s20,
                children: [
                  for (final item in shown)
                    SizedBox(
                      width: cardW,
                      child: _EditorsCard(
                        key: ValueKey(item.id),
                        item: item,
                        onTap: () => onItemTap(item),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EditorsCard extends StatelessWidget {
  const _EditorsCard({required this.item, required this.onTap, super.key});

  final HomeProductItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = HomeFeedData.resolveImage(item.imageUrl);

    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 0.85,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.r8),
              child: AppNetworkImage(url: imageUrl, memCacheWidth: 600),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.label.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            item.priceLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary(context),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
