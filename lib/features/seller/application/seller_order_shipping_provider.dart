import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../tracking/application/order_shipments_provider.dart';
import '../../tracking/data/repositories/tracking_repository_impl.dart';
import '../../tracking/domain/models/shipment_models.dart';

/// The seller's shipments for one marketplace order.
///
/// Uses the seller shipment list first and falls back to the per-order
/// tracking route, which the API also serves to the order's seller.
final sellerOrderShipmentsProvider = FutureProvider.autoDispose
    .family<List<Shipment>, String>((ref, orderId) async {
      final repo = ref.watch(trackingRepositoryProvider);
      final seller = await repo.listSellerShipments(orderId: orderId);
      if (seller case Success(:final value) when value.isNotEmpty) {
        return value;
      }
      final byOrder = await repo.listByOrder(orderId);
      return switch ((seller, byOrder)) {
        (_, Success(:final value)) => value,
        (Success(:final value), _) => value,
        (ResultFailure(:final failure), _) => throw failure,
      };
    });

/// `true` while a shipment create / update is in flight.
class SellerShipmentActionsNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  Future<Result<Shipment, Failure>> save({
    required String orderId,
    required Shipment? existing,
    required String status,
    String? currentLocation,
    String? carrier,
    String? trackingNumber,
    String? note,
  }) async {
    if (state) {
      return Result.failure(
        const ValidationFailure('An update is already being saved.'),
      );
    }
    final allowed = ShipmentStatuses.nextOptions(existing?.status);
    if (!allowed.contains(status)) {
      return Result.failure(
        ValidationFailure(
          'A shipment cannot move from '
          '${ShipmentStatuses.label(existing?.status ?? '')} to '
          '${ShipmentStatuses.label(status)}.',
        ),
      );
    }
    state = true;
    try {
      final repo = ref.read(trackingRepositoryProvider);
      final result = existing == null
          ? await repo.createShipment(
              orderId: orderId,
              status: status,
              currentLocation: currentLocation,
              carrier: carrier,
              trackingNumber: trackingNumber,
              note: note,
            )
          : await repo.updateShipment(
              shipmentId: existing.id,
              status: status,
              currentLocation: currentLocation,
              carrier: carrier,
              trackingNumber: trackingNumber,
              note: note,
            );
      ref.invalidate(sellerOrderShipmentsProvider(orderId));
      ref.invalidate(orderShipmentsProvider(orderId));
      if (existing != null) ref.invalidate(shipmentDetailProvider(existing.id));
      return result;
    } finally {
      state = false;
    }
  }
}

final sellerShipmentActionsProvider =
    NotifierProvider<SellerShipmentActionsNotifier, bool>(
      SellerShipmentActionsNotifier.new,
    );
