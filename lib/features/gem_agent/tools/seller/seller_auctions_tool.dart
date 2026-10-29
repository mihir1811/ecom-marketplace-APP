import '../../../../core/error/result.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../auction/data/repositories/auction_repository_impl.dart';
import '../../../auction/domain/models/auction_models.dart';
import '../../domain/agent_card.dart';
import '../../domain/agent_effect.dart';
import '../../domain/agent_session.dart';
import '../../domain/agent_tool.dart';
import '../../domain/tool_result.dart';
import '../account/account_tool.dart';

/// The seller's timed auctions: live / upcoming / ended / sold counts, total
/// bids, lots waiting on the seller's decision, and the live lots' bids.
class SellerAuctionsTool extends AccountTool {
  const SellerAuctionsTool();

  @override
  String get name => 'seller_auctions';

  @override
  AgentToolAccess get access => AgentToolAccess.seller;

  @override
  String get description =>
      'Seller only: the user\'s own auctions — live, upcoming, ended, sold, '
      'bids, and lots awaiting their decision.';

  @override
  Map<String, Object?> get parameters => const {
    'type': 'object',
    'properties': {
      'status': {
        'type': 'string',
        'enum': ['active', 'upcoming', 'ended', 'decision', 'any'],
        'description': 'decision = ended lots waiting for the seller.',
      },
      'mode': AnswerMode.schema,
    },
    'additionalProperties': false,
  };

  @override
  String progressLabel(Map<String, Object?> args) => 'Checking your auctions…';

  @override
  Future<ToolResult> execute(
    Map<String, Object?> args,
    AgentToolContext context,
  ) async {
    final repo = context.ref.read(auctionRepositoryProvider);
    final raw = args['status']?.toString();
    final status = raw == 'any' ? null : raw;
    final (standingResult, lotsResult) = await (
      repo.sellerStanding(),
      repo.sellerAuctions(
        limit: AccountTool.maxRows,
        status: status == 'decision' ? null : (status ?? 'active'),
      ),
    ).wait;
    final SellerAuctionStanding standing;
    switch (standingResult) {
      case ResultFailure(:final failure):
        return AccountTool.failureOf(failure);
      case Success(:final value):
        standing = value;
    }
    final lots = switch (lotsResult) {
      Success(:final value) => value.items,
      ResultFailure() => const <AuctionListing>[],
    };
    final shown = status == 'decision' ? standing.awaitingDecision : lots;

    final summary = standing.total == 0
        ? 'You have no auctions yet.'
        : '${standing.active} live, ${standing.upcoming} upcoming, '
              '${standing.sold} sold · ${AccountTool.plural(standing.bids, 'bid')}'
              '${standing.needsDecision > 0 ? ' · ${standing.needsDecision} waiting for your decision' : ''}.';
    final tab = status ?? (standing.needsDecision > 0 ? 'decision' : 'active');
    final route = '${AppRouteNames.sellerAuctions}?tab=$tab';
    final open = AnswerMode.parse(args['mode']) == AnswerMode.open;

    return ToolSuccess(
      summary: summary,
      completesTurn: true,
      effects: open ? [OpenPageEffect(route)] : const [],
      cards: [
        if (standing.total > 0)
          AgentStatsCard(
            stats: [
              AgentStat('Live', '${standing.active}'),
              AgentStat('Upcoming', '${standing.upcoming}'),
              AgentStat('Ended', '${standing.ended}'),
              AgentStat('Sold', '${standing.sold}'),
              AgentStat('Bids', '${standing.bids}'),
              if (standing.needsDecision > 0)
                AgentStat('Need decision', '${standing.needsDecision}'),
            ],
          ),
        if (shown.isNotEmpty)
          AgentListCard(
            title: status == 'decision' ? 'Waiting for you' : 'Lots',
            rows: [
              for (final lot in shown.take(AccountTool.maxRows))
                AgentListRow(
                  title: lot.title,
                  subtitle: [
                    lot.phaseLabel,
                    AccountTool.plural(lot.bids.length, 'bid'),
                  ].join(' · '),
                  trailing: AppCurrency.usd(lot.currentBid, decimals: 0),
                  imageUrl: lot.imageUrl,
                  route: route,
                ),
            ],
            moreCount: shown.length - AccountTool.maxRows,
            action: AgentCardAction('Open Auctions', route),
          ),
      ],
      data: {
        'active': standing.active,
        'upcoming': standing.upcoming,
        'ended': standing.ended,
        'sold': standing.sold,
        'bids': standing.bids,
        'awaiting_decision': standing.needsDecision,
        'lots': [
          for (final lot in shown.take(AccountTool.maxModelRows))
            {
              'title': lot.title,
              'phase': lot.phaseLabel,
              'current_bid_usd': lot.currentBid.round(),
              'bids': lot.bids.length,
            },
        ],
      },
    );
  }
}
