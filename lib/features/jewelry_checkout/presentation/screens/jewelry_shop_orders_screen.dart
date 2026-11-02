import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_layout.dart';
import '../../application/jewelry_orders_provider.dart';
import '../../domain/models/marketplace_order.dart';
import '../../domain/models/shop_order.dart';
import '../jewelry_checkout_format.dart';
import '../widgets/jewelry_order_status.dart';

/// Seller studio → Orders for a jewellery shop: the paid orders holding the
/// shop's pieces. [openOrderId] (the WhatsApp "Open order" button) shows
/// that order first, opened; another shop's order gets a notice instead.
class JewelryShopOrdersScreen extends ConsumerWidget {
  const JewelryShopOrdersScreen({this.openOrderId, super.key});

  final String? openOrderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LuxeScope(
      child: Builder(builder: (context) => _build(context, ref)),
    );
  }

  Widget _build(BuildContext context, WidgetRef ref) {
    final p = LuxePalette.of(context);
    final orders = ref.watch(jewelryShopOrdersProvider);
    final wanted = openOrderId?.trim().toLowerCase();
    return AppScaffold(
      backgroundColor: p.canvas,
      appBar: LuxeTopBar(title: context.tr(JewelryMarketL10n.shopOrdersTitle)),
      body: orders.when(
        skipLoadingOnRefresh: true,
        loading: () => ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            LuxeSkeleton(height: 104, radius: LuxeSpace.radius),
            SizedBox(height: 12),
            LuxeSkeleton(height: 104, radius: LuxeSpace.radius),
          ],
        ),
        // Not a jewellery shop (or not verified): the API says why.
        error: (e, _) => LuxeStateView(
          icon: Icons.storefront_outlined,
          tone: LuxeTone.error,
          title: context.tr(JewelryMarketL10n.shopOrdersUnavailable),
          message: e is Failure ? e.message : '$e',
          actionLabel: context.tr(CatalogL10n.retry),
          onAction: () => ref.invalidate(jewelryShopOrdersProvider),
        ),
        data: (items) {
          final opened = wanted == null || wanted.isEmpty
              ? null
              : items.where((o) => o.id.toLowerCase() == wanted).firstOrNull;
          final rest = [
            for (final o in items)
              if (!identical(o, opened)) o,
          ];
          final askedForOne = wanted != null && wanted.isNotEmpty;
          if (items.isEmpty && !askedForOne) {
            return LuxeStateView(
              icon: Icons.receipt_long_outlined,
              title: context.tr(JewelryMarketL10n.shopOrdersEmpty),
              message: context.tr(JewelryMarketL10n.shopOrdersEmptyBody),
            );
          }
          return RefreshIndicator(
            color: p.accent,
            onRefresh: () => ref.refresh(jewelryShopOrdersProvider.future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                if (askedForOne) ...[
                  if (opened != null) ...[
                    _SectionLabel(
                      context.tr(JewelryMarketL10n.shopOrderOpened),
                    ),
                    _ShopOrderCard(
                      key: ValueKey('open-${opened.id}'),
                      order: opened,
                      initiallyExpanded: true,
                    ),
                  ] else
                    const _OtherShopNotice(),
                  if (rest.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _SectionLabel(context.tr(JewelryMarketL10n.shopOrdersAll)),
                  ],
                ],
                for (final o in rest) ...[
                  _ShopOrderCard(key: ValueKey(o.id), order: o),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text.toUpperCase(), style: LuxeType.eyebrow(p.inkMuted)),
    );
  }
}

class _OtherShopNotice extends StatelessWidget {
  const _OtherShopNotice();

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.caution.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(LuxeSpace.radius),
        border: Border.all(color: p.caution.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: p.caution, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(JewelryMarketL10n.shopOrderOtherShop),
                  style: LuxeType.label(p.ink, size: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr(JewelryMarketL10n.shopOrderOtherShopBody),
                  style: LuxeType.body(p.inkMuted, size: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One order: summary row; tap to show the pieces, delivery address, the
/// buyer's note and the shipment.
class _ShopOrderCard extends StatefulWidget {
  const _ShopOrderCard({
    required this.order,
    this.initiallyExpanded = false,
    super.key,
  });

  final ShopOrder order;
  final bool initiallyExpanded;

  @override
  State<_ShopOrderCard> createState() => _ShopOrderCardState();
}

class _ShopOrderCardState extends State<_ShopOrderCard> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final o = widget.order;
    final image = o.coverImageUrl;
    final step = o.shipment?.status;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(LuxeSpace.radius),
        border: Border.all(color: _expanded ? p.accent : p.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(LuxeSpace.radius),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _Thumb(url: image, size: 64),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                o.orderNumber,
                                style: LuxeType.eyebrow(p.inkMuted),
                              ),
                            ),
                            if (step != null) _StepPill(status: step),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (o.buyerName.isNotEmpty)
                          Text(
                            context.tr(JewelryMarketL10n.shopBuyer, {
                              'name': o.buyerName,
                            }),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: LuxeType.label(p.ink, size: 14),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                dateTimeLabel(context, o.paidAt ?? o.createdAt),
                                style: LuxeType.body(p.inkMuted, size: 12),
                              ),
                            ),
                            Text(
                              rupees(o.shopTotal),
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
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: p.inkMuted,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) _Details(order: o),
        ],
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.order});

  final ShopOrder order;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final o = order;
    final a = o.address;
    final s = o.shipment;
    final note = o.buyerNote?.trim() ?? '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(color: p.hairline, height: 1),
          const SizedBox(height: 12),
          for (final item in o.items) _ItemRow(item: item),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr(JewelryMarketL10n.shopTotal),
                  style: LuxeType.label(p.ink, size: 14),
                ),
              ),
              Text(
                rupees(o.shopTotal),
                style: LuxeType.figure(
                  p.ink,
                  size: 15,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (a != null) ...[
            const SizedBox(height: 14),
            _Block(
              icon: Icons.local_shipping_outlined,
              title: context.tr(JewelryMarketL10n.deliverTo),
              lines: [
                [a.fullName, a.phone].where((t) => t.isNotEmpty).join(' · '),
                a.summaryLine,
              ],
            ),
          ],
          if (note.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Block(
              icon: Icons.sticky_note_2_outlined,
              title: context.tr(JewelryMarketL10n.orderNote),
              lines: [note],
            ),
          ],
          if (s != null &&
              (s.expectedDeliveryAt != null ||
                  (s.courierName?.isNotEmpty ?? false) ||
                  (s.trackingNumber?.isNotEmpty ?? false))) ...[
            const SizedBox(height: 12),
            _Block(
              icon: Icons.inventory_2_outlined,
              title: jewelryStepLabel(context, s.status),
              lines: [
                [
                  s.courierName,
                  s.trackingNumber,
                ].whereType<String>().where((t) => t.isNotEmpty).join(' · '),
                if (s.expectedDeliveryAt != null)
                  context.tr(JewelryMarketL10n.expectedBy, {
                    'date': calendarDateLabel(context, s.expectedDeliveryAt),
                  }),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final MarketplaceOrderItem item;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final i = item;
    final custom = i.customValues.entries
        .where((e) => e.value.trim().isNotEmpty)
        .map((e) => '${e.key}: “${e.value}”')
        .join(' · ');
    final cancelled = i.status == MarketplaceStepStatus.cancelled;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Thumb(url: i.imageUrl, size: 48),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  i.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: LuxeType.label(
                    cancelled ? p.inkMuted : p.ink,
                    size: 13.5,
                  ),
                ),
                if (i.options.isNotEmpty)
                  Text(
                    optionsLine(i.options),
                    style: LuxeType.body(p.inkMuted, size: 12),
                  ),
                if (custom.isNotEmpty)
                  Text(custom, style: LuxeType.body(p.inkMuted, size: 12)),
                Text(
                  '${context.tr(JewelryMarketL10n.shopQuantity, {'count': i.quantity})}'
                  ' · ${jewelryStepLabel(context, i.status)}',
                  style: LuxeType.body(
                    cancelled ? p.caution : p.inkMuted,
                    size: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            rupees(i.lineTotal),
            style: LuxeType.figure(cancelled ? p.inkMuted : p.ink, size: 13),
          ),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.icon, required this.title, required this.lines});

  final IconData icon;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final shown = lines.where((l) => l.trim().isNotEmpty).toList();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: p.accent),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: LuxeType.label(p.ink, size: 13.5)),
              for (final line in shown)
                Text(line, style: LuxeType.body(p.inkMuted, size: 12.5)),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final tone = switch (status) {
      MarketplaceStepStatus.delivered => p.positive,
      MarketplaceStepStatus.cancelled => p.inkMuted,
      _ => p.accent,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: ShapeDecoration(
        color: tone.withValues(alpha: 0.12),
        shape: const StadiumBorder(),
      ),
      child: Text(
        jewelryStepLabel(context, status),
        style: LuxeType.label(tone, size: 11.5),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url, required this.size});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox.square(
        dimension: size,
        child: url == null || url!.isEmpty
            ? ColoredBox(
                color: p.surfaceRaised,
                child: Icon(Icons.diamond_outlined, color: p.accent),
              )
            : AppNetworkImage(url: url!, memCacheWidth: (size * 3).round()),
      ),
    );
  }
}
