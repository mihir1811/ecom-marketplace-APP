import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../domain/models/marketplace_order.dart';

/// Website wording for a piece / shipment / update status.
String jewelryStepLabel(BuildContext context, String status) =>
    context.tr(switch (status) {
      MarketplaceStepStatus.placed => JewelryMarketL10n.stepPlaced,
      MarketplaceStepStatus.accepted => JewelryMarketL10n.stepAccepted,
      MarketplaceStepStatus.inProduction => JewelryMarketL10n.stepInProduction,
      MarketplaceStepStatus.qualityCheck => JewelryMarketL10n.stepQualityCheck,
      MarketplaceStepStatus.readyToShip => JewelryMarketL10n.stepPacked,
      MarketplaceStepStatus.shipped => JewelryMarketL10n.stepShipped,
      MarketplaceStepStatus.outForDelivery =>
        JewelryMarketL10n.stepOutForDelivery,
      MarketplaceStepStatus.delivered => JewelryMarketL10n.stepDelivered,
      MarketplaceStepStatus.cancelled => JewelryMarketL10n.stepCancelled,
      _ => JewelryMarketL10n.stepPlaced,
    });

/// Order-level pill: awaiting payment, cancelled, or the furthest-behind
/// shipment step once paid.
class JewelryOrderStatusPill extends StatelessWidget {
  const JewelryOrderStatusPill({required this.order, super.key});

  final MarketplaceOrder order;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final (String label, Color tone) = switch (order.status) {
      MarketplaceOrderStatus.pendingPayment => (
        context.tr(JewelryMarketL10n.awaitingPayment),
        p.caution,
      ),
      MarketplaceOrderStatus.cancelled => (
        context.tr(JewelryMarketL10n.stepCancelled),
        p.inkMuted,
      ),
      MarketplaceOrderStatus.failed => (
        context.tr(JewelryMarketL10n.paymentFailed),
        p.caution,
      ),
      _ =>
        order.shipments.isEmpty
            ? (context.tr(JewelryMarketL10n.stepPlaced), p.positive)
            : (
                jewelryStepLabel(context, order.shipments.first.status),
                order.shipments.first.status == MarketplaceStepStatus.delivered
                    ? p.positive
                    : p.accent,
              ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: ShapeDecoration(
        color: tone.withValues(alpha: 0.12),
        shape: const StadiumBorder(),
      ),
      child: Text(label, style: LuxeType.label(tone, size: 11.5)),
    );
  }
}
