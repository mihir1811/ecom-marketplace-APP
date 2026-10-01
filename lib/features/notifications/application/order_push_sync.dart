import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../buyer/application/buyer_orders_provider.dart';
import '../../refunds/application/refund_providers.dart';
import '../../seller/application/seller_orders_provider.dart';
import '../../tracking/application/order_shipments_provider.dart';
import '../domain/models/app_notification.dart';

/// True for pushes about an order, its shipment or its refund.
bool isOrderEvent(AppNotification notification) {
  final type = notification.type.toUpperCase();
  return type.startsWith('ORDER_') ||
      type.contains('REFUND') ||
      type.contains('SHIPMENT') ||
      type.contains('TRACKING') ||
      (notification.data['orderId'] ?? '').isNotEmpty;
}

/// Reloads every order view an incoming push affects.
///
/// The backend pushes `ORDER_ACCEPTED` / `ORDER_REJECTED` (and order, refund
/// and shipment events) over FCM the moment a seller acts. That push is the
/// app's realtime channel for orders: instead of polling, this invalidates
/// the matching providers so open screens refetch once and update in place.
void syncOrderViewsFromPush(Ref ref, AppNotification notification) {
  if (!isOrderEvent(notification)) return;
  final data = notification.data;
  final orderId = data['orderId'] ?? data['paymentOrderId'] ?? '';
  final sellerOrderId = data['sellerOrderId'] ?? '';

  // Buyer side.
  if (orderId.isNotEmpty) {
    ref.invalidate(buyerOrderDetailProvider(orderId));
    ref.invalidate(orderShipmentsProvider(orderId));
    ref.invalidate(orderRefundsProvider(orderId));
  }
  if (ref.exists(buyerOrdersProvider)) {
    ref.read(buyerOrdersProvider.notifier).loadInitial();
  }
  if (notification.type.toUpperCase().contains('REFUND')) {
    if (ref.exists(buyerRefundListProvider)) {
      ref.read(buyerRefundListProvider.notifier).refresh();
    }
    if (ref.exists(sellerRefundListProvider)) {
      ref.read(sellerRefundListProvider.notifier).refresh();
    }
  }

  // Seller side (no-ops for providers nobody is watching).
  refreshSellerOrderViews(ref, orderId: sellerOrderId);
  if (orderId.isNotEmpty && orderId != sellerOrderId) {
    ref.invalidate(sellerOrderDetailProvider(orderId));
  }
}
