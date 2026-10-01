import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../feedback/application/feedback_providers.dart';
import '../../../payment/domain/models/payment_models.dart';
import '../../../refunds/application/refund_providers.dart';
import '../../../refunds/domain/models/refund_request.dart';
import '../../application/buyer_orders_provider.dart';

const _refundedPaymentStatuses = {'REFUNDED', 'PARTIALLY_REFUNDED'};

/// Shown when one or more sellers rejected their part of [order]: the
/// rejection, the refund state (with a request button when nothing is in
/// progress) and a feedback form.
class OrderRejectionSection extends ConsumerWidget {
  const OrderRejectionSection({required this.order, super.key});

  final PaymentOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rejected = order.sellerDecisions.where((d) => d.isRejected).toList();
    if (rejected.isEmpty) return const SizedBox.shrink();
    final refundsAsync = ref.watch(orderRefundsProvider(order.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.cancel_outlined, color: AppColors.error, size: 20),
            const SizedBox(width: 8),
            Text(
              'Order Status: Rejected',
              style: AppTypography.title.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final decision in rejected) ...[
          _RejectedSeller(
            order: order,
            decision: decision,
            refundsAsync: refundsAsync,
          ),
          const SizedBox(height: 12),
        ],
        const Divider(height: 24),
        OrderFeedbackForm(orderId: order.id),
      ],
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

  String get _sellerName {
    if (decision.sellerName != null) return decision.sellerName!;
    for (final s in order.sellers) {
      if (s.id == decision.sellerId) return s.companyName;
    }
    return 'The seller';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentRefunded = _refundedPaymentStatuses.contains(
      order.status.toUpperCase(),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$_sellerName has rejected this order.',
            style: AppTypography.label.copyWith(fontWeight: FontWeight.w700),
          ),
          if (decision.reason != null) ...[
            const SizedBox(height: 4),
            Text(
              'Reason: ${decision.reason}',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
          ],
          if (decision.sellerNote != null) ...[
            const SizedBox(height: 4),
            Text(
              '“${decision.sellerNote}”',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary(context),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (paymentRefunded)
            _RefundLine(
              icon: Icons.account_balance_wallet_outlined,
              color: AppColors.success,
              text: 'Refunded to your GemWorld wallet.',
              action: TextButton(
                onPressed: () => context.openRoute(AppRouteNames.buyerWallet),
                child: const Text('View wallet'),
              ),
            )
          else
            refundsAsync.when(
              skipLoadingOnReload: true,
              loading: () => const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (error, _) => _RefundLine(
                icon: Icons.error_outline,
                color: AppColors.error,
                text: error is Failure
                    ? error.message
                    : 'Could not load refund status.',
                action: TextButton(
                  onPressed: () =>
                      ref.invalidate(orderRefundsProvider(order.id)),
                  child: const Text('Retry'),
                ),
              ),
              data: (refunds) => _refundState(context, ref, refunds),
            ),
        ],
      ),
    );
  }

  Widget _refundState(
    BuildContext context,
    WidgetRef ref,
    List<RefundRequest> refunds,
  ) {
    final forSeller = refunds
        .where((r) => r.sellerId == decision.sellerId)
        .toList();
    RefundRequest? active;
    for (final r in forSeller) {
      if (r.status == RefundStatus.pending ||
          r.status == RefundStatus.accepted) {
        active = r;
        break;
      }
    }
    if (active != null) {
      final pending = active.status == RefundStatus.pending;
      return _RefundLine(
        icon: pending ? Icons.schedule : Icons.sync,
        color: pending ? AppColors.info : AppColors.bronze,
        text: pending
            ? 'Refund requested — waiting for the seller.'
            : 'Refund processing — the amount is on its way back to you.',
        action: TextButton(
          onPressed: () => context.openRoute(AppRouteNames.buyerRefunds),
          child: const Text('View refunds'),
        ),
      );
    }

    final lastRejected = forSeller
        .where((r) => r.status == RefundStatus.rejected)
        .firstOrNull;
    final mutating = ref.watch(refundMutationProvider).isLoading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (lastRejected != null) ...[
          _RefundLine(
            icon: Icons.info_outline,
            color: AppColors.error,
            text: lastRejected.sellerNote == null
                ? 'Your previous refund request was declined.'
                : 'Your previous refund request was declined: '
                      '${lastRejected.sellerNote}',
          ),
          const SizedBox(height: 8),
        ],
        FilledButton.icon(
          onPressed: mutating ? null : () => _requestRefund(context, ref),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.charcoal,
            foregroundColor: AppColors.warmWhite,
            minimumSize: const Size.fromHeight(46),
          ),
          icon: mutating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.warmWhite,
                  ),
                )
              : const Icon(Icons.replay, size: 18),
          label: Text(mutating ? 'Sending…' : 'Request Refund'),
        ),
      ],
    );
  }

  Future<void> _requestRefund(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(
      text: decision.reason == null
          ? 'The seller rejected my order.'
          : 'The seller rejected my order (${decision.reason}).',
    );
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request refund'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          maxLength: 2000,
          decoration: const InputDecoration(
            labelText: 'Reason',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    final reason = controller.text.trim();
    controller.dispose();
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (reason.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please add a reason for the refund.')),
      );
      return;
    }
    final result = await ref
        .read(refundMutationProvider.notifier)
        .create(orderId: order.id, sellerId: decision.sellerId, reason: reason);
    switch (result) {
      case Success():
        ref.invalidate(buyerOrderDetailProvider(order.id));
        messenger.showSnackBar(
          const SnackBar(content: Text('Refund requested.')),
        );
      case ResultFailure(:final failure):
        messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }
}

class _RefundLine extends StatelessWidget {
  const _RefundLine({
    required this.icon,
    required this.color,
    required this.text,
    this.action,
  });

  final IconData icon;
  final Color color;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTypography.caption.copyWith(
              color: AppColors.textPrimary(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

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
  bool _sentThisSession = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _controller.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    if (_rating == 0 || message.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Add a rating and a short message.')),
      );
      return;
    }
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
        setState(() => _sentThisSession = true);
        _controller.clear();
        messenger.showSnackBar(
          const SnackBar(content: Text('Thanks — your feedback was sent.')),
        );
      case ResultFailure(:final failure):
        messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = ref.watch(orderFeedbackProvider(widget.orderId));
    final sending = ref.watch(feedbackSubmitProvider);
    final submitted = existing.asData?.value ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Share feedback',
          style: AppTypography.label.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Tell us how this rejection was handled. Our team reviews every '
          'message.',
          style: AppTypography.caption.copyWith(
            color: AppColors.textMuted(context),
          ),
        ),
        const SizedBox(height: 12),
        if (existing.isLoading && submitted.isEmpty)
          const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (submitted.isNotEmpty || _sentThisSession) ...[
          for (final f in submitted)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 18,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${f.rating == null ? '' : '${'★' * f.rating!}  '}'
                      '${f.message}',
                      style: AppTypography.caption,
                    ),
                  ),
                ],
              ),
            ),
          if (submitted.isEmpty)
            Text(
              'Feedback sent. Thank you!',
              style: AppTypography.caption.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
              ),
            ),
        ] else ...[
          Row(
            children: [
              for (var star = 1; star <= 5; star++)
                IconButton(
                  onPressed: sending
                      ? null
                      : () => setState(() => _rating = star),
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    star <= _rating ? Icons.star : Icons.star_border,
                    color: AppColors.bronze,
                  ),
                ),
            ],
          ),
          TextField(
            controller: _controller,
            enabled: !sending,
            maxLines: 3,
            maxLength: 1000,
            decoration: const InputDecoration(
              hintText: 'What could have gone better?',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: sending ? null : _submit,
              child: Text(sending ? 'Sending…' : 'Send feedback'),
            ),
          ),
        ],
      ],
    );
  }
}
