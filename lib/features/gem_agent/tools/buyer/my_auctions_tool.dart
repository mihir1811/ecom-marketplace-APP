import '../../../../core/error/result.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../auction/data/repositories/auction_repository_impl.dart';
import '../../../auction/domain/models/auction_models.dart';
import '../../domain/agent_card.dart';
import '../../domain/agent_tool.dart';
import '../../domain/tool_result.dart';
import '../account/account_tool.dart';

/// The user's bidding: auctions they are in, won and lost.
class MyAuctionsTool extends AccountTool {
  const MyAuctionsTool();

  @override
  String get name => 'my_auctions';

  @override
  String get description =>
      'Auctions the user bid on as a buyer: participating, winning, won, '
      'lost. Cannot place bids.';

  @override
  Map<String, Object?> get parameters => const {
    'type': 'object',
    'properties': {
      'outcome': {
        'type': 'string',
        'enum': ['all', 'participating', 'won', 'lost'],
      },
    },
    'additionalProperties': false,
  };

  @override
  String progressLabel(Map<String, Object?> args) => 'Checking your bids…';

  @override
  Future<ToolResult> execute(
    Map<String, Object?> args,
    AgentToolContext context,
  ) async {
    final outcome = switch (args['outcome']?.toString()) {
      final String o when ['participating', 'won', 'lost'].contains(o) => o,
      _ => 'all',
    };
    final result = await context.ref
        .read(auctionRepositoryProvider)
        .myActivity(limit: 10, outcome: outcome);
    final AuctionPage page;
    switch (result) {
      case ResultFailure(:final failure):
        return AccountTool.failureOf(failure);
      case Success(:final value):
        page = value;
    }
    final s = page.summary;
    final route = outcome == 'won'
        ? AppRouteNames.auctionWins
        : AppRouteNames.auctionActivity;

    return ToolSuccess(
      summary: s == null
          ? (page.items.isEmpty
                ? 'You have not bid on any auctions yet.'
                : '${AccountTool.plural(page.total, 'auction')} in your activity.')
          : 'You are in ${s.participating} live '
                '${s.participating == 1 ? 'auction' : 'auctions'}, won ${s.won} '
                'and lost ${s.lost}.',
      completesTurn: true,
      cards: [
        if (s != null)
          AgentStatsCard(
            stats: [
              AgentStat('Bidding now', '${s.participating}'),
              AgentStat('Won', '${s.won}'),
              AgentStat('Lost', '${s.lost}'),
            ],
          ),
        if (page.items.isNotEmpty)
          AgentListCard(
            rows: [
              for (final a in page.items.take(AccountTool.maxRows))
                AgentListRow(
                  title: a.title,
                  subtitle: [
                    a.phaseLabel,
                    if (a.myHighestBid != null)
                      'your bid ${AppCurrency.usd(a.myHighestBid!, decimals: 0)}',
                  ].join(' · '),
                  trailing: AppCurrency.usd(a.currentBid, decimals: 0),
                  imageUrl: a.imageUrl,
                  route: AppRouteNames.auctionDetailPath(a.id),
                ),
            ],
            moreCount: page.items.length - AccountTool.maxRows,
            action: AgentCardAction('My auctions', route),
          ),
      ],
      data: {
        if (s != null) ...{
          'participating': s.participating,
          'won': s.won,
          'lost': s.lost,
        },
        'auctions': [
          for (final a in page.items.take(AccountTool.maxModelRows))
            {
              'title': a.title,
              'phase': a.phaseLabel,
              'current_bid_usd': a.currentBid.round(),
              'my_bid_usd': ?a.myHighestBid?.round(),
            },
        ],
      },
    );
  }
}
