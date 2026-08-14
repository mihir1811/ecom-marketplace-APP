import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../payment/domain/models/payment_models.dart';
import '../../../refunds/application/refund_providers.dart';
import '../../../tracking/application/order_shipments_provider.dart';
import '../../../tracking/domain/models/shipment_models.dart';
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
                    'Order',
                    style: AppTypography.title.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: order.id));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Order ID copied')),
                    );
                  },
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  label: const Text('Copy order id'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.bronze,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s8),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.items.length == 1
                                  ? 'Order item'
                                  : '${order.items.length} items',
                              style: AppTypography.title.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sold by ${order.primarySellerName}',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _StatusChip(status: order.status),
                          if (order.createdAt != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Placed ${_formatOrderDate(order.createdAt!)}',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textMutedLight,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  for (var i = 0; i < order.items.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    _ItemRow(
                      item: order.items[i],
                      showSeller: order.items.length > 1 &&
                          (order.items[i].sellerName?.isNotEmpty ?? false),
                    ),
                  ],
                ],
              ),
            ),
            if (order.pricing != null) ...[
              const SizedBox(height: 12),
              _Card(
                child: _OrderPricingSummary(
                  pricing: order.pricing!,
                  amountUsd: order.amountUsd,
                  amountInr: order.amount,
                ),
              ),
              if (order.invoiceUrl != null && order.invoiceUrl!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (order.invoiceNumber != null &&
                          order.invoiceNumber!.isNotEmpty) ...[
                        Text(
                          'Invoice ${order.invoiceNumber}',
                          style: AppTypography.label.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s12),
                      ],
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.charcoal,
                            foregroundColor: AppColors.warmWhite,
                          ),
                          onPressed: () => _downloadInvoice(context, order),
                          icon: const Icon(Icons.download_outlined, size: 20),
                          label: const Text('Download invoice'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
            const SizedBox(height: 12),
            _Card(child: OrderTrackingSection(orderId: order.id)),
            const SizedBox(height: 12),
            _Card(child: _OrderRefundSection(order: order)),
            const SizedBox(height: 12),
            _Card(child: OrderReviewSection(order: order)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _OrderRefundSection extends ConsumerWidget {
  const _OrderRefundSection({required this.order});

  final PaymentOrder order;

  List<({String sellerId, String sellerName})> get _sellerTargets {
    final seen = <String>{};
    final targets = <({String sellerId, String sellerName})>[];
    for (final seller in order.sellers) {
      if (seller.id.isEmpty || !seen.add(seller.id)) continue;
      targets.add((sellerId: seller.id, sellerName: seller.companyName));
    }
    for (final item in order.items) {
      final id = item.sellerId;
      if (id == null || id.isEmpty || !seen.add(id)) continue;
      targets.add((
        sellerId: id,
        sellerName: item.sellerName?.trim().isNotEmpty == true
            ? item.sellerName!
            : 'Seller',
      ));
    }
    return targets;
  }

  bool get _isPaid => order.status.toUpperCase() == 'PAID';

  bool _shipmentBlocksRefund(List<Shipment> shipments) {
    return shipments.any(
      (s) => ShipmentStatuses.blocksBuyerRefund(s.status),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_isPaid) {
      return Text(
        'Refunds are available after payment succeeds, and only before '
        'out for delivery.',
        style: AppTypography.caption.copyWith(
          color: AppColors.textMutedLight,
        ),
      );
    }

    final shipmentsAsync = ref.watch(orderShipmentsProvider(order.id));
    return shipmentsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => _buildRefundActions(
        context,
        ref,
        refundBlocked: false,
      ),
      data: (shipments) => _buildRefundActions(
        context,
        ref,
        refundBlocked: _shipmentBlocksRefund(shipments),
      ),
    );
  }

  Widget _buildRefundActions(
    BuildContext context,
    WidgetRef ref, {
    required bool refundBlocked,
  }) {
    if (refundBlocked) {
      return Text(
        'Refunds are no longer available once the order is out for delivery '
        'or delivered.',
        style: AppTypography.caption.copyWith(
          color: AppColors.textMutedLight,
        ),
      );
    }

    final targets = _sellerTargets;
    if (targets.isEmpty) {
      return Text(
        'Seller details are not available for a refund on this order yet.',
        style: AppTypography.caption.copyWith(
          color: AppColors.textMutedLight,
        ),
      );
    }

    final mutating = ref.watch(refundMutationProvider).isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Refunds',
          style: AppTypography.label.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Request a refund for a seller portion of this paid order. '
          'Not available after out for delivery.',
          style: AppTypography.caption.copyWith(
            color: AppColors.textMutedLight,
          ),
        ),
        const SizedBox(height: 12),
        for (final target in targets) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: mutating
                  ? null
                  : () => _requestRefund(
                        context,
                        ref,
                        sellerId: target.sellerId,
                        sellerName: target.sellerName,
                      ),
              icon: const Icon(Icons.replay, size: 18),
              label: Text('Request refund · ${target.sellerName}'),
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextButton(
          onPressed: () => context.go(AppRouteNames.buyerRefunds),
          child: const Text('View my refund requests'),
        ),
      ],
    );
  }

  Future<void> _requestRefund(
    BuildContext context,
    WidgetRef ref, {
    required String sellerId,
    required String sellerName,
  }) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Refund · $sellerName'),
        content: TextField(
          controller: reasonController,
          maxLines: 4,
          maxLength: 2000,
          decoration: const InputDecoration(
            labelText: 'Reason',
            hintText: 'Why are you requesting a refund?',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    final reason = reasonController.text.trim();
    reasonController.dispose();
    if (confirmed != true || !context.mounted) return;
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a refund reason')),
      );
      return;
    }

    final result = await ref.read(refundMutationProvider.notifier).create(
          orderId: order.id,
          sellerId: sellerId,
          reason: reason,
        );
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case Success():
        messenger.showSnackBar(
          const SnackBar(content: Text('Refund request submitted')),
        );
      case ResultFailure(failure: final failure):
        messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
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
  const _ItemRow({required this.item, this.showSeller = false});

  final PaymentOrderItem item;
  final bool showSeller;

  @override
  Widget build(BuildContext context) {
    final typeLabel = item.productType.trim().isEmpty
        ? null
        : item.productType.replaceAll('_', ' ');
    final meta = [
      if (typeLabel != null) typeLabel,
      if (item.quantity > 1) 'Qty ${item.quantity}',
      if (showSeller && item.sellerName != null) 'Sold by ${item.sellerName}',
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.sandSurface,
            borderRadius: BorderRadius.circular(10),
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
        const SizedBox(width: 12),
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
                  fontSize: 15,
                ),
              ),
              if (meta.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  meta.join(' · '),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMutedLight,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                AppCurrency.usd(item.lineTotal),
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _formatOrderDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

/// Pricing card UI aligned with cart ORDER SUMMARY; values come from the API.
class _OrderPricingSummary extends StatelessWidget {
  const _OrderPricingSummary({
    required this.pricing,
    required this.amountUsd,
    required this.amountInr,
  });

  final PaymentOrderPricing pricing;
  final double amountUsd;
  final double amountInr;

  @override
  Widget build(BuildContext context) {
    final subtotalUsd = pricing.discountedSubtotal > 0
        ? pricing.discountedSubtotal
        : pricing.subtotal;
    final subtotalInr = pricing.subtotalInr;
    final totalUsd = pricing.totalUsd > 0 ? pricing.totalUsd : amountUsd;
    final totalInr = pricing.totalInr > 0 ? pricing.totalInr : amountInr;
    final rate = pricing.exchangeRate;
    final hasRate = rate > 0;
    final liveRateLabel =
        hasRate ? 'Live rate · 1 USD = ₹${rate.toStringAsFixed(2)}' : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ORDER SUMMARY',
          style: AppTypography.caption.copyWith(
            color: AppColors.textMutedLight,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        if (pricing.subtotal > subtotalUsd && pricing.promotionDiscount > 0)
          _MoneyRow(
            label: 'Items subtotal',
            primary: AppCurrency.usd(pricing.subtotal),
          ),
        if (pricing.promotionDiscount > 0)
          _MoneyRow(
            label: 'Promo',
            primary: AppCurrency.usd(-pricing.promotionDiscount),
          ),
        _MoneyRow(
          label: 'Subtotal',
          primary: subtotalInr > 0
              ? _inrLabel(subtotalInr)
              : AppCurrency.usd(subtotalUsd),
          secondary: subtotalInr > 0 ? AppCurrency.usd(subtotalUsd) : null,
        ),
        if (pricing.gst > 0)
          _MoneyRow(label: 'GST', primary: _inrLabel(pricing.gst)),
        if (pricing.transactionFee > 0)
          _MoneyRow(
            label: 'Transaction fee',
            primary: _inrLabel(pricing.transactionFee),
          ),
        if (pricing.platformFee > 0)
          _MoneyRow(
            label: 'Platform fee',
            primary: _inrLabel(pricing.platformFee),
          ),
        if (pricing.gemworldVerificationCommission > 0)
          _MoneyRow(
            label: 'GemWorld verification',
            primary: _inrLabel(pricing.gemworldVerificationCommission),
          ),
        const Divider(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total',
              style: AppTypography.label.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  totalInr > 0 ? _inrLabel(totalInr) : AppCurrency.usd(totalUsd),
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.bronze,
                  ),
                ),
                if (totalInr > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    liveRateLabel == null
                        ? AppCurrency.usd(totalUsd)
                        : '${AppCurrency.usd(totalUsd)} · $liveRateLabel',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMutedLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }

  String _inrLabel(double amount) =>
      '${AppCurrency.inrSymbol}${formatGroupedWhole(amount.roundToDouble())}';
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.primary,
    this.secondary,
  });

  final String label;
  final String primary;
  final String? secondary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                primary,
                style: AppTypography.label.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (secondary != null)
                Text(
                  secondary!,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMutedLight,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _downloadInvoice(BuildContext context, PaymentOrder order) async {
  final raw = order.invoiceUrl;
  if (raw == null || raw.trim().isEmpty) return;
  var url = raw.trim();
  if (url.toLowerCase().startsWith('www.')) url = 'https://$url';
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  final messenger = ScaffoldMessenger.of(context);
  try {
    final ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open the invoice.')),
      );
    }
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Could not open the invoice.')),
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
