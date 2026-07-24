import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/seller_orders_mock_data.dart';
import '../../domain/models/seller_orders_models.dart';
import '../widgets/seller_layout.dart';

class SellerOrdersScreen extends StatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen>
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => openSellerDrawer(context),
                icon: const Icon(Icons.menu),
                tooltip: 'Open menu',
              ),
              Text(
                'Orders',
                style: AppTypography.headline.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          labelColor: AppColors.bronzeDark,
          unselectedLabelColor: AppColors.textSecondaryLight,
          indicatorColor: AppColors.bronzeDark,
          indicatorWeight: 3,
          labelStyle: AppTypography.label.copyWith(fontWeight: FontWeight.w700),
          tabs: [
            Tab(text: 'Orders (${kSellerOrdersMock.length})'),
            Tab(text: 'Refunds (${kSellerRefundsMock.length})'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _OrdersTab(),
              _RefundsTab(),
            ],
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
          onTap: () => context.go(
            AppRouteNames.sellerOrderDetailPath(order.id),
          ),
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
            color: AppColors.warmWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.warmBorder),
            boxShadow: AppShadows.cardLight,
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
                                      color: AppColors.textMutedLight,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.textMutedLight,
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
                            const Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: AppColors.textMutedLight,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                order.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondaryLight,
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
                                    color: AppColors.textMutedLight,
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
    final fg = foreground ?? AppColors.charcoal;
    final bg = background ?? AppColors.sandSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: (foreground ?? AppColors.warmBorder).withValues(
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

class _RefundsTab extends StatelessWidget {
  const _RefundsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s16),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.s16),
          decoration: BoxDecoration(
            color: AppColors.sandSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.warmBorder),
          ),
          child: Stack(
            children: [
              Positioned(
                right: 0,
                top: 0,
                child: Icon(
                  Icons.replay,
                  size: 56,
                  color: AppColors.textMutedLight.withValues(alpha: 0.25),
                ),
              ),
              Text(
                'Review buyer refund requests for your orders. Accept to '
                'process a Razorpay refund, or reject with an optional note. '
                'Refunds are only allowed before delivery.',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondaryLight,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final refund in kSellerRefundsMock) ...[
          _RefundCard(refund: refund),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _RefundCard extends StatelessWidget {
  const _RefundCard({required this.refund});

  final SellerRefund refund;

  @override
  Widget build(BuildContext context) {
    final isAccepted = refund.status == SellerRefundStatus.accepted;
    final isPending = refund.status == SellerRefundStatus.pending;
    final statusColor = isPending
        ? AppColors.bronze
        : isAccepted
            ? AppColors.success
            : AppColors.error;
    final statusIcon = isPending
        ? Icons.schedule
        : isAccepted
            ? Icons.check_circle
            : Icons.cancel_outlined;
    final statusLabel = isPending
        ? 'Pending'
        : isAccepted
            ? 'Accepted'
            : 'Rejected';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warmBorder),
        boxShadow: AppShadows.cardLight,
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
                statusLabel,
                style: AppTypography.label.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                refund.amountLabel,
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
                    refund.buyer,
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
                    onTap: () => context.go(
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
                    refund.requestedAt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.charcoal,
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
                    refund.buyerReason,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondaryLight,
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
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
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
            color: AppColors.textMutedLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}
