import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../seller/presentation/atelier/atelier_components.dart';
import '../../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../../seller/presentation/atelier/atelier_studio.dart';
import '../../../../seller/presentation/atelier/atelier_theme.dart';
import '../../../../tracking/application/order_shipments_provider.dart';
import '../../../../tracking/domain/models/shipment_models.dart';
import '../../maison/maison_kit.dart';

AtelierTone _shipmentTone(String status) {
  final s = status.trim().toUpperCase();
  if (s == ShipmentStatuses.delivered) return AtelierTone.emerald;
  if (s == ShipmentStatuses.cancelled) return AtelierTone.ruby;
  if (s == ShipmentStatuses.processing || s == ShipmentStatuses.packed) {
    return AtelierTone.amber;
  }
  return AtelierTone.sapphire;
}

String _titleCase(String raw) => raw
    .toLowerCase()
    .split(RegExp(r'[_\s]+'))
    .where((w) => w.isNotEmpty)
    .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');

/// Shipments for the order (`GET /tracking/orders/{orderId}`) with
/// carrier, tracking number, location, timeline and seller comments.
class OrderTrackingPanel extends ConsumerWidget {
  const OrderTrackingPanel({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.atelier;
    final async = ref.watch(orderShipmentsProvider(orderId));

    return AtelierPanel(
      overline: 'Delivery',
      title: context.tr(AccountCommerceL10n.shipmentTracking),
      child: async.when(
        skipLoadingOnReload: true,
        loading: () => const AtelierSkeletonCard(height: 96),
        error: (e, _) => AtelierNotice(
          text: e is Failure
              ? e.message
              : context.tr(AccountCommerceL10n.trackingLoadFailed),
          tone: AtelierTone.ruby,
          icon: Icons.error_outline_rounded,
          actionLabel: context.tr(AccountCommerceL10n.retry),
          onAction: () => ref.invalidate(orderShipmentsProvider(orderId)),
        ),
        data: (shipments) {
          if (shipments.isEmpty) {
            return Row(
              children: [
                const AtelierIconBadge(
                  icon: Icons.local_shipping_outlined,
                  tone: AtelierTone.neutral,
                  size: 44,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(AccountCommerceL10n.noShipment),
                        style: AtelierType.label(p.ink, size: 13.5),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Tracking appears here as soon as the seller '
                        'dispatches your piece.',
                        style: AtelierType.caption(p.muted, size: 12),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          return Column(
            children: [
              for (var i = 0; i < shipments.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                Reveal(
                  index: i,
                  child: _ShipmentCard(shipment: shipments[i]),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ShipmentCard extends ConsumerWidget {
  const _ShipmentCard({required this.shipment});

  final Shipment shipment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.atelier;
    final detail =
        ref.watch(shipmentDetailProvider(shipment.id)).asData?.value ??
        shipment;
    final updates = [...detail.updates]
      ..sort(
        (a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );
    final number = detail.trackingNumber?.trim();
    final location = detail.currentLocation?.trim();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.sunken,
        borderRadius: BorderRadius.circular(AtelierRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AtelierPill(
                label: _titleCase(detail.status),
                tone: _shipmentTone(detail.status),
                icon: Icons.local_shipping_outlined,
              ),
              const Spacer(),
              if (detail.carrier != null && detail.carrier!.trim().isNotEmpty)
                Flexible(
                  child: Text(
                    detail.carrier!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AtelierType.label(p.inkSoft, size: 12.5),
                  ),
                ),
            ],
          ),
          if ((number != null && number.isNotEmpty) ||
              (location != null && location.isNotEmpty)) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (number != null && number.isNotEmpty)
                  AtelierKeyValue(
                    label: 'Tracking no.',
                    value: number,
                    valueWidget: Pressable(
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final palette = context.atelier;
                        await atelierCopy(number);
                        showMaisonToast(
                          messenger,
                          palette,
                          'Tracking number copied',
                          icon: Icons.copy_rounded,
                        );
                      },
                      semanticLabel: 'Copy tracking number',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 200),
                            child: Text(
                              number,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AtelierType.figure(p.ink, size: 13.5),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Icon(Icons.copy_rounded, size: 13, color: p.gold),
                        ],
                      ),
                    ),
                  ),
                if (location != null && location.isNotEmpty)
                  AtelierKeyValue(label: 'Now at', value: location),
              ],
            ),
          ],
          if (updates.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('TIMELINE', style: AtelierType.overline(p.muted)),
            const SizedBox(height: 8),
            for (var i = 0; i < updates.length; i++)
              _TimelineRow(
                update: updates[i],
                latest: i == 0,
                isLast: i == updates.length - 1,
              ),
          ],
          if (detail.comments.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('FROM THE SELLER', style: AtelierType.overline(p.muted)),
            const SizedBox(height: 6),
            for (final c in detail.comments)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(AtelierRadius.sm),
                  border: Border(left: BorderSide(color: p.gold, width: 2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.body, style: AtelierType.body(p.inkSoft, size: 13)),
                    if (c.createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        atelierDateTime(c.createdAt!.toLocal()),
                        style: AtelierType.caption(p.muted, size: 11),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.update,
    required this.latest,
    required this.isLast,
  });

  final TrackingUpdate update;
  final bool latest;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final when = update.createdAt == null
        ? null
        : atelierDateTime(update.createdAt!.toLocal());
    final sub = [
      if (update.location != null && update.location!.trim().isNotEmpty)
        update.location!.trim(),
      ?when,
    ].join('  ·  ');
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 16,
            child: Column(
              children: [
                const SizedBox(height: 3),
                AnimatedContainer(
                  duration: AtelierMotion.base,
                  width: latest ? 12 : 8,
                  height: latest ? 12 : 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: latest ? p.gold : p.surface,
                    border: Border.all(color: latest ? p.gold : p.muted),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: p.hairline,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _titleCase(update.status),
                    style: AtelierType.label(
                      latest ? p.ink : p.inkSoft,
                      size: 13,
                    ),
                  ),
                  if (sub.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(sub, style: AtelierType.caption(p.muted, size: 11.5)),
                  ],
                  if (update.note != null && update.note!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        update.note!.trim(),
                        style: AtelierType.body(p.inkSoft, size: 12.5),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
