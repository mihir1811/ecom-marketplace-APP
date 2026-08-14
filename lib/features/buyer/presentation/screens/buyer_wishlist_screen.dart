import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/catalog_empty_state.dart';
import '../../../../core/widgets/catalog_error_state.dart';
import '../../../product_detail/application/catalog_product_detail_loader.dart';
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
                          'Tap the heart on diamonds, gemstones, jewelry, watches, or bullion to save them here.',
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

class _WishlistTile extends ConsumerStatefulWidget {
  const _WishlistTile({
    required this.item,
    required this.onRemove,
    super.key,
  });

  final WishlistItem item;
  final VoidCallback onRemove;

  @override
  ConsumerState<_WishlistTile> createState() => _WishlistTileState();
}

class _WishlistTileState extends ConsumerState<_WishlistTile> {
  bool _opening = false;

  WishlistItem get item => widget.item;

  IconData get _icon => switch (item.category) {
        WishlistCategory.diamond => Icons.diamond_outlined,
        WishlistCategory.gemstone => Icons.auto_awesome,
        WishlistCategory.jewelry => Icons.workspace_premium_outlined,
        WishlistCategory.watch => Icons.watch_outlined,
        WishlistCategory.bullion => Icons.savings_outlined,
      };

  String get _categoryLabel => FavoriteProductType.label(item.productType);

  Future<void> _openProduct() async {
    if (_opening) return;
    if (openRememberedProductDetail(context, item.id)) return;

    setState(() => _opening = true);
    try {
      final detail = await CatalogProductDetailLoader.load(
        ref.read,
        productType: item.productType,
        productId: item.id,
      );
      if (!mounted) return;
      if (detail == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open this product right now.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      openProductDetail(context, detail);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warmWhite,
      borderRadius: BorderRadius.circular(AppSpacing.r20),
      child: InkWell(
        onTap: _opening ? null : _openProduct,
        borderRadius: BorderRadius.circular(AppSpacing.r20),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.s16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.r20),
            border: Border.all(color: AppColors.warmBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.sandSurface,
                  borderRadius: BorderRadius.circular(AppSpacing.r16),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMutedLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    if (item.subtitle.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                    if (item.priceLabel.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.cardLineGap),
                      Text(
                        item.priceLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_opening)
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  tooltip: 'Remove from wishlist',
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.favorite, color: AppColors.error),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
