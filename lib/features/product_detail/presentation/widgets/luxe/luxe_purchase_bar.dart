import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/luxe_tokens.dart';
import '../../../../../core/haptics/app_haptics.dart';
import '../../../../../core/utils/app_currency.dart';
import '../../../../../core/widgets/luxe/luxe_button.dart';
import '../../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../product_offer/application/product_offer_providers.dart';
import '../../../../product_offer/presentation/widgets/offer_countdown.dart';
import '../../../application/melee_qty_draft_provider.dart';
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
  offerAddedToBag: context.tr(DiamondFlowL10n.offerAddedToBag),
);

/// Label for the offer control in each [OfferButtonKind].
String luxeOfferLabel(
  BuildContext context,
  OfferButtonKind kind,
  Duration left, {
  double? counterAmount,
}) => switch (kind) {
  OfferButtonKind.makeOffer => context.tr(CatalogL10n.makeOffer),
  OfferButtonKind.pending => context.tr(DiamondFlowL10n.offerPending),
  OfferButtonKind.answerCounter => context.tr(
    DiamondFlowL10n.offerAnswerCounter,
    {'price': AppCurrency.usd(counterAmount ?? 0, decimals: 0)},
  ),
  OfferButtonKind.limitReached => context.tr(DiamondFlowL10n.offerLimitReached),
  OfferButtonKind.payNow => context.tr(DiamondFlowL10n.offerPayNowLeft, {
    'time': formatOfferTimeLeft(left),
  }),
  OfferButtonKind.paid => context.tr(DiamondFlowL10n.offerPaid),
  OfferButtonKind.withGemworld => context.tr(DiamondFlowL10n.offerWithGemworld),
};

/// Sticky commitment bar: quantity control (melee pcs / ct), optional offer
/// and the cart CTA carrying the price under its label.
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

  /// Lot price, or the share of it the melee draft selects.
  String _price(MeleeQtyDraft? draft, ProductMeleeQty? melee) {
    if (melee == null || draft == null || detail.price.isOnRequest) {
      return priceLabels.sale;
    }
    final amount = draft.proportionalPrice(detail.price.displayAmount, melee);
    return ProductPriceLabels.resolve(
      detail.price,
      amountOverride: amount < 0 ? 0 : amount,
      grouped: true,
    ).sale;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = LuxePalette.of(context);
    final state = ProductPurchaseActions.watchState(ref, detail);
    final copy = luxePurchaseCopy(context);
    void notify(String m, PurchaseTone t) => _notify(context, m, t);
    final melee = detail.naturalSpecTabs?.meleeQty;
    final draft = melee == null
        ? null
        : ref.watch(meleeQtyDraftProvider(detail.id));

    final label = context.tr(switch (state.kind) {
      CartButtonKind.add => DiamondFlowL10n.addToCart,
      CartButtonKind.viewInCart => DiamondFlowL10n.viewInCart,
      CartButtonKind.ownListing => DiamondFlowL10n.yourListing,
      CartButtonKind.onHoldMemo => DiamondFlowL10n.onHoldMemo,
      CartButtonKind.unavailable => DiamondFlowL10n.unavailable,
    });

    final qtyField = melee == null || state.kind == CartButtonKind.viewInCart
        ? null
        : _MeleeQtyField(productId: detail.id, qty: melee);
    // Narrow phones can't fit quantity, offer and cart on one line; the
    // quantity and offer then share a line above the cart button.
    final stacked =
        qtyField != null &&
        state.showOffer &&
        MediaQuery.sizeOf(context).width < 440;

    final offer = !state.showOffer
        ? null
        : OfferCountdown(
            expiresAt: state.offerEligibility.payable?.paymentExpiresAt,
            onExpired: () => ref.invalidate(
              productOfferEligibilityProvider(
                ProductPurchaseActions.offerKey(detail),
              ),
            ),
            builder: (context, left) => LuxeButton(
              expand: true,
              height: stacked ? 46 : 54,
              label: luxeOfferLabel(
                context,
                state.offerKind,
                left,
                counterAmount: state.offerEligibility.openCounter?.amount,
              ),
              variant:
                  state.offerKind == OfferButtonKind.payNow ||
                      state.offerKind == OfferButtonKind.answerCounter
                  ? LuxeButtonVariant.accent
                  : LuxeButtonVariant.secondary,
              loading: state.offerBusy,
              onPressed: state.offerEnabled
                  ? () => ProductPurchaseActions.offerAction(
                      context,
                      ref,
                      detail,
                      state: state,
                      ask: () => showLuxeOfferSheet(
                        context,
                        detail,
                        attemptsLeft: state.offerEligibility.attemptsLeft,
                      ),
                      copy: copy,
                      notify: notify,
                    )
                  : null,
            ),
          );

    final cart = LuxeButton(
      label: label,
      sublabel: state.kind == CartButtonKind.viewInCart
          ? null
          : _price(draft, melee),
      expand: true,
      loading: state.busy,
      icon: state.kind == CartButtonKind.viewInCart
          ? Icons.shopping_bag_rounded
          : (state.kind == CartButtonKind.add ? Icons.add_rounded : null),
      onPressed: state.enabled
          ? () => ProductPurchaseActions.primary(
              context,
              ref,
              detail,
              copy: copy,
              notify: notify,
            )
          : null,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.hairline, width: 0.6)),
      ),
      child: stacked
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: qtyField),
                    const SizedBox(width: 6),
                    Expanded(child: offer!),
                  ],
                ),
                const SizedBox(height: 6),
                cart,
              ],
            )
          : Row(
              children: [
                if (qtyField != null) ...[
                  Expanded(flex: offer == null ? 5 : 4, child: qtyField),
                  const SizedBox(width: 6),
                ],
                if (offer != null) ...[
                  Expanded(flex: 4, child: offer),
                  const SizedBox(width: 6),
                ],
                Expanded(flex: 5, child: cart),
              ],
            ),
    );
  }
}

/// Compact melee quantity: number field with a pcs / ct switch. Edits the
/// shared melee draft, so the cart button's price follows as the buyer types.
class _MeleeQtyField extends ConsumerStatefulWidget {
  const _MeleeQtyField({required this.productId, required this.qty});

  final String productId;
  final ProductMeleeQty qty;

  @override
  ConsumerState<_MeleeQtyField> createState() => _MeleeQtyFieldState();
}

class _MeleeQtyFieldState extends ConsumerState<_MeleeQtyField> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  var _syncing = false;

  MeleeQtyDraftNotifier get _notifier =>
      ref.read(meleeQtyDraftProvider(widget.productId).notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _notifier.ensureSeeded(widget.qty);
      _writeFieldFromDraft(force: true);
    });
    // Show the clamped value once the buyer leaves the field.
    _focus.addListener(() {
      if (!_focus.hasFocus) _writeFieldFromDraft(force: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _writeFieldFromDraft({bool force = false}) {
    // Don't rewrite what the buyer is typing (e.g. "0." on the way to 0.5).
    if (_focus.hasFocus && !force) return;
    final draft = ref.read(meleeQtyDraftProvider(widget.productId));
    if (draft == null) return;
    final text = draft.inCarat
        ? _formatCarat(draft.carat)
        : (draft.pieces == 0 ? '' : '${draft.pieces}');
    if (_controller.text == text) return;
    _syncing = true;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _syncing = false;
  }

  static String _formatCarat(double value) {
    if (value <= 0) return '';
    return value.toStringAsFixed(4).replaceFirst(_trailingZeros, '');
  }

  static final _trailingZeros = RegExp(r'\.?0+$');
  static final _caratInput = FilteringTextInputFormatter.allow(
    RegExp(r'[0-9.]'),
  );
  static final _piecesInput = FilteringTextInputFormatter.digitsOnly;

  void _setUnit(bool inCarat) {
    _notifier.setUnit(inCarat: inCarat, qty: widget.qty);
    _writeFieldFromDraft(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final qty = widget.qty;
    ref.listen(meleeQtyDraftProvider(widget.productId), (_, _) {
      _writeFieldFromDraft();
    });
    final draft = ref.watch(meleeQtyDraftProvider(widget.productId));
    final inCarat = draft?.inCarat ?? false;
    final max = inCarat
        ? (qty.totalCarat == null ? null : '/ ${_formatCarat(qty.totalCarat!)}')
        : (qty.totalPcs == null ? null : '/ ${qty.totalPcs}');

    Widget unit(String text, bool on) => Semantics(
      button: true,
      selected: on,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (on) return;
          AppHaptics.selection();
          _setUnit(!inCarat);
        },
        child: AnimatedContainer(
          duration: LuxeMotion.fast,
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: on ? p.ink : Colors.transparent,
            shape: const StadiumBorder(),
          ),
          child: Text(
            text,
            style: LuxeType.label(on ? p.canvas : p.inkMuted, size: 12),
          ),
        ),
      ),
    );

    // The "/ 100" hint only where the field has room for it.
    return LayoutBuilder(
      builder: (context, box) => _frame(
        p,
        inCarat: inCarat,
        unit: unit,
        max: box.maxWidth >= 170 ? max : null,
      ),
    );
  }

  Widget _frame(
    LuxePalette p, {
    required bool inCarat,
    required Widget Function(String text, bool on) unit,
    required String? max,
  }) {
    final qty = widget.qty;
    return Container(
      height: 46,
      padding: const EdgeInsets.only(left: 14, right: 4),
      decoration: ShapeDecoration(
        color: p.canvas,
        shape: StadiumBorder(side: BorderSide(color: p.hairline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              keyboardType: TextInputType.numberWithOptions(decimal: inCarat),
              textInputAction: TextInputAction.done,
              inputFormatters: [inCarat ? _caratInput : _piecesInput],
              style: LuxeType.figure(
                p.ink,
                size: 15,
              ).copyWith(fontWeight: FontWeight.w600),
              onChanged: (raw) {
                if (_syncing) return;
                if (inCarat) {
                  _notifier.setFromCarat(double.tryParse(raw) ?? 0, qty);
                } else {
                  _notifier.setFromPieces(int.tryParse(raw) ?? 0, qty);
                }
              },
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: '0',
                hintStyle: LuxeType.label(p.inkFaint, size: 13),
                suffixText: max,
                suffixStyle: LuxeType.label(p.inkFaint, size: 11.5),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: ShapeDecoration(
              color: p.surface,
              shape: StadiumBorder(side: BorderSide(color: p.hairline)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                unit(context.tr(CatalogL10n.pcsShort), !inCarat),
                unit('CT', inCarat),
              ],
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
  ProductDetail detail, {
  int? attemptsLeft,
}) {
  return showLuxeSheet<({String amount, String? message})>(
    context,
    title: context.tr(CatalogL10n.makeOffer),
    subtitle: context.tr(DiamondFlowL10n.offerSubtitle, {
      'price': ProductPriceLabels.resolve(detail.price).sale,
    }),
    builder: (context) => _OfferForm(
      maximum: ProductPurchaseActions.offerCeilingUsd(detail),
      attemptsNote: attemptsLeft == null
          ? null
          : context.tr(DiamondFlowL10n.offerAttemptsLeft, {
              'count': attemptsLeft,
              'max': detail.maxOfferAttemptsPerUser,
            }),
    ),
  );
}

class _OfferForm extends StatefulWidget {
  const _OfferForm({required this.maximum, this.attemptsNote});

  /// Listed price; offers above it are refused. The seller's minimum is
  /// private, so the form never mentions one.
  final double? maximum;

  /// e.g. "3 of 5 offers left on this stone".
  final String? attemptsNote;

  @override
  State<_OfferForm> createState() => _OfferFormState();
}

class _OfferFormState extends State<_OfferForm> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
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
    final max = widget.maximum;
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
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
            ),
            validator: (raw) {
              final value = double.tryParse((raw ?? '').trim());
              if (value == null || value <= 0) {
                return context.tr(DiamondFlowL10n.offerInvalid);
              }
              if (max != null && value > max) {
                return context.tr(DiamondFlowL10n.offerTooHigh, {
                  'amount': AppCurrency.format(max.toStringAsFixed(2)),
                });
              }
              return null;
            },
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _message,
            maxLines: 3,
            minLines: 2,
            decoration: InputDecoration(
              labelText: context.tr(CatalogL10n.messageOptional),
            ),
          ),
          if (widget.attemptsNote != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.attemptsNote!,
              style: LuxeType.label(p.inkMuted, size: 12),
            ),
          ],
          const SizedBox(height: 14),
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
