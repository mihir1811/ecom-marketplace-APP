import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/marketplace_product_card_shell.dart';
import '../home_feed_data.dart';

/// Title + See all + horizontal product rail.
class HomeProductRail extends StatelessWidget {
  const HomeProductRail({
    required this.title,
    required this.seeAllLabel,
    required this.items,
    required this.onSeeAll,
    required this.onItemTap,
    super.key,
  });

  final String title;
  final String seeAllLabel;
  final List<HomeProductItem> items;
  final VoidCallback onSeeAll;
  final ValueChanged<HomeProductItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
          child: Row(
            children: [
              Expanded(
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
              TextButton(
                onPressed: onSeeAll,
                child: Text(
                  seeAllLabel,
                  style: AppTypography.label.copyWith(
                    color: AppColors.bronze,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        SizedBox(
          height: 268,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s12),
            itemBuilder: (context, index) {
              final item = items[index];
              return _RailCard(
                key: ValueKey(item.id),
                item: item,
                onTap: () => onItemTap(item),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RailCard extends StatelessWidget {
  const _RailCard({required this.item, required this.onTap, super.key});

  final HomeProductItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = HomeFeedData.resolveImage(item.imageUrl);

    return SizedBox(
      width: 168,
      child: MarketplaceProductCardShell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: AppNetworkImage(url: imageUrl, memCacheWidth: 400),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s12,
                AppSpacing.s12,
                AppSpacing.s12,
                AppSpacing.s16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.cardLineGap),
                  Text(
                    item.priceLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary(context),
                      fontWeight: FontWeight.w500,
                    ),
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
