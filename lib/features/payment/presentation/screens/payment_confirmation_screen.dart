import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../buyer/application/buyer_orders_provider.dart';
import '../../../buyer/presentation/widgets/order_review_section.dart';
import '../../application/payment_checkout_provider.dart';
import '../../domain/models/payment_models.dart';

/// Fallback confirmation route — success dialog normally goes to orders.
class PaymentConfirmationScreen extends ConsumerWidget {
  const PaymentConfirmationScreen({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(orderDetailProvider(orderId));

    return AppScaffold(
      backgroundColor: AppColors.creamBg,
      appBar: AppBar(
        title: Text(
          'Order confirmation',
          style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          final message = e is Failure ? e.message : 'Could not load order.';
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.s16),
                  FilledButton(
                    onPressed: () =>
                        ref.invalidate(orderDetailProvider(orderId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        },
        data: (order) => _OrderBody(order: order),
      ),
    );
  }
}

class _OrderBody extends ConsumerWidget {
  const _OrderBody({required this.order});

  final PaymentOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pricing = order.pricing;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s16),
      children: [
        Icon(
          order.status.toUpperCase() == 'PAID'
              ? Icons.check_circle_outline
              : Icons.hourglass_bottom,
          size: 56,
          color: AppColors.bronze,
        ),
        const SizedBox(height: AppSpacing.s12),
        Text(
          order.status.toUpperCase() == 'PAID'
              ? 'Payment successful'
              : 'Order ${order.status}',
          textAlign: TextAlign.center,
          style: AppTypography.title.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'Order ID ${order.id}',
          textAlign: TextAlign.center,
          style: AppTypography.caption.copyWith(
            color: AppColors.textMutedLight,
          ),
        ),
        const SizedBox(height: AppSpacing.s24),
        ...order.items.map((item) => _ItemTile(item: item)),
        if (pricing != null) ...[
          const SizedBox(height: AppSpacing.s16),
          _PriceRow('Subtotal (USD)', '\$${pricing.subtotal.toStringAsFixed(2)}'),
          if (pricing.promotionDiscount > 0)
            _PriceRow(
              'Promo discount',
              '-\$${pricing.promotionDiscount.toStringAsFixed(2)}',
            ),
          _PriceRow('GST', AppCurrency.format(pricing.gst.toStringAsFixed(0))),
          _PriceRow(
            'Transaction fee',
            AppCurrency.format(pricing.transactionFee.toStringAsFixed(0)),
          ),
          _PriceRow(
            'Platform fee',
            AppCurrency.format(pricing.platformFee.toStringAsFixed(0)),
          ),
          if (pricing.gemworldVerificationCommission > 0)
            _PriceRow(
              'GemWorld verification',
              AppCurrency.format(
                pricing.gemworldVerificationCommission.toStringAsFixed(0),
              ),
            ),
          const Divider(height: 24),
          Row(
            children: [
              Text(
                'Total',
                style: AppTypography.label.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Text(
                AppCurrency.format(
                  (pricing.totalInr > 0 ? pricing.totalInr : order.amount)
                      .toStringAsFixed(0),
                ),
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.bronze,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.s24),
        OrderReviewSection(order: order),
        const SizedBox(height: AppSpacing.s32),
        FilledButton(
          onPressed: () {
            ref.invalidate(buyerOrdersProvider);
            context.go(AppRouteNames.buyerOrders);
          },
          child: const Text('View my orders'),
        ),
        const SizedBox(height: AppSpacing.s8),
        OutlinedButton(
          onPressed: () => context.go(AppRouteNames.home),
          child: const Text('Continue shopping'),
        ),
      ],
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item});

  final PaymentOrderItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s12),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.sandSurface,
              borderRadius: BorderRadius.circular(AppSpacing.r12),
            ),
            clipBehavior: Clip.antiAlias,
            child: item.image != null
                ? CachedNetworkImage(
                    imageUrl: item.image!,
                    fit: BoxFit.cover,
                    memCacheWidth: 112,
                  )
                : const Icon(Icons.diamond_outlined, color: AppColors.bronze),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Qty ${item.quantity} · \$${item.lineTotal.toStringAsFixed(2)}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
          Text(
            value,
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
