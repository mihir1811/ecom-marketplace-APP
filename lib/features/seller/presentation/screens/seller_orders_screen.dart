import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
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
import '../../data/seller_orders_mock_data.dart';
import '../../domain/models/seller_orders_models.dart';

class SellerOrdersScreen extends ConsumerStatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  ConsumerState<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends ConsumerState<SellerOrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final refundTotal = ref.watch(
      sellerRefundListProvider.select((s) => s.total),
    );
    final accent = AppColors.isDark(context)
        ? AppColors.bronzeLight
        : AppColors.bronzeDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TabBar(
          controller: _tabController,
          labelColor: accent,
          unselectedLabelColor: AppColors.textSecondary(context),
          indicatorColor: accent,
          indicatorWeight: 3,
          labelStyle: AppTypography.label.copyWith(fontWeight: FontWeight.w700),
          tabs: [
            Tab(text: 'Orders (${kSellerOrdersMock.length})'),
            Tab(text: 'Refunds ($refundTotal)'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [_OrdersTab(), _RefundsTab()],
          ),
        ),
      ],
    );
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: kSellerOrdersMock.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final order = kSellerOrdersMock[index];
        return _OrderSummaryCard(
          order: order,
          onTap: () =>
              context.openRoute(AppRouteNames.sellerOrderDetailPath(order.id)),
        );
      },
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.order, required this.onTap});

  final SellerOrder order;
  final VoidCallback onTap;

  Color get _statusColor {
    final s = order.status.toLowerCase();
    if (s.contains('deliver')) return AppColors.success;
    if (s.contains('out for')) return AppColors.info;
    if (s.contains('process') || s.contains('ship')) return AppColors.bronze;
    return AppColors.charcoalLight;
  }

  IconData get _statusIcon {
    final s = order.status.toLowerCase();
    if (s.contains('deliver')) return Icons.check_circle_outline;
    if (s.contains('out for')) return Icons.local_shipping_outlined;
    if (s.contains('process')) return Icons.hourglass_top_outlined;
    if (s.contains('ship')) return Icons.flight_takeoff_outlined;
    return Icons.shopping_bag_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _statusColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border(context)),
            boxShadow: AppColors.isDark(context) ? [] : AppShadows.cardLight,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(_statusIcon, color: accent, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.id,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.title.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Updated ${order.updatedAt}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.textMuted(context),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.chevron_right,
                              color: AppColors.textMuted(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _MetaChip(
                              icon: Icons.flag_outlined,
                              label: order.status,
                              foreground: accent,
                              background: accent.withValues(alpha: 0.12),
                            ),
                            _MetaChip(
                              icon: Icons.local_shipping_outlined,
                              label: order.carrier,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: AppColors.textMuted(context),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                order.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary(context),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (order.trackingNumber.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '#${order.trackingNumber}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textMuted(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    this.foreground,
    this.background,
  });

  final IconData icon;
  final String label;
  final Color? foreground;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final fg = foreground ?? AppColors.textPrimary(context);
    final bg = background ?? AppColors.surface(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: (foreground ?? AppColors.border(context)).withValues(
            alpha: foreground == null ? 1 : 0.25,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RefundsTab extends ConsumerWidget {
  const _RefundsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sellerRefundListProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(sellerRefundListProvider.notifier).refresh(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n is ScrollUpdateNotification &&
              n.metrics.maxScrollExtent > 0 &&
              n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
            ref.read(sellerRefundListProvider.notifier).loadMore();
          }
          return false;
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.s16),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.s16),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Icon(
                      Icons.replay,
                      size: 56,
                      color: AppColors.textMuted(
                        context,
                      ).withValues(alpha: 0.25),
                    ),
                  ),
                  Text(
                    'Review buyer refund requests for your orders. Accept to '
                    'process a Razorpay refund, or reject with an optional note. '
                    'Refunds are only allowed before delivery.',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary(context),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (state.isLoading && state.items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.errorMessage != null && state.items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Text(state.errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () =>
                          ref.read(sellerRefundListProvider.notifier).refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (state.items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text(
                    'No refund requests yet',
                    style: AppTypography.body,
                  ),
                ),
              )
            else ...[
              for (final refund in state.items) ...[
                _RefundCard(refund: refund),
                const SizedBox(height: 12),
              ],
              if (state.isLoadingMore)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RefundCard extends ConsumerWidget {
  const _RefundCard({required this.refund});

  final RefundRequest refund;

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
    final mutating = ref.watch(refundMutationProvider).isLoading;

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
              Text(
                refund.status.label,
                style: AppTypography.label.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                AppCurrency.usd(refund.amount),
                style: AppTypography.title.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _InfoBlock(
                  label: 'Buyer',
                  child: Text(
                    refund.buyerLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoBlock(
                  label: 'Order',
                  child: GestureDetector(
                    onTap: () => context.openRoute(
                      AppRouteNames.sellerOrderDetailPath(refund.orderId),
                    ),
                    child: Text(
                      refund.orderId,
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
                  label: 'Requested',
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
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _InfoBlock(
                  label: 'Buyer reason',
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
                    label: 'Your note',
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
                        : () => _rejectRefund(context, ref, refund.id),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: mutating
                        ? null
                        : () => _acceptRefund(context, ref, refund.id),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.charcoal,
                      foregroundColor: AppColors.warmWhite,
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _acceptRefund(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Accept refund?'),
        content: const Text(
          'This triggers a Razorpay refund for the seller portion.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result = await ref.read(refundMutationProvider.notifier).accept(id);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case Success():
        messenger.showSnackBar(
          const SnackBar(content: Text('Refund accepted')),
        );
      case ResultFailure(failure: final failure):
        messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<void> _rejectRefund(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final noteController = TextEditingController();
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject refund'),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Note (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    final note = noteController.text.trim();
    noteController.dispose();
    if (confirmed != true || !context.mounted) return;
    final result = await ref
        .read(refundMutationProvider.notifier)
        .reject(id, sellerNote: note.isEmpty ? null : note);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case Success():
        messenger.showSnackBar(
          const SnackBar(content: Text('Refund rejected')),
        );
      case ResultFailure(failure: final failure):
        messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
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
