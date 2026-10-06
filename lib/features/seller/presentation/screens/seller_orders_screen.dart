import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../refunds/application/refund_providers.dart';
import '../../../refunds/domain/models/refund_request.dart';
import '../../application/seller_orders_provider.dart';
import '../../domain/models/seller_order.dart';
import '../../domain/seller_order_board.dart';
import '../atelier/atelier_components.dart';
import '../atelier/atelier_feedback.dart';
import '../atelier/atelier_motion.dart';
import '../atelier/atelier_theme.dart';
import '../widgets/seller_order_customer_block.dart';
import '../widgets/seller_order_decision.dart';
import '../widgets/seller_order_summary_card.dart';

/// Seller order management: orders and refund requests split into status
/// tabs, with local search, sort and filters.
///
/// Both lists are loaded once ([sellerOrdersProvider],
/// [sellerRefundListProvider]); tabs, sorting and filters work on that data
/// without new requests. Decisions and FCM order / refund pushes reload
/// them, so an order moves from Pending to Confirmed (or a refund to
/// Approved) as soon as the backend reports it.
class SellerOrdersScreen extends ConsumerStatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  ConsumerState<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends ConsumerState<SellerOrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchCtrl = TextEditingController();
  SellerOrderFilters _filters = const SellerOrderFilters();

  static const _categories = SellerOrderCategory.values;

  SellerOrderCategory get _category => _categories[_tabController.index];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) setState(() {});
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      ref.read(sellerOrdersProvider.notifier).refresh(),
      ref.read(sellerRefundListProvider.notifier).refresh(),
    ]);
  }

  void _goTo(SellerOrderCategory category) {
    _tabController.animateTo(
      category.index,
      duration: AtelierMotion.slow,
      curve: AtelierMotion.emphasized,
    );
    setState(() {});
  }

  Future<void> _pickSort() async {
    final sort = await showAtelierOptions<SellerOrderSort>(
      context: context,
      title: 'Sort by',
      options: [
        for (final s in SellerOrderSort.values)
          AtelierOption(
            value: s,
            label: s.label,
            selected: s == _filters.sort,
            icon: switch (s) {
              SellerOrderSort.newest => Icons.south_rounded,
              SellerOrderSort.oldest => Icons.north_rounded,
              SellerOrderSort.highestValue => Icons.trending_up_rounded,
              SellerOrderSort.lowestValue => Icons.trending_down_rounded,
              SellerOrderSort.customerName => Icons.sort_by_alpha_rounded,
            },
          ),
      ],
    );
    if (sort != null && mounted) {
      setState(() => _filters = _filters.copyWith(sort: sort));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final orders = ref.watch(sellerOrdersProvider);
    final refunds = ref.watch(sellerRefundListProvider);
    final board = SellerOrderBoard(
      orders: orders.items,
      refunds: refunds.items,
    );
    final counts = board.counts();
    final gutter = AtelierSpace.gutter(MediaQuery.sizeOf(context).width);
    final inRefunds = _category.isRefund;
    final group = _categories.where((c) => c.isRefund == inRefunds);
    final orderTotal = _categories
        .where((c) => !c.isRefund)
        .fold(0, (sum, c) => sum + counts[c]!);
    final refundTotal = _categories
        .where((c) => c.isRefund)
        .fold(0, (sum, c) => sum + counts[c]!);
    final refreshing =
        orders.isRefreshing || (refunds.isLoading && refunds.items.isNotEmpty);
    final filtersShown =
        _filters.activeCount > 0 || _filters.sort != SellerOrderSort.newest;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(gutter, 6, gutter, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Reveal(
                    child: AtelierSegmented<bool>(
                      expand: true,
                      segments: [
                        AtelierSegment(
                          value: false,
                          label: context.tr(RemainingL10n.orders),
                          icon: Icons.receipt_long_outlined,
                          count: orderTotal,
                        ),
                        AtelierSegment(
                          value: true,
                          label: 'Refunds',
                          icon: Icons.replay_rounded,
                          count: refundTotal,
                        ),
                      ],
                      selected: inRefunds,
                      onChanged: (refund) => _goTo(
                        refund
                            ? SellerOrderCategory.refundRequested
                            : SellerOrderCategory.pending,
                      ),
                    ),
                  ),
                  const SizedBox(height: AtelierSpace.s12),
                  Reveal(
                    index: 1,
                    child: AnimatedSwitcher(
                      duration: AtelierMotion.base,
                      child: AtelierSegmented<SellerOrderCategory>(
                        key: ValueKey(inRefunds),
                        dense: true,
                        segments: [
                          for (final c in group)
                            AtelierSegment(
                              value: c,
                              label: c.isRefund
                                  ? c.label.replaceFirst('Refund ', '')
                                  : c.label,
                              count: counts[c],
                            ),
                        ],
                        selected: _category,
                        onChanged: _goTo,
                      ),
                    ),
                  ),
                  const SizedBox(height: AtelierSpace.s12),
                  Reveal(
                    index: 2,
                    child: Row(
                      children: [
                        Expanded(
                          child: AtelierSearchField(
                            controller: _searchCtrl,
                            hint: 'Search order, customer or product',
                            onChanged: (q) => setState(
                              () => _filters = _filters.copyWith(search: q),
                            ),
                          ),
                        ),
                        const SizedBox(width: AtelierSpace.s8),
                        AtelierIconButton(
                          icon: Icons.swap_vert_rounded,
                          tooltip: 'Sort: ${_filters.sort.label}',
                          filled: true,
                          size: 44,
                          dot: _filters.sort != SellerOrderSort.newest,
                          onPressed: _pickSort,
                        ),
                        const SizedBox(width: AtelierSpace.s6),
                        AtelierIconButton(
                          icon: Icons.tune_rounded,
                          tooltip: 'Filters',
                          filled: true,
                          size: 44,
                          badgeCount: _filters.activeCount,
                          onPressed: () => _openFilters(board),
                        ),
                      ],
                    ),
                  ),
                  AnimatedSize(
                    duration: AtelierMotion.base,
                    curve: AtelierMotion.emphasized,
                    alignment: Alignment.topCenter,
                    child: filtersShown
                        ? Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: _ActiveFilters(
                              filters: _filters,
                              showRefundStates: !inRefunds,
                              onChanged: (f) => setState(() => _filters = f),
                            ),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                  const SizedBox(height: AtelierSpace.s8),
                ],
              ),
            ),
            AnimatedOpacity(
              duration: AtelierMotion.base,
              opacity: refreshing ? 1 : 0,
              child: LinearProgressIndicator(
                minHeight: 1.5,
                color: p.gold,
                backgroundColor: Colors.transparent,
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  for (final category in _categories)
                    _CategoryList(
                      category: category,
                      gutter: gutter,
                      entries: board.entries(category, _filters),
                      isLoading: category.isRefund
                          ? refunds.isLoading && refunds.items.isEmpty
                          : orders.isLoading && orders.items.isEmpty,
                      errorMessage: category.isRefund
                          ? refunds.errorMessage
                          : orders.errorMessage,
                      truncated: category.isRefund
                          ? refunds.hasMore
                          : orders.truncated,
                      filtered:
                          _filters.activeCount > 0 ||
                          _filters.search.trim().isNotEmpty,
                      onRefresh: _refreshAll,
                      onClearFilters: () {
                        _searchCtrl.clear();
                        setState(
                          () => _filters = SellerOrderFilters(
                            sort: _filters.sort,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFilters(SellerOrderBoard board) async {
    final result = await showAtelierSheet<SellerOrderFilters>(
      context: context,
      title: 'Filter orders',
      subtitle: 'Narrow the list by date, payment and refund state.',
      builder: (_) => _FilterSheet(
        initial: _filters,
        paymentStatuses: board.paymentStatuses(),
        showRefundStates: !_category.isRefund,
      ),
    );
    if (result != null && mounted) setState(() => _filters = result);
  }
}

String _fmtDay(DateTime d) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year}';
}

String _humanize(String raw) {
  final words = raw.trim().toLowerCase().replaceAll('_', ' ');
  return words.isEmpty ? raw : words[0].toUpperCase() + words.substring(1);
}

class _ActiveFilters extends StatelessWidget {
  const _ActiveFilters({
    required this.filters,
    required this.showRefundStates,
    required this.onChanged,
  });

  final SellerOrderFilters filters;
  final bool showRefundStates;
  final ValueChanged<SellerOrderFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final from = filters.from;
    final to = filters.to;
    final tags = <Widget>[
      if (filters.sort != SellerOrderSort.newest)
        AtelierFilterTag(
          label: filters.sort.label,
          onRemove: () =>
              onChanged(filters.copyWith(sort: SellerOrderSort.newest)),
        ),
      if (filters.hasDateRange)
        AtelierFilterTag(
          label:
              '${from == null ? '…' : _fmtDay(from)} – '
              '${to == null ? '…' : _fmtDay(to)}',
          onRemove: () => onChanged(filters.copyWith(clearDates: true)),
        ),
      for (final status in filters.paymentStatuses)
        AtelierFilterTag(
          label: 'Payment: ${_humanize(status)}',
          onRemove: () => onChanged(
            filters.copyWith(
              paymentStatuses: {...filters.paymentStatuses}..remove(status),
            ),
          ),
        ),
      if (showRefundStates)
        for (final state in filters.refundStates)
          AtelierFilterTag(
            label: state.label,
            onRemove: () => onChanged(
              filters.copyWith(
                refundStates: {...filters.refundStates}..remove(state),
              ),
            ),
          ),
    ];
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < tags.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Reveal(index: i, horizontal: true, child: tags[i]),
            ),
          TextButton(
            onPressed: () =>
                onChanged(SellerOrderFilters(search: filters.search)),
            style: TextButton.styleFrom(foregroundColor: p.inkSoft),
            child: Text(
              'Clear all',
              style: AtelierType.label(p.inkSoft, size: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.initial,
    required this.paymentStatuses,
    required this.showRefundStates,
  });

  final SellerOrderFilters initial;
  final List<String> paymentStatuses;
  final bool showRefundStates;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late SellerOrderFilters _draft = widget.initial;

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final from = _draft.from;
    final to = _draft.to;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: from != null && to != null
          ? DateTimeRange(start: from, end: to)
          : null,
    );
    if (picked == null) return;
    setState(() {
      _draft = _draft.copyWith(from: picked.start, to: picked.end);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final from = _draft.from;
    final to = _draft.to;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('DATE', style: AtelierType.overline(p.muted)),
        const SizedBox(height: 10),
        Pressable(
          onTap: _pickDates,
          semanticLabel: 'Choose dates',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: p.sunken,
              borderRadius: BorderRadius.circular(AtelierRadius.md),
            ),
            child: Row(
              children: [
                Icon(Icons.date_range_rounded, size: 18, color: p.gold),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _draft.hasDateRange
                        ? '${from == null ? '…' : _fmtDay(from)} – '
                              '${to == null ? '…' : _fmtDay(to)}'
                        : 'Any date',
                    style: AtelierType.figure(
                      _draft.hasDateRange ? p.ink : p.muted,
                      size: 14,
                    ),
                  ),
                ),
                if (_draft.hasDateRange)
                  AtelierIconButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Clear dates',
                    size: 32,
                    onPressed: () => setState(
                      () => _draft = _draft.copyWith(clearDates: true),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (widget.paymentStatuses.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text('PAYMENT STATUS', style: AtelierType.overline(p.muted)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final status in widget.paymentStatuses)
                AtelierChoiceChip(
                  label: _humanize(status),
                  selected: _draft.paymentStatuses.contains(status),
                  onTap: () => setState(() {
                    final next = {..._draft.paymentStatuses};
                    next.contains(status)
                        ? next.remove(status)
                        : next.add(status);
                    _draft = _draft.copyWith(paymentStatuses: next);
                  }),
                ),
            ],
          ),
        ],
        if (widget.showRefundStates) ...[
          const SizedBox(height: 22),
          Text('REFUND STATUS', style: AtelierType.overline(p.muted)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final state in SellerOrderRefundState.values)
                AtelierChoiceChip(
                  label: state.label,
                  selected: _draft.refundStates.contains(state),
                  onTap: () => setState(() {
                    final next = {..._draft.refundStates};
                    next.contains(state) ? next.remove(state) : next.add(state);
                    _draft = _draft.copyWith(refundStates: next);
                  }),
                ),
            ],
          ),
        ],
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: AtelierButton(
                label: 'Reset',
                variant: AtelierButtonVariant.secondary,
                onPressed: () => Navigator.pop(
                  context,
                  SellerOrderFilters(sort: _draft.sort, search: _draft.search),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AtelierButton(
                label: context.tr(RemainingL10n.apply),
                onPressed: () => Navigator.pop(context, _draft),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({
    required this.category,
    required this.gutter,
    required this.entries,
    required this.isLoading,
    required this.errorMessage,
    required this.truncated,
    required this.filtered,
    required this.onRefresh,
    required this.onClearFilters,
  });

  final SellerOrderCategory category;
  final double gutter;
  final List<SellerOrderBoardEntry> entries;
  final bool isLoading;
  final String? errorMessage;
  final bool truncated;
  final bool filtered;
  final Future<void> Function() onRefresh;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final padding = EdgeInsets.fromLTRB(gutter, 8, gutter, 32);

    Widget body;
    if (isLoading) {
      body = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        children: const [AtelierSkeletonList(count: 4, height: 190)],
      );
    } else if (errorMessage != null && entries.isEmpty) {
      body = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        children: [
          AtelierErrorState(
            title: 'Couldn’t load ${category.label.toLowerCase()}',
            message: errorMessage!,
            onRetry: onRefresh,
          ),
        ],
      );
    } else if (entries.isEmpty) {
      body = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        children: [
          AtelierEmptyState(
            icon: filtered
                ? Icons.filter_alt_off_outlined
                : category.isRefund
                ? Icons.replay_rounded
                : Icons.receipt_long_outlined,
            title: filtered ? 'No matches' : 'Nothing here yet',
            message: filtered
                ? 'No ${category.label.toLowerCase()} match these filters.'
                : category.emptyMessage,
            actionLabel: filtered ? 'Clear filters' : null,
            onAction: filtered ? onClearFilters : null,
          ),
        ],
      );
    } else {
      final notices = <Widget>[
        if (errorMessage != null)
          AtelierNotice(
            text: errorMessage!,
            tone: AtelierTone.ruby,
            icon: Icons.error_outline_rounded,
            actionLabel: context.tr(RemainingL10n.retry),
            onAction: onRefresh,
          ),
        if (truncated)
          const AtelierNotice(
            text:
                'Showing your most recent records only. Narrow the date '
                'range to find older ones.',
          ),
      ];
      body = ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        itemCount: notices.length + entries.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          if (index < notices.length) return notices[index];
          final i = index - notices.length;
          final entry = entries[i];
          return Reveal(
            key: ValueKey(entry.key),
            index: i < 8 ? i : 0,
            child: entry.refund != null
                ? _RefundCard(refund: entry.refund!, order: entry.order)
                : SellerOrderSummaryCard(
                    order: entry.order!,
                    latestRefund: entry.latestRefund,
                    onTap: () => context.openRoute(
                      AppRouteNames.sellerOrderDetailPath(entry.order!.id),
                    ),
                  ),
          );
        },
      );
    }

    return RefreshIndicator(
      color: p.gold,
      backgroundColor: p.surface,
      onRefresh: onRefresh,
      child: body,
    );
  }
}

class _RefundCard extends ConsumerWidget {
  const _RefundCard({required this.refund, this.order});

  final RefundRequest refund;

  /// The refunded order, when it is among the loaded orders.
  final SellerOrder? order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.atelier;
    final tone = switch (refund.status) {
      RefundStatus.pending => AtelierTone.amber,
      RefundStatus.accepted => AtelierTone.emerald,
      RefundStatus.rejected => AtelierTone.ruby,
      RefundStatus.cancelled => AtelierTone.neutral,
    };
    final statusIcon = switch (refund.status) {
      RefundStatus.pending => Icons.schedule_rounded,
      RefundStatus.accepted => Icons.check_circle_rounded,
      RefundStatus.rejected => Icons.cancel_outlined,
      RefundStatus.cancelled => Icons.block_rounded,
    };
    final statusLabel = switch (refund.status) {
      RefundStatus.pending => 'Refund requested',
      RefundStatus.accepted => 'Refund approved',
      RefundStatus.rejected => 'Refund rejected',
      RefundStatus.cancelled => 'Withdrawn by buyer',
    };
    final mutating = ref.watch(refundMutationProvider).isLoading;
    final linked = order;
    final orderLabel = linked != null ? '#${linked.shortId}' : refund.orderId;
    final accent = p.tone(tone);

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AtelierRadius.lg),
        border: Border.all(
          color: refund.canSellerDecide
              ? accent.withValues(alpha: 0.45)
              : p.hairline,
        ),
        boxShadow: p.softShadow,
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AtelierPill(
                    label: statusLabel,
                    tone: tone,
                    icon: statusIcon,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppCurrency.usd(refund.amountUsd),
                    style: AtelierType.display(p.ink, size: 24),
                  ),
                  if (refund.amountInr > 0)
                    Text(
                      AppCurrency.inr(refund.amountInr),
                      style: AtelierType.figure(p.muted, size: 11.5),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          SellerOrderCustomerBlock(
            name: refund.user?.name.trim().isNotEmpty == true
                ? refund.buyerLabel
                : (linked?.customerLabel ?? refund.buyerLabel),
            email: linked?.customer?.email,
            phone: linked?.customer?.phone,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              AtelierKeyValue(
                label: context.tr(RemainingL10n.order),
                value: orderLabel,
                valueWidget: Pressable(
                  onTap: () => context.openRoute(
                    AppRouteNames.sellerOrderDetailPath(
                      linked?.id ?? refund.orderId,
                    ),
                  ),
                  semanticLabel: 'Open order $orderLabel',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: Text(
                          orderLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AtelierType.figure(p.gold, size: 13.5),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_outward_rounded,
                        size: 14,
                        color: p.gold,
                      ),
                    ],
                  ),
                ),
              ),
              AtelierKeyValue(
                label: context.tr(RemainingL10n.requested),
                value: refund.createdAtLabel,
              ),
              if (refund.resolvedAtLabel != null)
                AtelierKeyValue(
                  label: 'Resolved',
                  value: refund.resolvedAtLabel!,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.sunken,
              borderRadius: BorderRadius.circular(AtelierRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(RemainingL10n.buyerReason).toUpperCase(),
                  style: AtelierType.overline(p.muted),
                ),
                const SizedBox(height: 6),
                Text(
                  refund.reason,
                  style: AtelierType.body(p.inkSoft, size: 13),
                ),
                if (refund.sellerNote != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    context.tr(RemainingL10n.yourNote).toUpperCase(),
                    style: AtelierType.overline(p.muted),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    refund.sellerNote!,
                    style: AtelierType.body(p.inkSoft, size: 13),
                  ),
                ],
              ],
            ),
          ),
          if (refund.canSellerDecide) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AtelierButton(
                    label: context.tr(RemainingL10n.reject),
                    icon: Icons.close_rounded,
                    compact: true,
                    variant: AtelierButtonVariant.danger,
                    onPressed: mutating
                        ? null
                        : () => _rejectRefund(context, refund),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AtelierButton(
                    label: context.tr(RemainingL10n.accept),
                    icon: Icons.check_rounded,
                    compact: true,
                    loading: mutating,
                    variant: AtelierButtonVariant.gold,
                    onPressed: mutating
                        ? null
                        : () => _acceptRefund(context, refund),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static Future<Failure?> _outcome(
    Future<Result<RefundRequest, Failure>> call,
  ) async {
    return switch (await call) {
      Success() => null,
      ResultFailure(:final failure) => failure,
    };
  }

  Future<void> _acceptRefund(BuildContext context, RefundRequest refund) async {
    // Captured now: this card moves to another tab once the refund is
    // approved, so its context is gone when the dialog closes.
    final messenger = ScaffoldMessenger.of(context);
    final palette = context.atelier;
    final acceptedText = context.tr(RemainingL10n.refundAccepted);
    final done = await showAtelierDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SellerActionConfirmDialog(
        title: ctx.tr(RemainingL10n.acceptRefund),
        message: ctx.tr(RemainingL10n.thisTriggersARazorpayRefundForThe),
        confirmLabel: ctx.tr(RemainingL10n.accept),
        icon: Icons.currency_exchange_rounded,
        onConfirm: (ref) => _outcome(
          ref.read(refundMutationProvider.notifier).accept(refund.id),
        ),
      ),
    );
    if (done != true) return;
    AppHaptics.success();
    showAtelierToastOn(
      messenger,
      palette,
      acceptedText,
      tone: AtelierTone.emerald,
    );
  }

  Future<void> _rejectRefund(BuildContext context, RefundRequest refund) async {
    final messenger = ScaffoldMessenger.of(context);
    final palette = context.atelier;
    final rejectedText = context.tr(RemainingL10n.refundRejected);
    final done = await showAtelierDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RejectRefundDialog(refund: refund),
    );
    if (done != true) return;
    AppHaptics.success();
    showAtelierToastOn(
      messenger,
      palette,
      rejectedText,
      tone: AtelierTone.ruby,
    );
  }
}

class _RejectRefundDialog extends StatefulWidget {
  const _RejectRefundDialog({required this.refund});

  final RefundRequest refund;

  @override
  State<_RejectRefundDialog> createState() => _RejectRefundDialogState();
}

class _RejectRefundDialogState extends State<_RejectRefundDialog> {
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SellerActionConfirmDialog(
      title: context.tr(RemainingL10n.rejectRefund),
      message: 'Are you sure you want to reject this refund request?',
      confirmLabel: context.tr(RemainingL10n.reject),
      destructive: true,
      content: AtelierTextArea(
        controller: _noteCtrl,
        label: 'Note (optional)',
        maxLength: 2000,
      ),
      onConfirm: (ref) {
        final note = _noteCtrl.text.trim();
        return _RefundCard._outcome(
          ref
              .read(refundMutationProvider.notifier)
              .reject(widget.refund.id, sellerNote: note.isEmpty ? null : note),
        );
      },
    );
  }
}
