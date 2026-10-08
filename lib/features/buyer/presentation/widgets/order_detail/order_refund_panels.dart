import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/error/result.dart';
import '../../../../../core/haptics/app_haptics.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/router/app_navigation.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../feedback/application/feedback_providers.dart';
import '../../../../payment/domain/models/payment_models.dart';
import '../../../../refunds/application/refund_providers.dart';
import '../../../../refunds/domain/models/refund_request.dart';
import '../../../../seller/presentation/atelier/atelier_components.dart';
import '../../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../../seller/presentation/atelier/atelier_studio.dart';
import '../../../../seller/presentation/atelier/atelier_theme.dart';
import '../../../../tracking/application/order_shipments_provider.dart';
import '../../../../tracking/domain/models/shipment_models.dart';
import '../../../application/buyer_orders_provider.dart';
import '../../maison/maison_kit.dart';
import '../refunds/buyer_refund_card.dart';
import 'order_journey.dart';

const _refundedPaymentStatuses = {'REFUNDED', 'PARTIALLY_REFUNDED'};

/// Pending or approved refund the buyer has for [sellerId], if any.
RefundRequest? _activeRefund(List<RefundRequest>? refunds, String sellerId) {
  for (final r in refunds ?? const <RefundRequest>[]) {
    if (r.sellerId == sellerId &&
        (r.status == RefundStatus.pending ||
            r.status == RefundStatus.accepted)) {
      return r;
    }
  }
  return null;
}

// ── Refund request dialog ───────────────────────────────────────────────

/// Asks for a reason (with quick picks) and sends the refund request.
/// Returns `true` once the request was accepted by the server.
Future<bool> showRefundRequestDialog(
  BuildContext context, {
  required String orderId,
  required String sellerId,
  required String sellerName,
  String? initialReason,
  bool sellerRejected = false,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final palette = context.atelier;
  final submitted = context.tr(AccountCommerceL10n.refundSubmitted);
  final done = await showAtelierDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _RefundRequestDialog(
      orderId: orderId,
      sellerId: sellerId,
      sellerName: sellerName,
      initialReason: initialReason,
      sellerRejected: sellerRejected,
    ),
  );
  if (done != true) return false;
  AppHaptics.success();
  showMaisonToast(
    messenger,
    palette,
    submitted,
    tone: AtelierTone.emerald,
    icon: Icons.replay_rounded,
  );
  return true;
}

class _RefundRequestDialog extends StatefulWidget {
  const _RefundRequestDialog({
    required this.orderId,
    required this.sellerId,
    required this.sellerName,
    required this.sellerRejected,
    this.initialReason,
  });

  final String orderId;
  final String sellerId;
  final String sellerName;
  final String? initialReason;
  final bool sellerRejected;

  @override
  State<_RefundRequestDialog> createState() => _RefundRequestDialogState();
}

class _RefundRequestDialogState extends State<_RefundRequestDialog> {
  late final _reason = TextEditingController(text: widget.initialReason);

  List<String> get _quick => widget.sellerRejected
      ? const ['The seller rejected my order', 'I no longer need it']
      : const [
          'Not as described',
          'Delivery is taking too long',
          'Ordered by mistake',
          'Changed my mind',
        ];

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final reason = _reason.text.trim();
    return MaisonActionDialog(
      title: 'Request a refund',
      message:
          'Tell ${widget.sellerName} why. Approved refunds are credited to '
          'your GemWorld wallet.',
      confirmLabel: context.tr(CoreL10n.submit),
      icon: Icons.replay_rounded,
      canConfirm: reason.isNotEmpty,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('QUICK REASONS', style: AtelierType.overline(p.muted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final q in _quick)
                AtelierChoiceChip(
                  label: q,
                  selected: reason == q,
                  onTap: () => setState(() {
                    _reason.text = q;
                    _reason.selection = TextSelection.collapsed(
                      offset: q.length,
                    );
                  }),
                ),
            ],
          ),
          const SizedBox(height: 16),
          AtelierTextField(
            controller: _reason,
            label: context.tr(AccountCommerceL10n.reason),
            hint: context.tr(AccountCommerceL10n.refundReasonHint),
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [LengthLimitingTextInputFormatter(2000)],
            onChanged: (_) => setState(() {}),
          ),
          if (reason.isEmpty) ...[
            const SizedBox(height: 6),
            Text(
              context.tr(AccountCommerceL10n.refundReasonRequired),
              style: AtelierType.caption(p.muted, size: 11.5),
            ),
          ],
        ],
      ),
      onConfirm: (ref) async {
        final failure = await maisonOutcome(
          ref
              .read(refundMutationProvider.notifier)
              .create(
                orderId: widget.orderId,
                sellerId: widget.sellerId,
                reason: _reason.text.trim(),
              ),
        );
        if (failure == null && widget.sellerRejected) {
          ref.invalidate(buyerOrderDetailProvider(widget.orderId));
        }
        return failure;
      },
    );
  }
}

// ── Refund panel ────────────────────────────────────────────────────────

/// Refunds for a paid order, per seller: request one, or see where the
/// current one stands. Sellers that rejected the order are handled by
/// [OrderRejectionPanel].
class OrderRefundPanel extends ConsumerWidget {
  const OrderRefundPanel({required this.order, super.key});

  final PaymentOrder order;

  List<({String sellerId, String sellerName})> get _targets {
    final seen = <String>{
      for (final d in order.sellerDecisions)
        if (d.isRejected) d.sellerId,
    };
    final targets = <({String sellerId, String sellerName})>[];
    for (final seller in order.sellers) {
      if (seller.id.isEmpty || !seen.add(seller.id)) continue;
      targets.add((sellerId: seller.id, sellerName: seller.companyName));
    }
    for (final item in order.items) {
      final id = item.sellerId;
      if (id == null || id.isEmpty || !seen.add(id)) continue;
      targets.add((
        sellerId: id,
        sellerName: item.sellerName?.trim().isNotEmpty == true
            ? item.sellerName!
            : 'Seller',
      ));
    }
    return targets;
  }

  bool get _isPaid {
    final status = order.status.toUpperCase();
    return status == 'PAID' || status == 'PARTIALLY_REFUNDED';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AtelierPanel(
      overline: 'Refunds',
      title: 'Need a refund?',
      subtitle: 'Available for paid orders until they are out for delivery.',
      trailing: AtelierIconButton(
        icon: Icons.arrow_outward_rounded,
        tooltip: context.tr(AccountCommerceL10n.viewRefunds),
        filled: true,
        size: 38,
        onPressed: () => context.switchToRoute(AppRouteNames.buyerRefunds),
      ),
      child: _body(context, ref),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref) {
    if (!_isPaid) {
      return const AtelierNotice(
        text:
            'Refunds open once the payment succeeds, and close when the '
            'order is out for delivery.',
        icon: Icons.schedule_rounded,
      );
    }
    final shipmentsAsync = ref.watch(orderShipmentsProvider(order.id));
    if (shipmentsAsync.isLoading && !shipmentsAsync.hasValue) {
      return const AtelierSkeletonCard(height: 72);
    }
    final blocked = (shipmentsAsync.asData?.value ?? const <Shipment>[]).any(
      (s) => ShipmentStatuses.blocksBuyerRefund(s.status),
    );
    if (blocked) {
      return const AtelierNotice(
        text:
            'Refunds are no longer available once the order is out for '
            'delivery or delivered.',
        icon: Icons.local_shipping_outlined,
      );
    }
    final targets = _targets;
    if (targets.isEmpty) {
      return const AtelierNotice(
        text:
            'Seller details are not available for a refund on this order '
            'yet.',
      );
    }
    final refunds = ref.watch(orderRefundsProvider(order.id)).asData?.value;
    final mutating = ref.watch(refundMutationProvider).isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < targets.length; i++) ...[
          if (i > 0) const AtelierHairline(vertical: 12),
          _SellerRefundRow(
            sellerName: targets[i].sellerName,
            active: _activeRefund(refunds, targets[i].sellerId),
            busy: mutating,
            onRequest: () => showRefundRequestDialog(
              context,
              orderId: order.id,
              sellerId: targets[i].sellerId,
              sellerName: targets[i].sellerName,
            ),
          ),
        ],
      ],
    );
  }
}

class _SellerRefundRow extends StatelessWidget {
  const _SellerRefundRow({
    required this.sellerName,
    required this.active,
    required this.busy,
    required this.onRequest,
  });

  final String sellerName;
  final RefundRequest? active;
  final bool busy;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final current = active;
    return Row(
      children: [
        AtelierMonogram(name: sellerName, size: 34),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sellerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AtelierType.label(p.ink, size: 13.5),
              ),
              const SizedBox(height: 3),
              Text(
                current == null
                    ? 'No refund requested'
                    : current.status == RefundStatus.pending
                    ? 'Requested · waiting for the seller'
                    : 'Approved · on its way to your wallet',
                style: AtelierType.caption(p.muted, size: 11.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        if (current != null)
          AtelierPill(
            label: buyerRefundLabel(current.status),
            tone: buyerRefundTone(current.status),
            icon: buyerRefundIcon(current.status),
            dense: true,
          )
        else
          AtelierButton(
            label: 'Request',
            icon: Icons.replay_rounded,
            compact: true,
            variant: AtelierButtonVariant.secondary,
            onPressed: busy ? null : onRequest,
          ),
      ],
    );
  }
}

// ── Rejection ───────────────────────────────────────────────────────────

/// Shown when one or more sellers rejected their part of [order]: why,
/// the refund state (with a request button when nothing is in progress)
/// and a feedback form.
class OrderRejectionPanel extends ConsumerWidget {
  const OrderRejectionPanel({required this.order, super.key});

  final PaymentOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.atelier;
    final rejected = order.sellerDecisions.where((d) => d.isRejected).toList();
    if (rejected.isEmpty) return const SizedBox.shrink();
    final refundsAsync = ref.watch(orderRefundsProvider(order.id));

    return AtelierCard(
      borderColor: p.ruby.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const AtelierIconBadge(
                icon: Icons.do_not_disturb_alt_rounded,
                tone: AtelierTone.ruby,
                size: 42,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ATTENTION', style: AtelierType.overline(p.ruby)),
                    const SizedBox(height: 4),
                    Text(
                      rejected.length == order.sellerDecisions.length
                          ? 'The seller declined this order'
                          : 'Part of this order was declined',
                      style: AtelierType.display(p.ink, size: 22),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final decision in rejected) ...[
            _RejectedSeller(
              order: order,
              decision: decision,
              refundsAsync: refundsAsync,
            ),
            const SizedBox(height: 12),
          ],
          const AtelierHairline(vertical: 8),
          OrderFeedbackForm(orderId: order.id),
        ],
      ),
    );
  }
}

class _RejectedSeller extends ConsumerWidget {
  const _RejectedSeller({
    required this.order,
    required this.decision,
    required this.refundsAsync,
  });

  final PaymentOrder order;
  final PaymentOrderSellerDecision decision;
  final AsyncValue<List<RefundRequest>> refundsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.atelier;
    final name = orderSellerName(
      order,
      decision.sellerId,
      hint: decision.sellerName,
    );
    final refunded = _refundedPaymentStatuses.contains(
      order.status.toUpperCase(),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.ruby.withValues(alpha: p.isDark ? 0.08 : 0.04),
        borderRadius: BorderRadius.circular(AtelierRadius.md),
        border: Border.all(color: p.ruby.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AtelierMonogram(name: name, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$name declined the order',
                  style: AtelierType.label(p.ink, size: 13.5),
                ),
              ),
            ],
          ),
          if (decision.reason != null) ...[
            const SizedBox(height: 10),
            AtelierKeyValue(label: 'Reason', value: decision.reason!),
          ],
          if (decision.sellerNote != null) ...[
            const SizedBox(height: 8),
            Text(
              '“${decision.sellerNote}”',
              style: AtelierType.body(
                p.inkSoft,
                size: 13,
              ).copyWith(fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 12),
          if (refunded)
            AtelierNotice(
              text: 'Refunded to your GemWorld wallet.',
              tone: AtelierTone.emerald,
              icon: Icons.account_balance_wallet_outlined,
              actionLabel: 'View wallet',
              onAction: () => context.switchToRoute(AppRouteNames.buyerWallet),
            )
          else
            refundsAsync.when(
              skipLoadingOnReload: true,
              loading: () => const AtelierSkeletonCard(height: 72),
              error: (error, _) => AtelierNotice(
                text: error is Failure
                    ? error.message
                    : 'Could not load refund status.',
                tone: AtelierTone.ruby,
                icon: Icons.error_outline_rounded,
                actionLabel: 'Retry',
                onAction: () => ref.invalidate(orderRefundsProvider(order.id)),
              ),
              data: (refunds) => _refundState(context, ref, refunds, name),
            ),
        ],
      ),
    );
  }

  Widget _refundState(
    BuildContext context,
    WidgetRef ref,
    List<RefundRequest> refunds,
    String sellerName,
  ) {
    final active = _activeRefund(refunds, decision.sellerId);
    if (active != null) {
      final pending = active.status == RefundStatus.pending;
      return AtelierNotice(
        text: pending
            ? 'Refund requested — waiting for the seller.'
            : 'Refund approved — the amount is on its way back to you.',
        tone: pending ? AtelierTone.amber : AtelierTone.emerald,
        icon: pending ? Icons.hourglass_top_rounded : Icons.sync_rounded,
        actionLabel: 'View refunds',
        onAction: () => context.switchToRoute(AppRouteNames.buyerRefunds),
      );
    }
    final lastRejected = refunds
        .where(
          (r) =>
              r.sellerId == decision.sellerId &&
              r.status == RefundStatus.rejected,
        )
        .firstOrNull;
    final mutating = ref.watch(refundMutationProvider).isLoading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (lastRejected != null) ...[
          AtelierNotice(
            text: lastRejected.sellerNote == null
                ? 'Your previous refund request was declined.'
                : 'Your previous refund request was declined: '
                      '${lastRejected.sellerNote}',
            tone: AtelierTone.ruby,
          ),
          const SizedBox(height: 10),
        ],
        AtelierButton(
          label: 'Request refund',
          icon: Icons.replay_rounded,
          expand: true,
          loading: mutating,
          onPressed: mutating
              ? null
              : () => showRefundRequestDialog(
                  context,
                  orderId: order.id,
                  sellerId: decision.sellerId,
                  sellerName: sellerName,
                  sellerRejected: true,
                  initialReason: decision.reason == null
                      ? 'The seller rejected my order.'
                      : 'The seller rejected my order (${decision.reason}).',
                ),
        ),
      ],
    );
  }
}

// ── Feedback ────────────────────────────────────────────────────────────

/// Rating + message about this order, sent to `POST /feedback`.
class OrderFeedbackForm extends ConsumerStatefulWidget {
  const OrderFeedbackForm({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<OrderFeedbackForm> createState() => _OrderFeedbackFormState();
}

class _OrderFeedbackFormState extends ConsumerState<OrderFeedbackForm> {
  final _controller = TextEditingController();
  int _rating = 0;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _controller.text.trim();
    if (_rating == 0 || message.isEmpty) {
      AppHaptics.error();
      setState(() => _error = 'Add a rating and a short message.');
      return;
    }
    setState(() => _error = null);
    final messenger = ScaffoldMessenger.of(context);
    final palette = context.atelier;
    final result = await ref
        .read(feedbackSubmitProvider.notifier)
        .submitForOrder(
          orderId: widget.orderId,
          message: message,
          rating: _rating,
        );
    if (!mounted) return;
    switch (result) {
      case Success():
        AppHaptics.success();
        setState(() => _sent = true);
        _controller.clear();
        showMaisonToast(
          messenger,
          palette,
          'Thanks — your feedback was sent.',
          tone: AtelierTone.emerald,
        );
      case ResultFailure(:final failure):
        setState(() => _error = failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final existing = ref.watch(orderFeedbackProvider(widget.orderId));
    final sending = ref.watch(feedbackSubmitProvider);
    final submitted = existing.asData?.value ?? const [];

    final Widget body;
    if (existing.isLoading && submitted.isEmpty) {
      body = const AtelierSkeletonCard(height: 72);
    } else if (submitted.isNotEmpty || _sent) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final f in submitted)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded, size: 17, color: p.emerald),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (f.rating != null)
                          StarRow(rating: f.rating!, size: 14),
                        Text(
                          f.message,
                          style: AtelierType.body(p.inkSoft, size: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (submitted.isEmpty)
            Text(
              'Feedback sent. Thank you!',
              style: AtelierType.label(p.emerald, size: 13),
            ),
        ],
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StarPicker(
            rating: _rating,
            enabled: !sending,
            onChanged: (v) => setState(() {
              _rating = v;
              _error = null;
            }),
          ),
          const SizedBox(height: 12),
          AtelierTextField(
            controller: _controller,
            label: 'Message',
            hint: 'What could have gone better?',
            maxLines: 3,
            enabled: !sending,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [LengthLimitingTextInputFormatter(1000)],
            error: _error,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: AtelierButton(
              label: 'Send feedback',
              icon: Icons.send_rounded,
              compact: true,
              loading: sending,
              onPressed: sending ? null : _submit,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('SHARE FEEDBACK', style: AtelierType.overline(p.gold)),
        const SizedBox(height: 4),
        Text(
          'Tell us how this was handled. Our team reads every message.',
          style: AtelierType.caption(p.muted, size: 12),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(duration: AtelierMotion.base, child: body),
      ],
    );
  }
}

// ── Stars ───────────────────────────────────────────────────────────────

/// Read-only star rating.
class StarRow extends StatelessWidget {
  const StarRow({required this.rating, this.size = 16, super.key});

  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: i <= rating ? p.gold : p.muted,
          ),
      ],
    );
  }
}

/// Tappable five-star picker; the chosen stars pop in turn.
class StarPicker extends StatelessWidget {
  const StarPicker({
    required this.rating,
    required this.onChanged,
    this.enabled = true,
    this.size = 34,
    super.key,
  });

  final int rating;
  final ValueChanged<int> onChanged;
  final bool enabled;
  final double size;

  static const _words = ['', 'Poor', 'Fair', 'Good', 'Great', 'Exceptional'];

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Row(
      children: [
        for (var i = 1; i <= 5; i++)
          Pressable(
            onTap: enabled ? () => onChanged(i) : null,
            scale: 0.8,
            semanticLabel: '$i star${i == 1 ? '' : 's'}',
            borderRadius: BorderRadius.circular(size),
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: AnimatedScale(
                scale: i <= rating ? 1 : 0.88,
                duration: Duration(milliseconds: 220 + i * 40),
                curve: AtelierMotion.settle,
                child: Icon(
                  i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: size,
                  color: i <= rating ? p.gold : p.muted,
                ),
              ),
            ),
          ),
        const SizedBox(width: 8),
        Flexible(
          child: AnimatedSwitcher(
            duration: AtelierMotion.base,
            child: Text(
              _words[rating.clamp(0, 5)],
              key: ValueKey(rating),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AtelierType.label(p.gold, size: 13),
            ),
          ),
        ),
      ],
    );
  }
}
