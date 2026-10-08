import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_localizations.dart';
import '../../../../seller/presentation/atelier/atelier_components.dart';
import '../../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../../seller/presentation/atelier/atelier_studio.dart';
import '../../../../seller/presentation/atelier/atelier_theme.dart';
import '../../../domain/buyer_order_status.dart';
import '../../../domain/models/buyer_order.dart';
import '../../maison/maison_kit.dart';

/// Status colour for a buyer order stage.
AtelierTone buyerStageTone(BuyerOrderStage stage) => switch (stage) {
  BuyerOrderStage.paymentPending => AtelierTone.amber,
  BuyerOrderStage.awaitingSeller => AtelierTone.sapphire,
  BuyerOrderStage.confirmed => AtelierTone.emerald,
  BuyerOrderStage.refunded => AtelierTone.gold,
  BuyerOrderStage.issue => AtelierTone.ruby,
  BuyerOrderStage.other => AtelierTone.neutral,
};

IconData buyerStageIcon(BuyerOrderStage stage) => switch (stage) {
  BuyerOrderStage.paymentPending => Icons.schedule_rounded,
  BuyerOrderStage.awaitingSeller => Icons.hourglass_top_rounded,
  BuyerOrderStage.confirmed => Icons.check_circle_rounded,
  BuyerOrderStage.refunded => Icons.replay_rounded,
  BuyerOrderStage.issue => Icons.error_outline_rounded,
  BuyerOrderStage.other => Icons.info_outline_rounded,
};

/// One order in the buyer list: piece, seller, value, status and the
/// next thing that will happen.
class BuyerOrderCard extends StatelessWidget {
  const BuyerOrderCard({required this.order, required this.onTap, super.key});

  final BuyerOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final stage = buyerOrderStage(order);
    final tone = buyerStageTone(stage);
    final accent = p.tone(tone);
    final waiting =
        stage == BuyerOrderStage.paymentPending ||
        stage == BuyerOrderStage.awaitingSeller;
    final attention = stage == BuyerOrderStage.issue;
    final label = buyerOrderStageLabel(order);
    final items = order.itemCount <= 0
        ? null
        : context.tr(
            order.itemCount == 1
                ? AccountCommerceL10n.itemCount
                : AccountCommerceL10n.itemsCount,
            {'count': order.itemCount},
          );

    return Pressable(
      onTap: onTap,
      semanticLabel:
          '${order.productLabel}, ${maisonUsd(order.amountUsd)}, $label',
      borderRadius: BorderRadius.circular(AtelierRadius.lg),
      child: AnimatedContainer(
        duration: AtelierMotion.base,
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(AtelierRadius.lg),
          border: Border.all(
            color: attention ? accent.withValues(alpha: 0.4) : p.hairline,
          ),
          boxShadow: p.softShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (waiting)
              Container(
                height: 2,
                decoration: BoxDecoration(gradient: p.goldGradient),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AtelierThumb(url: order.imageUrl, size: 68),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              maisonShortId(order.id),
                              style: AtelierType.figure(p.muted, size: 11.5),
                            ),
                            const SizedBox(width: 8),
                            if (order.createdAt != null)
                              Expanded(
                                child: Tooltip(
                                  message: atelierDate(order.createdAt!),
                                  child: Text(
                                    maisonRelative(order.createdAt),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                    style: AtelierType.caption(
                                      p.muted,
                                      size: 11.5,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          order.productLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AtelierType.title(p.ink, size: 15.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ['By ${order.sellerName}', ?items].join('  ·  '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AtelierType.caption(p.inkSoft, size: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: p.hairline,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AtelierPill(
                          label: label,
                          tone: tone,
                          icon: buyerStageIcon(stage),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                buyerOrderNextStep(order),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AtelierType.caption(p.muted, size: 11.5),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 13,
                              color: p.gold,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            maisonUsd(order.amountUsd),
                            style: AtelierType.display(p.ink, size: 24),
                          ),
                          if (order.amountInr > 0)
                            Text(
                              maisonInr(order.amountInr),
                              style: AtelierType.figure(p.muted, size: 11),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
