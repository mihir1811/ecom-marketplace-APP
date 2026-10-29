import '../../../../core/error/result.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../product_offer/data/repositories/product_offer_repository_impl.dart';
import '../../../product_offer/domain/models/product_offer.dart';
import '../../domain/agent_card.dart';
import '../../domain/agent_effect.dart';
import '../../domain/agent_session.dart';
import '../../domain/agent_tool.dart';
import '../../domain/tool_result.dart';
import '../account/account_tool.dart';

/// Price offers buyers sent the seller. Read-only: accepting or declining
/// stays on the Offers screen.
class SellerOffersTool extends AccountTool {
  const SellerOffersTool();

  static const _statuses = {
    'pending': ProductOfferStatus.pending,
    'accepted': ProductOfferStatus.accepted,
    'rejected': ProductOfferStatus.rejected,
    'expired': ProductOfferStatus.expired,
  };

  @override
  String get name => 'seller_offers';

  @override
  AgentToolAccess get access => AgentToolAccess.seller;

  @override
  String get description =>
      'Seller only: price offers buyers made on the user\'s stones. '
      'Default pending. Cannot accept or decline — open the screen for that.';

  @override
  Map<String, Object?> get parameters => {
    'type': 'object',
    'properties': {
      'status': {
        'type': 'string',
        'enum': [..._statuses.keys, 'any'],
      },
      'mode': AnswerMode.schema,
    },
    'additionalProperties': false,
  };

  @override
  String progressLabel(Map<String, Object?> args) => 'Checking offers…';

  @override
  Future<ToolResult> execute(
    Map<String, Object?> args,
    AgentToolContext context,
  ) async {
    final raw = args['status']?.toString() ?? 'pending';
    final status = _statuses[raw];
    final result = await context.ref
        .read(productOfferRepositoryProvider)
        .listSeller(
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

    final word = status?.label.toLowerCase() ?? '';
    final total = page.total > 0 ? page.total : page.items.length;
    final route = status == null
        ? AppRouteNames.sellerOffers
        : '${AppRouteNames.sellerOffers}?status=${status.apiValue}';
    final open = AnswerMode.parse(args['mode']) == AnswerMode.open;
    return ToolSuccess(
      summary: total == 0
          ? 'No ${word.isEmpty ? '' : '$word '}offers right now.'
          : '${AccountTool.plural(total, '${word.isEmpty ? '' : '$word '}offer')}.',
      completesTurn: true,
      effects: open ? [OpenPageEffect(route)] : const [],
      cards: [
        if (page.items.isNotEmpty)
          AgentListCard(
            rows: [
              for (final o in page.items.take(AccountTool.maxRows))
                AgentListRow(
                  title: o.productLabel ?? o.stockNumber ?? 'Stone',
                  subtitle: [
                    o.status.label,
                    if (o.listPrice != null)
                      'listed ${AppCurrency.usd(o.listPrice!, decimals: 0)}',
                    AccountTool.shortDate(o.createdAt),
                  ].where((s) => s.isNotEmpty).join(' · '),
                  trailing: AppCurrency.usd(o.amount, decimals: 0),
                  imageUrl: o.imageUrl,
                  route: route,
                ),
            ],
            moreCount: total - AccountTool.maxRows,
            action: AgentCardAction('Open Offers', route),
          ),
      ],
      data: {
        'total': total,
        'offers': [
          for (final o in page.items.take(AccountTool.maxModelRows))
            {
              'product': o.productLabel ?? o.stockNumber,
              'offer_usd': o.amount.round(),
              'list_usd': ?o.listPrice?.round(),
              'status': o.status.apiValue,
            },
        ],
      },
    );
  }
}
