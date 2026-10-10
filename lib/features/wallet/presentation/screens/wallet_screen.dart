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
    final header = MaisonHeader(title: context.tr(RemainingL10n.wallet));

    final Widget content = walletAsync.when(
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
          const AtelierSkeletonList(count: 4, height: 72),
        ],
      ),
      error: (error, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
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
              ),
            ),
            const SizedBox(height: AtelierSpace.s20),
            Reveal(
              index: 3,
              child: _QuickActions(
                onAddFunds: () => WalletTopUpSheet.show(context),
                seller: seller,
                onSecondary: () => context.switchToRoute(
                  seller
                      ? AppRouteNames.sellerOrders
                      : AppRouteNames.buyerRefunds,
                ),
              ),
            ),
            const SizedBox(height: AtelierSpace.s20),
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

/// Add funds · Refunds (buyer) or Orders (seller), as tiles under the
/// vault. Pull down to refresh the wallet.
class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.seller,
    required this.onAddFunds,
    required this.onSecondary,
  });

  final bool seller;
  final VoidCallback onAddFunds;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            icon: Icons.add_rounded,
            label: 'Add funds',
            primary: true,
            onTap: onAddFunds,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionTile(
            icon: seller ? Icons.receipt_long_outlined : Icons.replay_rounded,
            label: context.tr(
              seller ? RemainingL10n.orders : AccountCommerceL10n.refunds,
            ),
            onTap: onSecondary,
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      borderRadius: BorderRadius.circular(AtelierRadius.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(AtelierRadius.lg),
          border: Border.all(
            color: primary ? p.gold.withValues(alpha: 0.5) : p.hairline,
          ),
          boxShadow: p.softShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: primary ? p.goldGradient : null,
                color: primary ? null : p.sunken,
              ),
              child: Icon(icon, size: 21, color: primary ? p.onGold : p.ink),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AtelierType.label(primary ? p.ink : p.inkSoft, size: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}
