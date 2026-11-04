import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/auth/confirm_sign_out.dart';
import '../../../../core/deep_links/order_link.dart';
import '../../../../core/deep_links/order_links.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/luxe/luxe_button.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_layout.dart';
import '../../../jewelry_reviews/application/jewelry_review_providers.dart';
import '../../../jewelry_reviews/presentation/widgets/jewelry_order_review_block.dart';
import '../../application/jewelry_checkout_controller.dart';
import '../../application/jewelry_orders_provider.dart';
import '../../data/repositories/jewelry_checkout_repository_impl.dart';
import '../../domain/models/marketplace_order.dart';
import '../jewelry_checkout_format.dart';
import '../open_jewelry_listing.dart';
import '../widgets/jewelry_order_status.dart';

/// One jewellery order: payment state ("Pay now" while unpaid), each shop's
/// shipment with its tracking timeline, the pieces (with cancel + refund
/// state) and the totals. Reading it also settles a pending payment.
class JewelryOrderDetailScreen extends ConsumerWidget {
  const JewelryOrderDetailScreen({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LuxeScope(
      child: Builder(builder: (context) => _build(context, ref)),
    );
  }

  /// Signs out and keeps this order waiting, so it opens right after the
  /// person signs in with the account that placed it.
  Future<void> _signOutForOrder(BuildContext context, WidgetRef ref) async {
    final router = GoRouter.of(context);
    final auth = ref.read(authProvider.notifier);
    if (!await confirmSignOut(context)) return;
    await auth.logout();
    router.go(AppRouteNames.login);
    OrderLinks.instance.receive(BuyerOrderLink(orderId), signInRequested: true);
  }

  Widget _build(BuildContext context, WidgetRef ref) {
    final p = LuxePalette.of(context);
    final orderAsync = ref.watch(jewelryOrderProvider(orderId));
    final order = orderAsync.valueOrNull;
    return AppScaffold(
      backgroundColor: p.canvas,
      appBar: LuxeTopBar(
        title: order?.orderNumber ?? context.tr(JewelryMarketL10n.orderTitle),
      ),
      body: orderAsync.when(
        skipLoadingOnRefresh: true,
        loading: () => ListView(
          padding: const EdgeInsets.all(12),
          children: const [
            LuxeSkeleton(height: 120, radius: LuxeSpace.radius),
            SizedBox(height: 8),
            LuxeSkeleton(height: 220, radius: LuxeSpace.radius),
          ],
        ),
        // 404: the order belongs to another buyer (often a WhatsApp link
        // opened on a phone signed in to a different account).
        error: (e, _) => e is NotFoundFailure
            ? LuxeStateView(
                icon: Icons.manage_accounts_outlined,
                tone: LuxeTone.error,
                title: context.tr(JewelryMarketL10n.orderOtherAccount),
                message: context.tr(JewelryMarketL10n.orderOtherAccountBody),
                actionLabel: context.tr(AccountCommerceL10n.signOut),
                onAction: () => _signOutForOrder(context, ref),
                secondaryLabel: context.tr(CatalogL10n.retry),
                onSecondary: () =>
                    ref.invalidate(jewelryOrderProvider(orderId)),
              )
            : LuxeStateView(
                icon: Icons.search_off_rounded,
                tone: LuxeTone.error,
                title: context.tr(JewelryMarketL10n.orderNotFound),
                message: e is Failure ? e.message : '$e',
                actionLabel: context.tr(CatalogL10n.retry),
                onAction: () => ref.invalidate(jewelryOrderProvider(orderId)),
              ),
        data: (order) => RefreshIndicator(
          color: p.accent,
          onRefresh: () {
            // The fresh order carries the latest reviews.
            final overrides = ref.read(
              jewelryOwnReviewOverridesProvider.notifier,
            );
            overrides.state = {
              for (final e in overrides.state.entries)
                if (!order.items.any((i) => i.id == e.key)) e.key: e.value,
            };
            return ref.refresh(jewelryOrderProvider(orderId).future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 20),
            children: [
              _Header(order: order),
              if (order.isPendingPayment) ...[
                const SizedBox(height: 8),
                _PayNow(order: order),
              ],
              for (final shipment in order.shipments) ...[
                const SizedBox(height: 8),
                _ShipmentCard(shipment: shipment),
              ],
              const SizedBox(height: 14),
              Text(
                context.tr(JewelryMarketL10n.pieces),
                style: LuxeType.display(22, p.ink),
              ),
              const SizedBox(height: 8),
              for (final item in order.items)
                _ItemCard(order: order, item: item),
              const SizedBox(height: 6),
              _Totals(order: order),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(LuxeSpace.radius),
        border: Border.all(color: p.hairline),
      ),
      child: child,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.order});

  final MarketplaceOrder order;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.orderNumber,
                  style: LuxeType.label(p.ink, size: 16),
                ),
              ),
              JewelryOrderStatusPill(order: order),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            context.tr(JewelryMarketL10n.placedOn, {
              'date': dateTimeLabel(context, order.createdAt),
            }),
            style: LuxeType.body(p.inkMuted, size: 13),
          ),
          if (order.paidAt != null)
            Text(
              context.tr(JewelryMarketL10n.paidOn, {
                'date': dateTimeLabel(context, order.paidAt),
                'method': (order.paymentMethod ?? '').toUpperCase(),
              }).trim(),
              style: LuxeType.body(p.inkMuted, size: 13),
            ),
        ],
      ),
    );
  }
}

/// Unpaid order: pay again, or re-check in case the money was taken.
class _PayNow extends ConsumerWidget {
  const _PayNow({required this.order});

  final MarketplaceOrder order;

  Future<void> _pay(BuildContext context, WidgetRef ref) async {
    final outcome = await ref
        .read(jewelryCheckoutProvider.notifier)
        .payAgain(order.id);
    if (!context.mounted) return;
    switch (outcome) {
      case JewelryCheckoutPaid():
        showLuxeToast(
          context,
          context.tr(JewelryMarketL10n.paymentConfirmed),
          tone: LuxeTone.success,
        );
      case JewelryCheckoutNotPaid(:final message):
        showLuxeToast(context, message, tone: LuxeTone.info);
      case JewelryCheckoutFailed(:final message):
        showLuxeToast(context, message, tone: LuxeTone.error);
    }
    ref.invalidate(jewelryOrderProvider(order.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = LuxePalette.of(context);
    final busy = ref.watch(jewelryCheckoutProvider);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.schedule_rounded, color: p.caution, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  context.tr(JewelryMarketL10n.paymentPendingBody),
                  style: LuxeType.body(p.ink, size: 13.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: LuxeButton(
                  label: context.tr(JewelryMarketL10n.checkPayment),
                  variant: LuxeButtonVariant.secondary,
                  expand: true,
                  height: 46,
                  onPressed: busy
                      ? null
                      : () => ref.invalidate(jewelryOrderProvider(order.id)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LuxeButton(
                  label: context.tr(JewelryMarketL10n.payNow, {
                    'amount': rupees(order.total),
                  }),
                  variant: LuxeButtonVariant.accent,
                  expand: true,
                  height: 46,
                  loading: busy,
                  onPressed: busy ? null : () => _pay(context, ref),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShipmentCard extends StatelessWidget {
  const _ShipmentCard({required this.shipment});

  final MarketplaceShipment shipment;

  Future<void> _open(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final s = shipment;
    const steps = MarketplaceStepStatus.steps;
    final reached = steps.indexOf(s.status);
    final cancelled = s.status == MarketplaceStepStatus.cancelled;
    final courier = s.shippingMethod == 'COURIER';
    final trackingUrl = Uri.tryParse(s.trackingUrl ?? '');
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storefront_outlined, size: 18, color: p.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(s.shopName, style: LuxeType.label(p.ink, size: 15)),
              ),
              Text(
                jewelryStepLabel(context, s.status),
                style: LuxeType.label(
                  cancelled ? p.inkMuted : p.accent,
                  size: 13,
                ),
              ),
            ],
          ),
          if (!cancelled && reached >= 0) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (reached + 1) / steps.length,
                minHeight: 6,
                color: p.accent,
                backgroundColor: p.surfaceRaised,
              ),
            ),
          ],
          if (s.expectedDeliveryAt != null) ...[
            const SizedBox(height: 8),
            Text(
              context.tr(JewelryMarketL10n.expectedBy, {
                'date': calendarDateLabel(context, s.expectedDeliveryAt),
              }),
              style: LuxeType.body(p.inkMuted, size: 13),
            ),
          ],
          if (courier && (s.courierName != null || s.trackingNumber != null))
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                [?s.courierName, ?s.trackingNumber].join(' · '),
                style: LuxeType.label(p.ink, size: 13),
              ),
            ),
          if (s.shippingMethod == 'SELLER_DELIVERY')
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                context.tr(JewelryMarketL10n.sellerDelivers),
                style: LuxeType.body(p.inkMuted, size: 13),
              ),
            ),
          if ((courier && trackingUrl != null && trackingUrl.hasScheme) ||
              s.sellerPhone != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (courier && trackingUrl != null && trackingUrl.hasScheme)
                  OutlinedButton.icon(
                    onPressed: () => _open(trackingUrl),
                    icon: const Icon(Icons.local_shipping_outlined, size: 18),
                    label: Text(context.tr(JewelryMarketL10n.trackParcel)),
                  ),
                if (s.sellerPhone != null)
                  OutlinedButton.icon(
                    onPressed: () => _open(
                      Uri(
                        scheme: 'tel',
                        path: s.sellerPhone!.replaceAll(RegExp(r'[\s-]'), ''),
                      ),
                    ),
                    icon: const Icon(Icons.call_outlined, size: 18),
                    label: Text(context.tr(JewelryMarketL10n.callShop)),
                  ),
              ],
            ),
          ],
          if (s.updates.isNotEmpty) ...[
            const SizedBox(height: 10),
            Divider(height: 1, color: p.hairline),
            const SizedBox(height: 8),
            for (final u in s.updates) _UpdateRow(update: u),
          ],
        ],
      ),
    );
  }
}

class _UpdateRow extends StatelessWidget {
  const _UpdateRow({required this.update});

  final MarketplaceOrderUpdate update;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final u = update;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5, right: 8),
            decoration: BoxDecoration(shape: BoxShape.circle, color: p.accent),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  jewelryStepLabel(context, u.status),
                  style: LuxeType.label(p.ink, size: 13.5),
                ),
                if (u.message != null)
                  Text(u.message!, style: LuxeType.body(p.inkMuted, size: 13)),
                if (u.location != null)
                  Text(u.location!, style: LuxeType.body(p.inkFaint, size: 12)),
                if (u.imageUrls.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 5,
                    children: [
                      for (final url in u.imageUrls.take(4))
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox.square(
                            dimension: 56,
                            child: AppNetworkImage(
                              url: url,
                              memCacheWidth: 168,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                Text(
                  dateTimeLabel(context, u.createdAt),
                  style: LuxeType.body(p.inkFaint, size: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends ConsumerWidget {
  const _ItemCard({required this.order, required this.item});

  final MarketplaceOrder order;
  final MarketplaceOrderItem item;

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final choice = await showLuxeSheet<({String reason, String note})>(
      context,
      title: context.tr(JewelryMarketL10n.cancelPiece),
      subtitle: context.tr(JewelryMarketL10n.cancelRefundNote, {
        'amount': rupees(item.paidTotal),
      }),
      builder: (_) => const _CancelForm(),
    );
    if (choice == null || !context.mounted) return;
    final result = await ref
        .read(jewelryCheckoutRepositoryProvider)
        .cancelItem(
          orderId: order.id,
          itemId: item.id,
          reason: choice.reason,
          note: choice.note,
        );
    if (!context.mounted) return;
    switch (result) {
      case Success():
        showLuxeToast(
          context,
          context.tr(JewelryMarketL10n.pieceCancelled),
          tone: LuxeTone.success,
        );
      case ResultFailure(:final failure):
        showLuxeToast(context, failure.message, tone: LuxeTone.error);
    }
    ref.invalidate(jewelryOrderProvider(order.id));
    ref.invalidate(jewelryOrdersProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = LuxePalette.of(context);
    final i = item;
    final custom = i.customValues.entries
        .where((e) => e.value.trim().isNotEmpty)
        .map((e) => '${e.key}: “${e.value}”')
        .join(' · ');
    final refund = switch (i.refundStatus) {
      'PROCESSED' => JewelryMarketL10n.refundProcessed,
      'FAILED' => JewelryMarketL10n.refundFailed,
      'PENDING' => JewelryMarketL10n.refundPending,
      _ => null,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(LuxeSpace.radius),
        border: Border.all(color: p.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => openJewelryListing(context, ref, i.listingSlug),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox.square(
                    dimension: 72,
                    child: i.imageUrl == null
                        ? ColoredBox(
                            color: p.surfaceRaised,
                            child: Icon(
                              Icons.diamond_outlined,
                              color: p.accent,
                            ),
                          )
                        : AppNetworkImage(url: i.imageUrl!, memCacheWidth: 216),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        i.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: LuxeType.label(p.ink, size: 14),
                      ),
                      Text(
                        i.shopName,
                        style: LuxeType.body(p.inkMuted, size: 12),
                      ),
                      if (i.options.isNotEmpty)
                        Text(
                          optionsLine(i.options),
                          style: LuxeType.body(p.inkMuted, size: 12.5),
                        ),
                      if (custom.isNotEmpty)
                        Text(
                          custom,
                          style: LuxeType.body(p.inkMuted, size: 12.5),
                        ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${i.quantity} × ${rupees(i.unitPrice)}',
                              style: LuxeType.body(p.inkMuted, size: 12.5),
                            ),
                          ),
                          Text(
                            jewelryStepLabel(context, i.status),
                            style: LuxeType.label(p.accent, size: 12.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (refund != null && i.refundAmount != null) ...[
            const SizedBox(height: 8),
            Text(
              context.tr(refund, {'amount': rupees(i.refundAmount!)}),
              style: LuxeType.label(
                i.refundStatus == 'FAILED' ? p.caution : p.positive,
                size: 12.5,
              ),
            ),
          ],
          if (i.canCancel) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr(JewelryMarketL10n.cancelUntil, {
                      'date': dateTimeLabel(context, i.cancellableUntil),
                    }),
                    style: LuxeType.body(p.inkMuted, size: 12),
                  ),
                ),
                TextButton(
                  onPressed: () => _cancel(context, ref),
                  child: Text(context.tr(JewelryMarketL10n.cancelPiece)),
                ),
              ],
            ),
          ],
          JewelryOrderReviewBlock(orderId: order.id, item: i),
        ],
      ),
    );
  }
}

class _CancelForm extends StatefulWidget {
  const _CancelForm();

  @override
  State<_CancelForm> createState() => _CancelFormState();
}

class _CancelFormState extends State<_CancelForm> {
  String _reason = MarketplaceCancelReason.values.first;
  final _note = TextEditingController();

  static String _label(String reason) => switch (reason) {
    'CHANGED_MIND' => JewelryMarketL10n.reasonChangedMind,
    'ORDERED_BY_MISTAKE' => JewelryMarketL10n.reasonMistake,
    'WRONG_OPTION' => JewelryMarketL10n.reasonWrongOption,
    'BETTER_PRICE' => JewelryMarketL10n.reasonBetterPrice,
    'TOO_SLOW' => JewelryMarketL10n.reasonTooSlow,
    _ => JewelryMarketL10n.reasonOther,
  };

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RadioGroup<String>(
          groupValue: _reason,
          onChanged: (v) => setState(() => _reason = v ?? _reason),
          child: Column(
            children: [
              for (final r in MarketplaceCancelReason.values)
                RadioListTile<String>(
                  value: r,
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.tr(_label(r))),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _note,
          maxLength: 300,
          minLines: 2,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: context.tr(CatalogL10n.messageOptional),
          ),
        ),
        const SizedBox(height: 8),
        LuxeButton(
          label: context.tr(JewelryMarketL10n.cancelPiece),
          expand: true,
          variant: LuxeButtonVariant.accent,
          onPressed: () =>
              Navigator.of(context).pop((reason: _reason, note: _note.text)),
        ),
      ],
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.order});

  final MarketplaceOrder order;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final a = order.address;
    Widget row(
      String label,
      String value, {
      bool strong = false,
      Color? tone,
    }) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: strong
                  ? LuxeType.label(p.ink, size: 15)
                  : LuxeType.body(p.inkMuted, size: 14),
            ),
          ),
          Text(
            value,
            style: LuxeType.figure(tone ?? p.ink, size: strong ? 16 : 14),
          ),
        ],
      ),
    );
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row(context.tr(JewelryMarketL10n.subtotal), rupees(order.subtotal)),
          for (final t in order.taxes) row(t.label, rupees(t.amount)),
          row(
            context.tr(JewelryMarketL10n.shipping),
            order.shippingTotal <= 0
                ? context.tr(JewelryMarketL10n.free)
                : rupees(order.shippingTotal),
          ),
          Divider(color: p.hairline, height: 18),
          row(
            context.tr(JewelryMarketL10n.total),
            rupees(order.total),
            strong: true,
          ),
          if (order.refundedTotal > 0)
            row(
              context.tr(JewelryMarketL10n.refunded),
              '−${rupees(order.refundedTotal)}',
              tone: p.positive,
            ),
          if (order.canShowInvoice) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () =>
                  context.push(AppRouteNames.jewelryOrderInvoicePath(order.id)),
              icon: const Icon(Icons.receipt_long_outlined, size: 18),
              label: Text(
                order.invoice == null
                    ? context.tr(JewelryMarketL10n.invoice)
                    : context.tr(JewelryMarketL10n.invoiceNumbered, {
                        'number': order.invoice!.number,
                      }),
              ),
            ),
          ],
          if (a != null) ...[
            const SizedBox(height: 10),
            Text(
              context.tr(JewelryMarketL10n.deliverTo).toUpperCase(),
              style: LuxeType.eyebrow(p.inkMuted),
            ),
            const SizedBox(height: 5),
            Text(a.fullName, style: LuxeType.label(p.ink, size: 14)),
            Text(a.summaryLine, style: LuxeType.body(p.inkMuted, size: 13)),
            Text(a.phone, style: LuxeType.body(p.inkMuted, size: 13)),
          ],
          if (order.buyerNote != null) ...[
            const SizedBox(height: 8),
            Text(
              '“${order.buyerNote!}”',
              style: LuxeType.body(p.inkMuted, size: 13),
            ),
          ],
        ],
      ),
    );
  }
}
