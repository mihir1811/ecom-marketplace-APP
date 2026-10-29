import '../../../../core/error/result.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../rewards/data/repositories/rewards_repository_impl.dart';
import '../../../wallet/data/repositories/wallet_repository_impl.dart';
import '../../../wallet/domain/models/wallet.dart';
import '../../domain/agent_card.dart';
import '../../domain/agent_tool.dart';
import '../../domain/tool_result.dart';
import '../account/account_tool.dart';

/// Wallet balance, recent wallet movements and reward points.
class MyWalletTool extends AccountTool {
  const MyWalletTool();

  @override
  String get name => 'my_wallet';

  @override
  String get description =>
      'The user\'s wallet balance, recent wallet transactions and reward '
      'points. Read-only; cannot top up or withdraw.';

  @override
  Map<String, Object?> get parameters => const {
    'type': 'object',
    'properties': {},
    'additionalProperties': false,
  };

  @override
  String progressLabel(Map<String, Object?> args) => 'Checking your wallet…';

  @override
  Future<ToolResult> execute(
    Map<String, Object?> args,
    AgentToolContext context,
  ) async {
    final (walletResult, rewardsResult) = await (
      context.ref.read(walletRepositoryProvider).getWallet(),
      context.ref.read(rewardsRepositoryProvider).getSummary(),
    ).wait;
    final Wallet wallet;
    switch (walletResult) {
      case ResultFailure(:final failure):
        return AccountTool.failureOf(failure);
      case Success(:final value):
        wallet = value;
    }
    // Rewards are optional (the programme may be off).
    final rewards = switch (rewardsResult) {
      Success(:final value) when value.settings.enabled => value,
      _ => null,
    };
    String money(num v) => wallet.currency.toUpperCase() == 'USD'
        ? AppCurrency.usd(v)
        : AppCurrency.inr(v);
    final route = context.session.onSellerSide
        ? AppRouteNames.sellerWallet
        : AppRouteNames.buyerWallet;
    final recent = wallet.recentTransactions.take(3).toList();

    return ToolSuccess(
      summary:
          'Wallet balance: ${money(wallet.balance)}.'
          '${rewards == null ? '' : ' Reward points: ${rewards.balance} (worth ${AppCurrency.inr(rewards.balanceValueInr, decimals: 0)}).'}',
      completesTurn: true,
      cards: [
        AgentStatsCard(
          stats: [
            AgentStat('Wallet', money(wallet.balance)),
            if (rewards != null)
              AgentStat(
                'Reward points',
                '${rewards.balance}',
                hint:
                    '≈ ${AppCurrency.inr(rewards.balanceValueInr, decimals: 0)}',
              ),
          ],
          action: AgentCardAction('Open wallet', route),
        ),
        if (recent.isNotEmpty)
          AgentListCard(
            title: 'Recent activity',
            rows: [
              for (final t in recent)
                AgentListRow(
                  title: t.typeLabel,
                  subtitle: AccountTool.shortDate(t.createdAt),
                  trailing: '${t.isCredit ? '+' : '−'}${money(t.amount.abs())}',
                  route: route,
                ),
            ],
          ),
      ],
      data: {
        'wallet_balance': wallet.balance,
        'currency': wallet.currency,
        'reward_points': ?rewards?.balance,
        'reward_value_inr': ?rewards?.balanceValueInr.round(),
      },
    );
  }
}
