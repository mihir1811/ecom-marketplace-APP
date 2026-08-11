import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/result.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../refunds/application/refund_providers.dart';
import '../../../refunds/domain/models/refund_request.dart';
import '../widgets/buyer_layout.dart';

class BuyerRefundsScreen extends ConsumerWidget {
  const BuyerRefundsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(buyerRefundListProvider);

    return BuyerLayout(
      title: 'Refunds',
      child: RefreshIndicator(
        onRefresh: () => ref.read(buyerRefundListProvider.notifier).refresh(),
        child: state.isLoading && state.items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : state.errorMessage != null && state.items.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.s24),
                    children: [
                      Text(state.errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: AppSpacing.s16),
                      Center(
                        child: FilledButton(
                          onPressed: () => ref
                              .read(buyerRefundListProvider.notifier)
                              .refresh(),
                          child: const Text('Retry'),
                        ),
                      ),
                    ],
                  )
                : state.items.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 120),
                          Center(
                            child: Text(
                              'No refund requests yet',
                              style: AppTypography.body,
                            ),
                          ),
                        ],
                      )
                    : NotificationListener<ScrollNotification>(
                        onNotification: (n) {
                          if (n.metrics.pixels >=
                              n.metrics.maxScrollExtent - 200) {
                            ref
                                .read(buyerRefundListProvider.notifier)
                                .loadMore();
                          }
                          return false;
                        },
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount:
                              state.items.length + (state.hasMore ? 1 : 0),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            if (index >= state.items.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            return _BuyerRefundCard(
                              refund: state.items[index],
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}

class _BuyerRefundCard extends ConsumerWidget {
  const _BuyerRefundCard({required this.refund});

  final RefundRequest refund;

  Color get _statusColor => switch (refund.status) {
        RefundStatus.pending => AppColors.bronze,
        RefundStatus.accepted => AppColors.success,
        RefundStatus.rejected => AppColors.error,
        RefundStatus.cancelled => AppColors.charcoalLight,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mutating = ref.watch(refundMutationProvider).isLoading;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warmBorder),
        boxShadow: AppShadows.cardLight,
      ),
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.replay, color: _statusColor, size: 20),
              const SizedBox(width: 8),
              Text(
                refund.status.label,
                style: AppTypography.label.copyWith(
                  color: _statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                AppCurrency.usd(refund.amount),
                style: AppTypography.title.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Seller · ${refund.sellerLabel}',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMutedLight,
            ),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => context.go(
              AppRouteNames.buyerOrderDetailPath(refund.orderId),
            ),
            child: Text(
              'Order ${refund.orderId}',
              style: AppTypography.body.copyWith(
                color: AppColors.bronzeDark,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            refund.reason,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          if (refund.sellerNote != null) ...[
            const SizedBox(height: 8),
            Text(
              'Seller note: ${refund.sellerNote}',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMutedLight,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Requested ${refund.createdAtLabel}',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMutedLight,
            ),
          ),
          if (refund.canCancel) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: mutating
                  ? null
                  : () async {
                      final result = await ref
                          .read(refundMutationProvider.notifier)
                          .cancel(refund.id);
                      if (!context.mounted) return;
                      final messenger = ScaffoldMessenger.of(context);
                      switch (result) {
                        case Success():
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Refund request cancelled'),
                            ),
                          );
                        case ResultFailure(failure: final failure):
                          messenger.showSnackBar(
                            SnackBar(content: Text(failure.message)),
                          );
                      }
                    },
              child: const Text('Cancel request'),
            ),
          ],
        ],
      ),
    );
  }
}
