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
          crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(width: 12),
                Text(
                  refund.amountLabel,
                  style: AppTypography.title.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _MetaLine(label: 'Buyer:', value: refund.buyer),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Order: ',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMutedLight,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.go(
                    AppRouteNames.sellerOrderDetailPath(refund.orderId),
                  ),
                  child: Text(
                    refund.orderId,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.bronzeDark,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              refund.requestedAt,
              style: AppTypography.caption.copyWith(
                color: AppColors.textMutedLight,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Buyer reason',
              style: AppTypography.label.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              refund.buyerReason,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            if (refund.sellerNote != null) ...[
              const SizedBox(height: 12),
              Text(
                'Your note',
                style:
                    AppTypography.label.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                refund.sellerNote!,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMutedLight,
            ),
          ),
          TextSpan(
            text: value,
            style: AppTypography.caption.copyWith(
              color: AppColors.charcoal,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
