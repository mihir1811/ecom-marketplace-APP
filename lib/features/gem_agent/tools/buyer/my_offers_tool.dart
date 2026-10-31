import '../../../../core/error/result.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../product_offer/data/repositories/product_offer_repository_impl.dart';
import '../../../product_offer/domain/models/product_offer.dart';
import '../../domain/agent_card.dart';
import '../../domain/agent_tool.dart';
import '../../domain/tool_result.dart';
import '../account/account_tool.dart';

/// Offers the user made on stones. Accepted, unpaid offers get a direct
/// "Pay now" link — the one thing a buyer usually needs to act on.
class MyOffersTool extends AccountTool {
  const MyOffersTool();

  @override
  String get name => 'my_offers';

  @override
  String get description =>
      'Price offers the user made as a buyer and their status (pending, '
      'accepted, rejected, expired, countered), including seller '
      'counter-offers waiting for the user\'s answer.';

  @override
  Map<String, Object?> get parameters => const {
    'type': 'object',
    'properties': {
      'status': {
        'type': 'string',
        'enum': [
          'pending',
          'accepted',
          'rejected',
          'expired',
          'countered',
          'any',
        ],
      },
    },
    'additionalProperties': false,
  };

  @override
  String progressLabel(Map<String, Object?> args) => 'Checking your offers…';

  @override
  Future<ToolResult> execute(
    Map<String, Object?> args,
    AgentToolContext context,
  ) async {
    final raw = args['status']?.toString();
    final status = raw == null || raw == 'any'
        ? null
        : ProductOfferStatus.fromApi(raw);
    final result = await context.ref
        .read(productOfferRepositoryProvider)
        .listMineAll(
          page: 1,
          limit: 20,
          statusFilter: status?.apiValue,
          cancelToken: context.cancelToken,
        );
    final ProductOfferListPage page;
    switch (result) {
      case ResultFailure(:final failure):
        return AccountTool.failureOf(failure);
      case Success(:final value):
        page = value;
    }
    final offers = page.items;
    bool payable(ProductOffer o) =>
        o.status == ProductOfferStatus.accepted && o.paidAt == null;
    final toPay = offers.where(payable).toList();
    final toAnswer = offers.where((o) => o.isOpenCounter).toList();
    final word = status == null ? '' : '${status.label.toLowerCase()} ';
    final total = page.total > 0 ? page.total : offers.length;

    return ToolSuccess(
      summary: total == 0
          ? 'You have no ${word}offers.'
          : '${AccountTool.plural(total, '${word}offer')}.'
                '${toPay.isEmpty ? '' : ' ${toPay.length} accepted and waiting for your payment.'}'
                '${toAnswer.isEmpty ? '' : ' ${toAnswer.length} seller counter-offer${toAnswer.length == 1 ? '' : 's'} to answer.'}',
      completesTurn: true,
      cards: [
        if (offers.isNotEmpty)
          AgentListCard(
            rows: [
              for (final o in offers.take(AccountTool.maxRows))
                AgentListRow(
                  title: o.productLabel ?? o.stockNumber ?? 'Stone',
                  subtitle: payable(o)
                      ? 'Accepted · pay now'
                      : o.isOpenCounter
                      ? 'Seller countered · answer'
                      : o.status.label,
                  trailing: AppCurrency.usd(o.amount, decimals: 0),
                  imageUrl: o.imageUrl,
                  route: payable(o)
                      ? AppRouteNames.buyerOfferPayPath(o.id)
                      : o.isOpenCounter
                      ? AppRouteNames.buyerOfferCounterPath(o.id)
                      : AppRouteNames.buyerOffers,
                ),
            ],
            moreCount: total - AccountTool.maxRows,
            action: toPay.length == 1
                ? AgentCardAction(
                    'Pay accepted offer',
                    AppRouteNames.buyerOfferPayPath(toPay.single.id),
                  )
                : const AgentCardAction('My offers', AppRouteNames.buyerOffers),
          ),
      ],
      data: {
        'total': total,
        'awaiting_payment': toPay.length,
        'counter_offers_to_answer': toAnswer.length,
        'offers': [
          for (final o in offers.take(AccountTool.maxModelRows))
            {
              'product': o.productLabel ?? o.stockNumber,
              'offer_usd': o.amount.round(),
              'status': o.status.apiValue,
              'from_seller': o.fromSeller,
            },
        ],
      },
    );
  }
}
