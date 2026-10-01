import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../refunds/domain/models/refund_request.dart';
import '../../domain/models/seller_order.dart';
import 'seller_order_customer_block.dart';
import 'seller_order_decision.dart';

/// Incoming order row: id, customer, product, quantity, amount, date and
/// status, plus Accept / Reject while the order is pending and the next
/// step once it is confirmed.
class SellerOrderSummaryCard extends StatelessWidget {
  const SellerOrderSummaryCard({
    required this.order,
    required this.onTap,
    this.latestRefund,
    super.key,
  });

  final SellerOrder order;
  final VoidCallback onTap;

  /// Newest refund request on this order, shown as a badge.
  final RefundRequest? latestRefund;

  @override
  Widget build(BuildContext context) {
    final accent = sellerOrderStatusColor(order.status);
    final quantity = order.totalQuantity;

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
                              child: Icon(
                                sellerOrderStatusIcon(order.status),
                                color: accent,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '#${order.shortId}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.title.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    sellerOrderDateLabel(order.createdAt),
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
                            Text(
                              sellerOrderAmountLabel(order),
                              style: AppTypography.label.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: AppColors.textMuted(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SellerOrderCustomerBlock(
                          name: order.customerLabel,
                          email: order.customer?.email,
                          phone: order.customer?.phone,
                        ),
                        const SizedBox(height: 8),
                        _Line(
                          icon: Icons.diamond_outlined,
                          text: quantity > 0
                              ? '${order.productSummary} · Qty $quantity'
                              : order.productSummary,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            SellerOrderStatusBadge(order: order),
                            if ((order.paymentStatus ?? '').isNotEmpty)
                              SellerOrderTag(
                                icon: Icons.payments_outlined,
                                text: _humanize(order.paymentStatus!),
                              ),
                            if (latestRefund != null)
                              SellerOrderTag(
                                icon: Icons.replay,
                                text: 'Refund ${latestRefund!.status.label.toLowerCase()}',
                                color: switch (latestRefund!.status) {
                                  RefundStatus.pending => AppColors.bronze,
                                  RefundStatus.accepted => AppColors.success,
                                  RefundStatus.rejected => AppColors.error,
                                  RefundStatus.cancelled =>
                                    AppColors.charcoalLight,
                                },
                              ),
                          ],
                        ),
                        if (order.status == SellerOrderStatus.accepted) ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: onTap,
                              icon: const Icon(
                                Icons.local_shipping_outlined,
                                size: 18,
                              ),
                              label: const Text('Next: update shipping'),
                            ),
                          ),
                        ],
                        if (order.status.canDecide) ...[
                          const SizedBox(height: 12),
                          SellerOrderDecisionButtons(
                            order: order,
                            compact: true,
                          ),
                        ],
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

String _humanize(String raw) {
  final words = raw.trim().toLowerCase().replaceAll('_', ' ');
  return words.isEmpty ? raw : words[0].toUpperCase() + words.substring(1);
}

/// Small outlined pill (payment / refund state).
class SellerOrderTag extends StatelessWidget {
  const SellerOrderTag({
    required this.icon,
    required this.text,
    this.color,
    super.key,
  });

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTypography.caption.copyWith(
              color: c,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted(context)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
