import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/wallet_provider.dart';
import '../../domain/models/wallet.dart';
import '../widgets/wallet_balance_card.dart';
import '../widgets/wallet_top_up_sheet.dart';
import '../widgets/wallet_transaction_tile.dart';

/// Shared wallet body used by buyer and seller shells.
class WalletPanel extends ConsumerWidget {
  const WalletPanel({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    await Future.wait([
      ref.read(walletProvider.notifier).refresh(),
      ref.read(walletTransactionsProvider.notifier).loadInitial(),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);
    final txns = ref.watch(walletTransactionsProvider);

    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: walletAsync.when(
        loading: () => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(child: CircularProgressIndicator()),
          ],
        ),
        error: (error, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.s24),
          children: [
            Text(
              error is Failure ? error.message : 'Could not load your wallet.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s16),
            Center(
              child: FilledButton(
                onPressed: () => _refresh(ref),
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
        data: (wallet) => _WalletLoadedView(wallet: wallet, txns: txns),
      ),
    );
  }
}

class _WalletLoadedView extends ConsumerWidget {
  const _WalletLoadedView({required this.wallet, required this.txns});

  final Wallet wallet;
  final WalletTransactionsState txns;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extra = txns.hasMore ? 1 : 0;
    final loadingTxns = txns.isLoading && txns.items.isEmpty;
    final empty = txns.items.isEmpty && !txns.isLoading;
    final count = 3 +
        (loadingTxns || empty ? 1 : txns.items.length) +
        extra;

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
          ref.read(walletTransactionsProvider.notifier).loadMore();
        }
        return false;
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          AppSpacing.s8,
          AppSpacing.s16,
          AppSpacing.s32,
        ),
        itemCount: count,
        separatorBuilder: (context, index) {
          if (index < 2) return const SizedBox(height: AppSpacing.s16);
          return const SizedBox(height: AppSpacing.s12);
        },
        itemBuilder: (context, index) {
          if (index == 0) {
            return WalletBalanceCard(wallet: wallet);
          }
          if (index == 1) {
            return FilledButton.icon(
              onPressed: () => WalletTopUpSheet.show(context),
              icon: const Icon(Icons.add),
              label: const Text('Top up'),
            );
          }
          if (index == 2) {
            return Text(
              'Transactions',
              style: AppTypography.title.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary(context),
              ),
            );
          }
          if (loadingTxns) {
            return const Padding(
              padding: EdgeInsets.only(top: AppSpacing.s32),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (empty) {
            if (txns.errorMessage != null) {
              return Column(
                children: [
                  Text(txns.errorMessage!, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.s12),
                  FilledButton(
                    onPressed: () => ref
                        .read(walletTransactionsProvider.notifier)
                        .loadInitial(),
                    child: const Text('Retry'),
                  ),
                ],
              );
            }
            return Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s32),
              child: Text(
                'No wallet transactions yet',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: AppColors.textMuted(context),
                ),
              ),
            );
          }
          final txnIndex = index - 3;
          if (txnIndex >= txns.items.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.s16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return WalletTransactionTile(transaction: txns.items[txnIndex]);
        },
      ),
    );
  }
}
