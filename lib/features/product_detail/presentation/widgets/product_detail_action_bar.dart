import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/error/result.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../cart/application/cart_provider.dart';
import '../../../product_offer/application/product_offer_providers.dart';
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

  Future<void> _makeOffer(BuildContext context, WidgetRef ref) async {
    if (!ref.read(authProvider).isAuthenticated) {
      _notify(context, 'Please sign in to make an offer');
      context.push(AppRouteNames.login);
      return;
    }

    final minHint = detail.minimumOfferPrice;
    final controller = TextEditingController(
      text: minHint != null ? minHint.toStringAsFixed(2) : '',
    );
    final messageCtrl = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Make an offer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Your offer (${AppCurrency.code})',
                prefixText: AppCurrency.symbol,
                helperText: minHint != null
                    ? 'Minimum ${AppCurrency.format(minHint)}'
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.r8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageCtrl,
              decoration: InputDecoration(
                labelText: 'Message (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.r8),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit offer'),
          ),
        ],
      ),
    );
    if (submitted != true || !context.mounted) {
      controller.dispose();
      messageCtrl.dispose();
      return;
    }

    final raw = controller.text.trim();
    final message = messageCtrl.text.trim().isEmpty
        ? null
        : messageCtrl.text.trim();
    controller.dispose();
    messageCtrl.dispose();
    if (raw.isEmpty) return;
    final amount = raw.contains('.') ? raw : '$raw.00';

    final result = await ref.read(productOfferMutationProvider.notifier).create(
          productId: detail.id,
          productType: detail.apiProductType,
          amount: amount,
          message: message,
        );
    if (!context.mounted) return;
    switch (result) {
      case Success():
        _notify(context, 'Offer submitted');
      case ResultFailure(:final failure):
        _notify(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchasable = detail.isPurchasable;
    final mutating = ref.watch(cartIsMutatingProvider);
    final inCart = ref.watch(isProductInCartProvider(detail.id));
    final offerMutating = ref.watch(productOfferMutationProvider).isLoading;
    final showOffer = detail.canMakeAnOffer;

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
          if (showOffer) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: offerMutating ? null : () => _makeOffer(context, ref),
                child: offerMutating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Make an offer'),
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
          ],
          Expanded(
            flex: showOffer ? 2 : 1,
            child: ElevatedButton(
              onPressed: !purchasable || mutating
                  ? null
                  : inCart
                      ? () => context.push(AppRouteNames.cart)
                      : () => _addToCart(context, ref),
              child: mutating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      !purchasable
                          ? 'Unavailable'
                          : inCart
                              ? 'View in cart'
                              : 'Add to cart',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
