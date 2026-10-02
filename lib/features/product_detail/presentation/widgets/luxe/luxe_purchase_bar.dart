import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/luxe_tokens.dart';
import '../../../../../core/utils/app_currency.dart';
import '../../../../../core/widgets/luxe/luxe_button.dart';
import '../../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../application/product_purchase_actions.dart';
import '../../../domain/models/product_detail.dart';
import '../../../domain/models/product_price_labels.dart';

/// Localized purchase copy for luxe flows.
PurchaseCopy luxePurchaseCopy(BuildContext context) => PurchaseCopy(
  signInToBuy: context.tr(DiamondFlowL10n.signInToBuy),
  selectJewelryOptions: PurchaseCopy.english.selectJewelryOptions,
  enterMeleeQty: context.tr(DiamondFlowL10n.enterMeleeQty),
  onlyCaratAvailable: (ct) =>
      context.tr(DiamondFlowL10n.onlyCaratAvailable, {'carat': ct}),
  onlyPiecesAvailable: (pcs) =>
      context.tr(DiamondFlowL10n.onlyPiecesAvailable, {'pieces': pcs}),
  addedToCart: context.tr(DiamondFlowL10n.addedToCart),
  signInToOffer: context.tr(DiamondFlowL10n.signInToOffer),
  ownListingOffer: context.tr(DiamondFlowL10n.ownListingOffer),
  offerSent: context.tr(DiamondFlowL10n.offerSent),
);

/// Sticky commitment bar: compact price, optional offer, primary cart CTA.
class LuxePurchaseBar extends ConsumerWidget {
  const LuxePurchaseBar({
    required this.detail,
    required this.priceLabels,
    super.key,
  });

  final ProductDetail detail;
  final ProductPriceLabels priceLabels;

  void _notify(BuildContext context, String message, PurchaseTone tone) {
    final added = message == context.tr(DiamondFlowL10n.addedToCart);
    showLuxeToast(
      context,
      message,
      tone: switch (tone) {
        PurchaseTone.success => LuxeTone.success,
        PurchaseTone.warning => LuxeTone.info,
        PurchaseTone.error => LuxeTone.error,
      },
      actionLabel: added ? context.tr(DiamondFlowL10n.viewInCart) : null,
      onAction: added ? () => context.push(AppRouteNames.cart) : null,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = LuxePalette.of(context);
    final state = ProductPurchaseActions.watchState(ref, detail);
    final copy = luxePurchaseCopy(context);
    void notify(String m, PurchaseTone t) => _notify(context, m, t);

    final label = context.tr(switch (state.kind) {
      CartButtonKind.add => DiamondFlowL10n.addToCart,
      CartButtonKind.viewInCart => DiamondFlowL10n.viewInCart,
      CartButtonKind.ownListing => DiamondFlowL10n.yourListing,
      CartButtonKind.onHoldMemo => DiamondFlowL10n.onHoldMemo,
      CartButtonKind.unavailable => DiamondFlowL10n.unavailable,
    });

    final showPrice =
        !state.showOffer || MediaQuery.sizeOf(context).width >= 440;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.hairline, width: 0.6)),
      ),
      child: Row(
        children: [
          if (showPrice)
            Expanded(
              flex: 4,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      priceLabels.sale,
                      style: LuxeType.figure(
                        p.ink,
                        size: 18,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (priceLabels.list != null)
                    Text(
                      priceLabels.list!,
                      maxLines: 1,
                      style: LuxeType.label(p.inkFaint, size: 11.5).copyWith(
                        decoration: TextDecoration.lineThrough,
                        decorationColor: p.inkFaint,
                      ),
                    ),
                ],
              ),
            ),
          if (state.showOffer) ...[
            if (showPrice) const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: LuxeButton(
                expand: true,
                label: context.tr(CatalogL10n.makeOffer),
                variant: LuxeButtonVariant.secondary,
                loading: state.offerBusy,
                onPressed: () => ProductPurchaseActions.makeOffer(
                  context,
                  ref,
                  detail,
                  ask: () => showLuxeOfferSheet(context, detail),
                  copy: copy,
                  notify: notify,
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: LuxeButton(
              label: label,
              expand: true,
              loading: state.busy,
              icon: state.kind == CartButtonKind.viewInCart
                  ? Icons.shopping_bag_rounded
                  : (state.kind == CartButtonKind.add
                        ? Icons.add_rounded
                        : null),
              onPressed: state.enabled
                  ? () => ProductPurchaseActions.primary(
                      context,
                      ref,
                      detail,
                      copy: copy,
                      notify: notify,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Offer form in a luxe sheet; returns the amount and optional message.
Future<({String amount, String? message})?> showLuxeOfferSheet(
  BuildContext context,
  ProductDetail detail,
) {
  return showLuxeSheet<({String amount, String? message})>(
    context,
    title: context.tr(CatalogL10n.makeOffer),
    subtitle: context.tr(DiamondFlowL10n.offerSubtitle, {
      'price': ProductPriceLabels.resolve(detail.price).sale,
    }),
    builder: (context) => _OfferForm(minimum: detail.minimumOfferPrice),
  );
}

class _OfferForm extends StatefulWidget {
  const _OfferForm({required this.minimum});

  final double? minimum;

  @override
  State<_OfferForm> createState() => _OfferFormState();
}

class _OfferFormState extends State<_OfferForm> {
  final _form = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: widget.minimum?.toStringAsFixed(2) ?? '',
  );
  final _message = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _message.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_form.currentState?.validate() ?? false)) return;
    final message = _message.text.trim();
    Navigator.of(context).pop((
      amount: _amount.text.trim(),
      message: message.isEmpty ? null : message,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final min = widget.minimum;
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          TextFormField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            style: LuxeType.figure(p.ink, size: 22),
            decoration: InputDecoration(
              labelText: context.tr(CatalogL10n.yourOffer, {
                'currency': AppCurrency.code,
              }),
              prefixText: '${AppCurrency.symbol} ',
              prefixStyle: LuxeType.figure(p.inkMuted, size: 22),
              helperText: min == null
                  ? null
                  : context.tr(DiamondFlowL10n.offerMinimum, {
                      'amount': AppCurrency.format(min.toStringAsFixed(2)),
                    }),
            ),
            validator: (raw) {
              final value = double.tryParse((raw ?? '').trim());
              if (value == null || value <= 0) {
                return context.tr(DiamondFlowL10n.offerInvalid);
              }
              if (min != null && value < min) {
                return context.tr(DiamondFlowL10n.offerTooLow, {
                  'amount': AppCurrency.format(min.toStringAsFixed(2)),
                });
              }
              return null;
            },
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _message,
            maxLines: 3,
            minLines: 2,
            decoration: InputDecoration(
              labelText: context.tr(CatalogL10n.messageOptional),
            ),
          ),
          const SizedBox(height: 22),
          LuxeButton(
            label: context.tr(CatalogL10n.submitOffer),
            expand: true,
            variant: LuxeButtonVariant.accent,
            trailingIcon: Icons.arrow_forward_rounded,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
