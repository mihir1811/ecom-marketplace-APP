import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../payment/domain/models/payment_models.dart';
import '../../../refunds/application/refund_providers.dart';
import '../../../tracking/application/order_shipments_provider.dart';
import '../../domain/order_lifecycle.dart';

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

Color orderToneColor(OrderStatusTone tone) => switch (tone) {
  OrderStatusTone.pending => AppColors.info,
  OrderStatusTone.progress => AppColors.bronze,
  OrderStatusTone.success => AppColors.success,
  OrderStatusTone.danger => AppColors.error,
  OrderStatusTone.neutral => AppColors.charcoalLight,
};

/// Current status headline plus the step-by-step progression.
class OrderStatusSection extends ConsumerWidget {
  const OrderStatusSection({required this.order, super.key});

  final PaymentOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lifecycle = watchOrderLifecycle(ref, order);
    final color = orderToneColor(lifecycle.tone);
    final multiSeller = order.sellerDecisions.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Status',
          style: AppTypography.caption.copyWith(
            color: AppColors.textMuted(context),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                lifecycle.headline,
                style: AppTypography.title.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        if (lifecycle.message != null) ...[
          const SizedBox(height: 4),
          Text(
            lifecycle.message!,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
        const SizedBox(height: 16),
        for (var i = 0; i < lifecycle.steps.length; i++)
          _StepRow(
            step: lifecycle.steps[i],
            isLast: i == lifecycle.steps.length - 1,
          ),
        if (multiSeller) ...[
          const Divider(height: 24),
          Text(
            'Seller confirmation',
            style: AppTypography.label.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          for (final decision in order.sellerDecisions)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      decision.sellerName ?? _sellerName(order, decision),
                      style: AppTypography.caption,
                    ),
                  ),
                  Text(
                    switch (decision.status) {
                      SellerDecisionStatuses.accepted => 'Confirmed',
                      SellerDecisionStatuses.rejected => 'Rejected',
                      _ => 'Approval pending',
                    },
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: decision.isRejected
                          ? AppColors.error
                          : decision.isAccepted
                          ? AppColors.success
                          : AppColors.info,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  static String _sellerName(
    PaymentOrder order,
    PaymentOrderSellerDecision decision,
  ) {
    for (final s in order.sellers) {
      if (s.id == decision.sellerId) return s.companyName;
    }
    for (final item in order.items) {
      if (item.sellerId == decision.sellerId && item.sellerName != null) {
        return item.sellerName!;
      }
    }
    return 'Seller';
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.isLast});

  final OrderLifecycleStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (step.state) {
      OrderStepState.done => (AppColors.success, Icons.check),
      OrderStepState.current => (AppColors.bronze, Icons.circle),
      OrderStepState.failed => (AppColors.error, Icons.close),
      OrderStepState.upcoming => (AppColors.border(context), null),
    };
    final active = step.state != OrderStepState.upcoming;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active
                        ? color.withValues(alpha: 0.15)
                        : AppColors.surface(context),
                    border: Border.all(color: color, width: 1.5),
                  ),
                  child: icon == null
                      ? null
                      : Icon(
                          icon,
                          size: step.state == OrderStepState.current ? 8 : 13,
                          color: color,
                        ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: step.state == OrderStepState.done
                          ? AppColors.success.withValues(alpha: 0.5)
                          : AppColors.border(context),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14, top: 1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.label,
                    style: AppTypography.label.copyWith(
                      fontWeight: step.state == OrderStepState.current
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: active
                          ? AppColors.textPrimary(context)
                          : AppColors.textMuted(context),
                    ),
                  ),
                  if (step.detail != null)
                    Text(
                      step.detail!,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted(context),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
