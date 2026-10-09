import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_localizations.dart';
import '../../../../buyer/presentation/maison/maison_kit.dart';
import '../../../../seller/presentation/atelier/atelier_components.dart';
import '../../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../../seller/presentation/atelier/atelier_studio.dart';
import '../../../../seller/presentation/atelier/atelier_theme.dart';
import '../../../domain/models/reference_models.dart';

enum CircleRange {
  all('All time'),
  d7('7 days'),
  d15('15 days'),
  d30('30 days'),
  custom('Custom');

  const CircleRange(this.label);
  final String label;
}

/// Commission ledger: the period's net in one figure, a range filter, then
/// each referred order by month with its items and signed amount.
class CircleEarningsPanel extends StatefulWidget {
  const CircleEarningsPanel({
    required this.purchases,
    required this.loading,
    required this.loadingMore,
    required this.hasMore,
    required this.onRetry,
    required this.onLoadMore,
    this.error,
    super.key,
  });

  final List<ReferencePurchase> purchases;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;

  @override
  State<CircleEarningsPanel> createState() => _CircleEarningsPanelState();
}

class _CircleEarningsPanelState extends State<CircleEarningsPanel> {
  CircleRange _range = CircleRange.all;
  DateTimeRange? _custom;

  List<ReferencePurchase> get _filtered {
    final now = DateTime.now().toUtc();
    DateTime start;
    DateTime? end;
    switch (_range) {
      case CircleRange.all:
        return widget.purchases;
      case CircleRange.d7:
        start = now.subtract(const Duration(days: 7));
      case CircleRange.d15:
        start = now.subtract(const Duration(days: 15));
      case CircleRange.d30:
        start = now.subtract(const Duration(days: 30));
      case CircleRange.custom:
        final c = _custom;
        if (c == null) return widget.purchases;
        start = DateTime(c.start.year, c.start.month, c.start.day).toUtc();
        end = DateTime(c.end.year, c.end.month, c.end.day, 23, 59, 59).toUtc();
    }
    return [
      for (final p in widget.purchases)
        if (p.commissionAt == null ||
            (!p.commissionAt!.toUtc().isBefore(start) &&
                (end == null || !p.commissionAt!.toUtc().isAfter(end))))
          p,
    ];
  }

  Future<void> _onRange(CircleRange range) async {
    if (range != CircleRange.custom) {
      setState(() => _range = range);
      return;
    }
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _custom,
      helpText: context.tr(RemainingL10n.customDateRange),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _range = CircleRange.custom;
      _custom = picked;
    });
  }

  void _clearRange() => setState(() {
    _range = CircleRange.all;
    _custom = null;
  });

  @override
  Widget build(BuildContext context) {
    final all = widget.purchases;

    if (widget.loading && all.isEmpty) {
      return const Column(
        children: [
          SkeletonBox(height: 120, radius: AtelierRadius.lg),
          SizedBox(height: 16),
          AtelierSkeletonList(count: 3, height: 84),
        ],
      );
    }
    if (widget.error != null && all.isEmpty) {
      return AtelierErrorState(
        title: 'Earnings unavailable',
        message: widget.error!,
        onRetry: widget.onRetry,
      );
    }

    final filtered = _filtered;
    final net = filtered.fold<double>(0, (s, e) => s + e.commissionInr);
    final reversed = filtered.where((e) => e.commissionInr < 0).length;

    final head = <Widget>[
      _LedgerSummary(
        net: net,
        orders: filtered.length,
        reversed: reversed,
        range: _range,
      ),
      const SizedBox(height: 14),
      AtelierSegmented<CircleRange>(
        dense: true,
        segments: [
          for (final r in CircleRange.values)
            AtelierSegment(
              value: r,
              label: r == CircleRange.all ? context.tr(RemainingL10n.all) : r.label,
              icon: r == CircleRange.custom ? Icons.date_range_rounded : null,
            ),
        ],
        selected: _range,
        onChanged: _onRange,
      ),
      AnimatedSize(
        duration: AtelierMotion.base,
        curve: AtelierMotion.emphasized,
        alignment: Alignment.topLeft,
        child: _range == CircleRange.custom && _custom != null
            ? Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Flexible(
                      child: AtelierFilterTag(
                        label:
                            '${atelierDate(_custom!.start)} → '
                            '${atelierDate(_custom!.end)}',
                        onRemove: _clearRange,
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox(width: double.infinity),
      ),
    ];
    final children = <Widget>[];

    if (filtered.isEmpty) {
      children.add(const SizedBox(height: 8));
      children.add(
        AtelierEmptyState(
          icon: Icons.receipt_long_outlined,
          title: all.isEmpty ? 'No commission yet' : 'Nothing in this period',
          message: context.tr(RemainingL10n.noCommissionPurchases),
          actionLabel: all.isEmpty ? null : 'Show all time',
          onAction: all.isEmpty ? null : _clearRange,
        ),
      );
    } else {
      String? month;
      for (var i = 0; i < filtered.length; i++) {
        final purchase = filtered[i];
        final label = maisonMonthLabel(purchase.commissionAt);
        if (label != month) {
          month = label;
          children.add(const SizedBox(height: 10));
          children.add(
            MaisonGroupLabel(
              label: label,
              count: filtered
                  .where((e) => maisonMonthLabel(e.commissionAt) == label)
                  .length,
            ),
          );
        }
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Reveal(
              key: ValueKey('earning-${purchase.id}'),
              index: i < 8 ? i : 0,
              offset: 8,
              child: CircleEarningRow(purchase: purchase),
            ),
          ),
        );
      }
    }

    if (all.isNotEmpty) {
      children.add(
        MaisonListFooter(
          loadingMore: widget.loadingMore,
          hasMore: widget.hasMore,
          errorMessage: widget.error,
          onLoadMore: widget.onLoadMore,
          endLabel: 'Every referred order',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...head,
        AnimatedSwitcher(
          duration: AtelierMotion.base,
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.topCenter,
            children: [...previous, ?current],
          ),
          child: Column(
            key: ValueKey('$_range-${_custom?.start}-${_custom?.end}'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    );
  }
}

class _LedgerSummary extends StatelessWidget {
  const _LedgerSummary({
    required this.net,
    required this.orders,
    required this.reversed,
    required this.range,
  });

  final double net;
  final int orders;
  final int reversed;
  final CircleRange range;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final tone = net < 0 ? p.ruby : p.emerald;
    final period = switch (range) {
      CircleRange.all => 'All time',
      CircleRange.custom => 'Selected dates',
      _ => 'Last ${range.label}',
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.goldSoft, p.goldSoft.withValues(alpha: 0.3)],
        ),
        borderRadius: BorderRadius.circular(AtelierRadius.lg),
        border: Border.all(color: p.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NET COMMISSION · ${period.toUpperCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtelierType.overline(p.gold),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: CountUpText(
                    atelierMoney(net, symbol: '₹', decimals: 2),
                    style: AtelierType.display(tone, size: 34),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$orders ${orders == 1 ? 'order' : 'orders'}',
                style: AtelierType.label(p.ink, size: 12.5),
              ),
              if (reversed > 0) ...[
                const SizedBox(height: 3),
                Text(
                  '$reversed reversed',
                  style: AtelierType.caption(p.ruby, size: 11.5),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// One referred order: who bought, what, when and the signed commission.
class CircleEarningRow extends StatelessWidget {
  const CircleEarningRow({required this.purchase, super.key});

  final ReferencePurchase purchase;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final reversed = purchase.commissionInr < 0;
    final tone = reversed ? p.ruby : p.emerald;
    final meta = [
      if (purchase.metaLabel.isNotEmpty) purchase.metaLabel,
      if (purchase.createdAtLabel.trim().isNotEmpty) purchase.createdAtLabel,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AtelierRadius.md),
        border: Border.all(color: p.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tone.withValues(alpha: p.isDark ? 0.16 : 0.08),
                ),
                child: Icon(
                  reversed ? Icons.undo_rounded : Icons.south_west_rounded,
                  size: 16,
                  color: tone,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      purchase.buyerLabel ?? purchase.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AtelierType.label(p.ink, size: 14),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AtelierType.caption(p.muted, size: 11),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                purchase.signedAmountLabel,
                style: AtelierType.figure(tone, size: 15.5),
              ),
            ],
          ),
          if (reversed) ...[
            const SizedBox(height: 10),
            const AtelierNotice(
              text: 'Commission reversed (seller rejected the order)',
              tone: AtelierTone.ruby,
              icon: Icons.undo_rounded,
            ),
          ],
          if (purchase.items.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final item in purchase.items)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: p.sunken,
                      borderRadius: BorderRadius.circular(AtelierRadius.pill),
                    ),
                    child: Text(
                      item.lineLabel,
                      style: AtelierType.caption(p.inkSoft, size: 11),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
