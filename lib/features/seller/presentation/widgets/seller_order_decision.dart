import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../application/seller_orders_provider.dart';
import '../../domain/models/seller_order.dart';

/// Amount as the API priced it: both currencies when both are present.
String sellerOrderAmountLabel(SellerOrder order) {
  final usd = order.amountUsd;
  final inr = order.amountInr;
  if (usd != null && usd > 0 && inr != null && inr > 0) {
    return AppCurrency.dual(usd, inr);
  }
  if (inr != null && inr > 0) return AppCurrency.inr(inr);
  if (usd != null && usd > 0) return AppCurrency.usd(usd);
  final amount = order.amount;
  if (amount == null) return '—';
  return order.currency?.toUpperCase() == AppCurrency.inrCode
      ? AppCurrency.inr(amount)
      : AppCurrency.usd(amount);
}

String sellerOrderDateLabel(DateTime? date) {
  if (date == null) return '—';
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year}, '
      '${two(date.hour)}:${two(date.minute)}';
}

Color sellerOrderStatusColor(SellerOrderStatus status) => switch (status) {
  SellerOrderStatus.pending => AppColors.bronze,
  SellerOrderStatus.accepted => AppColors.success,
  SellerOrderStatus.rejected => AppColors.error,
  SellerOrderStatus.unknown => AppColors.charcoalLight,
};

IconData sellerOrderStatusIcon(SellerOrderStatus status) => switch (status) {
  SellerOrderStatus.pending => Icons.hourglass_top_outlined,
  SellerOrderStatus.accepted => Icons.check_circle_outline,
  SellerOrderStatus.rejected => Icons.cancel_outlined,
  SellerOrderStatus.unknown => Icons.help_outline,
};

String sellerOrderStatusLabel(SellerOrder order) =>
    order.status == SellerOrderStatus.unknown && order.rawStatus.isNotEmpty
    ? order.rawStatus.replaceAll('_', ' ')
    : order.status.label;

/// Pill showing the seller decision state.
class SellerOrderStatusBadge extends StatelessWidget {
  const SellerOrderStatusBadge({required this.order, super.key});

  final SellerOrder order;

  @override
  Widget build(BuildContext context) {
    final color = sellerOrderStatusColor(order.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(sellerOrderStatusIcon(order.status), size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              sellerOrderStatusLabel(order),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Accept / Reject for a pending order. Renders nothing for other states.
class SellerOrderDecisionButtons extends ConsumerWidget {
  const SellerOrderDecisionButtons({
    required this.order,
    this.compact = false,
    super.key,
  });

  final SellerOrder order;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!order.status.canDecide) return const SizedBox.shrink();
    final busy = ref.watch(
      sellerOrderActionsProvider.select((ids) => ids.contains(order.id)),
    );
    final height = compact ? 40.0 : 48.0;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: height,
            child: OutlinedButton.icon(
              onPressed: busy
                  ? null
                  : () => confirmRejectSellerOrder(context, ref, order),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(
                  color: AppColors.error.withValues(alpha: busy ? 0.3 : 0.6),
                ),
              ),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Reject Order'),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: height,
            child: FilledButton.icon(
              onPressed: busy
                  ? null
                  : () => confirmAcceptSellerOrder(context, ref, order),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.charcoal,
                foregroundColor: AppColors.warmWhite,
              ),
              icon: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.warmWhite,
                      ),
                    )
                  : const Icon(Icons.check, size: 18),
              label: Text(busy ? 'Updating…' : 'Accept Order'),
            ),
          ),
        ),
      ],
    );
  }
}

/// Asks "Confirm Order" first; the API is called only after Confirm, while
/// the dialog shows progress and stays open on errors.
Future<void> confirmAcceptSellerOrder(
  BuildContext context,
  WidgetRef ref,
  SellerOrder order,
) async {
  // Captured now: the card that opened the dialog moves to another tab (and
  // is disposed) as soon as the order is accepted.
  final messenger = ScaffoldMessenger.of(context);
  final done = await showAppDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => SellerActionConfirmDialog(
      title: 'Confirm Order',
      message: 'Are you sure you want to accept this order?',
      confirmLabel: 'Confirm',
      content: _OrderSummaryLine(order: order),
      onConfirm: (ref) => _decide(
        ref.read(sellerOrderActionsProvider.notifier).accept(order),
      ),
    ),
  );
  if (done != true) return;
  AppHaptics.success();
  messenger.showSnackBar(
    const SnackBar(
      content: Text('Order accepted. The customer sees it as confirmed.'),
    ),
  );
}

const _rejectReasons = [
  'Sold elsewhere',
  'Out of stock',
  'Price changed',
  'Unable to ship to this address',
  'Other',
];

/// Asks "Reject Order" (with the reason the API requires) before rejecting.
Future<void> confirmRejectSellerOrder(
  BuildContext context,
  WidgetRef ref,
  SellerOrder order,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final done = await showAppDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _RejectOrderDialog(order: order),
  );
  if (done != true) return;
  AppHaptics.success();
  messenger.showSnackBar(
    const SnackBar(
      content: Text(
        'Order rejected. The customer has been refunded to their wallet.',
      ),
    ),
  );
}

Future<Failure?> _decide(Future<Result<SellerOrder?, Failure>> call) async {
  final result = await call;
  return switch (result) {
    Success() => null,
    ResultFailure(:final failure) => failure,
  };
}

/// Confirmation dialog that runs [onConfirm] itself: both buttons are
/// disabled and Confirm shows a spinner until the request settles, so the
/// action cannot be sent twice. A failure keeps the dialog open with the
/// error; success closes it with `true`. Cancel closes it with `false`
/// and changes nothing.
class SellerActionConfirmDialog extends ConsumerStatefulWidget {
  const SellerActionConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
    this.content,
    this.destructive = false,
    this.canConfirm = true,
    super.key,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final Widget? content;
  final bool destructive;
  final bool canConfirm;

  /// Performs the action; returns the failure, or `null` on success.
  final Future<Failure?> Function(WidgetRef ref) onConfirm;

  @override
  ConsumerState<SellerActionConfirmDialog> createState() =>
      _SellerActionConfirmDialogState();
}

class _SellerActionConfirmDialogState
    extends ConsumerState<SellerActionConfirmDialog> {
  bool _busy = false;
  String? _error;

  Future<void> _confirm() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final failure = await widget.onConfirm(ref);
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop(true);
      return;
    }
    AppHaptics.error();
    setState(() {
      _busy = false;
      _error = failure.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.destructive ? AppColors.error : AppColors.charcoal;
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: Text(widget.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.message,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary(context),
                ),
              ),
              if (widget.content != null) ...[
                const SizedBox(height: 12),
                widget.content!,
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 18,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _error!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _busy || !widget.canConfirm ? null : _confirm,
            style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: AppColors.warmWhite,
            ),
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.warmWhite,
                    ),
                  )
                : Text(widget.confirmLabel),
          ),
        ],
      ),
    );
  }
}

class _OrderSummaryLine extends StatelessWidget {
  const _OrderSummaryLine({required this.order});

  final SellerOrder order;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Text(
        '#${order.shortId} · ${order.customerLabel} · '
        '${sellerOrderAmountLabel(order)}',
        style: AppTypography.caption.copyWith(
          color: AppColors.textPrimary(context),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RejectOrderDialog extends StatefulWidget {
  const _RejectOrderDialog({required this.order});

  final SellerOrder order;

  @override
  State<_RejectOrderDialog> createState() => _RejectOrderDialogState();
}

class _RejectOrderDialogState extends State<_RejectOrderDialog> {
  String? _reason;
  final _otherCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _otherCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String? get _resolvedReason {
    if (_reason == null) return null;
    if (_reason != 'Other') return _reason;
    final custom = _otherCtrl.text.trim();
    return custom.isEmpty ? null : custom;
  }

  @override
  Widget build(BuildContext context) {
    final reason = _resolvedReason;
    return SellerActionConfirmDialog(
      title: 'Reject Order',
      message: 'Are you sure you want to reject this order?',
      confirmLabel: 'Reject',
      destructive: true,
      canConfirm: reason != null,
      onConfirm: (ref) {
        final note = _noteCtrl.text.trim();
        return _decide(
          ref
              .read(sellerOrderActionsProvider.notifier)
              .reject(
                widget.order,
                reason: reason!,
                sellerNote: note.isEmpty ? null : note,
              ),
        );
      },
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OrderSummaryLine(order: widget.order),
          const SizedBox(height: 8),
          Text(
            'The customer is refunded to their GemWorld wallet. This cannot '
            'be undone.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted(context),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Reason',
            style: AppTypography.label.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in _rejectReasons)
                ChoiceChip(
                  label: Text(option),
                  selected: _reason == option,
                  onSelected: (_) => setState(() => _reason = option),
                ),
            ],
          ),
          if (_reason == 'Other') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _otherCtrl,
              maxLength: 200,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Describe the reason',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            maxLength: 1000,
            decoration: const InputDecoration(
              labelText: 'Note to customer (optional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
