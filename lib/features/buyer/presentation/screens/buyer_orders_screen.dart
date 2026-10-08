import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/gem3d/gem_mesh.dart';
import '../../../seller/presentation/atelier/atelier_components.dart';
import '../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import '../../application/buyer_orders_provider.dart';
import '../../domain/buyer_order_status.dart';
import '../../domain/models/buyer_order.dart';
import '../maison/maison_kit.dart';
import '../maison/maison_layout.dart';
import '../widgets/orders/buyer_order_card.dart';

/// Buyer orders (GET /payment/orders): headline figures, status buckets,
/// search and sort over the loaded pages, grouped by month.
class BuyerOrdersScreen extends ConsumerStatefulWidget {
  const BuyerOrdersScreen({super.key});

  @override
  ConsumerState<BuyerOrdersScreen> createState() => _BuyerOrdersScreenState();
}

class _BuyerOrdersScreenState extends ConsumerState<BuyerOrdersScreen> {
  final _search = TextEditingController();
  BuyerOrderFilter _filter = BuyerOrderFilter.all;
  BuyerOrderSort _sort = BuyerOrderSort.newest;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() =>
      ref.read(buyerOrdersProvider.notifier).loadInitial();

  void _loadMore() => ref.read(buyerOrdersProvider.notifier).loadMore();

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis == Axis.vertical &&
        n.metrics.maxScrollExtent > 0 &&
        n.metrics.pixels >= n.metrics.maxScrollExtent - 320) {
      _loadMore();
    }
    return false;
  }

  void _setFilter(BuyerOrderFilter f) => setState(() => _filter = f);

  void _clearFilters() {
    _search.clear();
    setState(() => _filter = BuyerOrderFilter.all);
  }

  Future<void> _pickSort() async {
    final sort = await showAtelierOptions<BuyerOrderSort>(
      context: context,
      title: 'Sort orders',
      options: [
        for (final s in BuyerOrderSort.values)
          AtelierOption(
            value: s,
            label: s.label,
            selected: s == _sort,
            icon: switch (s) {
              BuyerOrderSort.newest => Icons.south_rounded,
              BuyerOrderSort.oldest => Icons.north_rounded,
              BuyerOrderSort.highest => Icons.trending_up_rounded,
              BuyerOrderSort.lowest => Icons.trending_down_rounded,
            },
          ),
      ],
    );
    if (sort != null && mounted) setState(() => _sort = sort);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final state = ref.watch(buyerOrdersProvider);
    // Only orders whose payment went through; pending or failed checkouts
    // are not shown.
    final orders = successfulBuyerOrders(state.orders);
    // A page can be all unpaid checkouts: keep loading until there is a
    // screenful of paid orders or nothing left.
    if (orders.length < 8 &&
        state.hasMore &&
        !state.isLoading &&
        !state.isLoadingMore &&
        state.errorMessage == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadMore();
      });
    }
    final counts = buyerOrderCounts(orders);
    final visible = buyerOrderView(
      orders,
      filter: _filter,
      query: _search.text,
      sort: _sort,
    );
    final gutter = AtelierSpace.gutter(MediaQuery.sizeOf(context).width);
    final awaiting = orders
        .where((o) => buyerOrderStage(o) == BuyerOrderStage.awaitingSeller)
        .length;
    final liveValue = orders
        .where((o) {
          final s = buyerOrderStage(o);
          return s == BuyerOrderStage.awaitingSeller ||
              s == BuyerOrderStage.confirmed;
        })
        .fold<double>(0, (sum, o) => sum + o.amountUsd);
    final filtered =
        _filter != BuyerOrderFilter.all || _search.text.trim().isNotEmpty;

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
                          overline: 'My account',
                          title: context.tr(AccountCommerceL10n.orders),
                          subtitle:
                              'Every piece you’ve acquired, from checkout '
                              'to your door.',
                          cut: GemCut.oval,
                        ),
                        const SizedBox(height: 22),
                        Reveal(
                          index: 3,
                          child: MaisonStatStrip(
                            stats: [
                              MaisonStat(
                                label: 'In progress',
                                value: '${counts[BuyerOrderFilter.active]}',
                                caption: awaiting > 0
                                    ? '$awaiting awaiting seller'
                                    : 'On their way',
                                tone: AtelierTone.sapphire,
                                pulse: awaiting > 0,
                                selected: _filter == BuyerOrderFilter.active,
                                onTap: () => _setFilter(
                                  _filter == BuyerOrderFilter.active
                                      ? BuyerOrderFilter.all
                                      : BuyerOrderFilter.active,
                                ),
                              ),
                              MaisonStat(
                                label: 'Attention',
                                value: '${counts[BuyerOrderFilter.issues]}',
                                caption: 'Rejected by seller',
                                tone: counts[BuyerOrderFilter.issues]! > 0
                                    ? AtelierTone.ruby
                                    : null,
                                selected: _filter == BuyerOrderFilter.issues,
                                onTap: () => _setFilter(
                                  _filter == BuyerOrderFilter.issues
                                      ? BuyerOrderFilter.all
                                      : BuyerOrderFilter.issues,
                                ),
                              ),
                              MaisonStat(
                                label: 'Active value',
                                value: maisonUsd(liveValue),
                                caption: state.hasMore
                                    ? 'Loaded orders'
                                    : 'Paid & in progress',
                              ),
                            ],
                          ),
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
                    AtelierSegmented<BuyerOrderFilter>(
                      dense: true,
                      segments: [
                        for (final f in BuyerOrderFilter.values)
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
                      hint: 'Search piece, seller or order no.',
                      onChanged: (_) => setState(() {}),
                      sortLabel: _sort.label,
                      sortActive: _sort != BuyerOrderSort.newest,
                      onSort: _pickSort,
                    ),
                  ],
                ),
              ),
              MaisonRefreshHairline(
                visible: state.isLoading && orders.isNotEmpty,
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(gutter, 6, gutter, 32),
                sliver: _OrdersBody(
                  state: state,
                  orders: orders,
                  visible: visible,
                  filtered: filtered,
                  filterLabel: _filter.label,
                  onRetry: _refresh,
                  onLoadMore: _loadMore,
                  onClearFilters: _clearFilters,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrdersBody extends StatelessWidget {
  const _OrdersBody({
    required this.state,
    required this.orders,
    required this.visible,
    required this.filtered,
    required this.filterLabel,
    required this.onRetry,
    required this.onLoadMore,
    required this.onClearFilters,
  });

  final BuyerOrdersListState state;

  /// Paid orders loaded so far.
  final List<BuyerOrder> orders;
  final List<BuyerOrder> visible;
  final bool filtered;
  final String filterLabel;
  final Future<void> Function() onRetry;
  final VoidCallback onLoadMore;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty &&
        (state.isLoading ||
            state.isLoadingMore ||
            (state.hasMore && state.errorMessage == null))) {
      return const SliverToBoxAdapter(
        child: MaisonCentered(
          child: AtelierSkeletonList(count: 4, height: 168),
        ),
      );
    }
    if (state.errorMessage != null && orders.isEmpty) {
      return SliverToBoxAdapter(
        child: AtelierErrorState(
          title: 'Orders unavailable',
          message: state.errorMessage!,
          onRetry: onRetry,
        ),
      );
    }
    if (orders.isEmpty) {
      return SliverToBoxAdapter(
        child: MaisonEmptyState(
          cut: GemCut.cushion,
          title: 'Your first piece awaits',
          message: context.tr(AccountCommerceL10n.noOrders),
          actionLabel: 'Explore the collection',
          actionIcon: Icons.arrow_forward_rounded,
          onAction: () => context.switchToRoute(AppRouteNames.home),
        ),
      );
    }
    if (visible.isEmpty) {
      return SliverToBoxAdapter(
        child: AtelierEmptyState(
          icon: Icons.filter_alt_off_outlined,
          title: 'No matches',
          message: filtered
              ? 'No ${filterLabel.toLowerCase()} orders match your search.'
              : 'Nothing to show here yet.',
          actionLabel: 'Clear filters',
          onAction: onClearFilters,
        ),
      );
    }

    final rows = <Widget>[];
    String? month;
    var i = 0;
    for (final order in visible) {
      final label = maisonMonthLabel(order.createdAt);
      if (label != month) {
        rows.add(MaisonGroupLabel(label: label));
        month = label;
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Reveal(
            key: ValueKey(order.id),
            index: i < 8 ? i : 0,
            child: BuyerOrderCard(
              order: order,
              onTap: () => context.openRoute(
                AppRouteNames.buyerOrderDetailPath(order.id),
              ),
            ),
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
        onLoadMore: onLoadMore,
        endLabel: 'That’s every order',
      ),
    );

    return SliverList.builder(
      itemCount: rows.length,
      itemBuilder: (context, index) => MaisonCentered(child: rows[index]),
    );
  }
}
