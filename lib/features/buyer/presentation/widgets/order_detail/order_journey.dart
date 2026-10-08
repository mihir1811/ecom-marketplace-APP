import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../payment/domain/models/payment_models.dart';
import '../../../../refunds/application/refund_providers.dart';
import '../../../../seller/presentation/atelier/atelier_components.dart';
import '../../../../seller/presentation/atelier/atelier_studio.dart';
import '../../../../seller/presentation/atelier/atelier_theme.dart';
import '../../../../tracking/application/order_shipments_provider.dart';
import '../../../domain/order_lifecycle.dart';

/// Lifecycle of [order] for the buyer, rebuilt whenever the order, its
/// shipments or its refunds reload (pushes invalidate those providers).
OrderLifecycle watchOrderLifecycle(WidgetRef ref, PaymentOrder order) {
  final shipments = ref.watch(orderShipmentsProvider(order.id)).asData?.value;
  final refunds = ref.watch(orderRefundsProvider(order.id)).asData?.value;
  return buildOrderLifecycle(
    paymentStatus: order.status,
    decisions: order.sellerDecisions,
    shipments: shipments ?? const [],
    refunds: refunds ?? const [],
  );
}

AtelierTone orderLifecycleTone(OrderStatusTone tone) => switch (tone) {
  OrderStatusTone.pending => AtelierTone.sapphire,
  OrderStatusTone.progress => AtelierTone.gold,
  OrderStatusTone.success => AtelierTone.emerald,
  OrderStatusTone.danger => AtelierTone.ruby,
  OrderStatusTone.neutral => AtelierTone.neutral,
};

/// Seller name for a decision, from the decision, the order's sellers or
/// its items.
String orderSellerName(PaymentOrder order, String sellerId, {String? hint}) {
  if (hint != null && hint.trim().isNotEmpty) return hint;
  for (final s in order.sellers) {
    if (s.id == sellerId) return s.companyName;
  }
  for (final item in order.items) {
    if (item.sellerId == sellerId && item.sellerName != null) {
      return item.sellerName!;
    }
  }
  return 'Seller';
}

/// Step-by-step journey of the order, drawn in as it loads, plus each
/// seller's confirmation on multi-seller orders.
class OrderJourneyPanel extends ConsumerWidget {
  const OrderJourneyPanel({required this.order, super.key});

  final PaymentOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.atelier;
    final lifecycle = watchOrderLifecycle(ref, order);
    final steps = lifecycle.steps;
    final reached = steps.lastIndexWhere(
      (s) => s.state != OrderStepState.upcoming,
    );
    final multiSeller = order.sellerDecisions.length > 1;

    return AtelierPanel(
      overline: 'Journey',
      title: 'Where it stands',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: reached < 0 ? 0.0 : reached.toDouble()),
            duration: context.reduceMotion
                ? Duration.zero
                : Duration(milliseconds: 380 * (reached + 1)),
            curve: Curves.easeInOutCubic,
            builder: (context, t, _) => Column(
              children: [
                for (var i = 0; i < steps.length; i++)
                  _StepRow(
                    step: steps[i],
                    isLast: i == steps.length - 1,
                    lit: t >= i - 0.02,
                    fill: (t - i).clamp(0.0, 1.0),
                  ),
              ],
            ),
          ),
          if (multiSeller) ...[
            const AtelierHairline(vertical: 16),
            Text('SELLER CONFIRMATION', style: AtelierType.overline(p.muted)),
            const SizedBox(height: 12),
            for (final d in order.sellerDecisions)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    AtelierMonogram(
                      name: orderSellerName(
                        order,
                        d.sellerId,
                        hint: d.sellerName,
                      ),
                      size: 30,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        orderSellerName(order, d.sellerId, hint: d.sellerName),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AtelierType.label(p.ink, size: 13.5),
                      ),
                    ),
                    AtelierPill(
                      dense: true,
                      label: d.isRejected
                          ? 'Rejected'
                          : d.isAccepted
                          ? 'Confirmed'
                          : 'Awaiting',
                      tone: d.isRejected
                          ? AtelierTone.ruby
                          : d.isAccepted
                          ? AtelierTone.emerald
                          : AtelierTone.sapphire,
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.isLast,
    required this.lit,
    required this.fill,
  });

  final OrderLifecycleStep step;
  final bool isLast;
  final bool lit;

  /// 0..1 progress of the connector below this step.
  final double fill;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final state = lit ? step.state : OrderStepState.upcoming;
    final (Color fillColor, Color edge, Widget? glyph) = switch (state) {
      OrderStepState.done => (
        p.gold,
        p.gold,
        Icon(Icons.check_rounded, size: 13, color: p.onGold),
      ),
      OrderStepState.current => (
        p.goldSoft,
        p.gold,
        const AtelierPulseDot(tone: AtelierTone.gold, size: 7),
      ),
      OrderStepState.failed => (
        p.ruby.withValues(alpha: 0.12),
        p.ruby,
        Icon(Icons.close_rounded, size: 13, color: p.ruby),
      ),
      OrderStepState.upcoming => (p.sunken, p.hairline, null),
    };
    final active = state != OrderStepState.upcoming;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: AtelierMotion.slow,
                  curve: AtelierMotion.settle,
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: fillColor,
                    border: Border.all(color: edge, width: 1.4),
                  ),
                  child: glyph == null ? null : Center(child: glyph),
                ),
                if (!isLast)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: CustomPaint(
                        size: const Size(1.5, double.infinity),
                        painter: _ConnectorPainter(
                          base: p.hairline,
                          color: p.gold,
                          fill: step.state == OrderStepState.done ? fill : 0,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 2, bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: AtelierMotion.base,
                    style: AtelierType.label(
                      state == OrderStepState.failed
                          ? p.ruby
                          : active
                          ? p.ink
                          : p.muted,
                      size: state == OrderStepState.current ? 14.5 : 13.5,
                      weight: state == OrderStepState.current
                          ? FontWeight.w700
                          : FontWeight.w600,
                    ),
                    child: Text(step.label),
                  ),
                  if (step.detail != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      step.detail!,
                      style: AtelierType.caption(p.muted, size: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hairline connector filled in gold from the top to [fill].
class _ConnectorPainter extends CustomPainter {
  _ConnectorPainter({
    required this.base,
    required this.color,
    required this.fill,
  });

  final Color base;
  final Color color;
  final double fill;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final paint = Paint()
      ..strokeWidth = 1.5
      ..color = base;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    if (fill <= 0) return;
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height * fill.clamp(0.0, 1.0)),
      paint..color = color,
    );
  }

  @override
  bool shouldRepaint(_ConnectorPainter old) =>
      old.fill != fill || old.color != color || old.base != base;
}
