import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../cart/application/cart_provider.dart';
import '../../domain/models/product_detail.dart';

/// Sticky commitment bar. Keep only the primary decision actions here.
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
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.push(AppRouteNames.buyerInquiryNew),
              child: const Text('Make an offer'),
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