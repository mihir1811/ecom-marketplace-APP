import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../buyer/presentation/maison/maison_kit.dart';
import '../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import '../../application/rewards_provider.dart';
import '../widgets/rewards_balance_card.dart';
import '../widgets/rewards_club_card.dart';
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
    final header = MaisonHeader(title: context.tr(CoreL10n.rewards));

    final Widget content = rewardsAsync.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 22),
          const AspectRatio(
            aspectRatio: 1.7,
            child: SkeletonBox(
              height: double.infinity,
              radius: AtelierRadius.xl,
            ),
          ),
          const SizedBox(height: 20),
          const SkeletonBox(height: 92, radius: AtelierRadius.lg),
          const SizedBox(height: 20),
          const AtelierSkeletonList(count: 4, height: 72),
        ],
      ),
      error: (error, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
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
            Reveal(
              index: index++,
              child: RewardsBalanceCard(rewards: rewards),
            ),
            const SizedBox(height: AtelierSpace.s20),
            if (!settings.enabled) ...[
              Reveal(
                index: index++,
                child: RewardsPausedNotice(balance: rewards.balance),
              ),
              const SizedBox(height: AtelierSpace.s20),
            ] else if (rewards.pointsToUnlock > 0) ...[
              Reveal(
                index: index++,
                child: RewardsUnlockCard(rewards: rewards),
              ),
              const SizedBox(height: AtelierSpace.s20),
            ],
            if (rewards.club.hasClubs) ...[
              Reveal(
                index: index++,
                child: RewardsClubCard(
                  status: rewards.club,
                  showBonus: settings.enabled,
                ),
              ),
              const SizedBox(height: AtelierSpace.s20),
            ],
            if (settings.enabled)
              Reveal(
                index: index++,
                child: RewardsRatesStrip(settings: settings),
              ),
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
            header,
            const SizedBox(height: 22),
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
          padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 40),
          child: MaisonCentered(maxWidth: 1200, child: content),
        ),
      ),
    );
  }
}
