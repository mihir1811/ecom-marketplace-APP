import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/router/workspace_mode.dart';
import '../../../buyer/presentation/maison/maison_kit.dart';
import '../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import '../../application/wallet_provider.dart';
import '../widgets/wallet/wallet_top_up_sheet.dart';
import '../widgets/wallet/wallet_vault_card.dart';
import '../widgets/wallet/wallet_activity.dart';

/// Wallet shared by the buyer and seller shells: balance vault, Add funds
/// (Razorpay), money flow and the full ledger. Links (orders, refunds)
/// stay on the side the user is on.
class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletBodyState();
}

class _WalletBodyState extends ConsumerState<WalletScreen> {
  WalletLedgerFilter _filter = WalletLedgerFilter.all;

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(walletProvider.notifier).refresh(),
      ref.read(walletTransactionsProvider.notifier).loadInitial(),
    ]);
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis == Axis.vertical &&
        n.metrics.maxScrollExtent > 0 &&
        n.metrics.pixels >= n.metrics.maxScrollExtent - 280) {
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

    final seller = currentWorkspace(context) == AppWorkspace.seller;

    final Widget content = walletAsync.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      loading: () => const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SkeletonBox(height: 130, radius: AtelierRadius.lg),
          SizedBox(height: 20),
          AtelierSkeletonList(count: 4, height: 72),
        ],
      ),
      error: (error, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
            Reveal(
              index: 2,
              child: WalletVaultCard(
                wallet: wallet,
                label: seller ? 'Business wallet' : 'Private wallet',
                actions: [
                  WalletCardAction(
                    icon: Icons.add_rounded,
                    label: 'Add funds',
                    primary: true,
                    onTap: () => WalletTopUpSheet.show(context),
                  ),
                  WalletCardAction(
                    icon: seller
                        ? Icons.receipt_long_outlined
                        : Icons.replay_rounded,
                    label: context.tr(
                      seller
                          ? RemainingL10n.orders
                          : AccountCommerceL10n.refunds,
                    ),
                    onTap: () => context.switchToRoute(
                      seller
                          ? AppRouteNames.sellerOrders
                          : AppRouteNames.buyerRefunds,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AtelierSpace.s16),
            Reveal(index: 4, child: WalletFlow(transactions: txns.items)),
          ],
        );
        final ledger = WalletLedger(
          txns: txns,
          filter: _filter,
          onFilter: (f) => setState(() => _filter = f),
          onRetry: () =>
              ref.read(walletTransactionsProvider.notifier).loadInitial(),
          onLoadMore: () =>
              ref.read(walletTransactionsProvider.notifier).loadMore(),
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
          padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 40),
          child: MaisonCentered(maxWidth: 1200, child: content),
        ),
      ),
    );
  }
}
