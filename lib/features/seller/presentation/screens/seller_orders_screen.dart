import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../refunds/application/refund_providers.dart';
import '../../../refunds/domain/models/refund_request.dart';
import '../../application/seller_orders_provider.dart';
import '../../domain/models/seller_order.dart';
import '../../domain/seller_order_board.dart';
import '../widgets/seller_order_customer_block.dart';
import '../widgets/seller_order_decision.dart';
import '../widgets/seller_order_summary_card.dart';

import '../../../../core/l10n/app_localizations.dart';

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

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(sellerOrdersProvider);
    final refunds = ref.watch(sellerRefundListProvider);
    final board = SellerOrderBoard(orders: orders.items, refunds: refunds.items);
    final counts = board.counts();
    final accent = AppColors.isDark(context)
        ? AppColors.bronzeLight
        : AppColors.bronzeDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: accent,
          unselectedLabelColor: AppColors.textSecondary(context),
          indicatorColor: accent,
          indicatorWeight: 3,
          labelStyle: AppTypography.label.copyWith(fontWeight: FontWeight.w700),
          tabs: [
            for (final c in _categories) Tab(text: '${c.label} (${counts[c]})'),
          ],
        ),
        _Toolbar(
          searchCtrl: _searchCtrl,
          filters: _filters,
          onSearch: (q) => setState(() => _filters = _filters.copyWith(search: q)),
          onSort: (sort) =>
              setState(() => _filters = _filters.copyWith(sort: sort)),
          onOpenFilters: () => _openFilters(board),
        ),
        if (_filters.activeCount > 0)
          _ActiveFilters(
            filters: _filters,
            showRefundStates: !_category.isRefund,
            onChanged: (f) => setState(() => _filters = f),
          ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              for (final category in _categories)
                _CategoryList(
                  category: category,
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
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openFilters(SellerOrderBoard board) async {
    final result = await showModalBottomSheet<SellerOrderFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(
        initial: _filters,
        paymentStatuses: board.paymentStatuses(),
        showRefundStates: !_category.isRefund,
      ),
    );
    if (result != null && mounted) setState(() => _filters = result);
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.searchCtrl,
    required this.filters,
    required this.onSearch,
    required this.onSort,
    required this.onOpenFilters,
  });

  final TextEditingController searchCtrl;
  final SellerOrderFilters filters;
  final ValueChanged<String> onSearch;
  final ValueChanged<SellerOrderSort> onSort;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final active = filters.activeCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchCtrl,
              onChanged: onSearch,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search order, customer or product',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: filters.search.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          searchCtrl.clear();
                          onSearch('');
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.r8),
                  borderSide: BorderSide(color: AppColors.border(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.r8),
                  borderSide: BorderSide(color: AppColors.border(context)),
                ),
              ),
            ),
          ),
          PopupMenuButton<SellerOrderSort>(
            tooltip: 'Sort: ${filters.sort.label}',
            icon: const Icon(Icons.sort),
            initialValue: filters.sort,
            onSelected: onSort,
            itemBuilder: (_) => [
              for (final sort in SellerOrderSort.values)
                CheckedPopupMenuItem(
                  value: sort,
                  checked: sort == filters.sort,
                  child: Text(sort.label),
                ),
            ],
          ),
          IconButton(
            tooltip: 'Filters',
            onPressed: onOpenFilters,
            icon: Badge(
              isLabelVisible: active > 0,
              label: Text('$active'),
              child: const Icon(Icons.tune),
            ),
          ),
        ],
      ),
    );
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
    final from = filters.from;
    final to = filters.to;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          if (filters.hasDateRange)
            _chip(
              '${from == null ? '…' : _fmtDay(from)} – '
              '${to == null ? '…' : _fmtDay(to)}',
              () => onChanged(filters.copyWith(clearDates: true)),
            ),
          for (final status in filters.paymentStatuses)
            _chip(
              'Payment: ${_humanize(status)}',
              () => onChanged(
                filters.copyWith(
                  paymentStatuses: {...filters.paymentStatuses}..remove(status),
                ),
              ),
            ),
          if (showRefundStates)
            for (final state in filters.refundStates)
              _chip(
                state.label,
                () => onChanged(
                  filters.copyWith(
                    refundStates: {...filters.refundStates}..remove(state),
                  ),
                ),
              ),
          TextButton(
            onPressed: () => onChanged(
              SellerOrderFilters(sort: filters.sort, search: filters.search),
            ),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InputChip(label: Text(label), onDeleted: onRemove),
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
    final from = _draft.from;
    final to = _draft.to;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter orders',
                style: AppTypography.title.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              _label(context, 'Date'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDates,
                      icon: const Icon(Icons.date_range, size: 18),
                      label: Text(
                        _draft.hasDateRange
                            ? '${from == null ? '…' : _fmtDay(from)} – '
                                  '${to == null ? '…' : _fmtDay(to)}'
                            : 'Any date',
                      ),
                    ),
                  ),
                  if (_draft.hasDateRange)
                    IconButton(
                      tooltip: 'Clear dates',
                      onPressed: () => setState(
                        () => _draft = _draft.copyWith(clearDates: true),
                      ),
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
              if (widget.paymentStatuses.isNotEmpty) ...[
                const SizedBox(height: 16),
                _label(context, 'Payment status'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final status in widget.paymentStatuses)
                      FilterChip(
                        label: Text(_humanize(status)),
                        selected: _draft.paymentStatuses.contains(status),
                        onSelected: (on) => setState(() {
                          final next = {..._draft.paymentStatuses};
                          on ? next.add(status) : next.remove(status);
                          _draft = _draft.copyWith(paymentStatuses: next);
                        }),
                      ),
                  ],
                ),
              ],
              if (widget.showRefundStates) ...[
                const SizedBox(height: 16),
                _label(context, 'Refund status'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final state in SellerOrderRefundState.values)
                      FilterChip(
                        label: Text(state.label),
                        selected: _draft.refundStates.contains(state),
                        onSelected: (on) => setState(() {
                          final next = {..._draft.refundStates};
                          on ? next.add(state) : next.remove(state);
                          _draft = _draft.copyWith(refundStates: next);
                        }),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(
                        context,
                        SellerOrderFilters(
                          sort: _draft.sort,
                          search: _draft.search,
                        ),
                      ),
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, _draft),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.charcoal,
                        foregroundColor: AppColors.warmWhite,
                      ),
                      child: Text(context.tr(RemainingL10n.apply)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Text(
    text,
    style: AppTypography.label.copyWith(fontWeight: FontWeight.w700),
  );
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({
    required this.category,
    required this.entries,
    required this.isLoading,
    required this.errorMessage,
    required this.truncated,
    required this.filtered,
    required this.onRefresh,
  });

  final SellerOrderCategory category;
  final List<SellerOrderBoardEntry> entries;
  final bool isLoading;
  final String? errorMessage;
  final bool truncated;
  final bool filtered;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (errorMessage != null && entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Text(errorMessage!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: onRefresh,
                    child: Text(context.tr(RemainingL10n.retry)),
                  ),
                ],
              ),
            )
          else if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(
                  filtered
                      ? 'No ${category.label.toLowerCase()} match these filters.'
                      : category.emptyMessage,
                  textAlign: TextAlign.center,
                  style: AppTypography.body,
                ),
              ),
            )
          else ...[
            if (errorMessage != null) _Notice(text: errorMessage!),
            if (truncated)
              const _Notice(
                text:
                    'Showing your most recent records only. Narrow the date '
                    'range to find older ones.',
              ),
            for (final entry in entries) ...[
              if (entry.refund != null)
                _RefundCard(refund: entry.refund!, order: entry.order)
              else
                SellerOrderSummaryCard(
                  order: entry.order!,
                  latestRefund: entry.latestRefund,
                  onTap: () => context.openRoute(
                    AppRouteNames.sellerOrderDetailPath(entry.order!.id),
                  ),
                ),
              const SizedBox(height: 14),
            ],
          ],
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: AppColors.textMuted(context),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted(context),
              ),
            ),
          ),
        ],
      ),
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
    final statusColor = switch (refund.status) {
      RefundStatus.pending => AppColors.bronze,
      RefundStatus.accepted => AppColors.success,
      RefundStatus.rejected => AppColors.error,
      RefundStatus.cancelled => AppColors.charcoalLight,
    };
    final statusIcon = switch (refund.status) {
      RefundStatus.pending => Icons.schedule,
      RefundStatus.accepted => Icons.check_circle,
      RefundStatus.rejected => Icons.cancel_outlined,
      RefundStatus.cancelled => Icons.block,
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

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: AppColors.isDark(context) ? [] : AppShadows.cardLight,
      ),
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusLabel,
                  style: AppTypography.label.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppCurrency.usd(refund.amountUsd),
                    style: AppTypography.title.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  if (refund.amountInr > 0)
                    Text(
                      AppCurrency.inr(refund.amountInr),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InfoBlock(
            label: context.tr(RemainingL10n.buyer),
            child: SellerOrderCustomerBlock(
              name: refund.user?.name.trim().isNotEmpty == true
                  ? refund.buyerLabel
                  : (linked?.customerLabel ?? refund.buyerLabel),
              email: linked?.customer?.email,
              phone: linked?.customer?.phone,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _InfoBlock(
                  label: context.tr(RemainingL10n.order),
                  child: GestureDetector(
                    onTap: () => context.openRoute(
                      AppRouteNames.sellerOrderDetailPath(
                        linked?.id ?? refund.orderId,
                      ),
                    ),
                    child: Text(
                      orderLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.copyWith(
                        color: AppColors.bronzeDark,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoBlock(
                  label: context.tr(RemainingL10n.requested),
                  child: Text(
                    refund.createdAtLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textPrimary(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (refund.resolvedAtLabel != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoBlock(
                    label: 'Resolved',
                    child: Text(
                      refund.resolvedAtLabel!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textPrimary(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _InfoBlock(
                  label: context.tr(RemainingL10n.buyerReason),
                  child: Text(
                    refund.reason,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ),
              ),
              if (refund.sellerNote != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoBlock(
                    label: context.tr(RemainingL10n.yourNote),
                    child: Text(
                      refund.sellerNote!,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (refund.canSellerDecide) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: mutating
                        ? null
                        : () => _rejectRefund(context, refund),
                    child: Text(context.tr(RemainingL10n.reject)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: mutating
                        ? null
                        : () => _acceptRefund(context, refund),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.charcoal,
                      foregroundColor: AppColors.warmWhite,
                    ),
                    child: Text(context.tr(RemainingL10n.accept)),
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
    final acceptedText = context.tr(RemainingL10n.refundAccepted);
    final done = await showAppDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SellerActionConfirmDialog(
        title: ctx.tr(RemainingL10n.acceptRefund),
        message: ctx.tr(RemainingL10n.thisTriggersARazorpayRefundForThe),
        confirmLabel: ctx.tr(RemainingL10n.accept),
        onConfirm: (ref) =>
            _outcome(ref.read(refundMutationProvider.notifier).accept(refund.id)),
      ),
    );
    if (done != true) return;
    AppHaptics.success();
    messenger.showSnackBar(SnackBar(content: Text(acceptedText)));
  }

  Future<void> _rejectRefund(BuildContext context, RefundRequest refund) async {
    final messenger = ScaffoldMessenger.of(context);
    final rejectedText = context.tr(RemainingL10n.refundRejected);
    final done = await showAppDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RejectRefundDialog(refund: refund),
    );
    if (done != true) return;
    AppHaptics.success();
    messenger.showSnackBar(SnackBar(content: Text(rejectedText)));
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
      content: TextField(
        controller: _noteCtrl,
        maxLines: 3,
        maxLength: 2000,
        decoration: const InputDecoration(
          labelText: 'Note (optional)',
          border: OutlineInputBorder(),
        ),
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

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textMuted(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}
