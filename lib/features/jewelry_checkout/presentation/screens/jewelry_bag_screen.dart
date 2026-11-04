import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/luxe/luxe_button.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_layout.dart';
import '../../../../core/widgets/luxe/luxe_quantity_stepper.dart';
import '../../application/jewelry_bag_provider.dart';
import '../../domain/models/bag_line.dart';
import '../../domain/models/marketplace_quote.dart';
import '../jewelry_checkout_format.dart';
import '../open_jewelry_listing.dart';

/// The jewellery bag: lines saved on the device, priced live by
/// `POST /marketplace/cart/quote` every time the bag opens or changes.
///
/// Each line shows today's price and any problem (sold out, only N left,
/// no longer listed); checkout stays disabled until the quote is ready.
class JewelryBagScreen extends ConsumerWidget {
  const JewelryBagScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LuxeScope(
      child: Builder(builder: (context) => _build(context, ref)),
    );
  }

  Widget _build(BuildContext context, WidgetRef ref) {
    final p = LuxePalette.of(context);
    final lines = ref.watch(jewelryBagProvider);
    final quoteAsync = ref.watch(jewelryBagQuoteProvider);
    final quote = quoteAsync.value;
    final signedIn = ref.watch(authProvider.select((s) => s.isAuthenticated));

    return AppScaffold(
      backgroundColor: p.canvas,
      appBar: LuxeTopBar(
        title: context.tr(JewelryMarketL10n.bagTitle),
        actions: [
          if (signedIn)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: LuxeIconButton(
                icon: Icons.receipt_long_outlined,
                tooltip: context.tr(JewelryMarketL10n.ordersTitle),
                size: 42,
                onPressed: () => context.push(AppRouteNames.jewelryOrders),
              ),
            ),
        ],
      ),
      body: lines.isEmpty
          ? LuxeStateView(
              icon: Icons.shopping_bag_outlined,
              title: context.tr(JewelryMarketL10n.bagEmpty),
              message: context.tr(JewelryMarketL10n.bagEmptyBody),
              actionLabel: context.tr(JewelryMarketL10n.browseJewelry),
              onAction: () => context.push(AppRouteNames.jewelry),
            )
          : RefreshIndicator(
              color: p.accent,
              onRefresh: () => ref.refresh(jewelryBagQuoteProvider.future),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
                children: [
                  if (quoteAsync.hasError)
                    _Banner(
                      text: context.tr(JewelryMarketL10n.quoteFailed),
                      onRetry: () => ref.invalidate(jewelryBagQuoteProvider),
                    ),
                  for (final line in lines)
                    _BagLineCard(
                      line: line,
                      quote: quote?.lineFor(line),
                      pricing: quoteAsync.isLoading,
                    ),
                  const SizedBox(height: 4),
                  _Summary(quote: quote, loading: quoteAsync.isLoading),
                ],
              ),
            ),
      bottomNavigationBar: lines.isEmpty
          ? null
          : _CheckoutBar(quote: quote, loading: quoteAsync.isLoading),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.onRetry});

  final String text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 8, 5, 8),
      decoration: BoxDecoration(
        color: p.caution.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
        border: Border.all(color: p.caution.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 18, color: p.caution),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: LuxeType.label(p.ink, size: 13))),
          TextButton(
            onPressed: onRetry,
            child: Text(context.tr(CatalogL10n.retry)),
          ),
        ],
      ),
    );
  }
}

class _BagLineCard extends ConsumerWidget {
  const _BagLineCard({
    required this.line,
    required this.quote,
    required this.pricing,
  });

  final BagLine line;
  final QuoteLine? quote;
  final bool pricing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = LuxePalette.of(context);
    final n = ref.read(jewelryBagProvider.notifier);
    final q = quote;
    final problem = q?.problem;
    final unit = q != null && problem == null ? q.unitPrice : line.unitPrice;
    final maxQty = q == null || q.maxQuantity <= 0
        ? BagLine.maxQuantity
        : q.maxQuantity;
    final image = q?.imageUrl ?? line.imageUrl;
    final engraving = line.customValues.entries
        .where((e) => e.value.trim().isNotEmpty)
        .map((e) => '${e.key}: “${e.value.trim()}”')
        .join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(LuxeSpace.radius),
        border: Border.all(
          color: problem == null
              ? p.hairline
              : p.caution.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
            onTap: () => openJewelryListing(
              context,
              ref,
              q?.listingSlug ?? line.listingSlug,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox.square(
                    dimension: 88,
                    child: image == null
                        ? ColoredBox(
                            color: p.surfaceRaised,
                            child: Icon(
                              Icons.diamond_outlined,
                              color: p.accent,
                            ),
                          )
                        : AppNetworkImage(url: image, memCacheWidth: 264),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        q?.title.isNotEmpty == true ? q!.title : line.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: LuxeType.label(p.ink, size: 14.5),
                      ),
                      if ((q?.shopName ?? line.shopName ?? '').isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          q?.shopName.isNotEmpty == true
                              ? q!.shopName
                              : line.shopName!,
                          style: LuxeType.body(p.inkMuted, size: 12),
                        ),
                      ],
                      if (line.options.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          optionsLine(line.options),
                          style: LuxeType.body(p.inkMuted, size: 12.5),
                        ),
                      ],
                      if (engraving.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          engraving,
                          style: LuxeType.body(p.inkMuted, size: 12.5),
                        ),
                      ],
                      const SizedBox(height: 6),
                      if (pricing && q == null)
                        const LuxeSkeleton(width: 80, height: 16)
                      else if (unit != null)
                        Text(
                          rupees(unit),
                          style: LuxeType.figure(
                            p.ink,
                            size: 15,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (problem != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.error_outline_rounded, size: 16, color: p.caution),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    problem,
                    style: LuxeType.label(p.caution, size: 12.5),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => n.remove(line.key),
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: p.inkMuted,
                ),
                label: Text(
                  context.tr(JewelryMarketL10n.remove),
                  style: LuxeType.label(p.inkMuted, size: 13),
                ),
              ),
              const Spacer(),
              LuxeQuantityStepper(
                value: line.quantity.clamp(1, maxQty),
                max: maxQty,
                onChanged: (v) => n.setQuantity(line.key, v),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.quote, required this.loading});

  final CartQuote? quote;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final q = quote;
    Widget row(
      String label,
      String value, {
      bool strong = false,
      Color? tone,
    }) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: strong
                  ? LuxeType.label(p.ink, size: 15)
                  : LuxeType.body(p.inkMuted, size: 14),
            ),
          ),
          Text(
            value,
            style: LuxeType.figure(
              tone ?? p.ink,
              size: strong ? 17 : 14,
            ).copyWith(fontWeight: strong ? FontWeight.w600 : FontWeight.w400),
          ),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(LuxeSpace.radius),
        border: Border.all(color: p.hairline),
      ),
      child: q == null
          ? const Column(
              children: [
                LuxeSkeleton(height: 14),
                SizedBox(height: 8),
                LuxeSkeleton(height: 14),
                SizedBox(height: 8),
                LuxeSkeleton(height: 18),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                row(context.tr(JewelryMarketL10n.subtotal), rupees(q.subtotal)),
                for (final t in q.taxes) row(t.label, rupees(t.amount)),
                row(
                  context.tr(JewelryMarketL10n.shipping),
                  q.shipping <= 0
                      ? context.tr(JewelryMarketL10n.free)
                      : rupees(q.shipping),
                  tone: q.shipping <= 0 ? p.positive : null,
                ),
                Divider(color: p.hairline, height: 20),
                row(
                  context.tr(JewelryMarketL10n.total),
                  rupees(q.total),
                  strong: true,
                ),
                const SizedBox(height: 5),
                Text(
                  context.tr(
                    q.ready
                        ? JewelryMarketL10n.pricesConfirmed
                        : JewelryMarketL10n.fixBagFirst,
                  ),
                  style: LuxeType.body(
                    q.ready ? p.inkMuted : p.caution,
                    size: 12.5,
                  ),
                ),
              ],
            ),
    );
  }
}

class _CheckoutBar extends ConsumerWidget {
  const _CheckoutBar({required this.quote, required this.loading});

  final CartQuote? quote;
  final bool loading;

  void _checkout(BuildContext context, WidgetRef ref) {
    if (!ref.read(authProvider).isAuthenticated) {
      showLuxeToast(
        context,
        context.tr(JewelryMarketL10n.signInToCheckout),
        tone: LuxeTone.info,
      );
      context.push(AppRouteNames.login);
      return;
    }
    context.push(AppRouteNames.jewelryCheckout);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = LuxePalette.of(context);
    final q = quote;
    final ready = q != null && q.ready && !loading;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: p.surface,
          border: Border(top: BorderSide(color: p.hairline, width: 0.6)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(JewelryMarketL10n.total),
                    style: LuxeType.label(p.inkMuted, size: 11.5),
                  ),
                  if (q == null)
                    const LuxeSkeleton(width: 90, height: 18)
                  else
                    Text(
                      rupees(q.total),
                      style: LuxeType.figure(
                        p.ink,
                        size: 18,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 5,
              child: LuxeButton(
                label: context.tr(JewelryMarketL10n.checkout),
                expand: true,
                loading: loading && q == null,
                trailingIcon: Icons.arrow_forward_rounded,
                onPressed: ready ? () => _checkout(context, ref) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
