import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/l10n/app_localizations.dart';
import '../../../../payment/domain/models/payment_models.dart';
import '../../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../../seller/presentation/atelier/atelier_studio.dart';
import '../../../../seller/presentation/atelier/atelier_theme.dart';
import '../../maison/maison_kit.dart';
import 'order_journey.dart';
import '../../../../../core/theme/luxe_tokens.dart';

/// Shortcuts the hero offers.
enum OrderShortcut { tracking, invoice, refund, review }

/// Dark opening band of an order: live status, what it means, the total,
/// when it was placed, a copyable order number and shortcuts to the
/// sections below.
class OrderDetailHero extends ConsumerWidget {
  const OrderDetailHero({
    required this.order,
    required this.onShortcut,
    super.key,
  });

  final PaymentOrder order;
  final ValueChanged<OrderShortcut> onShortcut;

  bool get _paid {
    final s = order.status.toUpperCase();
    return s == 'PAID' || s == 'PARTIALLY_REFUNDED';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.atelier;
    final lifecycle = watchOrderLifecycle(ref, order);
    final tone = orderLifecycleTone(lifecycle.tone);
    final soft = p.onOnyx.withValues(alpha: 0.62);
    final pricing = order.pricing;
    final totalUsd = (pricing?.totalUsd ?? 0) > 0
        ? pricing!.totalUsd
        : order.amountUsd;
    final totalInr = order.isLiveAuction
        ? order.amount
        : (pricing?.totalInr ?? 0) > 0
        ? pricing!.totalInr
        : order.amount;
    final hasInvoice = order.invoiceUrl?.trim().isNotEmpty ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 640;
        return ClipRRect(
          borderRadius: BorderRadius.circular(AtelierRadius.xl),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: LuxeStage.vault,
              border: Border.all(
                color: p.isDark ? p.hairline : Colors.transparent,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Container(
                    height: 1.2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          p.tone(tone).withValues(alpha: 0),
                          p.tone(tone).withValues(alpha: 0.9),
                          p.tone(tone).withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 28 : 20,
                    wide ? 26 : 20,
                    wide ? 28 : 20,
                    wide ? 24 : 18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Reveal(child: _OrderNumber(orderId: order.id)),
                      const SizedBox(height: 14),
                      Reveal(
                        index: 1,
                        child: Padding(
                          padding: EdgeInsets.zero,
                          child: Row(
                            children: [
                              AtelierPulseDot(tone: tone, size: 8),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  lifecycle.headline,
                                  style: AtelierType.display(
                                    p.onOnyx,
                                    size: wide ? 40 : 30,
                                    weight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (lifecycle.message != null) ...[
                        const SizedBox(height: 8),
                        Reveal(
                          index: 2,
                          child: Padding(
                            padding: EdgeInsets.zero,
                            child: Text(
                              lifecycle.message!,
                              style: AtelierType.body(soft, size: 13.5),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Reveal(
                        index: 3,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TOTAL',
                                    style: AtelierType.overline(soft),
                                  ),
                                  const SizedBox(height: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: CountUpText(
                                      totalInr > 0
                                          ? maisonInr(totalInr)
                                          : maisonUsd(totalUsd),
                                      style: AtelierType.display(
                                        p.onOnyx,
                                        size: 32,
                                        weight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (order.isLiveAuction)
                                    Text(
                                      'Live show: '
                                      '${order.liveAuction?.showTitle ?? 'Live auction'}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AtelierType.caption(
                                        soft,
                                        size: 12,
                                      ),
                                    )
                                  else if (totalInr > 0)
                                    Text(
                                      maisonUsd(totalUsd),
                                      style: AtelierType.figure(soft, size: 12),
                                    ),
                                ],
                              ),
                            ),
                            if (order.createdAt != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'PLACED',
                                    style: AtelierType.overline(soft),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    atelierDate(order.createdAt!),
                                    style: AtelierType.label(
                                      p.onOnyx,
                                      size: 13.5,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Reveal(
                        index: 4,
                        child: Container(
                          height: 1,
                          color: p.onOnyx.withValues(alpha: 0.1),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Reveal(
                        index: 5,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _HeroChip(
                              icon: Icons.local_shipping_outlined,
                              label: 'Track',
                              onTap: () => onShortcut(OrderShortcut.tracking),
                            ),
                            if (hasInvoice)
                              _HeroChip(
                                icon: Icons.receipt_long_outlined,
                                label: 'Invoice',
                                onTap: () => onShortcut(OrderShortcut.invoice),
                              ),
                            if (_paid)
                              _HeroChip(
                                icon: Icons.replay_rounded,
                                label: context.tr(AccountCommerceL10n.refunds),
                                onTap: () => onShortcut(OrderShortcut.refund),
                              ),
                            if (order.status.toUpperCase() == 'PAID')
                              _HeroChip(
                                icon: Icons.star_outline_rounded,
                                label: 'Review',
                                onTap: () => onShortcut(OrderShortcut.review),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OrderNumber extends StatelessWidget {
  const _OrderNumber({required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final soft = p.onOnyx.withValues(alpha: 0.62);
    return Pressable(
      onTap: () async {
        final messenger = ScaffoldMessenger.of(context);
        final palette = context.atelier;
        final copied = context.tr(AccountCommerceL10n.orderIdCopied);
        await atelierCopy(orderId);
        showMaisonToast(messenger, palette, copied, icon: Icons.copy_rounded);
      },
      semanticLabel: context.tr(AccountCommerceL10n.copyOrderId),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('ORDER', style: AtelierType.overline(p.gold)),
          const SizedBox(width: 10),
          Text(
            maisonShortId(orderId),
            style: AtelierType.figure(p.onOnyx, size: 13),
          ),
          const SizedBox(width: 6),
          Icon(Icons.copy_rounded, size: 13, color: soft),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      borderRadius: BorderRadius.circular(AtelierRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: p.onOnyx.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AtelierRadius.pill),
          border: Border.all(color: p.onOnyx.withValues(alpha: 0.14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: p.gold),
            const SizedBox(width: 7),
            Text(label, style: AtelierType.label(p.onOnyx, size: 12.5)),
          ],
        ),
      ),
    );
  }
}
