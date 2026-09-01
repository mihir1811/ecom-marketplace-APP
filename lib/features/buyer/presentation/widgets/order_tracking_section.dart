import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../tracking/application/order_shipments_provider.dart';
import '../../../tracking/domain/models/shipment_models.dart';

/// Shipments + timeline for a paid order (`GET /tracking/orders/{orderId}`).
class OrderTrackingSection extends ConsumerWidget {
  const OrderTrackingSection({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(orderShipmentsProvider(orderId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr(AccountCommerceL10n.shipmentTracking),
          style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text(
            e is Failure
                ? e.message
                : context.tr(AccountCommerceL10n.trackingLoadFailed),
            style: AppTypography.caption.copyWith(color: AppColors.error),
          ),
          data: (shipments) {
            if (shipments.isEmpty) {
              return Text(
                context.tr(AccountCommerceL10n.noShipment),
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted(context),
                ),
              );
            }
            return Column(
              children: [for (final s in shipments) _ShipmentCard(shipment: s)],
            );
          },
        ),
      ],
    );
  }
}

class _ShipmentCard extends ConsumerWidget {
  const _ShipmentCard({required this.shipment});

  final Shipment shipment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(shipmentDetailProvider(shipment.id));
    final detail = detailAsync.asData?.value ?? shipment;
    final updates = detail.updates;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  detail.statusLabel,
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (detail.carrier != null && detail.carrier!.isNotEmpty)
                Text(
                  detail.carrier!,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted(context),
                  ),
                ),
            ],
          ),
          if (detail.trackingNumber != null &&
              detail.trackingNumber!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              context.tr(AccountCommerceL10n.trackingNumber, {
                'number': detail.trackingNumber,
              }),
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (detail.currentLocation != null &&
              detail.currentLocation!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              context.tr(AccountCommerceL10n.location, {
                'location': detail.currentLocation,
              }),
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
          ],
          if (updates.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Timeline',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            for (final u in updates) _TimelineRow(update: u),
          ],
          if (detail.comments.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Comments',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            for (final c in detail.comments)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  c.body,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.update});

  final TrackingUpdate update;

  @override
  Widget build(BuildContext context) {
    final date = update.createdAt;
    final dateLabel = date == null
        ? null
        : '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.circle, size: 8, color: AppColors.bronze),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  update.statusLabel,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (update.location != null && update.location!.isNotEmpty)
                  Text(
                    update.location!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted(context),
                    ),
                  ),
                if (update.note != null && update.note!.isNotEmpty)
                  Text(
                    update.note!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                if (dateLabel != null)
                  Text(
                    dateLabel,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted(context),
                      fontSize: 11,
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
