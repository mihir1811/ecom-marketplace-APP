import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/haptics/app_haptics.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/luxe_tokens.dart';
import '../../../../../core/utils/app_currency.dart';
import '../../../../../core/utils/format_catalog_price.dart';
import '../../../../../core/widgets/luxe/luxe_button.dart';
import '../../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../product_offer/application/product_offer_providers.dart';
import '../../../../product_offer/presentation/widgets/offer_countdown.dart';
import '../../../../rough_diamonds/application/rough_detail_providers.dart';
import '../../../../rough_diamonds/domain/models/rough_parcel.dart';
import '../../../application/product_purchase_actions.dart';
import '../../../domain/adapters/rough_product_detail.dart';
import '../../../domain/models/product_detail.dart';
import '../../../domain/models/product_price_labels.dart';
import '../../screens/certificate_viewer_screen.dart';
import 'luxe_purchase_bar.dart';

/// Ticked lots of [parcel] that are still free, in tick order.
List<RoughLot> selectedRoughLots(List<String> ids, RoughParcel parcel) => [
  for (final id in ids)
    if (parcel.lotById(id) case final lot? when parcel.isLotFree(lot)) lot,
];

/// Lot selection totals: carats, pieces and price add up per chosen lot.
({double carat, int pieces, double price}) roughLotTotals(
  List<RoughLot> lots,
) => (
  carat: lots.fold(0.0, (s, l) => s + l.caratWeight),
  pieces: lots.fold(0, (s, l) => s + l.pieces),
  price: lots.fold(0.0, (s, l) => s + l.totalPrice),
);

String _usd(double v) => AppCurrency.format(formatGroupedWhole(v));

String _when(DateTime t) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  String two(int n) => n.toString().padLeft(2, '0');
  return '${t.day} ${months[t.month - 1]}, ${two(t.hour)}:${two(t.minute)}';
}

/// Status card under the price: running auction, sold-by-lot remainder or
/// "Not available".
class LuxeRoughStatus extends StatelessWidget {
  const LuxeRoughStatus({required this.detail, super.key});

  final ProductDetail detail;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final rough = detail.roughDetail!;
    final parcel = rough.parcel;
    final (
      IconData icon,
      Color tone,
      String title,
      String? body,
    ) = switch (rough) {
      _ when rough.isGone => (
        Icons.remove_shopping_cart_outlined,
        p.caution,
        context.tr(RoughFlowL10n.goneTitle),
        null,
      ),
      _ when parcel.inAuction => (
        Icons.gavel_rounded,
        p.accent,
        context.tr(RoughFlowL10n.auctionLive),
        parcel.auctionEndTime == null
            ? context.tr(RoughFlowL10n.auctionLotsNote)
            : '${context.tr(RoughFlowL10n.auctionEnds, {'time': _when(parcel.auctionEndTime!)})}'
                  ' · ${context.tr(RoughFlowL10n.auctionLotsNote)}',
      ),
      _ when !rough.onSale => (
        Icons.block_rounded,
        p.caution,
        detail.availability?.label ?? context.tr(RoughFlowL10n.notAvailable),
        null,
      ),
      _ when parcel.buy.separable => (
        Icons.grid_view_rounded,
        p.positive,
        context.tr(RoughFlowL10n.separableNote),
        context.tr(RoughFlowL10n.leftLine, {
          'carat': roughCarat(parcel.buy.remainingCarat),
          'price': _usd(parcel.buy.remainingPrice),
        }),
      ),
      _ => (Icons.check_circle_outline_rounded, p.positive, '', null),
    };
    if (title.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
        border: Border.all(color: tone.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: tone),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: LuxeType.label(p.ink, size: 13)),
                if (body != null) ...[
                  const SizedBox(height: 2),
                  Text(body, style: LuxeType.body(p.inkMuted, size: 12.5)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sieve lots of the parcel. Separable parcels get a checkbox per free lot;
/// sold or held lots show their tag instead.
class LuxeRoughLots extends ConsumerWidget {
  const LuxeRoughLots({required this.detail, super.key});

  final ProductDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = LuxePalette.of(context);
    final rough = detail.roughDetail!;
    final parcel = rough.parcel;
    if (parcel.lots.isEmpty) return const SizedBox.shrink();
    final picking = rough.onSale && parcel.buy.canBuyLots && !parcel.inAuction;
    final ids = ref.watch(roughLotSelectionProvider(detail.id));
    final selected = selectedRoughLots(ids, parcel);
    final notifier = ref.read(roughLotSelectionProvider(detail.id).notifier);
    final totals = roughLotTotals(selected);
    final note = parcel.inAuction
        ? RoughFlowL10n.auctionLotsNote
        : picking
        ? RoughFlowL10n.separableNote
        : RoughFlowL10n.wholeOnlyNote;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr(RoughFlowL10n.lotsTitle),
          style: LuxeType.display(28, p.ink),
        ),
        const SizedBox(height: 2),
        Text(
          '${context.tr(RoughFlowL10n.lotsCount, {'count': parcel.lots.length})}'
          ' · ${context.tr(note)}',
          style: LuxeType.body(p.inkMuted, size: 13),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(LuxeSpace.radius),
            border: Border.all(color: p.hairline),
          ),
          child: Column(
            children: [
              for (var i = 0; i < parcel.lots.length; i++)
                _LotRow(
                  lot: parcel.lots[i],
                  first: i == 0,
                  selectable: picking && parcel.isLotFree(parcel.lots[i]),
                  selected: selected.contains(parcel.lots[i]),
                  onToggle: () {
                    AppHaptics.selection();
                    notifier.toggle(parcel.lots[i].id);
                  },
                ),
            ],
          ),
        ),
        AnimatedSize(
          duration: LuxeMotion.medium,
          curve: LuxeMotion.settle,
          alignment: Alignment.topCenter,
          child: selected.isEmpty
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.tr(RoughFlowL10n.selectedLine, {
                            'count': selected.length,
                            'carat': roughCarat(totals.carat),
                            'pieces': roughPieces(totals.pieces),
                          }),
                          style: LuxeType.label(p.ink, size: 13),
                        ),
                      ),
                      Text(
                        _usd(totals.price),
                        style: LuxeType.figure(p.ink, size: 14),
                      ),
                      TextButton(
                        onPressed: notifier.clear,
                        style: TextButton.styleFrom(
                          foregroundColor: p.accent,
                          minimumSize: const Size(44, 40),
                        ),
                        child: Text(context.tr(RoughFlowL10n.clearSelection)),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _LotRow extends StatelessWidget {
  const _LotRow({
    required this.lot,
    required this.first,
    required this.selectable,
    required this.selected,
    required this.onToggle,
  });

  final RoughLot lot;
  final bool first;
  final bool selectable;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final cpp = lot.caratPerPiece;
    final facts = [
      roughPieces(lot.pieces),
      roughCarat(lot.caratWeight),
      if (cpp != null) '${cpp.toStringAsFixed(2)} ct/pc',
      if (lot.pricePerCarat > 0) roughPerCarat(lot.pricePerCarat),
    ].join(' · ');
    final tag = lot.isSold
        ? context.tr(RoughFlowL10n.lotSold)
        : lot.isReserved
        ? context.tr(RoughFlowL10n.lotHeld)
        : null;
    final notes = lot.notes?.trim();

    final row = Padding(
      padding: EdgeInsets.fromLTRB(selectable ? 2 : 12, 8, 12, 8),
      child: Row(
        children: [
          if (selectable)
            Checkbox(
              value: selected,
              onChanged: (_) => onToggle(),
              activeColor: p.ink,
              checkColor: p.canvas,
              semanticLabel: context.tr(RoughFlowL10n.selectLot, {
                'size': lot.sieveSize,
              }),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: lot.sieveSize,
                        style: LuxeType.label(
                          tag == null ? p.ink : p.inkFaint,
                          size: 14,
                        ),
                      ),
                      if (notes != null && notes.isNotEmpty)
                        TextSpan(
                          text: '  $notes',
                          style: LuxeType.body(p.inkFaint, size: 12),
                        ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  facts,
                  maxLines: 2,
                  style: LuxeType.body(p.inkMuted, size: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _usd(lot.totalPrice),
                style:
                    LuxeType.figure(
                      tag == null ? p.ink : p.inkFaint,
                      size: 14,
                    ).copyWith(
                      decoration: tag == null
                          ? null
                          : TextDecoration.lineThrough,
                    ),
              ),
              if (tag != null) ...[
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: ShapeDecoration(
                    color: p.caution.withValues(alpha: 0.12),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(tag, style: LuxeType.label(p.caution, size: 11)),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? p.accentSoft : null,
        border: first
            ? null
            : Border(top: BorderSide(color: p.hairline, width: 0.6)),
      ),
      child: selectable ? InkWell(onTap: onToggle, child: row) : row,
    );
  }
}

/// Kimberley Process certificate (the lab report rides in the certificate
/// row under the price).
class LuxeRoughDocuments extends StatelessWidget {
  const LuxeRoughDocuments({required this.parcel, super.key});

  final RoughParcel parcel;

  static bool hasAny(RoughParcel p) =>
      (p.kpCertificateUrl ?? '').trim().isNotEmpty ||
      (p.kpCertificateNumber ?? '').trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final url = parcel.kpCertificateUrl?.trim() ?? '';
    final number = parcel.kpCertificateNumber?.trim() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr(RoughFlowL10n.documents).toUpperCase(),
          style: LuxeType.eyebrow(p.inkMuted),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
          constraints: const BoxConstraints(minHeight: 44),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
            border: Border.all(color: p.hairline),
          ),
          child: Row(
            children: [
              Icon(Icons.description_outlined, color: p.accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: context.tr(RoughFlowL10n.kpCertificate),
                        style: LuxeType.label(p.ink, size: 13),
                      ),
                      if (number.isNotEmpty)
                        TextSpan(
                          text: ' · $number',
                          style: LuxeType.figure(p.inkMuted, size: 12),
                        ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (url.isNotEmpty)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: p.accent,
                    minimumSize: const Size(44, 36),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => openCertificateViewer(
                    context,
                    url: url,
                    title: context.tr(RoughFlowL10n.kpCertificate),
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 15),
                  label: Text(
                    context.tr(RoughFlowL10n.viewDocument),
                    style: LuxeType.label(p.accent, size: 12.5),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Sticky purchase bar for a rough parcel, driven by the server's `buy`:
/// whole parcel, chosen lots, make an offer, or "Go to auction".
class LuxeRoughPurchaseBar extends ConsumerWidget {
  const LuxeRoughPurchaseBar({
    required this.detail,
    required this.priceLabels,
    super.key,
  });

  final ProductDetail detail;
  final ProductPriceLabels priceLabels;

  void _notify(BuildContext context, String message, PurchaseTone tone) {
    final added = tone == PurchaseTone.success;
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
    final rough = detail.roughDetail!;
    final parcel = rough.parcel;
    final state = ProductPurchaseActions.watchState(ref, detail);
    final copy = luxePurchaseCopy(context);
    void notify(String m, PurchaseTone t) => _notify(context, m, t);
    final lots = selectedRoughLots(
      ref.watch(roughLotSelectionProvider(detail.id)),
      parcel,
    );

    // Re-read the parcel after every add: a lot may have gone meanwhile.
    void reread() => ref.invalidate(roughParcelProvider(detail.id));

    final Widget primary;
    if (parcel.inAuction && !rough.isGone) {
      primary = LuxeButton(
        label: context.tr(RoughFlowL10n.goToAuction),
        sublabel: parcel.auctionEndTime == null
            ? null
            : context.tr(RoughFlowL10n.auctionEnds, {
                'time': _when(parcel.auctionEndTime!),
              }),
        icon: Icons.gavel_rounded,
        expand: true,
        variant: LuxeButtonVariant.accent,
        onPressed: () =>
            context.push(AppRouteNames.auctionDetailPath(parcel.auctionId!)),
      );
    } else if (state.kind == CartButtonKind.ownListing || !rough.onSale) {
      primary = LuxeButton(
        label: context.tr(switch (state.kind) {
          CartButtonKind.ownListing => DiamondFlowL10n.yourListing,
          CartButtonKind.onHoldMemo => DiamondFlowL10n.onHoldMemo,
          _ => RoughFlowL10n.notAvailable,
        }),
        expand: true,
        onPressed: null,
      );
    } else if (lots.isNotEmpty) {
      final totals = roughLotTotals(lots);
      primary = LuxeButton(
        label: lots.length == 1
            ? context.tr(RoughFlowL10n.addOneLot)
            : context.tr(RoughFlowL10n.addLots, {'count': lots.length}),
        sublabel: ProductPriceLabels.resolve(
          detail.price,
          amountOverride: totals.price,
          grouped: true,
        ).sale,
        icon: Icons.add_rounded,
        expand: true,
        loading: state.busy,
        onPressed: state.busy
            ? null
            : () async {
                final added = await ProductPurchaseActions.addRoughLots(
                  context,
                  ref,
                  detail,
                  lotIds: [for (final l in lots) l.id],
                  copy: copy,
                  notify: notify,
                );
                if (added) {
                  ref
                      .read(roughLotSelectionProvider(detail.id).notifier)
                      .clear();
                }
                reread();
              },
      );
    } else if (parcel.buy.canBuyWhole ||
        state.kind == CartButtonKind.viewInCart) {
      final inCart = state.kind == CartButtonKind.viewInCart;
      primary = LuxeButton(
        label: context.tr(
          inCart
              ? DiamondFlowL10n.viewInCart
              : parcel.lots.isEmpty
              ? DiamondFlowL10n.addToCart
              : RoughFlowL10n.addParcel,
        ),
        sublabel: inCart ? null : priceLabels.sale,
        icon: inCart ? Icons.shopping_bag_rounded : Icons.add_rounded,
        expand: true,
        loading: state.busy,
        onPressed: !inCart && !state.enabled
            ? null
            : () async {
                await ProductPurchaseActions.primary(
                  context,
                  ref,
                  detail,
                  copy: copy,
                  notify: notify,
                );
                if (!inCart) reread();
              },
      );
    } else {
      // Some lots are taken: only single lots are left to pick.
      primary = LuxeButton(
        label: context.tr(RoughFlowL10n.pickLots),
        expand: true,
        onPressed: null,
      );
    }

    final showOffer =
        state.showOffer && lots.isEmpty && rough.onSale && !parcel.inAuction;
    final offer = !showOffer
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

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.hairline, width: 0.6)),
      ),
      child: Row(
        children: [
          if (offer != null) ...[
            Expanded(flex: 4, child: offer),
            const SizedBox(width: 6),
          ],
          Expanded(flex: 5, child: primary),
        ],
      ),
    );
  }
}
