import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../data/repositories/tracking_repository_impl.dart';
import '../domain/models/shipment_models.dart';

final orderShipmentsProvider = FutureProvider.autoDispose
    .family<List<Shipment>, String>((ref, orderId) async {
      final result = await ref
          .watch(trackingRepositoryProvider)
          .listByOrder(orderId);
      return switch (result) {
        Success(:final value) => value,
        ResultFailure(:final failure) => throw failure,
      };
    });

final shipmentDetailProvider = FutureProvider.autoDispose
    .family<Shipment, String>((ref, shipmentId) async {
      final result = await ref
          .watch(trackingRepositoryProvider)
          .getShipment(shipmentId);
      return switch (result) {
        Success(:final value) => value,
        ResultFailure(:final failure) => throw failure,
      };
    });
