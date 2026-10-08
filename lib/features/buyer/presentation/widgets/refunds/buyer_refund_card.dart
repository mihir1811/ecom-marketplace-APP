import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/haptics/app_haptics.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/router/app_navigation.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../refunds/application/refund_providers.dart';
import '../../../../refunds/domain/models/refund_request.dart';
import '../../../../seller/presentation/atelier/atelier_components.dart';
import '../../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../../seller/presentation/atelier/atelier_studio.dart';
import '../../../../seller/presentation/atelier/atelier_theme.dart';
import '../../maison/maison_kit.dart';

/// Buyer-facing name of a refund status.
String buyerRefundLabel(RefundStatus status) => switch (status) {
  RefundStatus.pending => 'In review',
  RefundStatus.accepted => 'Approved',
  RefundStatus.rejected => 'Declined',
  RefundStatus.cancelled => 'Withdrawn',
};

AtelierTone buyerRefundTone(RefundStatus status) => switch (status) {
  RefundStatus.pending => AtelierTone.amber,
  RefundStatus.accepted => AtelierTone.emerald,
  RefundStatus.rejected => AtelierTone.ruby,
  RefundStatus.cancelled => AtelierTone.neutral,
};

IconData buyerRefundIcon(RefundStatus status) => switch (status) {
  RefundStatus.pending => Icons.hourglass_top_rounded,
  RefundStatus.accepted => Icons.check_circle_rounded,
  RefundStatus.rejected => Icons.cancel_outlined,
  RefundStatus.cancelled => Icons.undo_rounded,
};

/// One refund request: amount, where it stands, the seller, the order it
/// belongs to, both sides' notes and — while in review — Withdraw.
class BuyerRefundCard extends ConsumerWidget {
  const BuyerRefundCard({required this.refund, super.key});

  final RefundRequest refund;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.atelier;
    final tone = buyerRefundTone(refund.status);
    final accent = p.tone(tone);
    final reference = refund.razorpayRefundId?.trim();

    return AnimatedContainer(
      duration: AtelierMotion.base,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AtelierRadius.lg),
        border: Border.all(
          color: refund.status.isPending
              ? accent.withValues(alpha: 0.4)
              : p.hairline,
        ),
        boxShadow: p.softShadow,
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AtelierPill(
                    label: buyerRefundLabel(refund.status),
                    tone: tone,
                    icon: buyerRefundIcon(refund.status),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 170),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        maisonUsd(refund.amountUsd),
                        style: AtelierType.display(
                          refund.status == RefundStatus.accepted
                              ? p.emerald
                              : p.ink,
                          size: 26,
                        ),
                      ),
                      if (refund.amountInr > 0)
                        Text(
                          maisonInr(refund.amountInr),
                          style: AtelierType.figure(p.muted, size: 11.5),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          RefundTrack(status: refund.status),
          const SizedBox(height: 18),
          Row(
            children: [
              AtelierMonogram(name: refund.sellerLabel, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SELLER', style: AtelierType.overline(p.muted)),
                    const SizedBox(height: 3),
                    Text(
                      refund.sellerLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtelierType.title(p.ink, size: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _OrderLink(orderId: refund.orderId),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.sunken,
              borderRadius: BorderRadius.circular(AtelierRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('YOUR REASON', style: AtelierType.overline(p.muted)),
                const SizedBox(height: 6),
                Text(
                  refund.reason,
                  style: AtelierType.body(p.inkSoft, size: 13),
                ),
                if (refund.sellerNote != null) ...[
                  const SizedBox(height: 12),
                  Text('SELLER’S NOTE', style: AtelierType.overline(p.muted)),
                  const SizedBox(height: 6),
                  Text(
                    '“${refund.sellerNote}”',
                    style: AtelierType.body(
                      p.inkSoft,
                      size: 13,
                    ).copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              AtelierKeyValue(
                label: context.tr(RemainingL10n.requested),
                value: refund.createdAt != null
                    ? atelierDate(refund.createdAt!)
                    : refund.createdAtLabel,
              ),
              if (refund.resolvedAtLabel != null || refund.resolvedAt != null)
                AtelierKeyValue(
                  label: 'Resolved',
                  value: refund.resolvedAt != null
                      ? atelierDate(refund.resolvedAt!)
                      : refund.resolvedAtLabel!,
                ),
              if (reference != null && reference.isNotEmpty)
                AtelierKeyValue(
                  label: 'Reference',
                  value: reference,
                  valueWidget: Pressable(
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final palette = context.atelier;
                      await atelierCopy(reference);
                      showMaisonToast(
                        messenger,
                        palette,
                        'Refund reference copied',
                        icon: Icons.copy_rounded,
                      );
                    },
                    semanticLabel: 'Copy refund reference',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 160),
                          child: Text(
                            reference,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AtelierType.figure(p.ink, size: 13),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.copy_rounded, size: 13, color: p.gold),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (refund.status == RefundStatus.accepted) ...[
            const SizedBox(height: 16),
            AtelierNotice(
              text: 'Approved refunds are credited to your GemWorld wallet.',
              tone: AtelierTone.emerald,
              icon: Icons.account_balance_wallet_outlined,
              actionLabel: 'Open wallet',
              onAction: () => context.switchToRoute(AppRouteNames.buyerWallet),
            ),
          ],
          if (refund.canCancel) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Changed your mind? You can withdraw while the seller '
                    'reviews it.',
                    style: AtelierType.caption(p.muted, size: 11.5),
                  ),
                ),
                const SizedBox(width: 12),
                AtelierButton(
                  label: context.tr(AccountCommerceL10n.cancelRequest),
                  icon: Icons.undo_rounded,
                  compact: true,
                  variant: AtelierButtonVariant.danger,
                  onPressed: () => _withdraw(context),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _withdraw(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final palette = context.atelier;
    final done = await showAtelierDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MaisonActionDialog(
        title: 'Withdraw this request?',
        message:
            'The ${maisonUsd(refund.amountUsd)} refund request to '
            '${refund.sellerLabel} will be closed. You can raise a new one '
            'from the order while it is still eligible.',
        confirmLabel: 'Withdraw',
        cancelLabel: 'Keep it',
        destructive: true,
        icon: Icons.undo_rounded,
        onConfirm: (ref) => maisonOutcome(
          ref.read(refundMutationProvider.notifier).cancel(refund.id),
        ),
      ),
    );
    if (done != true) return;
    AppHaptics.success();
    showMaisonToast(
      messenger,
      palette,
      'Refund request withdrawn',
      tone: AtelierTone.emerald,
    );
  }
}

class _OrderLink extends StatelessWidget {
  const _OrderLink({required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Pressable(
      onTap: () =>
          context.openRoute(AppRouteNames.buyerOrderDetailPath(orderId)),
      semanticLabel: 'Open order ${maisonShortId(orderId)}',
      borderRadius: BorderRadius.circular(AtelierRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: p.goldSoft,
          borderRadius: BorderRadius.circular(AtelierRadius.pill),
          border: Border.all(color: p.gold.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              maisonShortId(orderId),
              style: AtelierType.figure(p.ink, size: 12),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_outward_rounded, size: 14, color: p.gold),
          ],
        ),
      ),
    );
  }
}

/// Requested → Seller review → Wallet, filled to where [status] stands.
class RefundTrack extends StatelessWidget {
  const RefundTrack({required this.status, super.key});

  final RefundStatus status;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final accepted = status == RefundStatus.accepted;
    final failed =
        status == RefundStatus.rejected || status == RefundStatus.cancelled;
    final reached = accepted ? 2 : 1;
    final labels = [
      'Requested',
      switch (status) {
        RefundStatus.rejected => 'Declined',
        RefundStatus.cancelled => 'Withdrawn',
        _ => 'Seller review',
      },
      switch (status) {
        RefundStatus.pending => 'Refund to wallet',
        RefundStatus.accepted => 'Credited to wallet',
        _ => 'Not refunded',
      },
    ];
    _NodeState stateOf(int i) {
      if (i < reached) return _NodeState.done;
      if (i > reached) return _NodeState.upcoming;
      if (accepted) return _NodeState.done;
      return failed ? _NodeState.failed : _NodeState.current;
    }

    final accent = failed ? p.muted : p.gold;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: reached.toDouble()),
      duration: context.reduceMotion ? Duration.zero : AtelierMotion.lazy,
      curve: AtelierMotion.emphasized,
      builder: (context, t, _) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 9),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: (t - (i - 1)).clamp(0.0, 1.0),
                        minHeight: 2,
                        color: accent,
                        backgroundColor: p.hairline,
                      ),
                    ),
                  ),
                ),
              _TrackNode(
                label: labels[i],
                state: stateOf(i),
                lit: t >= i - 0.05,
                alignEnd: i == 2,
                alignStart: i == 0,
              ),
            ],
          ],
        );
      },
    );
  }
}

enum _NodeState { done, current, failed, upcoming }

class _TrackNode extends StatelessWidget {
  const _TrackNode({
    required this.label,
    required this.state,
    required this.lit,
    this.alignStart = false,
    this.alignEnd = false,
  });

  final String label;
  final _NodeState state;
  final bool lit;
  final bool alignStart;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final active = lit && state != _NodeState.upcoming;
    final (Color fill, Color edge, IconData? glyph) = switch (state) {
      _NodeState.done => (p.gold, p.gold, Icons.check_rounded),
      _NodeState.current => (p.goldSoft, p.gold, null),
      _NodeState.failed => (p.sunken, p.ruby, Icons.close_rounded),
      _NodeState.upcoming => (p.sunken, p.hairline, null),
    };
    return SizedBox(
      width: 76,
      child: Column(
        crossAxisAlignment: alignStart
            ? CrossAxisAlignment.start
            : alignEnd
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: AtelierMotion.slow,
            curve: AtelierMotion.settle,
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? fill : p.sunken,
              border: Border.all(color: active ? edge : p.hairline, width: 1.4),
            ),
            child: !active
                ? null
                : glyph != null
                ? Icon(
                    glyph,
                    size: 12,
                    color: state == _NodeState.done ? p.onGold : p.ruby,
                  )
                : const Center(
                    child: AtelierPulseDot(tone: AtelierTone.gold, size: 6),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 2,
            textAlign: alignStart
                ? TextAlign.start
                : alignEnd
                ? TextAlign.end
                : TextAlign.center,
            style: AtelierType.caption(active ? p.ink : p.muted, size: 10.5),
          ),
        ],
      ),
    );
  }
}
