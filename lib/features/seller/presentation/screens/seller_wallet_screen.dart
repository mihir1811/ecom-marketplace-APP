import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../wallet/application/wallet_provider.dart';
import '../atelier/atelier_components.dart';
import '../atelier/atelier_feedback.dart';
import '../atelier/atelier_motion.dart';
import '../atelier/atelier_theme.dart';
import '../widgets/wallet/seller_wallet_widgets.dart';

enum _LedgerFilter { all, credits, debits }

/// Seller workspace wallet: balance, Razorpay top-up and the full ledger.
class SellerWalletScreen extends ConsumerStatefulWidget {
  const SellerWalletScreen({super.key});

  @override
  ConsumerState<SellerWalletScreen> createState() => _SellerWalletScreenState();
}

class _SellerWalletScreenState extends ConsumerState<SellerWalletScreen> {
  _LedgerFilter _filter = _LedgerFilter.all;

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(walletProvider.notifier).refresh(),
      ref.read(walletTransactionsProvider.notifier).loadInitial(),
    ]);
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis == Axis.vertical &&
        n.metrics.pixels >= n.metrics.maxScrollExtent - 240) {
      ref.read(walletTransactionsProvider.notifier).loadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final walletAsync = ref.watch(walletProvider);
    final txns = ref.watch(walletTransactionsProvider);
    final width = MediaQuery.sizeOf(context).width;
    final gutter = AtelierSpace.gutter(width);
    final wide = width >= 1000;

    return RefreshIndicator(
      color: p.gold,
      backgroundColor: p.surface,
      onRefresh: _refresh,
      child: walletAsync.when(
        skipLoadingOnRefresh: true,
        skipLoadingOnReload: true,
        loading: () => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 32),
          children: const [
            AspectRatio(
              aspectRatio: 1.62,
              child: SkeletonBox(
                height: double.infinity,
                radius: AtelierRadius.xl,
              ),
            ),
            SizedBox(height: 20),
            AtelierSkeletonList(count: 4, height: 72),
          ],
        ),
        error: (error, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 32),
          children: [
            AtelierErrorState(
              title: 'Wallet unavailable',
              message: error is Failure
                  ? error.message
                  : context.tr(RemainingL10n.walletLoadError),
              onRetry: _refresh,
            ),
          ],
        ),
        data: (wallet) {
          final summary = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Reveal(child: WalletBalanceHero(wallet: wallet)),
              const SizedBox(height: AtelierSpace.s20),
              Reveal(
                index: 1,
                child: Row(
                  children: [
                    Expanded(
                      child: AtelierButton(
                        label: context.tr(RemainingL10n.topUp),
                        icon: Icons.add_rounded,
                        variant: AtelierButtonVariant.gold,
                        onPressed: () => SellerTopUpSheet.show(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    AtelierButton(
                      label: context.tr(RemainingL10n.refresh),
                      icon: Icons.refresh_rounded,
                      variant: AtelierButtonVariant.secondary,
                      onPressed: _refresh,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AtelierSpace.s20),
              Reveal(
                index: 2,
                child: WalletFlowSummary(transactions: txns.items),
              ),
            ],
          );

          final ledger = _Ledger(
            txns: txns,
            filter: _filter,
            onFilter: (f) => setState(() => _filter = f),
            onRetry: () =>
                ref.read(walletTransactionsProvider.notifier).loadInitial(),
            onRetryMore: () =>
                ref.read(walletTransactionsProvider.notifier).loadMore(),
          );

          return NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 440, child: summary),
                            const SizedBox(width: AtelierSpace.s32),
                            Expanded(child: ledger),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            summary,
                            const SizedBox(height: AtelierSpace.s32),
                            ledger,
                          ],
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Ledger extends StatelessWidget {
  const _Ledger({
    required this.txns,
    required this.filter,
    required this.onFilter,
    required this.onRetry,
    required this.onRetryMore,
  });

  final WalletTransactionsState txns;
  final _LedgerFilter filter;
  final ValueChanged<_LedgerFilter> onFilter;
  final VoidCallback onRetry;
  final VoidCallback onRetryMore;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final visible = [
      for (final t in txns.items)
        if (filter == _LedgerFilter.all ||
            (filter == _LedgerFilter.credits) == t.isCredit)
          t,
    ];
    final credits = txns.items.where((t) => t.isCredit).length;

    final rows = <Widget>[];
    String? lastDay;
    var i = 0;
    for (final t in visible) {
      final day = walletDayLabel(t.createdAt);
      if (day != lastDay) {
        rows.add(
          Padding(
            padding: EdgeInsets.only(top: lastDay == null ? 0 : 18, bottom: 8),
            child: Text(
              day.toUpperCase(),
              style: AtelierType.overline(p.muted),
            ),
          ),
        );
        lastDay = day;
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Reveal(
            key: ValueKey(t.id),
            index: i < 10 ? i : 0,
            child: WalletLedgerRow(
              transaction: t,
              onTap: () => showWalletTransactionSheet(context, t),
            ),
          ),
        ),
      );
      i++;
    }

    Widget body;
    if (txns.isLoading && txns.items.isEmpty) {
      body = const AtelierSkeletonList(count: 5, height: 70);
    } else if (txns.items.isEmpty && txns.errorMessage != null) {
      body = AtelierErrorState(
        compact: true,
        title: 'Transactions unavailable',
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
            : 'No ${filter == _LedgerFilter.credits ? 'credits' : 'debits'} '
                  'in the loaded transactions.',
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...rows,
          if (txns.isLoadingMore)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                    color: p.gold,
                  ),
                ),
              ),
            )
          else if (txns.errorMessage != null)
            AtelierNotice(
              text: txns.errorMessage!,
              tone: AtelierTone.ruby,
              icon: Icons.error_outline_rounded,
              actionLabel: context.tr(RemainingL10n.retry),
              onAction: onRetryMore,
            )
          else if (txns.hasMore)
            Center(
              child: AtelierButton(
                label: context.tr(RemainingL10n.loadMore),
                compact: true,
                variant: AtelierButtonVariant.ghost,
                onPressed: onRetryMore,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'You’ve reached the beginning',
                textAlign: TextAlign.center,
                style: AtelierType.caption(p.muted, size: 11.5),
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AtelierSectionHeader(
          overline: 'Ledger',
          title: context.tr(RemainingL10n.transactions),
        ),
        const SizedBox(height: 14),
        AtelierSegmented<_LedgerFilter>(
          expand: true,
          dense: true,
          segments: [
            AtelierSegment(
              value: _LedgerFilter.all,
              label: context.tr(RemainingL10n.all),
              count: txns.items.length,
            ),
            AtelierSegment(
              value: _LedgerFilter.credits,
              label: 'In',
              icon: Icons.south_west_rounded,
              count: credits,
            ),
            AtelierSegment(
              value: _LedgerFilter.debits,
              label: 'Out',
              icon: Icons.north_east_rounded,
              count: txns.items.length - credits,
            ),
          ],
          selected: filter,
          onChanged: onFilter,
        ),
        const SizedBox(height: 18),
        AnimatedSwitcher(
          duration: AtelierMotion.base,
          child: KeyedSubtree(key: ValueKey(filter), child: body),
        ),
      ],
    );
  }
}
