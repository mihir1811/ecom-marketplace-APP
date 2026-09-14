import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../home_feed_data.dart';

/// Compact horizontal brand / house row.
class HomeBrandRow extends StatelessWidget {
  const HomeBrandRow({
    required this.title,
    required this.items,
    required this.onTap,
    super.key,
  });

  final String title;
  final List<HomeBrandItem> items;
  final ValueChanged<HomeBrandItem> onTap;

  @override
  Widget build(BuildContext context) {
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
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s12),
            itemBuilder: (context, index) {
              final item = items[index];
              return _BrandChip(
                key: ValueKey(item.name),
                item: item,
                onTap: () => onTap(item),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BrandChip extends StatelessWidget {
  const _BrandChip({required this.item, required this.onTap, super.key});

  final HomeBrandItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = HomeFeedData.resolveImage(item.imageUrl);

    return Material(
      color: AppColors.card(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        side: BorderSide(color: AppColors.border(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 148,
          child: Row(
            children: [
              SizedBox(
                width: 72,
                height: 96,
                child: AppNetworkImage(url: imageUrl, memCacheWidth: 200),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s12,
                  ),
                  child: Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
                      height: 1.25,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
