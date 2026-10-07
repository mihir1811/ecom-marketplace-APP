import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/gem3d/gem_mesh.dart';
import '../../../product_offer/application/product_offer_providers.dart';
import '../../../product_offer/domain/models/product_offer.dart';
import '../atelier/atelier_components.dart';
import '../atelier/atelier_feedback.dart';
import '../atelier/atelier_motion.dart';
import '../atelier/atelier_studio.dart';
import '../atelier/atelier_theme.dart';

/// Negotiation desk: every buyer price offer, with the ones awaiting a
/// decision surfaced first and accept / decline one tap away.
class SellerOffersScreen extends ConsumerStatefulWidget {
  const SellerOffersScreen({super.key});

  @override
  ConsumerState<SellerOffersScreen> createState() => _SellerOffersScreenState();
}

class _SellerOffersScreenState extends ConsumerState<SellerOffersScreen> {
  ProductOfferStatus? _filter;
  final _search = TextEditingController();
  String _query = '';
  final Set<String> _busy = {};

  /// Per-status counts from the last unfiltered load, so the filter row
  /// keeps its numbers while a server-side filter is applied.
  Map<ProductOfferStatus, int>? _counts;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
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
                '${offer.displayTitle} is accepted.'
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
          overline: 'Negotiation desk',
          title: context.tr(RemainingL10n.offers),
          subtitle: context.tr(RemainingL10n.reviewBuyerPriceOffersOnYour),
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
    return LayoutBuilder(
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
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _openDetail(ProductOffer offer) {
    showAtelierSheet<void>(
      context: context,
      title: offer.displayTitle,
      subtitle: '${offer.productType} · ${offer.status.label}',
      builder: (sheetContext) => _OfferDetail(
        offer: offer,
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

AtelierTone _toneFor(ProductOfferStatus s) => switch (s) {
  ProductOfferStatus.pending => AtelierTone.amber,
  ProductOfferStatus.accepted => AtelierTone.emerald,
  ProductOfferStatus.rejected => AtelierTone.ruby,
  ProductOfferStatus.expired => AtelierTone.neutral,
};

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
  });

  final ProductOffer offer;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

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
                            label: offer.status.label,
                            tone: _toneFor(offer.status),
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
  const _OfferDetail({required this.offer, this.onAccept, this.onDecline});

  final ProductOffer offer;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

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
                    label: offer.status.label,
                    tone: _toneFor(offer.status),
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      meta.join(' · '),
                      style: AtelierType.caption(p.inkSoft, size: 12.5),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _PriceComparison(offer: offer),
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
