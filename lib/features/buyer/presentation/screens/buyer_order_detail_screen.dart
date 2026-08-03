import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../payment/domain/models/payment_models.dart';
import '../../application/buyer_orders_provider.dart';
import '../widgets/buyer_layout.dart';
import '../widgets/order_review_section.dart';
import '../widgets/order_tracking_section.dart';

/// Buyer order detail from GET /payment/orders/{orderId}.
class BuyerOrderDetailScreen extends ConsumerWidget {
  const BuyerOrderDetailScreen({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(buyerOrderDetailProvider(orderId));

    return BuyerLayout(
      title: 'Order details',
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          final message = e is Failure ? e.message : 'Order not found';
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message),
                TextButton(
                  onPressed: () => context.go(AppRouteNames.buyerOrders),
                  child: const Text('Back to orders'),
                ),
              ],
            ),
          );
        },
        data: (order) => ListView(
          padding: const EdgeInsets.all(AppSpacing.s16),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.go(AppRouteNames.buyerOrders),
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back',
                ),
                Expanded(
                  child: Text(
                    'Order ${order.id}',
                    style: AppTypography.title.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s8),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.primaryProductLabel,
                    style: AppTypography.headline.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sold by ${order.primarySellerName}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _StatusChip(status: order.status),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Items',
                    style: AppTypography.title.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final item in order.items) _ItemRow(item: item),
                ],
              ),
            ),
            if (order.pricing != null) ...[
              const SizedBox(height: 12),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pricing',
                      style: AppTypography.title.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _PriceRow(
                      'Subtotal',
                      '\$${order.pricing!.subtotal.toStringAsFixed(2)}',
                    ),
                    if (order.pricing!.promotionDiscount > 0)
                      _PriceRow(
                        'Promo',
                        '-\$${order.pricing!.promotionDiscount.toStringAsFixed(2)}',
                      ),
                    _PriceRow(
                      'GST',
                      AppCurrency.format(
                        order.pricing!.gst.toStringAsFixed(0),
                      ),
                    ),
                    _PriceRow(
                      'Transaction fee',
                      AppCurrency.format(
                        order.pricing!.transactionFee.toStringAsFixed(0),
                      ),
                    ),
                    _PriceRow(
                      'Platform fee',
                      AppCurrency.format(
                        order.pricing!.platformFee.toStringAsFixed(0),
                      ),
                    ),
                    if (order.pricing!.gemworldVerificationCommission > 0)
                      _PriceRow(
                        'GemWorld verification',
                        AppCurrency.format(
                          order.pricing!.gemworldVerificationCommission
                              .toStringAsFixed(0),
                        ),
                      ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        Text(
                          'Total',
                          style: AppTypography.label.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          AppCurrency.format(
                            (order.pricing!.totalInr > 0
                                    ? order.pricing!.totalInr
                                    : order.amount)
                                .toStringAsFixed(0),
                          ),
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.bronze,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            _Card(child: OrderTrackingSection(orderId: order.id)),
            const SizedBox(height: 12),
            _Card(child: OrderReviewSection(order: order)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: AppTypography.caption.copyWith(
          color: AppColors.info,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final PaymentOrderItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.sandSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: item.image != null
                ? CachedNetworkImage(
                    imageUrl: item.image!,
                    fit: BoxFit.cover,
                    memCacheWidth: 96,
                  )
                : const Icon(Icons.diamond_outlined, color: AppColors.bronze),
          ),
          const SizedBox(width: 10),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textMutedLight,
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

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warmBorder),
      ),
      child: child,
    );
  }
}
