import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/gem3d/gem_mesh.dart';
import '../../../product_detail/open_catalog_product_detail.dart';
import '../../../product_offer/application/product_offer_providers.dart';
import '../../../product_offer/domain/models/product_offer.dart';
import '../../../product_offer/presentation/widgets/offer_countdown.dart';
import '../atelier/atelier_components.dart';
import '../atelier/atelier_feedback.dart';
import '../atelier/atelier_motion.dart';
import '../atelier/atelier_studio.dart';
import '../atelier/atelier_theme.dart';

/// Negotiation desk: every buyer price offer, with the ones awaiting a
/// decision surfaced first and accept / decline one tap away.
class SellerOffersScreen extends ConsumerStatefulWidget {
  const SellerOffersScreen({super.key, this.initialStatus});

  /// `status` query value (`PENDING`, `ACCEPTED`…) to open filtered.
  final String? initialStatus;

  @override
  ConsumerState<SellerOffersScreen> createState() => _SellerOffersScreenState();
}

class _SellerOffersScreenState extends ConsumerState<SellerOffersScreen>
    with WidgetsBindingObserver {
  ProductOfferStatus? _filter;
  final _search = TextEditingController();
  String _query = '';
  final Set<String> _busy = {};

  /// Per-status counts from the last unfiltered load, so the filter row
  /// keeps its numbers while a server-side filter is applied.
  Map<ProductOfferStatus, int>? _counts;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final initial = _statusFrom(widget.initialStatus);
    if (initial != null) {
      _filter = initial;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _filter == initial) _applyFilter(initial);
      });
    }
  }

  @override
  void didUpdateWidget(SellerOffersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialStatus != oldWidget.initialStatus) {
      _applyFilter(_statusFrom(widget.initialStatus));
    }
  }

  static ProductOfferStatus? _statusFrom(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return ProductOfferStatus.fromApi(raw);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _search.dispose();
    super.dispose();
  }

  /// Both 24-hour clocks run on the backend; a fresh list on return shows
  /// what expired or was declined automatically meanwhile.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _applyFilter(ProductOfferStatus? filter) async {
    setState(() => _filter = filter);
    await ref
        .read(sellerOfferListProvider.notifier)
        .refresh(statusFilter: filter?.apiValue);
  }

  Future<void> _refresh() => ref
      .read(sellerOfferListProvider.notifier)
      .refresh(statusFilter: _filter?.apiValue);

  Future<void> _respond(ProductOffer offer, ProductOfferStatus status) async {
    final accepting = status == ProductOfferStatus.accepted;
    final ok = await showAtelierConfirm(
      context: context,
      title: accepting ? 'Accept this offer?' : 'Decline this offer?',
      message: accepting
          ? '${offer.buyerName ?? 'The buyer'} will be notified that '
                '${atelierMoney(offer.amount, decimals: 2)} for '
                '${offer.displayTitle} is accepted and has 24 hours to pay. '
                'Every other open offer on this stone is declined, and the '
                'stone is held for this buyer until then.'
          : '${offer.buyerName ?? 'The buyer'} will be told you passed on '
                '${atelierMoney(offer.amount, decimals: 2)}. This can’t be undone.',
      confirmLabel: accepting
          ? context.tr(RemainingL10n.accept)
          : context.tr(RemainingL10n.reject),
      destructive: !accepting,
      icon: accepting ? Icons.handshake_outlined : Icons.do_not_disturb_rounded,
    );
    if (!ok || !mounted) return;
    setState(() => _busy.add(offer.id));
    final result = await ref
        .read(sellerOfferListProvider.notifier)
        .respond(id: offer.id, status: status);
    if (!mounted) return;
    setState(() => _busy.remove(offer.id));
    switch (result) {
      case Success():
        accepting ? AppHaptics.success() : AppHaptics.warning();
        final counts = _counts;
        if (counts != null) {
          counts[offer.status] = ((counts[offer.status] ?? 1) - 1).clamp(
            0,
            1 << 30,
          );
          counts[status] = (counts[status] ?? 0) + 1;
        }
        showAtelierToast(
          context,
          accepting
              ? context.tr(RemainingL10n.offerAccepted)
              : context.tr(RemainingL10n.offerRejected),
          tone: accepting ? AtelierTone.emerald : AtelierTone.neutral,
        );
      case ResultFailure(:final failure):
        AppHaptics.error();
        showAtelierToast(context, failure.message, tone: AtelierTone.ruby);
    }
  }

  List<ProductOffer> _visible(List<ProductOffer> items) {
    final filtered = _filter == null
        ? items
        : items.where((o) => o.status == _filter).toList();
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _pendingFirst(filtered);
    return _pendingFirst([
      for (final o in filtered)
        if ([
          o.displayTitle,
          o.buyerName,
          o.buyerEmail,
          o.stockNumber,
          o.productType,
          o.productSpecs,
        ].any((v) => v != null && v.toLowerCase().contains(q)))
          o,
    ]);
  }

  static List<ProductOffer> _pendingFirst(List<ProductOffer> items) {
    final pending = [
      for (final o in items)
        if (o.status.isPending) o,
    ];
    if (pending.isEmpty || pending.length == items.length) return items;
    return [
      ...pending,
      for (final o in items)
        if (!o.status.isPending) o,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sellerOfferListProvider);
    if (state.statusFilter == null &&
        !state.isLoading &&
        !state.hasMore &&
        state.errorMessage == null) {
      _counts = {
        for (final s in ProductOfferStatus.values)
          s: state.items.where((o) => o.status == s).length,
      };
    }
    final counts = _counts;
    final items = _visible(state.items);
    final pending = state.items.where((o) => o.status.isPending).toList();
    final pendingCount = counts?[ProductOfferStatus.pending] ?? pending.length;
    final pendingValue = pending.fold<double>(0, (s, o) => s + o.amount);
    final ratios = [
      for (final o in state.items)
        if ((o.listPrice ?? 0) > 0) o.amount / o.listPrice!,
    ];
    final avgRatio = ratios.isEmpty
        ? null
        : ratios.reduce((a, b) => a + b) / ratios.length;

    return AtelierPage(
      onRefresh: _refresh,
      children: [
        AtelierHero(
          title: context.tr(RemainingL10n.offers),
          cut: GemCut.cushion,
          footer: AtelierHeroStats(
            stats: [
              AtelierHeroStat(
                label: 'Awaiting you',
                value: '$pendingCount',
                caption: pendingCount == 1
                    ? 'offer to answer'
                    : 'offers to answer',
                tone: pendingCount > 0 ? AtelierTone.amber : null,
              ),
              AtelierHeroStat(
                label: 'On the table',
                value: atelierMoney(pendingValue),
                caption: 'Pending offer value',
              ),
              AtelierHeroStat(
                label: 'Avg. vs list',
                value: avgRatio == null
                    ? '—'
                    : '${(avgRatio * 100).toStringAsFixed(0)}%',
                caption: 'Of asking price',
              ),
            ],
          ),
        ),
        const SizedBox(height: AtelierSpace.s24),
        Reveal(
          index: 2,
          child: AtelierSegmented<ProductOfferStatus?>(
            segments: [
              AtelierSegment(
                value: null,
                label: context.tr(RemainingL10n.all),
                count: counts?.values.fold<int>(0, (a, b) => a + b),
              ),
              AtelierSegment(
                value: ProductOfferStatus.pending,
                label: context.tr(RemainingL10n.pending),
                icon: Icons.hourglass_top_rounded,
                count: counts?[ProductOfferStatus.pending],
              ),
              AtelierSegment(
                value: ProductOfferStatus.accepted,
                label: context.tr(RemainingL10n.accepted),
                icon: Icons.check_rounded,
                count: counts?[ProductOfferStatus.accepted],
              ),
              AtelierSegment(
                value: ProductOfferStatus.rejected,
                label: context.tr(RemainingL10n.rejected),
                icon: Icons.close_rounded,
                count: counts?[ProductOfferStatus.rejected],
              ),
              AtelierSegment(
                value: ProductOfferStatus.expired,
                label: context.tr(RemainingL10n.expired),
                icon: Icons.history_toggle_off_rounded,
                count: counts?[ProductOfferStatus.expired],
              ),
            ],
            selected: _filter,
            onChanged: _applyFilter,
          ),
        ),
        const SizedBox(height: AtelierSpace.s12),
        Reveal(
          index: 3,
          child: AtelierSearchField(
            controller: _search,
            hint: 'Search buyer, product or stock no.',
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        if (state.errorMessage != null && state.items.isNotEmpty) ...[
          const SizedBox(height: AtelierSpace.s12),
          AtelierNotice(
            text: state.errorMessage!,
            tone: AtelierTone.ruby,
            icon: Icons.error_outline_rounded,
            actionLabel: context.tr(RemainingL10n.retry),
            onAction: _refresh,
          ),
        ],
        const SizedBox(height: AtelierSpace.s20),
        AnimatedSwitcher(
          duration: AtelierMotion.base,
          switchInCurve: AtelierMotion.emphasized,
          child: KeyedSubtree(
            key: ValueKey(
              '${_filter?.name}-${state.isLoading}-${items.length}',
            ),
            child: _body(context, state, items),
          ),
        ),
      ],
    );
  }

  Widget _body(
    BuildContext context,
    SellerOfferListState state,
    List<ProductOffer> items,
  ) {
    if (state.isLoading && state.items.isEmpty) {
      return const AtelierSkeletonList(count: 4, height: 168);
    }
    if (state.errorMessage != null && state.items.isEmpty) {
      return AtelierErrorState(
        title: 'Offers unavailable',
        message: state.errorMessage!,
        onRetry: _refresh,
      );
    }
    if (items.isEmpty) {
      final searching = _query.trim().isNotEmpty;
      return AtelierEmptyState(
        icon: searching ? Icons.search_off_rounded : Icons.local_offer_outlined,
        title: searching
            ? 'No matches'
            : _filter == ProductOfferStatus.pending
            ? 'You’re all caught up'
            : 'No offers yet',
        message: searching
            ? 'Nothing in this view matches “${_query.trim()}”.'
            : context.tr(RemainingL10n.noOffersInThisFilter),
        actionLabel: searching ? 'Clear search' : null,
        onAction: searching
            ? () {
                _search.clear();
                setState(() => _query = '');
              }
            : null,
      );
    }
    final grid = LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 920 ? 2 : 1;
        const gap = AtelierSpace.s16;
        final w = (constraints.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < items.length; i++)
              SizedBox(
                width: w,
                child: Reveal(
                  key: ValueKey(items[i].id),
                  index: i < 8 ? i : 0,
                  child: _OfferCard(
                    offer: items[i],
                    busy: _busy.contains(items[i].id),
                    onOpen: () => _openDetail(items[i]),
                    onAccept: () =>
                        _respond(items[i], ProductOfferStatus.accepted),
                    onDecline: () =>
                        _respond(items[i], ProductOfferStatus.rejected),
                    onExpired: _refresh,
                  ),
                ),
              ),
          ],
        );
      },
    );
    if (!state.hasMore) return grid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        grid,
        const SizedBox(height: AtelierSpace.s20),
        Center(
          child: AtelierButton(
            label: 'Load more offers',
            variant: AtelierButtonVariant.secondary,
            compact: true,
            loading: state.isLoadingMore,
            onPressed: () =>
                ref.read(sellerOfferListProvider.notifier).loadMore(),
          ),
        ),
      ],
    );
  }

  Future<void> _viewProduct(ProductOffer offer) async {
    final opened = await openCatalogProductDetail(
      context,
      ref,
      productType: offer.productType,
      productId: offer.productId,
    );
    if (opened || !mounted) return;
    showAtelierToast(
      context,
      context.tr(AccountCommerceL10n.productOpenFailed),
      tone: AtelierTone.ruby,
    );
  }

  void _openDetail(ProductOffer offer) {
    showAtelierSheet<void>(
      context: context,
      title: offer.displayTitle,
      subtitle: '${offer.productTypeLabel} · ${offer.displayStatusLabel}',
      builder: (sheetContext) => _OfferDetail(
        offer: offer,
        onViewProduct: offer.productId.isEmpty
            ? null
            : () {
                Navigator.of(sheetContext).pop();
                _viewProduct(offer);
              },
        onAccept: offer.status.isPending
            ? () {
                Navigator.of(sheetContext).pop();
                _respond(offer, ProductOfferStatus.accepted);
              }
            : null,
        onDecline: offer.status.isPending
            ? () {
                Navigator.of(sheetContext).pop();
                _respond(offer, ProductOfferStatus.rejected);
              }
            : null,
      ),
    );
  }
}

AtelierTone _toneFor(ProductOffer offer) => switch (offer.status) {
  ProductOfferStatus.pending => AtelierTone.amber,
  ProductOfferStatus.accepted =>
    offer.isPayable || offer.isWithGemworld
        ? AtelierTone.gold
        : AtelierTone.emerald,
  ProductOfferStatus.rejected => AtelierTone.ruby,
  ProductOfferStatus.expired => AtelierTone.neutral,
};

/// Accepted and unpaid: how long the buyer has left to pay.
class _PaymentWindow extends StatelessWidget {
  const _PaymentWindow({required this.offer, this.onExpired});

  final ProductOffer offer;
  final VoidCallback? onExpired;

  @override
  Widget build(BuildContext context) {
    return OfferCountdown(
      expiresAt: offer.paymentExpiresAt,
      onExpired: onExpired,
      builder: (context, left) => AtelierNotice(
        text:
            'Waiting for payment · ${formatOfferTimeLeft(left)} left. The '
            'stone is held for this buyer; unpaid offers are released after '
            '24 hours.',
        tone: AtelierTone.gold,
        icon: Icons.schedule_rounded,
      ),
    );
  }
}

List<String> _metaParts(BuildContext context, ProductOffer offer) => [
  if (offer.productSpecs != null) offer.productSpecs!,
  if (offer.certificateLabel != null) offer.certificateLabel!,
  if (offer.stockNumber != null)
    context.tr(RemainingL10n.stockWithNumber, {
      'stockNumber': offer.stockNumber!,
    }),
];

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.busy,
    required this.onOpen,
    required this.onAccept,
    required this.onDecline,
    this.onExpired,
  });

  final ProductOffer offer;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback? onExpired;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final pending = offer.status.isPending;
    final meta = _metaParts(context, offer);
    final buyer = offer.buyerName ?? offer.buyerEmail;

    return AtelierCard(
      onTap: onOpen,
      semanticLabel: 'Offer on ${offer.displayTitle}',
      borderColor: pending ? p.amber.withValues(alpha: 0.35) : null,
      padding: const EdgeInsets.all(AtelierSpace.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AtelierThumb(url: offer.imageUrl, size: 68),
              const SizedBox(width: AtelierSpace.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: AtelierPill(
                            label: offer.displayStatusLabel,
                            tone: _toneFor(offer),
                            dense: true,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            offer.productType.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AtelierType.overline(p.muted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      offer.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AtelierType.display(p.ink, size: 19),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        meta.join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AtelierType.caption(p.muted, size: 11.5),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AtelierSpace.s16),
          _PriceComparison(offer: offer),
          const SizedBox(height: AtelierSpace.s12),
          Row(
            children: [
              if (buyer != null) ...[
                AtelierMonogram(name: buyer, size: 26),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    buyer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AtelierType.label(p.inkSoft, size: 12.5),
                  ),
                ),
              ] else
                const Spacer(),
              Text(
                offer.createdAtLabel,
                style: AtelierType.caption(p.muted, size: 11),
              ),
            ],
          ),
          if (offer.message != null) ...[
            const SizedBox(height: AtelierSpace.s12),
            _Quote(text: offer.message!, maxLines: 2),
          ],
          if (offer.isPayable) ...[
            const SizedBox(height: AtelierSpace.s12),
            _PaymentWindow(offer: offer, onExpired: onExpired),
          ],
          if (offer.isWithGemworld) ...[
            const SizedBox(height: AtelierSpace.s12),
            const AtelierNotice(
              text:
                  'GemWorld is arranging the payment with this buyer. The '
                  'stone stays held for them until the order is paid or '
                  'cancelled.',
              tone: AtelierTone.gold,
              icon: Icons.support_agent_outlined,
            ),
          ],
          if (offer.belowMinimum &&
              (pending || offer.status == ProductOfferStatus.rejected)) ...[
            const SizedBox(height: AtelierSpace.s12),
            AtelierNotice(
              text: pending
                  ? 'Below your minimum offer price: declined automatically '
                        'within 10 minutes unless you accept it.'
                  : 'Declined automatically: below your minimum offer price.',
              tone: pending ? AtelierTone.amber : AtelierTone.neutral,
              icon: Icons.south_rounded,
            ),
          ],
          AnimatedSize(
            duration: AtelierMotion.base,
            curve: AtelierMotion.emphasized,
            child: pending
                ? Padding(
                    padding: const EdgeInsets.only(top: AtelierSpace.s16),
                    child: Row(
                      children: [
                        Expanded(
                          child: AtelierButton(
                            label: context.tr(RemainingL10n.reject),
                            compact: true,
                            variant: AtelierButtonVariant.secondary,
                            onPressed: busy ? null : onDecline,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: AtelierButton(
                            label: context.tr(RemainingL10n.accept),
                            icon: Icons.check_rounded,
                            compact: true,
                            variant: AtelierButtonVariant.gold,
                            loading: busy,
                            onPressed: onAccept,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// Buyer offer against list price, with a meter that shows how close the
/// offer comes to asking.
class _PriceComparison extends StatelessWidget {
  const _PriceComparison({required this.offer});

  final ProductOffer offer;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final list = offer.listPrice;
    final ratio = list == null || list <= 0 ? null : offer.amount / list;
    final gap = list == null ? null : list - offer.amount;
    return Container(
      padding: const EdgeInsets.all(AtelierSpace.s12),
      decoration: BoxDecoration(
        color: p.sunken.withValues(alpha: p.isDark ? 0.6 : 0.55),
        borderRadius: BorderRadius.circular(AtelierRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(RemainingL10n.buyerOffer).toUpperCase(),
                      style: AtelierType.overline(p.gold),
                    ),
                    const SizedBox(height: 4),
                    CountUpText(
                      atelierMoney(offer.amount, decimals: 2),
                      style: AtelierType.display(p.ink, size: 26),
                    ),
                  ],
                ),
              ),
              if (list != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      context.tr(RemainingL10n.listPrice).toUpperCase(),
                      style: AtelierType.overline(p.muted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      atelierMoney(list, decimals: 2),
                      style: AtelierType.figure(p.inkSoft, size: 14),
                    ),
                  ],
                ),
            ],
          ),
          if (ratio != null) ...[
            const SizedBox(height: 10),
            AtelierMeter(
              value: ratio.clamp(0.0, 1.0).toDouble(),
              height: 5,
              color: ratio >= 0.95
                  ? p.emerald
                  : ratio >= 0.85
                  ? p.gold
                  : p.amber,
            ),
            const SizedBox(height: 6),
            Text(
              gap != null && gap > 0
                  ? '${(ratio * 100).toStringAsFixed(0)}% of list · '
                        '${atelierMoney(gap)} below asking'
                  : '${(ratio * 100).toStringAsFixed(0)}% of list · at or above asking',
              style: AtelierType.caption(p.muted, size: 11),
            ),
          ],
        ],
      ),
    );
  }
}

class _Quote extends StatelessWidget {
  const _Quote({required this.text, this.maxLines});

  final String text;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: p.gold, width: 2)),
      ),
      child: Text(
        '“$text”',
        maxLines: maxLines,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
        style: AtelierType.body(
          p.inkSoft,
          size: 13,
        ).copyWith(fontStyle: FontStyle.italic),
      ),
    );
  }
}

class _OfferDetail extends StatelessWidget {
  const _OfferDetail({
    required this.offer,
    this.onAccept,
    this.onDecline,
    this.onViewProduct,
  });

  final ProductOffer offer;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  /// Opens the product's detail page; null when the offer has no product id.
  final VoidCallback? onViewProduct;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final meta = _metaParts(context, offer);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            AtelierThumb(url: offer.imageUrl, size: 84),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AtelierPill(
                    label: offer.displayStatusLabel,
                    tone: _toneFor(offer),
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      meta.join(' · '),
                      style: AtelierType.caption(p.inkSoft, size: 12.5),
                    ),
                  ],
                  if (onViewProduct != null) ...[
                    const SizedBox(height: 8),
                    Pressable(
                      onTap: onViewProduct,
                      semanticLabel: 'View product',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View product',
                            style: AtelierType.label(p.gold, size: 13).copyWith(
                              decoration: TextDecoration.underline,
                              decorationColor: p.gold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.open_in_new_rounded,
                            size: 14,
                            color: p.gold,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _PriceComparison(offer: offer),
        if (offer.isPayable) ...[
          const SizedBox(height: 14),
          _PaymentWindow(offer: offer),
        ],
        if (offer.message != null) ...[
          const SizedBox(height: 18),
          Text('MESSAGE', style: AtelierType.overline(p.muted)),
          const SizedBox(height: 6),
          _Quote(text: offer.message!),
        ],
        const SizedBox(height: 20),
        Wrap(
          spacing: 24,
          runSpacing: 16,
          children: [
            if (offer.buyerName != null)
              AtelierKeyValue(label: 'Buyer', value: offer.buyerName!),
            if (offer.buyerEmail != null)
              AtelierKeyValue(label: 'Email', value: offer.buyerEmail!),
            AtelierKeyValue(label: 'Received', value: offer.createdAtLabel),
            AtelierKeyValue(label: 'Updated', value: offer.updatedAtLabel),
            if (offer.acceptedAt != null)
              AtelierKeyValue(
                label: 'Accepted',
                value: atelierDate(offer.acceptedAt!),
              ),
            if (offer.paidAt != null)
              AtelierKeyValue(label: 'Paid', value: atelierDate(offer.paidAt!)),
            if (offer.productId.isNotEmpty)
              AtelierKeyValue(
                label: 'Product ID',
                value: offer.productId,
                valueWidget: Pressable(
                  onTap: () async {
                    await atelierCopy(offer.productId);
                    if (context.mounted) {
                      showAtelierToast(context, 'Product ID copied');
                    }
                  },
                  semanticLabel: 'Copy product ID',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        offer.productId,
                        style: AtelierType.figure(p.ink, size: 12.5),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.copy_rounded, size: 13, color: p.gold),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (onAccept != null || onDecline != null) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: AtelierButton(
                  label: context.tr(RemainingL10n.reject),
                  variant: AtelierButtonVariant.danger,
                  onPressed: onDecline,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: AtelierButton(
                  label: context.tr(RemainingL10n.accept),
                  icon: Icons.check_rounded,
                  variant: AtelierButtonVariant.gold,
                  onPressed: onAccept,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
