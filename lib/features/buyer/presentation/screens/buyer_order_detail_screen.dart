import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../payment/domain/models/payment_models.dart';
import '../../../refunds/application/refund_providers.dart';
import '../../../seller/presentation/atelier/atelier_components.dart';
import '../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import '../../../tracking/application/order_shipments_provider.dart';
import '../../application/buyer_orders_provider.dart';
import '../maison/maison_kit.dart';
import '../maison/maison_layout.dart';
import '../widgets/order_detail/order_detail_hero.dart';
import '../widgets/order_detail/order_journey.dart';
import '../widgets/order_detail/order_refund_panels.dart';
import '../widgets/order_detail/order_review_panel.dart';
import '../widgets/order_detail/order_summary_panels.dart';
import '../widgets/order_detail/order_tracking_panel.dart';

/// Buyer order detail from GET /payment/orders/{orderId}.
///
/// Seller decisions, shipments and refunds arrive as FCM pushes, which
/// invalidate this order's providers (see `syncOrderViewsFromPush`), so the
/// status updates in place. Returning to the app also reloads it, covering
/// platforms without push.
class BuyerOrderDetailScreen extends ConsumerStatefulWidget {
  const BuyerOrderDetailScreen({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<BuyerOrderDetailScreen> createState() =>
      _BuyerOrderDetailScreenState();
}

class _BuyerOrderDetailScreenState
    extends ConsumerState<BuyerOrderDetailScreen> {
  late final AppLifecycleListener _lifecycle;
  final _trackingKey = GlobalKey();
  final _refundKey = GlobalKey();
  final _reviewKey = GlobalKey();

  String get orderId => widget.orderId;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _reload);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    ref.invalidate(orderShipmentsProvider(orderId));
    ref.invalidate(orderRefundsProvider(orderId));
    try {
      ref.invalidate(buyerOrderDetailProvider(orderId));
      await ref.read(buyerOrderDetailProvider(orderId).future);
    } catch (_) {
      // The error state below shows the failure.
    }
  }

  void _onShortcut(OrderShortcut shortcut, PaymentOrder order) {
    final key = switch (shortcut) {
      OrderShortcut.invoice => null,
      OrderShortcut.tracking => _trackingKey,
      OrderShortcut.refund => _refundKey,
      OrderShortcut.review => _reviewKey,
    };
    if (key == null) {
      openOrderInvoice(context, order);
      return;
    }
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      alignment: 0.04,
      duration: context.reduceMotion ? Duration.zero : AtelierMotion.slow,
      curve: AtelierMotion.emphasized,
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(buyerOrderDetailProvider(orderId));
    final gutter = AtelierSpace.gutter(MediaQuery.sizeOf(context).width);

    return MaisonLayout(
      detail: true,
      child: async.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => _DetailSkeleton(gutter: gutter),
        error: (e, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(gutter, 24, gutter, 32),
          children: [
            AtelierErrorState(
              title: 'Order unavailable',
              message: e is Failure
                  ? e.message
                  : context.tr(AccountCommerceL10n.orderNotFound),
              onRetry: _reload,
            ),
            Center(
              child: AtelierButton(
                label: context.tr(AccountCommerceL10n.backToOrders),
                icon: Icons.arrow_back_rounded,
                variant: AtelierButtonVariant.ghost,
                compact: true,
                onPressed: () =>
                    context.goBack(fallbackLocation: AppRouteNames.buyerOrders),
              ),
            ),
          ],
        ),
        data: (order) => _OrderDetailBody(
          order: order,
          gutter: gutter,
          onRefresh: _reload,
          onShortcut: (s) => _onShortcut(s, order),
          trackingKey: _trackingKey,
          refundKey: _refundKey,
          reviewKey: _reviewKey,
        ),
      ),
    );
  }
}

class _OrderDetailBody extends StatelessWidget {
  const _OrderDetailBody({
    required this.order,
    required this.gutter,
    required this.onRefresh,
    required this.onShortcut,
    required this.trackingKey,
    required this.refundKey,
    required this.reviewKey,
  });

  final PaymentOrder order;
  final double gutter;
  final Future<void> Function() onRefresh;
  final ValueChanged<OrderShortcut> onShortcut;
  final GlobalKey trackingKey;
  final GlobalKey refundKey;
  final GlobalKey reviewKey;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final rejected = order.sellerDecisions.any((d) => d.isRejected);

    final journey = OrderJourneyPanel(order: order);
    final items = OrderItemsPanel(order: order);
    final payment = OrderPaymentPanel(order: order);
    final tracking = KeyedSubtree(
      key: trackingKey,
      child: OrderTrackingPanel(orderId: order.id),
    );
    final refund = KeyedSubtree(
      key: refundKey,
      child: OrderRefundPanel(order: order),
    );
    final review = KeyedSubtree(
      key: reviewKey,
      child: OrderReviewPanel(order: order),
    );

    List<Widget> stack(List<Widget> panels, {int from = 0}) => [
      for (var i = 0; i < panels.length; i++) ...[
        if (i > 0) const SizedBox(height: AtelierSpace.s16),
        Reveal(index: from + i, child: panels[i]),
      ],
    ];

    return RefreshIndicator(
      color: p.gold,
      backgroundColor: p.surface,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 40),
        child: MaisonCentered(
          maxWidth: 1120,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Reveal(
                    child: OrderDetailHero(
                      order: order,
                      onShortcut: onShortcut,
                    ),
                  ),
                  if (rejected) ...[
                    const SizedBox(height: AtelierSpace.s16),
                    Reveal(index: 1, child: OrderRejectionPanel(order: order)),
                  ],
                  const SizedBox(height: AtelierSpace.s16),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 11,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: stack([
                              journey,
                              tracking,
                              items,
                            ], from: 2),
                          ),
                        ),
                        const SizedBox(width: AtelierSpace.s16),
                        Expanded(
                          flex: 9,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: stack([payment, refund, review], from: 3),
                          ),
                        ),
                      ],
                    )
                  else
                    ...stack([
                      journey,
                      items,
                      payment,
                      tracking,
                      refund,
                      review,
                    ], from: 2),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton({required this.gutter});

  final double gutter;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 32),
      children: const [
        MaisonCentered(
          maxWidth: 1120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SkeletonBox(height: 260, radius: AtelierRadius.xl),
              SizedBox(height: 16),
              AtelierSkeletonCard(height: 220),
              SizedBox(height: 16),
              AtelierSkeletonCard(height: 140),
              SizedBox(height: 16),
              AtelierSkeletonCard(height: 180),
            ],
          ),
        ),
      ],
    );
  }
}
