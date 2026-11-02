import 'package:flutter/material.dart';

import '../../../refunds/domain/models/refund_request.dart';
import '../../domain/models/seller_order.dart';
import '../atelier/atelier_components.dart';
import '../atelier/atelier_motion.dart';
import '../atelier/atelier_theme.dart';
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
    final p = context.atelier;
    final tone = sellerOrderStatusTone(order.status);
    final accent = p.tone(tone);
    final quantity = order.totalQuantity;
    final pending = order.status.canDecide;
    final amount = sellerOrderAmountParts(order);

    return Pressable(
      onTap: onTap,
      semanticLabel:
          'Order ${order.shortId}, ${order.customerLabel}, '
          '${sellerOrderAmountLabel(order)}, ${sellerOrderStatusLabel(order)}',
      child: Container(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(AtelierRadius.lg),
          border: Border.all(
            color: pending ? accent.withValues(alpha: 0.45) : p.hairline,
          ),
          boxShadow: p.softShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (pending)
              Container(
                height: 2,
                decoration: BoxDecoration(gradient: p.goldGradient),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ORDER', style: AtelierType.overline(p.muted)),
                            const SizedBox(height: 4),
                            Text(
                              '#${order.shortId}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AtelierType.figure(
                                p.ink,
                                size: 16,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              amount.primary,
                              maxLines: 1,
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                              style: AtelierType.display(p.ink, size: 24),
                            ),
                            if (amount.secondary != null)
                              Text(
                                amount.secondary!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AtelierType.figure(p.muted, size: 11.5),
                              ),
                            const SizedBox(height: 2),
                            Tooltip(
                              message: sellerOrderDateLabel(order.createdAt),
                              child: Text(
                                sellerOrderRelativeTime(order.createdAt),
                                style: AtelierType.caption(p.muted, size: 11.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SellerOrderCustomerBlock(
                    name: order.customerLabel,
                    email: order.customer?.email,
                    phone: order.customer?.phone,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: p.sunken,
                      borderRadius: BorderRadius.circular(AtelierRadius.sm),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.diamond_outlined, size: 15, color: p.gold),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            order.productSummary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AtelierType.label(p.inkSoft, size: 12.5),
                          ),
                        ),
                        if (quantity > 0)
                          Text(
                            'Qty $quantity',
                            style: AtelierType.figure(p.muted, size: 11.5),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: [
                      SellerOrderStatusBadge(order: order),
                      if ((order.paymentStatus ?? '').isNotEmpty)
                        SellerOrderTag(
                          icon: Icons.payments_outlined,
                          text: _humanize(order.paymentStatus!),
                        ),
                      if (latestRefund != null)
                        SellerOrderTag(
                          icon: Icons.replay_rounded,
                          text:
                              'Refund ${latestRefund!.status.label.toLowerCase()}',
                          tone: switch (latestRefund!.status) {
                            RefundStatus.pending => AtelierTone.amber,
                            RefundStatus.accepted => AtelierTone.emerald,
                            RefundStatus.rejected => AtelierTone.ruby,
                            RefundStatus.cancelled => AtelierTone.neutral,
                          },
                        ),
                    ],
                  ),
                  if (order.status == SellerOrderStatus.accepted) ...[
                    const SizedBox(height: 8),
                    Pressable(
                      onTap: onTap,
                      semanticLabel: 'Next: update shipping',
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_shipping_outlined,
                            size: 17,
                            color: p.gold,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Next: update shipping',
                            style: AtelierType.label(p.gold, size: 13),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 15,
                            color: p.gold,
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (pending) ...[
                    const SizedBox(height: 10),
                    SellerOrderDecisionButtons(order: order, compact: true),
                  ],
                ],
              ),
            ),
          ],
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
    this.tone = AtelierTone.neutral,
    super.key,
  });

  final IconData icon;
  final String text;
  final AtelierTone tone;

  @override
  Widget build(BuildContext context) {
    return AtelierPill(label: text, icon: icon, tone: tone);
  }
}
