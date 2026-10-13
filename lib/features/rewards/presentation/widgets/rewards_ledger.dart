import 'package:flutter/material.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../buyer/presentation/maison/maison_kit.dart';
import '../../../seller/presentation/atelier/atelier_components.dart';
import '../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../seller/presentation/atelier/atelier_studio.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import '../../application/rewards_provider.dart';
import '../../domain/models/rewards.dart';
import '../rewards_format.dart';

IconData rewardTxnIcon(RewardTxnType type) => switch (type) {
  RewardTxnType.earn => Icons.auto_awesome_outlined,
  RewardTxnType.redeem => Icons.shopping_bag_outlined,
  RewardTxnType.redeemRefund => Icons.replay_rounded,
  RewardTxnType.adminCredit => Icons.card_giftcard_outlined,
  RewardTxnType.adminDebit => Icons.remove_circle_outline_rounded,
  RewardTxnType.unknown => Icons.stars_outlined,
};

Color _accent(AtelierPalette p, RewardTransaction t) => switch (t.type) {
  RewardTxnType.earn => p.gold,
  RewardTxnType.redeemRefund || RewardTxnType.adminCredit => p.emerald,
  RewardTxnType.unknown => p.muted,
  _ => p.inkSoft,
};

/// `+45 pts`, `−300 pts`, or unsigned for an unknown type.
String _signed(RewardTransaction t) {
  final sign = t.isCredit ? '+' : (t.isDebit ? '−' : '');
  return '$sign${rewardPointsLabel(t.points)}';
}

String _time(DateTime? date) {
  if (date == null) return '';
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(date.hour)}:${two(date.minute)}';
}

/// History filter.
enum RewardsLedgerFilter { all, earned, used }

/// Full points history: Earned / Used filter, day groups, pagination.
class RewardsLedger extends StatelessWidget {
  const RewardsLedger({
    required this.txns,
    required this.filter,
    required this.onFilter,
    required this.onRetry,
    required this.onLoadMore,
    super.key,
  });

  final RewardTransactionsState txns;
  final RewardsLedgerFilter filter;
  final ValueChanged<RewardsLedgerFilter> onFilter;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final visible = [
      for (final t in txns.items)
        if (switch (filter) {
          RewardsLedgerFilter.all => true,
          RewardsLedgerFilter.earned => t.isCredit,
          RewardsLedgerFilter.used => t.isDebit,
        })
          t,
    ];
    final earned = txns.items.where((t) => t.isCredit).length;
    final used = txns.items.where((t) => t.isDebit).length;

    Widget body;
    if (txns.isLoading && txns.items.isEmpty) {
      body = const AtelierSkeletonList(count: 5, height: 72);
    } else if (txns.items.isEmpty && txns.errorMessage != null) {
      body = AtelierErrorState(
        compact: true,
        title: 'History unavailable',
        message: txns.errorMessage!,
        onRetry: onRetry,
      );
    } else if (visible.isEmpty) {
      body = AtelierEmptyState(
        compact: true,
        icon: Icons.auto_awesome_outlined,
        title: txns.items.isEmpty ? 'No points yet' : 'Nothing to show',
        message: txns.items.isEmpty
            ? 'Points you earn on completed orders and use at checkout '
                  'appear here.'
            : 'No ${filter == RewardsLedgerFilter.earned ? 'earned' : 'used'} '
                  'points in the loaded history.',
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
                onTap: () => showRewardTransactionSheet(context, t),
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
            endLabel: 'The beginning of your rewards',
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AtelierSectionHeader(title: 'Points history'),
        const SizedBox(height: 14),
        AtelierSegmented<RewardsLedgerFilter>(
          expand: true,
          dense: true,
          segments: [
            AtelierSegment(
              value: RewardsLedgerFilter.all,
              label: 'All',
              count: txns.items.length,
            ),
            AtelierSegment(
              value: RewardsLedgerFilter.earned,
              label: 'Earned',
              icon: Icons.south_west_rounded,
              count: earned,
            ),
            AtelierSegment(
              value: RewardsLedgerFilter.used,
              label: 'Used',
              icon: Icons.north_east_rounded,
              count: used,
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

  final RewardTransaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final t = transaction;
    final accent = _accent(p, t);
    final subtitle = [
      if (_time(t.createdAt).isNotEmpty) _time(t.createdAt),
      if (t.note != null) t.note!,
    ].join('  ·  ');

    return Pressable(
      onTap: onTap,
      semanticLabel: '${t.label}, ${_signed(t)}',
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
              child: Icon(rewardTxnIcon(t.type), size: 18, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.label,
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
                  _signed(t),
                  style: AtelierType.figure(
                    t.isCredit ? p.emerald : (t.isDebit ? p.ink : p.muted),
                    size: 14.5,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Balance ${rewardPointsCount(t.balanceAfter)}',
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

/// One movement with its note, copyable references and a shortcut to the
/// linked order.
Future<void> showRewardTransactionSheet(
  BuildContext context,
  RewardTransaction t,
) {
  return showAtelierSheet<void>(
    context: context,
    title: t.label,
    subtitle: [
      maisonDayLabel(t.createdAt),
      _time(t.createdAt),
    ].where((e) => e.isNotEmpty).join(' · '),
    builder: (sheetContext) {
      final p = sheetContext.atelier;
      final orderId = t.orderId;
      final refs = <(String, String)>[
        ('Transaction ID', t.id),
        if (orderId != null) ('Order ID', orderId),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Reveal(
            child: Text(
              _signed(t),
              style: AtelierType.display(
                t.isCredit ? p.emerald : (t.isDebit ? p.ink : p.muted),
                size: 42,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AtelierPill(
                label: t.isCredit
                    ? 'Points in'
                    : (t.isDebit ? 'Points out' : 'Points update'),
                tone: t.isCredit ? AtelierTone.emerald : AtelierTone.neutral,
                icon: rewardTxnIcon(t.type),
                dense: true,
              ),
              Text(
                'Balance after ${rewardPointsLabel(t.balanceAfter)}',
                style: AtelierType.caption(p.muted),
              ),
            ],
          ),
          if (t.amountInr != null && t.amountInr! > 0) ...[
            const SizedBox(height: 20),
            AtelierKeyValue(label: 'Value', value: maisonInr(t.amountInr!)),
          ],
          if (t.note != null) ...[
            const SizedBox(height: 20),
            AtelierKeyValue(label: 'Note', value: t.note!),
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
          if (orderId != null) ...[
            const SizedBox(height: 12),
            AtelierButton(
              label: 'Open order ${maisonShortId(orderId)}',
              icon: Icons.local_mall_outlined,
              variant: AtelierButtonVariant.secondary,
              expand: true,
              onPressed: () {
                Navigator.of(sheetContext).pop();
                context.openRoute(AppRouteNames.buyerOrderDetailPath(orderId));
              },
            ),
          ],
        ],
      );
    },
  );
}
