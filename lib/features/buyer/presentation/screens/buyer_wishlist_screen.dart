import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/wishlist_provider.dart';
import '../../domain/models/wishlist_item.dart';
import '../widgets/buyer_layout.dart';

class BuyerWishlistScreen extends ConsumerWidget {
  const BuyerWishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(wishlistProvider);

    return BuyerLayout(
      title: 'My Wishlist',
      child: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 48,
                      color: AppColors.textMutedLight.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    Text(
                      'Your wishlist is empty',
                      style: AppTypography.title.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      'Tap the heart on diamonds, gemstones, jewelry, or watches to save them here.',
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.s16),
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.s12),
              itemBuilder: (context, index) {
                final item = items[index];
                return _WishlistTile(
                  item: item,
                  onRemove: () {
                    ref.read(wishlistProvider.notifier).remove(item.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Removed from wishlist'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _WishlistTile extends StatelessWidget {
  const _WishlistTile({
    required this.item,
    required this.onRemove,
  });

  final WishlistItem item;
  final VoidCallback onRemove;

  IconData get _icon => switch (item.category) {
        WishlistCategory.diamond => Icons.diamond_outlined,
        WishlistCategory.gemstone => Icons.auto_awesome,
        WishlistCategory.jewelry => Icons.workspace_premium_outlined,
        WishlistCategory.watch => Icons.watch_outlined,
      };

  String get _categoryLabel => switch (item.category) {
        WishlistCategory.diamond => 'Diamond',
        WishlistCategory.gemstone => 'Gemstone',
        WishlistCategory.jewelry => 'Jewelry',
        WishlistCategory.watch => 'Watch',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warmBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.sandSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: item.imageAsset != null
                ? Image.asset(
                    item.imageAsset!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      _icon,
                      color: AppColors.bronze,
                    ),
                  )
                : item.imageUrl != null
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          _icon,
                          color: AppColors.bronze,
                        ),
                      )
                    : Icon(_icon, color: AppColors.bronze),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _categoryLabel,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMutedLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.title.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.priceLabel,
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: onRemove,
            icon: const Icon(Icons.favorite, color: AppColors.error),
          ),
        ],
      ),
    );
  }
}
