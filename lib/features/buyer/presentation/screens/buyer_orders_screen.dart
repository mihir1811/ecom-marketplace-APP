import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/buyer_orders_mock_data.dart';
import '../../domain/models/buyer_order.dart';
import '../widgets/buyer_layout.dart';

/// Buyer orders — tracking view only (no status/refund edits).
class BuyerOrdersScreen extends StatelessWidget {
  const BuyerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BuyerLayout(
      title: 'Orders',
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: kBuyerOrdersMock.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final order = kBuyerOrdersMock[index];
          return _BuyerOrderCard(
            order: order,
            onTap: () => context.go(
              AppRouteNames.buyerOrderDetailPath(order.id),
            ),
          );
        },
      ),
    );
  }
}

class _BuyerOrderCard extends StatelessWidget {
  const _BuyerOrderCard({required this.order, required this.onTap});

  final BuyerOrder order;
  final VoidCallback onTap;

  Color get _statusColor {
    final s = order.status.toLowerCase();
    if (s.contains('deliver')) return AppColors.success;
    if (s.contains('out for')) return AppColors.info;
    if (s.contains('process') || s.contains('ship')) return AppColors.bronze;
    return AppColors.charcoalLight;
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
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order.productLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.title.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textMutedLight,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Order ${order.id} · ${order.sellerName}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMutedLight,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    order.status,
                    style: AppTypography.caption.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.local_shipping_outlined,
                      size: 16,
                      color: AppColors.textMutedLight,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${order.carrier} · #${order.trackingNumber}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
