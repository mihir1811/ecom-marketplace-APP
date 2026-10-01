import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/seller_orders_provider.dart';

/// Compact dashboard card: how many orders await approval, and a link to the
/// Orders screen where they are managed. Full lists live there only.
class SellerDashboardOrdersSummary extends ConsumerWidget {
  const SellerDashboardOrdersSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(sellerPendingOrdersProvider);
    final count = pending.asData?.value.total;
    final hasPending = (count ?? 0) > 0;
    final accent = hasPending ? AppColors.bronze : AppColors.success;

    final subtitle = pending.when(
      skipLoadingOnReload: true,
      loading: () => 'Checking for new orders…',
      error: (_, _) => 'Could not load order count.',
      data: (page) => page.total == 0
          ? 'No orders are waiting for your approval.'
          : page.total == 1
          ? '1 order is waiting for your approval.'
          : '${page.total} orders are waiting for your approval.',
    );

    return Material(
      color: AppColors.card(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        side: BorderSide(color: AppColors.border(context)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        onTap: () => context.openRoute(AppRouteNames.sellerOrders),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  hasPending
                      ? Icons.hourglass_top_outlined
                      : Icons.task_alt_outlined,
                  color: accent,
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasPending ? 'Orders ($count pending)' : 'Orders',
                      style: AppTypography.title.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (pending.hasError)
                IconButton(
                  tooltip: 'Retry',
                  onPressed: () => ref.invalidate(sellerPendingOrdersProvider),
                  icon: const Icon(Icons.refresh),
                )
              else
                TextButton(
                  onPressed: () =>
                      context.openRoute(AppRouteNames.sellerOrders),
                  child: const Text('Manage'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
