import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../buyer/presentation/maison/maison_kit.dart';
import '../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import '../../application/rewards_provider.dart';
import '../widgets/rewards_balance_card.dart';
import '../widgets/rewards_ledger.dart';
import '../widgets/rewards_overview.dart';

/// Buyer reward points: balance, club progress, live rates and history.
class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> {
  RewardsLedgerFilter _filter = RewardsLedgerFilter.all;

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(rewardsProvider.notifier).refresh(),
      ref.read(rewardTransactionsProvider.notifier).loadInitial(),
    ]);
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis == Axis.vertical &&
        n.metrics.maxScrollExtent > 0 &&
        n.metrics.pixels >= n.metrics.maxScrollExtent - 280) {
      ref.read(rewardTransactionsProvider.notifier).loadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final rewardsAsync = ref.watch(rewardsProvider);
    final txns = ref.watch(rewardTransactionsProvider);
    final width = MediaQuery.sizeOf(context).width;
    final gutter = AtelierSpace.gutter(width);
    final wide = width >= 1000;

    final Widget content = rewardsAsync.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      loading: () => const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SkeletonBox(height: 150, radius: AtelierRadius.lg),
          SizedBox(height: 14),
          AtelierSkeletonList(count: 4, height: 72),
        ],
      ),
      error: (error, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtelierErrorState(
            title: 'Rewards unavailable',
            message: error is Failure
                ? error.message
                : 'Could not load your reward points.',
            onRetry: _refresh,
          ),
        ],
      ),
      data: (rewards) {
        final settings = rewards.settings;
        var index = 2;
        final summary = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Balance, club progress and rates in one compact card.
            Reveal(
              index: index++,
              child: RewardsBalanceCard(rewards: rewards),
            ),
            if (!settings.enabled) ...[
              const SizedBox(height: AtelierSpace.s12),
              Reveal(
                index: index++,
                child: RewardsPausedNotice(balance: rewards.balance),
              ),
            ],
          ],
        );
        final ledger = RewardsLedger(
          txns: txns,
          filter: _filter,
          onFilter: (f) => setState(() => _filter = f),
          onRetry: () =>
              ref.read(rewardTransactionsProvider.notifier).loadInitial(),
          onLoadMore: () =>
              ref.read(rewardTransactionsProvider.notifier).loadMore(),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 460, child: summary),
                  const SizedBox(width: AtelierSpace.s32),
                  Expanded(child: ledger),
                ],
              )
            else ...[
              summary,
              const SizedBox(height: AtelierSpace.s32),
              ledger,
            ],
          ],
        );
      },
    );

    return RefreshIndicator(
      color: p.gold,
      backgroundColor: p.surface,
      onRefresh: _refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(gutter, 6, gutter, 40),
          child: MaisonCentered(maxWidth: 1200, child: content),
        ),
      ),
    );
  }
}
