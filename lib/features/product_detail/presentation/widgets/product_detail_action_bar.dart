import 'package:flutter/material.dart';
import '../../../../core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/account_access.dart';
import '../../../../core/catalog/catalog_purchase_policy.dart';
import '../../../../core/auth/auth_providers.dart';
import '../../../../core/error/result.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../cart/application/cart_provider.dart';
import '../../../product_offer/application/product_offer_providers.dart';
import '../../application/jewelry_config_draft_provider.dart';
import '../../application/melee_qty_draft_provider.dart';
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
    if (!AccountAccess.guard(context, ref)) return;
    final auth = ref.read(authProvider);
    final blockMessage = detail.addToCartBlockMessage(
      userId: auth.user?.id,
      sellerId: auth.sellerId,
    );
    if (blockMessage != null) {
      _notify(context, blockMessage);
      return;
    }

    var quantity = 1;
    Map<String, dynamic>? specifications;
    final jewelryDetail = detail.jewelryDetail;
    if (jewelryDetail != null) {
      ref
          .read(jewelryConfigDraftProvider(detail.id).notifier)
          .ensureSeeded(jewelryDetail);
      final draft = ref.read(jewelryConfigDraftProvider(detail.id));
      quantity = draft?.quantity ?? 1;
      specifications = {
        if (draft?.purity != null) 'purity': draft!.purity,
        if (draft?.size != null) 'size': draft!.size,
        if (draft?.stoneWeightLabel != null)
          'stoneWeight': draft!.stoneWeightLabel,
        if (draft?.sku != null) 'sku': draft!.sku,
      };
    }
    final meleeQty = detail.naturalSpecTabs?.meleeQty;
    if (meleeQty != null) {
      ref
          .read(meleeQtyDraftProvider(detail.id).notifier)
          .ensureSeeded(meleeQty);
      final draft = ref.read(meleeQtyDraftProvider(detail.id));
      if (draft == null || (draft.pieces < 1 && draft.carat <= 0)) {
        _notify(context, 'Enter how many pieces or carats to add');
        return;
      }
      if (draft.inCarat) {
        final maxCt = meleeQty.totalCarat;
        if (maxCt != null && draft.carat > maxCt + 1e-9) {
          _notify(context, 'Only ${maxCt.toStringAsFixed(2)} ct available');
          return;
        }
      } else {
        final maxPcs = meleeQty.totalPcs;
        if (maxPcs != null && draft.pieces > maxPcs) {
          _notify(context, 'Only $maxPcs pcs available');
          return;
        }
      }
      // Partial melee amount lives in specifications; quantity is the cart line.
      quantity = 1;
      final calculated = draft.proportionalPrice(
        detail.price.displayAmount,
        meleeQty,
      );
      specifications = draft.toSpecifications(calculatedPrice: calculated);
    }

    final result = await ref
        .read(cartProvider.notifier)
        .addProduct(
          productId: detail.id,
          productType: detail.apiProductType,
          quantity: quantity,
          specifications: specifications,
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
    if (!AccountAccess.guard(context, ref)) return;
    if (_isOwnListing(ref)) {
      _notify(context, 'You cannot make an offer on your own listing');
      return;
    }

    final minHint = detail.minimumOfferPrice;
    final controller = TextEditingController(
      text: minHint != null ? minHint.toStringAsFixed(2) : '',
    );
    final messageCtrl = TextEditingController();
    final submitted = await showAppDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr(CatalogL10n.makeOffer)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              decoration: InputDecoration(
                labelText: context.tr(CatalogL10n.yourOffer, {
                  'currency': AppCurrency.code,
                }),
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
                labelText: context.tr(CatalogL10n.messageOptional),
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
            child: Text(context.tr(CatalogL10n.cancel)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr(CatalogL10n.submitOffer)),
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

    final result = await ref
        .read(productOfferMutationProvider.notifier)
        .create(
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

  bool _isOwnListing(WidgetRef ref) {
    final auth = ref.read(authProvider);
    return detail.isOwnedByCurrentAccount(
      userId: auth.user?.id,
      sellerId: auth.sellerId,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchasable = detail.isPurchasable;
    final mutating = ref.watch(cartIsMutatingProvider);
    final inCart = ref.watch(isProductInCartProvider(detail.id));
    final offerMutating = ref.watch(productOfferMutationProvider).isLoading;
    final auth = ref.watch(authProvider);
    final ownListing = detail.isOwnedByCurrentAccount(
      userId: auth.user?.id,
      sellerId: auth.sellerId,
    );
    final blockMessage = detail.addToCartBlockMessage(
      userId: auth.user?.id,
      sellerId: auth.sellerId,
    );
    final showOffer = detail.canMakeAnOffer && !ownListing;
    final addLabel = ownListing
        ? 'Your listing'
        : blockMessage != null
        ? (CatalogPurchasePolicy.isOnHoldOrMemo(detail.availabilityStatus) ||
                  CatalogPurchasePolicy.isOnHoldOrMemo(
                    detail.availability?.label,
                  )
              ? 'On hold / memo'
              : 'Unavailable')
        : inCart
        ? 'View in cart'
        : 'Add to cart';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        border: Border(top: BorderSide(color: AppColors.border(context))),
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
                onPressed: offerMutating
                    ? null
                    : () => _makeOffer(context, ref),
                child: offerMutating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(context.tr(CatalogL10n.makeOffer)),
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
          ],
          Expanded(
            flex: showOffer ? 2 : 1,
            child: ElevatedButton(
              onPressed: ownListing || !purchasable || mutating
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
                  : Text(addLabel),
            ),
          ),
        ],
      ),
    );
  }
}
