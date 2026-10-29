import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_currency.dart';
import '../../application/seller_orders_provider.dart';
import '../../domain/models/seller_order.dart';
import '../atelier/atelier_components.dart';
import '../atelier/atelier_feedback.dart';
import '../atelier/atelier_theme.dart';

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

/// The same amount split for visual hierarchy: USD leads, INR follows.
({String primary, String? secondary}) sellerOrderAmountParts(
  SellerOrder order,
) {
  final usd = order.amountUsd;
  final inr = order.amountInr;
  if (usd != null && usd > 0 && inr != null && inr > 0) {
    return (primary: AppCurrency.usd(usd), secondary: AppCurrency.inr(inr));
  }
  return (primary: sellerOrderAmountLabel(order), secondary: null);
}

String sellerOrderDateLabel(DateTime? date) {
  if (date == null) return '—';
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year}, '
      '${two(date.hour)}:${two(date.minute)}';
}

/// "5m ago" / "3h ago" / date — for scanning lists quickly.
String sellerOrderRelativeTime(DateTime? date) {
  if (date == null) return '—';
  final diff = DateTime.now().difference(date.toLocal());
  if (diff.isNegative || diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return sellerOrderDateLabel(date).split(',').first;
}

Color sellerOrderStatusColor(SellerOrderStatus status) => switch (status) {
  SellerOrderStatus.pending => AppColors.bronze,
  SellerOrderStatus.accepted => AppColors.success,
  SellerOrderStatus.rejected => AppColors.error,
  SellerOrderStatus.unknown => AppColors.charcoalLight,
};

AtelierTone sellerOrderStatusTone(SellerOrderStatus status) => switch (status) {
  SellerOrderStatus.pending => AtelierTone.gold,
  SellerOrderStatus.accepted => AtelierTone.emerald,
  SellerOrderStatus.rejected => AtelierTone.ruby,
  SellerOrderStatus.unknown => AtelierTone.neutral,
};

IconData sellerOrderStatusIcon(SellerOrderStatus status) => switch (status) {
  SellerOrderStatus.pending => Icons.hourglass_top_outlined,
  SellerOrderStatus.accepted => Icons.check_circle_outline,
  SellerOrderStatus.rejected => Icons.cancel_outlined,
  SellerOrderStatus.unknown => Icons.help_outline,
};

String sellerOrderStatusLabel(SellerOrder order) =>
    order.isAuctionSale && order.status == SellerOrderStatus.accepted
    ? 'Sold'
    : order.status == SellerOrderStatus.unknown && order.rawStatus.isNotEmpty
    ? order.rawStatus.replaceAll('_', ' ')
    : order.status.label;

/// Pill showing the seller decision state.
class SellerOrderStatusBadge extends StatelessWidget {
  const SellerOrderStatusBadge({required this.order, super.key});

  final SellerOrder order;

  @override
  Widget build(BuildContext context) {
    return AtelierPill(
      label: sellerOrderStatusLabel(order),
      tone: sellerOrderStatusTone(order.status),
      icon: sellerOrderStatusIcon(order.status),
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

    return Row(
      children: [
        Expanded(
          child: AtelierButton(
            label: 'Reject Order',
            icon: Icons.close_rounded,
            compact: compact,
            variant: AtelierButtonVariant.danger,
            onPressed: busy
                ? null
                : () => confirmRejectSellerOrder(context, ref, order),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AtelierButton(
            label: busy ? 'Updating…' : 'Accept Order',
            icon: Icons.check_rounded,
            compact: compact,
            loading: busy,
            variant: AtelierButtonVariant.gold,
            onPressed: busy
                ? null
                : () => confirmAcceptSellerOrder(context, ref, order),
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
  final palette = context.atelier;
  final done = await showAtelierDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => SellerActionConfirmDialog(
      title: 'Confirm Order',
      message: 'Are you sure you want to accept this order?',
      confirmLabel: 'Confirm',
      icon: Icons.verified_outlined,
      content: _OrderSummaryLine(order: order),
      onConfirm: (ref) =>
          _decide(ref.read(sellerOrderActionsProvider.notifier).accept(order)),
    ),
  );
  if (done != true) return;
  AppHaptics.success();
  showAtelierToastOn(
    messenger,
    palette,
    'Order accepted. The customer sees it as confirmed.',
    tone: AtelierTone.emerald,
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
  final palette = context.atelier;
  final done = await showAtelierDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _RejectOrderDialog(order: order),
  );
  if (done != true) return;
  AppHaptics.success();
  showAtelierToastOn(
    messenger,
    palette,
    'Order rejected. The customer has been refunded to their wallet.',
    tone: AtelierTone.ruby,
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
    this.icon,
    super.key,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final Widget? content;
  final bool destructive;
  final bool canConfirm;
  final IconData? icon;

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
    return PopScope(
      canPop: !_busy,
      child: AtelierDialogFrame(
        title: widget.title,
        message: widget.message,
        icon:
            widget.icon ??
            (widget.destructive
                ? Icons.report_gmailerrorred_rounded
                : Icons.task_alt_rounded),
        tone: widget.destructive ? AtelierTone.ruby : AtelierTone.gold,
        content: (widget.content == null && _error == null)
            ? null
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ?widget.content,
                  AnimatedSize(
                    duration: AtelierMotion.base,
                    curve: AtelierMotion.emphasized,
                    child: _error == null
                        ? const SizedBox(width: double.infinity)
                        : Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: AtelierNotice(
                              text: _error!,
                              tone: AtelierTone.ruby,
                              icon: Icons.error_outline_rounded,
                            ),
                          ),
                  ),
                ],
              ),
        actions: [
          AtelierButton(
            label: 'Cancel',
            variant: AtelierButtonVariant.secondary,
            onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          ),
          AtelierButton(
            label: widget.confirmLabel,
            loading: _busy,
            variant: widget.destructive
                ? AtelierButtonVariant.danger
                : AtelierButtonVariant.primary,
            onPressed: _busy || !widget.canConfirm ? null : _confirm,
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
    final p = context.atelier;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.sunken,
        borderRadius: BorderRadius.circular(AtelierRadius.md),
      ),
      child: Row(
        children: [
          AtelierMonogram(name: order.customerLabel, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${order.shortId} · ${order.customerLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtelierType.label(p.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  sellerOrderAmountLabel(order),
                  style: AtelierType.figure(p.inkSoft, size: 12.5),
                ),
              ],
            ),
          ),
        ],
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
    final p = context.atelier;
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
          const SizedBox(height: 10),
          Text(
            'The customer is refunded to their GemWorld wallet. This cannot '
            'be undone.',
            style: AtelierType.caption(p.muted),
          ),
          const SizedBox(height: 18),
          Text('REASON', style: AtelierType.overline(p.muted)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in _rejectReasons)
                AtelierChoiceChip(
                  label: option,
                  selected: _reason == option,
                  onTap: () => setState(() => _reason = option),
                ),
            ],
          ),
          AnimatedSize(
            duration: AtelierMotion.base,
            curve: AtelierMotion.emphasized,
            child: _reason == 'Other'
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: AtelierTextArea(
                      controller: _otherCtrl,
                      label: 'Describe the reason',
                      maxLength: 200,
                      maxLines: 1,
                      onChanged: (_) => setState(() {}),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: 12),
          AtelierTextArea(
            controller: _noteCtrl,
            label: 'Note to customer (optional)',
            maxLength: 1000,
          ),
        ],
      ),
    );
  }
}

/// Soft filled text input used in workspace dialogs.
class AtelierTextArea extends StatelessWidget {
  const AtelierTextArea({
    required this.controller,
    required this.label,
    this.maxLines = 3,
    this.maxLength,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      cursorColor: p.gold,
      style: AtelierType.body(p.ink),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AtelierType.caption(p.muted, size: 13),
        floatingLabelStyle: AtelierType.caption(p.gold, size: 13),
        filled: true,
        fillColor: p.sunken,
        counterStyle: AtelierType.caption(p.muted, size: 10.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AtelierRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AtelierRadius.md),
          borderSide: BorderSide(color: p.gold),
        ),
      ),
    );
  }
}
