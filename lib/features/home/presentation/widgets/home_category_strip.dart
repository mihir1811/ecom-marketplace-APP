import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../home_feed_data.dart';

/// Horizontal circular category strip.
class HomeCategoryStrip extends StatelessWidget {
  const HomeCategoryStrip({
    required this.items,
    required this.onTap,
    super.key,
  });

  final List<HomeCategoryItem> items;
  final ValueChanged<HomeCategoryItem> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s16),
        itemBuilder: (context, index) {
          final item = items[index];
          return _CategoryCircle(
            key: ValueKey(item.route),
            item: item,
            onTap: () => onTap(item),
          );
        },
      ),
    );
  }
}

class _CategoryCircle extends StatelessWidget {
  const _CategoryCircle({required this.item, required this.onTap, super.key});

  final HomeCategoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.r12),
      child: SizedBox(
        width: 80,
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.border(context),
                  width: 1,
                ),
              ),
              child: ClipOval(
                child: AppNetworkImage(url: item.imageUrl, memCacheWidth: 200),
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              item.titleKey,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(context),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
