import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/catalog_empty_state.dart';
import '../../../../core/widgets/catalog_error_state.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../application/wishlist_provider.dart';
import '../../domain/models/wishlist_item.dart';
import '../widgets/buyer_layout.dart';

class BuyerWishlistScreen extends ConsumerWidget {
  const BuyerWishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlist = ref.watch(wishlistProvider);
    final items = wishlist.items;

    return BuyerLayout(
      title: 'My Wishlist',
      child: wishlist.isLoading && items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : wishlist.errorMessage != null && items.isEmpty
              ? CatalogErrorState(
                  message: wishlist.errorMessage!,
                  onRetry: () =>
                      ref.read(wishlistProvider.notifier).refresh(),
                )
              : items.isEmpty
                  ? const CatalogEmptyState(
                      icon: Icons.favorite_border,
                      title: 'Your wishlist is empty',
                      message:
                          'Tap the heart on diamonds, gemstones, jewelry, or watches to save them here.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.s16),
                      itemCount: items.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.s12),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _WishlistTile(
                          key: ValueKey(item.id),
                          item: item,
                          onRemove: () async {
                            await ref
                                .read(wishlistProvider.notifier)
                                .remove(item.id, productType: item.productType);
                            if (!context.mounted) return;
                            final error =
                                ref.read(wishlistProvider).errorMessage;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  error ?? 'Removed from wishlist',
                                ),
                                duration: const Duration(seconds: 1),
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
    super.key,
  });

  final WishlistItem item;
  final VoidCallback onRemove;

  IconData get _icon => switch (item.category) {
        WishlistCategory.diamond => Icons.diamond_outlined,
        WishlistCategory.gemstone => Icons.auto_awesome,
        WishlistCategory.jewelry => Icons.workspace_premium_outlined,
        WishlistCategory.watch => Icons.watch_outlined,
        WishlistCategory.bullion => Icons.savings_outlined,
      };

  String get _categoryLabel => switch (item.category) {
        WishlistCategory.diamond => 'Diamond',
        WishlistCategory.gemstone => 'Gemstone',
        WishlistCategory.jewelry => 'Jewelry',
        WishlistCategory.watch => 'Watch',
        WishlistCategory.bullion => 'Bullion',
      };

  void _openProduct(BuildContext context) {
    if (openRememberedProductDetail(context, item.id)) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Open this product from the catalog to see its details.',
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warmWhite,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _openProduct(context),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.s16),
          decoration: BoxDecoration(
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
                        ? AppNetworkImage(
                            url: item.imageUrl!,
                            fit: BoxFit.cover,
                            error: Icon(
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
        ),
      ),
    );
  }
}
