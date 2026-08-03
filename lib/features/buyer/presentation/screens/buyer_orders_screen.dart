import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../application/buyer_orders_provider.dart';
import '../../domain/models/buyer_order.dart';
import '../widgets/buyer_layout.dart';

/// Buyer orders list from GET /payment/orders.
class BuyerOrdersScreen extends ConsumerWidget {
  const BuyerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(buyerOrdersProvider);

    return BuyerLayout(
      title: 'Orders',
      child: RefreshIndicator(
        onRefresh: () => ref.read(buyerOrdersProvider.notifier).loadInitial(),
        child: state.isLoading && state.orders.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : state.errorMessage != null && state.orders.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.s24),
                    children: [
                      Text(state.errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: AppSpacing.s16),
                      Center(
                        child: FilledButton(
                          onPressed: () => ref
                              .read(buyerOrdersProvider.notifier)
                              .loadInitial(),
                          child: const Text('Retry'),
                        ),
                      ),
                    ],
                  )
                : state.orders.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 120),
                          Center(
                            child: Text(
                              'No orders yet',
                              style: AppTypography.body,
                            ),
                          ),
                        ],
                      )
                    : NotificationListener<ScrollNotification>(
                        onNotification: (n) {
                          if (n.metrics.pixels >=
                              n.metrics.maxScrollExtent - 200) {
                            ref.read(buyerOrdersProvider.notifier).loadMore();
                          }
                          return false;
                        },
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount:
                              state.orders.length + (state.hasMore ? 1 : 0),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            if (index >= state.orders.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final order = state.orders[index];
                            return _BuyerOrderCard(
                              order: order,
                              onTap: () => context.go(
                                AppRouteNames.buyerOrderDetailPath(order.id),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}

class _BuyerOrderCard extends StatelessWidget {
  const _BuyerOrderCard({required this.order, required this.onTap});

  final BuyerOrder order;
  final VoidCallback onTap;

  Color get _statusColor {
    final s = order.status.toUpperCase();
    if (s == 'PAID') return AppColors.success;
    if (s == 'PENDING') return AppColors.info;
    if (s.contains('REFUND')) return AppColors.bronze;
    if (s == 'FAILED') return AppColors.error;
    return AppColors.charcoalLight;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _statusColor;
    final date = order.createdAt;
    final dateLabel = date == null
        ? null
        : '${date.day}/${date.month}/${date.year}';

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
                    Expanded(
                      child: Text(
                        AppCurrency.format(
                          order.amountInr.toStringAsFixed(0),
                        ),
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (dateLabel != null)
                      Text(
                        dateLabel,
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
      ),
    );
  }
}
