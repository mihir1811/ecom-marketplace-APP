import 'package:flutter/material.dart';
import '../../../../core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../product_offer/application/product_offer_providers.dart';
import '../../../product_offer/presentation/widgets/offer_countdown.dart';
import '../../application/product_purchase_actions.dart';
import '../../domain/models/product_detail.dart';

/// Sticky commitment bar. Keep only the primary decision actions here.
class ProductDetailActionBar extends ConsumerWidget {
  const ProductDetailActionBar({required this.detail, super.key});

  final ProductDetail detail;

  void _notify(BuildContext context, String message, PurchaseTone tone) {
    switch (tone) {
      case PurchaseTone.success:
        AppHaptics.success();
      case PurchaseTone.warning:
        AppHaptics.warning();
      case PurchaseTone.error:
        AppHaptics.error();
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<({String amount, String? message})?> _askOffer(
    BuildContext context,
  ) async {
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
    final amount = controller.text;
    final message = messageCtrl.text.trim();
    controller.dispose();
    messageCtrl.dispose();
    if (submitted != true) return null;
    return (amount: amount, message: message.isEmpty ? null : message);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ProductPurchaseActions.watchState(ref, detail);
    void notify(String message, PurchaseTone tone) =>
        _notify(context, message, tone);
    final showOffer = state.showOffer;
    final offerMutating = state.offerBusy;
    final mutating = state.busy;
    final addLabel = switch (state.kind) {
      CartButtonKind.ownListing => 'Your listing',
      CartButtonKind.onHoldMemo => 'On hold / memo',
      CartButtonKind.unavailable => 'Unavailable',
      CartButtonKind.viewInCart => 'View in cart',
      CartButtonKind.add => 'Add to cart',
    };

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
              child: OfferCountdown(
                expiresAt: state.offerEligibility.payable?.paymentExpiresAt,
                onExpired: () => ref.invalidate(
                  productOfferEligibilityProvider(
                    ProductPurchaseActions.offerKey(detail),
                  ),
                ),
                builder: (context, left) => OutlinedButton(
                  onPressed: offerMutating || !state.offerEnabled
                      ? null
                      : () => ProductPurchaseActions.offerAction(
                          context,
                          ref,
                          detail,
                          state: state,
                          ask: () => _askOffer(context),
                          copy: PurchaseCopy.english,
                          notify: notify,
                        ),
                  child: offerMutating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          switch (state.offerKind) {
                            OfferButtonKind.makeOffer => context.tr(
                              CatalogL10n.makeOffer,
                            ),
                            OfferButtonKind.pending => 'Offer sent',
                            OfferButtonKind.limitReached => 'No offers left',
                            OfferButtonKind.payNow =>
                              'Pay now · ${formatOfferTimeLeft(left)}',
                            OfferButtonKind.paid => 'Offer paid',
                          },
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
          ],
          Expanded(
            flex: showOffer ? 2 : 1,
            child: ElevatedButton(
              onPressed: !state.enabled
                  ? null
                  : () => ProductPurchaseActions.primary(
                      context,
                      ref,
                      detail,
                      copy: PurchaseCopy.english,
                      notify: notify,
                    ),
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
