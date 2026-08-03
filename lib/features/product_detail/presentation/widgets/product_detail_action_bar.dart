import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/error/result.dart';
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

  Future<void> _addToCart(BuildContext context, WidgetRef ref) async {
    if (!ref.read(authProvider).isAuthenticated) {
      _notify(context, 'Please sign in to add items to your cart');
      context.push(AppRouteNames.login);
      return;
    }

    final result = await ref.read(cartProvider.notifier).addProduct(
          productId: detail.id,
          productType: detail.apiProductType,
        );
    if (!context.mounted) return;
    switch (result) {
      case Success():
        _notify(context, 'Added to cart');
      case ResultFailure(:final failure):
        _notify(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchasable = detail.isPurchasable;
    final mutating = ref.watch(cartIsMutatingProvider);

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
              onPressed: purchasable && !mutating
                  ? () => _addToCart(context, ref)
                  : null,
              child: mutating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(purchasable ? 'Add to cart' : 'Unavailable'),
            ),
          ),
        ],
      ),
    );
  }
}
