import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/seller_orders_mock_data.dart';
import '../../domain/models/seller_orders_models.dart';
import '../widgets/seller_layout.dart';

class SellerOrdersScreen extends StatelessWidget {
  const SellerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
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
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: kSellerOrdersMock.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = kSellerOrdersMock[index];
              return _OrderSummaryCard(
                order: order,
                onTap: () => context.go(
                  AppRouteNames.sellerOrderDetailPath(order.id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.order, required this.onTap});

  final SellerOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warmWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.warmBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: AppTypography.body.copyWith(
                          color: AppColors.charcoal,
                        ),
                        children: [
                          const TextSpan(text: 'Order '),
                          TextSpan(
                            text: order.id,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      'Updated ${order.updatedAt}',
                      textAlign: TextAlign.right,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMutedLight,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${order.status} · ${order.carrier}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondaryLight,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.textMutedLight,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    order.location,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMutedLight,
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
}
