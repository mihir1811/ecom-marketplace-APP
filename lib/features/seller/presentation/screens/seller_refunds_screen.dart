import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/seller_orders_mock_data.dart';
import '../../domain/models/seller_orders_models.dart';
import '../widgets/seller_layout.dart';

class SellerRefundsScreen extends StatelessWidget {
  const SellerRefundsScreen({super.key});

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
              ),
              Text(
                'Refunds',
                style: AppTypography.headline.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.s16),
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.s16),
                decoration: BoxDecoration(
                  color: AppColors.sandSurface,
                  borderRadius: BorderRadius.circular(14),
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
          ),
        ),
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
    final statusColor = isAccepted ? AppColors.success : AppColors.error;
    final statusIcon =
        isAccepted ? Icons.check_circle : Icons.cancel_outlined;
    final statusLabel = isAccepted ? 'Accepted' : 'Rejected';

    return Material(
      color: AppColors.warmWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.warmBorder),
      ),
      child: Padding(
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
