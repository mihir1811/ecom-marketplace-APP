import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/l10n/app_localizations.dart';
import '../../../../payment/domain/models/payment_models.dart';
import '../../../../rewards/presentation/rewards_format.dart';
import '../../../../../core/router/app_navigation.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../seller/presentation/atelier/atelier_components.dart';
import '../../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../../seller/presentation/atelier/atelier_studio.dart';
import '../../../../seller/presentation/atelier/atelier_theme.dart';
import '../../maison/maison_kit.dart';

/// The pieces on the order with type, quantity, seller and line total.
class OrderItemsPanel extends StatelessWidget {
  const OrderItemsPanel({required this.order, super.key});

  final PaymentOrder order;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final items = order.items;
    final multiSeller =
        items.map((e) => e.sellerName).whereType<String>().toSet().length > 1;
    return AtelierPanel(
      overline: 'Pieces',
      title: items.length == 1
          ? context.tr(AccountCommerceL10n.orderItem)
          : context.tr(AccountCommerceL10n.itemsCount, {'count': items.length}),
      subtitle: context.tr(AccountCommerceL10n.soldBy, {
        'seller': order.primarySellerName,
      }),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const AtelierHairline(vertical: 12),
            Reveal(
              index: i,
              child: _ItemRow(item: items[i], showSeller: multiSeller),
            ),
          ],
          if (items.isEmpty)
            Text(
              'Item details are not available for this order.',
              style: AtelierType.caption(p.muted),
            ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.showSeller});

  final PaymentOrderItem item;
  final bool showSeller;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final type = item.productType.trim().replaceAll('_', ' ');
    final meta = [
      if (type.isNotEmpty) type[0].toUpperCase() + type.substring(1),
      if (item.quantity > 1)
        context.tr(AccountCommerceL10n.quantity, {'count': item.quantity}),
      if (showSeller && item.sellerName != null)
        context.tr(AccountCommerceL10n.soldBy, {'seller': item.sellerName}),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AtelierThumb(url: item.image, size: 64),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AtelierType.title(p.ink, size: 14.5),
              ),
              if (meta.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  meta.join('  ·  '),
                  maxLines: 2,
                  style: AtelierType.caption(p.muted, size: 12),
                ),
              ],
              if (item.isReturned) ...[
                const SizedBox(height: 8),
                const AtelierPill(
                  label: 'Returned',
                  tone: AtelierTone.amber,
                  icon: Icons.assignment_return_outlined,
                  dense: true,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          maisonUsd(item.lineTotal),
          style: AtelierType.figure(p.ink, size: 14.5),
        ),
      ],
    );
  }
}

/// Price breakdown as the API returned it, the total in both currencies
/// and the invoice.
class OrderPaymentPanel extends StatelessWidget {
  const OrderPaymentPanel({required this.order, super.key});

  final PaymentOrder order;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final pricing = order.pricing;
    final status = order.status.trim();
    final paid = status.toUpperCase() == 'PAID';
    final hasInvoice = order.invoiceUrl?.trim().isNotEmpty ?? false;

    return AtelierPanel(
      overline: 'Payment',
      title: context.tr(AccountCommerceL10n.orderSummary),
      trailing: AtelierPill(
        label: _titleCase(status),
        tone: paid
            ? AtelierTone.emerald
            : status.toUpperCase() == 'FAILED'
            ? AtelierTone.ruby
            : status.toUpperCase().contains('REFUND')
            ? AtelierTone.gold
            : AtelierTone.amber,
        dense: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (pricing != null)
            _Breakdown(
              pricing: pricing,
              amountUsd: order.amountUsd,
              amountInr: order.amount,
            )
          else
            _TotalRow(primary: maisonUsd(order.amountUsd)),
          if (order.rewardPoints.used > 0) ...[
            const SizedBox(height: 12),
            _Line(
              label: 'Paid with reward points',
              value: '−${maisonInr(order.rewardPoints.usedAmountInr)}',
              secondary: rewardPointsLabel(order.rewardPoints.used),
              valueColor: p.emerald,
            ),
          ],
          _RewardEarnNote(points: order.rewardPoints),
          if (hasInvoice) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: p.sunken,
                borderRadius: BorderRadius.circular(AtelierRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 20,
                        color: p.gold,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'INVOICE',
                              style: AtelierType.overline(p.muted),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              order.invoiceNumber?.trim().isNotEmpty == true
                                  ? order.invoiceNumber!
                                  : 'Tax invoice',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AtelierType.figure(p.ink, size: 13.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AtelierButton(
                    label: context.tr(AccountCommerceL10n.downloadInvoice),
                    icon: Icons.download_rounded,
                    compact: true,
                    expand: true,
                    onPressed: () => openOrderInvoice(context, order),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Breakdown extends StatelessWidget {
  const _Breakdown({
    required this.pricing,
    required this.amountUsd,
    required this.amountInr,
  });

  final PaymentOrderPricing pricing;
  final double amountUsd;
  final double amountInr;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final subtotalUsd = pricing.discountedSubtotal > 0
        ? pricing.discountedSubtotal
        : pricing.subtotal;
    final subtotalInr = pricing.subtotalInr;
    final totalUsd = pricing.totalUsd > 0 ? pricing.totalUsd : amountUsd;
    final totalInr = pricing.totalInr > 0 ? pricing.totalInr : amountInr;
    final rate = pricing.exchangeRate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pricing.subtotal > subtotalUsd && pricing.promotionDiscount > 0)
          _Line(
            label: context.tr(AccountCommerceL10n.itemsSubtotal),
            value: maisonUsd(pricing.subtotal),
          ),
        if (pricing.promotionDiscount > 0)
          _Line(
            label: 'Promotion',
            value: '−${maisonUsd(pricing.promotionDiscount)}',
            valueColor: p.emerald,
          ),
        _Line(
          label: 'Subtotal',
          value: subtotalInr > 0
              ? maisonInr(subtotalInr)
              : maisonUsd(subtotalUsd),
          secondary: subtotalInr > 0 ? maisonUsd(subtotalUsd) : null,
        ),
        if (pricing.gst > 0) _Line(label: 'GST', value: maisonInr(pricing.gst)),
        if (pricing.transactionFee > 0)
          _Line(
            label: context.tr(AccountCommerceL10n.transactionFee),
            value: maisonInr(pricing.transactionFee),
          ),
        if (pricing.platformFee > 0)
          _Line(
            label: context.tr(AccountCommerceL10n.platformFee),
            value: maisonInr(pricing.platformFee),
          ),
        if (pricing.gemworldVerificationCommission > 0)
          _Line(
            label: context.tr(AccountCommerceL10n.verificationFee),
            value: maisonInr(pricing.gemworldVerificationCommission),
          ),
        const AtelierHairline(vertical: 10),
        _TotalRow(
          primary: totalInr > 0 ? maisonInr(totalInr) : maisonUsd(totalUsd),
          secondary: totalInr > 0
              ? [
                  maisonUsd(totalUsd),
                  if (rate > 0) '1 USD = ₹${rate.toStringAsFixed(2)}',
                ].join('  ·  ')
              : null,
        ),
      ],
    );
  }
}

/// Whether this order earns points, and how many once it completes.
class _RewardEarnNote extends StatelessWidget {
  const _RewardEarnNote({required this.points});

  final PaymentOrderRewardPoints points;

  @override
  Widget build(BuildContext context) {
    if (!points.earnsPoints) return const SizedBox.shrink();
    final earned = points.earned;
    if (earned == 0) return const SizedBox.shrink();
    final pending = earned == null;
    final bonus = points.hasClubBonus
        ? ' ${points.clubName} bonus: '
              '${rewardMultiplierLabel(points.earnMultiplier)} points.'
        : '';
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: AtelierNotice(
        tone: pending ? AtelierTone.gold : AtelierTone.emerald,
        icon: pending
            ? Icons.hourglass_top_rounded
            : Icons.auto_awesome_outlined,
        text: pending
            ? "You'll earn reward points when this order is complete.$bonus"
            : 'Earned ${rewardPointsLabel(earned)} on this order.$bonus',
        actionLabel: 'Rewards',
        onAction: () => context.openRoute(AppRouteNames.buyerRewards),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    this.secondary,
    this.valueColor,
  });

  final String label;
  final String value;
  final String? secondary;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: AtelierType.body(p.inkSoft, size: 13)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: AtelierType.figure(valueColor ?? p.ink, size: 13.5),
              ),
              if (secondary != null)
                Text(secondary!, style: AtelierType.caption(p.muted, size: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.primary, this.secondary});

  final String primary;
  final String? secondary;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Total', style: AtelierType.title(p.ink, size: 15)),
          ),
        ),
        Flexible(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CountUpText(primary, style: AtelierType.display(p.ink, size: 28)),
              if (secondary != null)
                Text(
                  secondary!,
                  textAlign: TextAlign.end,
                  style: AtelierType.caption(p.muted, size: 11.5),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

String _titleCase(String raw) => raw
    .toLowerCase()
    .split('_')
    .where((w) => w.isNotEmpty)
    .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');

/// Opens the order's invoice in the browser; toasts when it cannot.
Future<void> openOrderInvoice(BuildContext context, PaymentOrder order) async {
  final raw = order.invoiceUrl?.trim();
  if (raw == null || raw.isEmpty) return;
  final messenger = ScaffoldMessenger.of(context);
  final palette = context.atelier;
  final failed = context.tr(AccountCommerceL10n.invoiceOpenFailed);
  final url = raw.toLowerCase().startsWith('www.') ? 'https://$raw' : raw;
  final uri = Uri.tryParse(url);
  var ok = false;
  if (uri != null) {
    try {
      ok = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
    } catch (_) {
      ok = false;
    }
  }
  if (!ok) {
    showMaisonToast(messenger, palette, failed, tone: AtelierTone.ruby);
  }
}
