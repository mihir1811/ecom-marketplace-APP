import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/gem3d/gem_mesh.dart';
import '../../../refunds/application/refund_providers.dart';
import '../../../refunds/domain/models/refund_request.dart';
import '../../../seller/presentation/atelier/atelier_components.dart';
import '../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import '../maison/maison_kit.dart';
import '../maison/maison_layout.dart';
import '../widgets/refunds/buyer_refund_card.dart';

enum _RefundFilter {
  all('All', null),
  review('In review', RefundStatus.pending),
  approved('Approved', RefundStatus.accepted),
  declined('Declined', RefundStatus.rejected),
  withdrawn('Withdrawn', RefundStatus.cancelled);

  const _RefundFilter(this.label, this.status);
  final String label;
  final RefundStatus? status;

  bool matches(RefundRequest r) => status == null || r.status == status;
}

enum _RefundSort {
  newest('Newest first'),
  oldest('Oldest first'),
  highest('Highest amount'),
  lowest('Lowest amount');

  const _RefundSort(this.label);
  final String label;
}

/// Buyer refund requests (GET /refunds/mine): what is in review, what came
/// back, filters by outcome, search and withdraw.
class BuyerRefundsScreen extends ConsumerStatefulWidget {
  const BuyerRefundsScreen({super.key});

  @override
  ConsumerState<BuyerRefundsScreen> createState() => _BuyerRefundsScreenState();
}

class _BuyerRefundsScreenState extends ConsumerState<BuyerRefundsScreen> {
  final _search = TextEditingController();
  _RefundFilter _filter = _RefundFilter.all;
  _RefundSort _sort = _RefundSort.newest;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() =>
      ref.read(buyerRefundListProvider.notifier).refresh();

  void _loadMore() => ref.read(buyerRefundListProvider.notifier).loadMore();

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis == Axis.vertical &&
        n.metrics.maxScrollExtent > 0 &&
        n.metrics.pixels >= n.metrics.maxScrollExtent - 320) {
      _loadMore();
    }
    return false;
  }

  void _setFilter(_RefundFilter f) => setState(() => _filter = f);

  Future<void> _pickSort() async {
    final sort = await showAtelierOptions<_RefundSort>(
      context: context,
      title: 'Sort refunds',
      options: [
        for (final s in _RefundSort.values)
          AtelierOption(
            value: s,
            label: s.label,
            selected: s == _sort,
            icon: switch (s) {
              _RefundSort.newest => Icons.south_rounded,
              _RefundSort.oldest => Icons.north_rounded,
              _RefundSort.highest => Icons.trending_up_rounded,
              _RefundSort.lowest => Icons.trending_down_rounded,
            },
          ),
      ],
    );
    if (sort != null && mounted) setState(() => _sort = sort);
  }

  List<RefundRequest> _view(List<RefundRequest> items) {
    final q = _search.text.trim().toLowerCase();
    final out = [
      for (final r in items)
        if (_filter.matches(r) &&
            (q.isEmpty ||
                r.sellerLabel.toLowerCase().contains(q) ||
                r.orderId.toLowerCase().contains(q) ||
                r.reason.toLowerCase().contains(q)))
          r,
    ];
    int byDate(RefundRequest a, RefundRequest b) =>
        (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0));
    switch (_sort) {
      case _RefundSort.newest:
        out.sort((a, b) => byDate(b, a));
      case _RefundSort.oldest:
        out.sort(byDate);
      case _RefundSort.highest:
        out.sort((a, b) => b.amountUsd.compareTo(a.amountUsd));
      case _RefundSort.lowest:
        out.sort((a, b) => a.amountUsd.compareTo(b.amountUsd));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final state = ref.watch(buyerRefundListProvider);
    final items = state.items;
    final counts = {
      for (final f in _RefundFilter.values) f: items.where(f.matches).length,
    };
    final visible = _view(items);
    final gutter = AtelierSpace.gutter(MediaQuery.sizeOf(context).width);

    return MaisonLayout(
      child: RefreshIndicator(
        color: p.gold,
        backgroundColor: p.surface,
        onRefresh: _refresh,
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 18),
                sliver: SliverToBoxAdapter(
                  child: MaisonCentered(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MaisonHeader(
                          title: context.tr(AccountCommerceL10n.refunds),
                          cut: GemCut.pear,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              MaisonPinnedBar(
                height: 124,
                gutter: gutter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AtelierSegmented<_RefundFilter>(
                      dense: true,
                      segments: [
                        for (final f in _RefundFilter.values)
                          AtelierSegment(
                            value: f,
                            label: f.label,
                            count: counts[f],
                          ),
                      ],
                      selected: _filter,
                      onChanged: _setFilter,
                    ),
                    const SizedBox(height: 12),
                    MaisonSearchRow(
                      controller: _search,
                      hint: 'Search seller, order or reason',
                      onChanged: (_) => setState(() {}),
                      sortLabel: _sort.label,
                      sortActive: _sort != _RefundSort.newest,
                      onSort: _pickSort,
                    ),
                  ],
                ),
              ),
              MaisonRefreshHairline(
                visible: state.isLoading && items.isNotEmpty,
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(gutter, 6, gutter, 32),
                sliver: _body(context, state, visible),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    RefundListState state,
    List<RefundRequest> visible,
  ) {
    if (state.isLoading && state.items.isEmpty) {
      return const SliverToBoxAdapter(
        child: MaisonCentered(
          child: AtelierSkeletonList(count: 3, height: 240),
        ),
      );
    }
    if (state.errorMessage != null && state.items.isEmpty) {
      return SliverToBoxAdapter(
        child: AtelierErrorState(
          title: 'Refunds unavailable',
          message: state.errorMessage!,
          onRetry: _refresh,
        ),
      );
    }
    if (state.items.isEmpty) {
      return SliverToBoxAdapter(
        child: MaisonEmptyState(
          cut: GemCut.pear,
          title: 'No refund requests',
          message:
              '${context.tr(AccountCommerceL10n.noRefunds)} Requests start '
              'from an order, before it is out for delivery.',
          actionLabel: 'Go to orders',
          actionIcon: Icons.local_mall_outlined,
          onAction: () => context.switchToRoute(AppRouteNames.buyerOrders),
        ),
      );
    }
    if (visible.isEmpty) {
      return SliverToBoxAdapter(
        child: AtelierEmptyState(
          icon: Icons.filter_alt_off_outlined,
          title: 'No matches',
          message:
              'No ${_filter == _RefundFilter.all ? '' : '${_filter.label.toLowerCase()} '}'
              'requests match your search.',
          actionLabel: 'Clear filters',
          onAction: () {
            _search.clear();
            setState(() => _filter = _RefundFilter.all);
          },
        ),
      );
    }

    final rows = <Widget>[];
    String? month;
    var i = 0;
    for (final refund in visible) {
      final label = maisonMonthLabel(refund.createdAt);
      if (label != month) {
        rows.add(MaisonGroupLabel(label: label));
        month = label;
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Reveal(
            key: ValueKey(refund.id),
            index: i < 8 ? i : 0,
            child: BuyerRefundCard(refund: refund),
          ),
        ),
      );
      i++;
    }
    rows.add(
      MaisonListFooter(
        loadingMore: state.isLoadingMore,
        hasMore: state.hasMore,
        errorMessage: state.errorMessage,
        onLoadMore: _loadMore,
        endLabel: 'That’s every request',
      ),
    );
    return SliverList.builder(
      itemCount: rows.length,
      itemBuilder: (context, index) => MaisonCentered(child: rows[index]),
    );
  }
}
