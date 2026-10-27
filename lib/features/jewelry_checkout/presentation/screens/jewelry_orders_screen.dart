import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_layout.dart';
import '../../application/jewelry_orders_provider.dart';
import '../../domain/models/marketplace_order.dart';
import '../jewelry_checkout_format.dart';
import '../widgets/jewelry_order_status.dart';

/// The buyer's jewellery marketplace orders: paid and cancelled ones plus
/// unpaid orders from the last 24 hours ("Pay now").
class JewelryOrdersScreen extends ConsumerWidget {
  const JewelryOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LuxeScope(
      child: Builder(builder: (context) => _build(context, ref)),
    );
  }

  Widget _build(BuildContext context, WidgetRef ref) {
    final p = LuxePalette.of(context);
    final orders = ref.watch(jewelryOrdersProvider);
    return AppScaffold(
      backgroundColor: p.canvas,
      appBar: LuxeTopBar(title: context.tr(JewelryMarketL10n.ordersTitle)),
      body: orders.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            LuxeSkeleton(height: 104, radius: LuxeSpace.radius),
            SizedBox(height: 12),
            LuxeSkeleton(height: 104, radius: LuxeSpace.radius),
          ],
        ),
        error: (e, _) => LuxeStateView(
          icon: Icons.cloud_off_rounded,
          tone: LuxeTone.error,
          title: context.tr(CatalogFlowL10n.errorTitle),
          message: e is Failure ? e.message : '$e',
          actionLabel: context.tr(CatalogL10n.retry),
          onAction: () => ref.invalidate(jewelryOrdersProvider),
        ),
        data: (items) => items.isEmpty
            ? LuxeStateView(
                icon: Icons.receipt_long_outlined,
                title: context.tr(JewelryMarketL10n.noOrders),
                message: context.tr(JewelryMarketL10n.noOrdersBody),
                actionLabel: context.tr(JewelryMarketL10n.browseJewelry),
                onAction: () => context.push(AppRouteNames.jewelry),
              )
            : RefreshIndicator(
                color: p.accent,
                onRefresh: () => ref.refresh(jewelryOrdersProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _OrderCard(order: items[i]),
                ),
              ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final MarketplaceOrder order;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final image = order.coverImageUrl;
    final title = order.items.isEmpty ? '' : order.items.first.title;
    final more = order.items.length - 1;
    return InkWell(
      borderRadius: BorderRadius.circular(LuxeSpace.radius),
      onTap: () => context.push(AppRouteNames.jewelryOrderDetailPath(order.id)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(LuxeSpace.radius),
          border: Border.all(color: p.hairline),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox.square(
                dimension: 72,
                child: image == null
                    ? ColoredBox(
                        color: p.surfaceRaised,
                        child: Icon(Icons.diamond_outlined, color: p.accent),
                      )
                    : AppNetworkImage(url: image, memCacheWidth: 216),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.orderNumber,
                          style: LuxeType.eyebrow(p.inkMuted),
                        ),
                      ),
                      JewelryOrderStatusPill(order: order),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    more > 0
                        ? context.tr(JewelryMarketL10n.andMore, {
                            'title': title,
                            'count': more,
                          })
                        : title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: LuxeType.label(p.ink, size: 14),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dateTimeLabel(context, order.createdAt),
                          style: LuxeType.body(p.inkMuted, size: 12),
                        ),
                      ),
                      Text(
                        rupees(order.total),
                        style: LuxeType.figure(
                          p.ink,
                          size: 14,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
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
