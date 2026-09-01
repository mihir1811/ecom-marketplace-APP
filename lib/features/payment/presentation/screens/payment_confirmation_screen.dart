import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_top_bar.dart';
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
      backgroundColor: AppColors.bg(context),
      appBar: SimpleAppTopBar(
        title: context.tr(AccountCommerceL10n.orderConfirmation),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          final message = e is Failure
              ? e.message
              : context.tr(AccountCommerceL10n.couldNotLoadOrder);
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
                    child: Text(context.tr(AccountCommerceL10n.retry)),
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
              ? context.tr(AccountCommerceL10n.paymentSuccessful)
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
          _UsdPriceRow('Subtotal', pricing.subtotal),
          if (pricing.promotionDiscount > 0)
            _UsdPriceRow(
              context.tr(AccountCommerceL10n.promoDiscount),
              -pricing.promotionDiscount,
            ),
          _InrPriceRow('GST', pricing.gst),
          _InrPriceRow(
            context.tr(AccountCommerceL10n.transactionFee),
            pricing.transactionFee,
          ),
          _InrPriceRow(
            context.tr(AccountCommerceL10n.platformFee),
            pricing.platformFee,
          ),
          if (pricing.gemworldVerificationCommission > 0)
            _InrPriceRow(
              context.tr(AccountCommerceL10n.verificationFee),
              pricing.gemworldVerificationCommission,
            ),
          const Divider(height: 24),
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
                    AppCurrency.usd(
                      pricing.totalUsd > 0 ? pricing.totalUsd : order.amountUsd,
                    ),
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.bronze,
                    ),
                  ),
                  Text(
                    AppCurrency.inr(
                      pricing.totalInr > 0 ? pricing.totalInr : order.amount,
                    ),
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.bronze,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.s24),
        OrderReviewSection(order: order),
        const SizedBox(height: AppSpacing.s24),
        if (order.invoiceUrl != null && order.invoiceUrl!.isNotEmpty) ...[
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
              label: Text(context.tr(AccountCommerceL10n.downloadInvoice)),
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
        ],
        const SizedBox(height: AppSpacing.s32),
        FilledButton(
          onPressed: () {
            ref.invalidate(buyerOrdersProvider);
            context.resetTo(AppRouteNames.buyerOrders);
          },
          child: Text(context.tr(AccountCommerceL10n.viewMyOrders)),
        ),
        const SizedBox(height: AppSpacing.s8),
        OutlinedButton(
          onPressed: () => context.resetTo(AppRouteNames.home),
          child: Text(context.tr(AccountCommerceL10n.continueShopping)),
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
                ? AppNetworkImage(
                    url: item.image!,
                    fit: BoxFit.cover,
                    width: 56,
                    height: 56,
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
                if (item.quantity > 1)
                  Text(
                    context.tr(AccountCommerceL10n.quantity, {
                      'count': item.quantity,
                    }),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMutedLight,
                    ),
                  ),
                Text(
                  AppCurrency.usd(item.lineTotal),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w600,
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

class _UsdPriceRow extends StatelessWidget {
  const _UsdPriceRow(this.label, this.usdValue);

  final String label;
  final double usdValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          Text(
            AppCurrency.usd(usdValue),
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _InrPriceRow extends StatelessWidget {
  const _InrPriceRow(this.label, this.inrValue);

  final String label;
  final double inrValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          Text(
            AppCurrency.inr(inrValue, decimals: 0),
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
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
        SnackBar(
          // ignore: use_build_context_synchronously
          content: Text(context.tr(AccountCommerceL10n.invoiceOpenFailed)),
        ),
      );
    }
  } catch (_) {
    messenger.showSnackBar(
      SnackBar(
        // ignore: use_build_context_synchronously
        content: Text(context.tr(AccountCommerceL10n.invoiceOpenFailed)),
      ),
    );
  }
}
