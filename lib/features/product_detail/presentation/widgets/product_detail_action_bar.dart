import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../buyer/application/wishlist_provider.dart';
import '../../../cart/application/cart_provider.dart';
import '../../domain/models/product_detail.dart';

/// Sticky commitment bar. Same three actions for every segment.
class ProductDetailActionBar extends ConsumerWidget {
  const ProductDetailActionBar({required this.detail, super.key});

  final ProductDetail detail;

  void _notify(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlisted = ref.watch(isInWishlistProvider(detail.id));
    final purchasable = detail.isPurchasable;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.warmWhite,
        border: Border(top: BorderSide(color: AppColors.warmBorder)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s12,
      ),
      child: Row(
        children: [
          _IconAction(
            icon: wishlisted ? Icons.favorite : Icons.favorite_border,
            tint: wishlisted ? AppColors.terracotta : AppColors.charcoal,
            tooltip: wishlisted ? 'Remove from wishlist' : 'Save to wishlist',
            onTap: () {
              final added = ref
                  .read(wishlistProvider.notifier)
                  .toggle(detail.toWishlistItem());
              _notify(
                context,
                added ? 'Saved to wishlist' : 'Removed from wishlist',
              );
            },
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.push(AppRouteNames.buyerInquiryNew),
              child: const Text('Inquiry'),
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: ElevatedButton(
              onPressed: purchasable
                  ? () {
                      final added = ref
                          .read(cartProvider.notifier)
                          .addItem(detail.toCartItem());
                      _notify(
                        context,
                        added ? 'Added to cart' : 'Already in your cart',
                      );
                    }
                  : null,
              child: Text(purchasable ? 'Add to cart' : 'Unavailable'),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.tint,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color tint;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.r8),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.r8),
            border: Border.all(color: AppColors.warmBorder),
          ),
          child: Icon(icon, size: 20, color: tint),
        ),
      ),
    );
  }
}