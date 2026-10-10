import 'package:flutter/material.dart';

import '../../../../../core/haptics/app_haptics.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/router/app_navigation.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/router/workspace_mode.dart';
import '../../../../buyer/presentation/maison/maison_kit.dart';
import '../../../../seller/presentation/atelier/atelier_components.dart';
import '../../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../../seller/presentation/atelier/atelier_studio.dart';
import '../../../../seller/presentation/atelier/atelier_theme.dart';
import '../../../application/wallet_provider.dart';
import '../../../domain/models/wallet.dart';

/// What a ledger entry was.
enum WalletTxnKind { topUp, refund, payment, otherIn, otherOut }

WalletTxnKind walletTxnKind(WalletTransaction t) {
  final type = t.type.toUpperCase();
  if (type.contains('TOP')) return WalletTxnKind.topUp;
  if (type.contains('REFUND')) return WalletTxnKind.refund;
  if (type.contains('PAYMENT') ||
      type.contains('ORDER') ||
      type.contains('PURCHASE')) {
    return WalletTxnKind.payment;
  }
  return t.isCredit ? WalletTxnKind.otherIn : WalletTxnKind.otherOut;
}

IconData walletTxnIcon(WalletTxnKind kind) => switch (kind) {
  WalletTxnKind.topUp => Icons.add_rounded,
  WalletTxnKind.refund => Icons.replay_rounded,
  WalletTxnKind.payment => Icons.shopping_bag_outlined,
  WalletTxnKind.otherIn => Icons.south_west_rounded,
  WalletTxnKind.otherOut => Icons.north_east_rounded,
};

String _time(DateTime? date) {
  if (date == null) return '';
  final d = date.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(d.hour)}:${two(d.minute)}';
}

// ── Money flow ──────────────────────────────────────────────────────────

/// Where the money came from and went, across the loaded transactions:
/// one animated bar and a three-line legend.
class WalletFlow extends StatelessWidget {
  const WalletFlow({required this.transactions, super.key});

  final List<WalletTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    var added = 0.0, refunds = 0.0, spent = 0.0;
    for (final t in transactions) {
      final v = t.amount.abs();
      switch (walletTxnKind(t)) {
        case WalletTxnKind.topUp || WalletTxnKind.otherIn:
          added += v;
        case WalletTxnKind.refund:
          refunds += v;
        case WalletTxnKind.payment || WalletTxnKind.otherOut:
          spent += v;
      }
    }
    final total = added + refunds + spent;
    final parts = [
      (label: 'Added', value: added, color: p.gold, icon: Icons.add_rounded),
      (
        label: 'Refunds in',
        value: refunds,
        color: p.emerald,
        icon: Icons.replay_rounded,
      ),
      (
        label: 'Spent',
        value: spent,
        color: p.inkSoft,
        icon: Icons.shopping_bag_outlined,
      ),
    ];

    return AtelierCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MONEY FLOW', style: AtelierType.overline(p.gold)),
                    const SizedBox(height: 4),
                    Text(
                      transactions.isEmpty
                          ? 'No activity yet'
                          : 'Your ${transactions.length} most recent movements',
                      style: AtelierType.caption(p.muted, size: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: context.reduceMotion
                    ? Duration.zero
                    : AtelierMotion.lazy,
                curve: AtelierMotion.emphasized,
                builder: (context, t, _) {
                  if (total == 0) {
                    return Container(color: p.sunken);
                  }
                  return Row(
                    children: [
                      for (final part in parts)
                        if (part.value > 0)
                          Expanded(
                            flex: (part.value / total * 1000 * t).round().clamp(
                              1,
                              1000,
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(right: 2),
                              color: part.color,
                            ),
                          ),
                      Expanded(
                        flex: ((1 - t) * 1000).round().clamp(0, 1000) + 1,
                        child: Container(color: p.sunken),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final part in parts)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: part.color.withValues(
                        alpha: p.isDark ? 0.16 : 0.1,
                      ),
                    ),
                    child: Icon(part.icon, size: 14, color: part.color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      part.label,
                      style: AtelierType.label(p.inkSoft, size: 13),
                    ),
                  ),
                  if (total > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Text(
                        '${(part.value / total * 100).round()}%',
                        style: AtelierType.figure(p.muted, size: 11),
                      ),
                    ),
                  CountUpText(
                    maisonInr(part.value),
                    style: AtelierType.figure(p.ink, size: 14),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Ledger ──────────────────────────────────────────────────────────────

/// Ledger filter.
enum WalletLedgerFilter { all, credits, debits }

/// Full activity: In / Out filter, day groups, pagination footer.
class WalletLedger extends StatelessWidget {
  const WalletLedger({
    required this.txns,
    required this.filter,
    required this.onFilter,
    required this.onRetry,
    required this.onLoadMore,
    super.key,
  });

  final WalletTransactionsState txns;
  final WalletLedgerFilter filter;
  final ValueChanged<WalletLedgerFilter> onFilter;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final visible = [
      for (final t in txns.items)
        if (filter == WalletLedgerFilter.all ||
            (filter == WalletLedgerFilter.credits) == t.isCredit)
          t,
    ];
    final credits = txns.items.where((t) => t.isCredit).length;

    Widget body;
    if (txns.isLoading && txns.items.isEmpty) {
      body = const AtelierSkeletonList(count: 5, height: 72);
    } else if (txns.items.isEmpty && txns.errorMessage != null) {
      body = AtelierErrorState(
        compact: true,
        title: 'Activity unavailable',
        message: txns.errorMessage!,
        onRetry: onRetry,
      );
    } else if (visible.isEmpty) {
      body = AtelierEmptyState(
        compact: true,
        icon: Icons.receipt_long_outlined,
        title: txns.items.isEmpty ? 'No activity yet' : 'Nothing to show',
        message: txns.items.isEmpty
            ? context.tr(RemainingL10n.noWalletTransactions)
            : 'No ${filter == WalletLedgerFilter.credits ? 'money in' : 'money out'} '
                  'in the loaded activity.',
      );
    } else {
      final rows = <Widget>[];
      String? day;
      var i = 0;
      for (final t in visible) {
        final label = maisonDayLabel(t.createdAt);
        if (label != day) {
          rows.add(MaisonGroupLabel(label: label));
          day = label;
        }
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Reveal(
              key: ValueKey(t.id),
              index: i < 10 ? i : 0,
              child: _LedgerRow(
                transaction: t,
                onTap: () => showWalletTransactionSheet(context, t),
              ),
            ),
          ),
        );
        i++;
      }
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...rows,
          MaisonListFooter(
            loadingMore: txns.isLoadingMore,
            hasMore: txns.hasMore,
            errorMessage: txns.errorMessage,
            onLoadMore: onLoadMore,
            endLabel: 'The beginning of your wallet',
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AtelierSectionHeader(title: 'Activity'),
        const SizedBox(height: 14),
        AtelierSegmented<WalletLedgerFilter>(
          expand: true,
          dense: true,
          segments: [
            AtelierSegment(
              value: WalletLedgerFilter.all,
              label: context.tr(RemainingL10n.all),
              count: txns.items.length,
            ),
            AtelierSegment(
              value: WalletLedgerFilter.credits,
              label: 'Money in',
              icon: Icons.south_west_rounded,
              count: credits,
            ),
            AtelierSegment(
              value: WalletLedgerFilter.debits,
              label: 'Money out',
              icon: Icons.north_east_rounded,
              count: txns.items.length - credits,
            ),
          ],
          selected: filter,
          onChanged: onFilter,
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: AtelierMotion.base,
          child: KeyedSubtree(key: ValueKey(filter), child: body),
        ),
      ],
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.transaction, required this.onTap});

  final WalletTransaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final t = transaction;
    final credit = t.isCredit;
    final kind = walletTxnKind(t);
    final accent = switch (kind) {
      WalletTxnKind.topUp => p.gold,
      WalletTxnKind.refund || WalletTxnKind.otherIn => p.emerald,
      _ => p.inkSoft,
    };
    final sign = credit ? '+' : '−';
    final subtitle = [
      if (_time(t.createdAt).isNotEmpty) _time(t.createdAt),
      if (t.note != null && t.note!.trim().isNotEmpty) t.note!.trim(),
    ].join('  ·  ');

    return Pressable(
      onTap: onTap,
      semanticLabel: '${t.typeLabel}, $sign${maisonInr(t.amount.abs())}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(AtelierRadius.md),
          border: Border.all(color: p.hairline),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: p.isDark ? 0.14 : 0.09),
                border: Border.all(color: accent.withValues(alpha: 0.22)),
              ),
              child: Icon(walletTxnIcon(kind), size: 18, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.typeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AtelierType.label(p.ink, size: 14),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtelierType.caption(p.muted, size: 11.5),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$sign${maisonInr(t.amount.abs())}',
                  style: AtelierType.figure(
                    credit ? p.emerald : p.ink,
                    size: 14.5,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  context.tr(RemainingL10n.balanceAfterAmount, {
                    'amount': maisonInr(t.balanceAfter),
                  }),
                  style: AtelierType.caption(p.muted, size: 10.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Detail of one entry with copyable references and, when it belongs to
/// an order, a shortcut to that order.
Future<void> showWalletTransactionSheet(
  BuildContext context,
  WalletTransaction t,
) {
  return showAtelierSheet<void>(
    context: context,
    title: t.typeLabel,
    subtitle: [
      maisonDayLabel(t.createdAt),
      _time(t.createdAt),
    ].where((e) => e.isNotEmpty).join(' · '),
    builder: (sheetContext) {
      final p = sheetContext.atelier;
      final credit = t.isCredit;
      final orderId = t.orderId?.trim();
      final refs = <(String, String)>[
        ('Transaction ID', t.id),
        if (orderId != null && orderId.isNotEmpty) ('Order ID', orderId),
        if (t.razorpayOrderId != null && t.razorpayOrderId!.isNotEmpty)
          ('Razorpay order', t.razorpayOrderId!),
        if (t.razorpayPaymentId != null && t.razorpayPaymentId!.isNotEmpty)
          ('Razorpay payment', t.razorpayPaymentId!),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Reveal(
            child: Text(
              '${credit ? '+' : '−'}${maisonInr(t.amount.abs())}',
              style: AtelierType.display(credit ? p.emerald : p.ink, size: 42),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              AtelierPill(
                label: credit ? 'Money in' : 'Money out',
                tone: credit ? AtelierTone.emerald : AtelierTone.neutral,
                icon: walletTxnIcon(walletTxnKind(t)),
                dense: true,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  sheetContext.tr(RemainingL10n.balanceAfterAmount, {
                    'amount': maisonInr(t.balanceAfter),
                  }),
                  style: AtelierType.caption(p.muted),
                ),
              ),
            ],
          ),
          if (t.note != null && t.note!.trim().isNotEmpty) ...[
            const SizedBox(height: 20),
            AtelierKeyValue(label: 'Note', value: t.note!.trim()),
          ],
          const SizedBox(height: 20),
          for (var i = 0; i < refs.length; i++)
            Reveal(
              index: i + 1,
              offset: 8,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                  decoration: BoxDecoration(
                    color: p.sunken,
                    borderRadius: BorderRadius.circular(AtelierRadius.sm),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: AtelierKeyValue(
                          label: refs[i].$1,
                          value: refs[i].$2,
                          valueWidget: Text(
                            refs[i].$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AtelierType.figure(p.ink, size: 12.5),
                          ),
                        ),
                      ),
                      AtelierIconButton(
                        icon: Icons.copy_rounded,
                        tooltip: 'Copy ${refs[i].$1}',
                        size: 34,
                        onPressed: () async {
                          await atelierCopy(refs[i].$2);
                          if (!sheetContext.mounted) return;
                          AppHaptics.selection();
                          showAtelierToast(
                            sheetContext,
                            '${refs[i].$1} copied',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (orderId != null && orderId.isNotEmpty) ...[
            const SizedBox(height: 12),
            AtelierButton(
              label: 'Open order ${maisonShortId(orderId)}',
              icon: Icons.local_mall_outlined,
              variant: AtelierButtonVariant.secondary,
              expand: true,
              onPressed: () {
                Navigator.of(sheetContext).pop();
                context.openRoute(
                  currentWorkspace(context) == AppWorkspace.seller
                      ? AppRouteNames.sellerOrderDetailPath(orderId)
                      : AppRouteNames.buyerOrderDetailPath(orderId),
                );
              },
            ),
          ],
        ],
      );
    },
  );
}
