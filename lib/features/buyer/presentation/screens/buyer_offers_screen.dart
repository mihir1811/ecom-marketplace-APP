import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/account_access.dart';
import '../../../../core/error/result.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/gem3d/gem_mesh.dart';
import '../../../product_detail/application/catalog_product_detail_loader.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../../product_offer/application/product_offer_providers.dart';
import '../../../product_offer/domain/models/product_offer.dart';
import '../../../product_offer/presentation/widgets/offer_countdown.dart';
import '../../../seller/presentation/atelier/atelier_components.dart';
import '../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../seller/presentation/atelier/atelier_studio.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import '../maison/maison_kit.dart';
import '../maison/maison_layout.dart';

enum _OfferFilter {
  all('All', null),
  pending('Pending', ProductOfferStatus.pending),
  accepted('Accepted', ProductOfferStatus.accepted),
  rejected('Rejected', ProductOfferStatus.rejected),
  expired('Expired', ProductOfferStatus.expired);

  const _OfferFilter(this.label, this.status);
  final String label;
  final ProductOfferStatus? status;
}

AtelierTone buyerOfferTone(ProductOffer offer) {
  if (offer.isPaid) return AtelierTone.emerald;
  return switch (offer.status) {
    ProductOfferStatus.pending => AtelierTone.amber,
    ProductOfferStatus.accepted =>
      offer.isPayable || offer.isWithGemworld
          ? AtelierTone.gold
          : AtelierTone.neutral,
    ProductOfferStatus.rejected => AtelierTone.ruby,
    ProductOfferStatus.expired => AtelierTone.neutral,
  };
}

IconData buyerOfferIcon(ProductOffer offer) {
  if (offer.isPaid) return Icons.check_circle_rounded;
  return switch (offer.status) {
    ProductOfferStatus.pending => Icons.hourglass_top_rounded,
    ProductOfferStatus.accepted => Icons.handshake_outlined,
    ProductOfferStatus.rejected => Icons.cancel_outlined,
    ProductOfferStatus.expired => Icons.history_toggle_off_rounded,
  };
}

/// Buyer offers (GET /product-offer/mine): what is waiting on a seller, what
/// was accepted and must be paid within 24 hours, and what closed.
class BuyerOffersScreen extends ConsumerStatefulWidget {
  const BuyerOffersScreen({this.payOfferId, super.key});

  /// Accepted offer to put in the bag and check out on open (from the
  /// `OFFER_ACCEPTED` push), as the website does for `?pay=<offerId>`.
  final String? payOfferId;

  @override
  ConsumerState<BuyerOffersScreen> createState() => _BuyerOffersScreenState();
}

class _BuyerOffersScreenState extends ConsumerState<BuyerOffersScreen>
    with WidgetsBindingObserver {
  _OfferFilter _filter = _OfferFilter.all;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final payId = widget.payOfferId?.trim();
    if (payId != null && payId.isNotEmpty) {
      _filter = _OfferFilter.accepted;
      Future.microtask(() => _payFromLink(payId));
    }
  }

  /// Finds the accepted offer in a fresh list, then pays it like Pay now.
  Future<void> _payFromLink(String offerId) async {
    await _refresh();
    if (!mounted) return;
    final offer = ref
        .read(buyerOfferListProvider)
        .items
        .where((o) => o.id == offerId)
        .firstOrNull;
    if (offer != null && offer.isPayable) {
      await _pay(offer);
      return;
    }
    final message = offer == null
        ? 'This offer is no longer available to purchase. It may have '
              'expired after 24 hours.'
        : offer.isPaid
        ? 'This offer is already paid.'
        : offer.isWithGemworld
        ? 'GemWorld is arranging the payment for this offer.'
        : 'This offer is no longer available to purchase. It may have '
              'expired after 24 hours.';
    showAtelierToast(context, message, tone: AtelierTone.neutral);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// The backend applies both 24-hour clocks on every call, so coming back
  /// to the app is enough to show current states.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() => ref
      .read(buyerOfferListProvider.notifier)
      .refresh(statusFilter: _filter.status?.apiValue);

  void _loadMore() => ref.read(buyerOfferListProvider.notifier).loadMore();

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis == Axis.vertical &&
        n.metrics.maxScrollExtent > 0 &&
        n.metrics.pixels >= n.metrics.maxScrollExtent - 320) {
      _loadMore();
    }
    return false;
  }

  void _setFilter(_OfferFilter f) {
    if (f == _filter) return;
    setState(() => _filter = f);
    _refresh();
  }

  Future<void> _pay(ProductOffer offer) async {
    if (!AccountAccess.guard(context, ref)) return;
    final messenger = ScaffoldMessenger.of(context);
    final palette = context.atelier;
    setState(() => _busy.add(offer.id));
    final result = await ref
        .read(productOfferMutationProvider.notifier)
        .addAcceptedOfferToBag(offer);
    if (!mounted) return;
    setState(() => _busy.remove(offer.id));
    if (result case ResultFailure(:final failure)) {
      AppHaptics.error();
      showMaisonToast(
        messenger,
        palette,
        failure.message,
        tone: AtelierTone.ruby,
      );
      return;
    }
    AppHaptics.success();
    showMaisonToast(
      messenger,
      palette,
      context.tr(DiamondFlowL10n.offerAddedToBag),
      tone: AtelierTone.emerald,
      icon: Icons.shopping_bag_outlined,
    );
    context.push(AppRouteNames.cart);
  }

  Future<void> _open(ProductOffer offer) async {
    if (offer.productId.isEmpty) return;
    if (openRememberedProductDetail(context, offer.productId)) return;
    setState(() => _busy.add(offer.id));
    final detail = await CatalogProductDetailLoader.load(
      ref.read,
      productType: offer.productType,
      productId: offer.productId,
    );
    if (!mounted) return;
    setState(() => _busy.remove(offer.id));
    if (detail != null) {
      openProductDetail(context, detail);
      return;
    }
    showAtelierToast(
      context,
      context.tr(AccountCommerceL10n.productOpenFailed),
      tone: AtelierTone.ruby,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final state = ref.watch(buyerOfferListProvider);
    final items = state.items;
    final payable = items.where((o) => o.isPayable).length;
    final pending = items.where((o) => o.status.isPending).length;
    final gutter = AtelierSpace.gutter(MediaQuery.sizeOf(context).width);

    return MaisonLayout(
      child: RefreshIndicator(
        color: p.gold,
        backgroundColor: p.surface,
        onRefresh: _refresh,
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 18),
                sliver: SliverToBoxAdapter(
                  child: MaisonCentered(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MaisonHeader(
                          title: context.tr(DiamondFlowL10n.myOffers),
                          cut: GemCut.cushion,
                        ),
                        const SizedBox(height: 22),
                        Reveal(
                          index: 3,
                          child: MaisonStatStrip(
                            stats: [
                              MaisonStat(
                                label: 'To pay',
                                value: '$payable',
                                caption: payable > 0
                                    ? 'Within 24 hours'
                                    : 'Nothing to pay',
                                tone: payable > 0 ? AtelierTone.gold : null,
                                pulse: payable > 0,
                                selected: _filter == _OfferFilter.accepted,
                                onTap: () => _setFilter(
                                  _filter == _OfferFilter.accepted
                                      ? _OfferFilter.all
                                      : _OfferFilter.accepted,
                                ),
                              ),
                              MaisonStat(
                                label: 'Waiting',
                                value: '$pending',
                                caption: 'With the seller',
                                tone: pending > 0 ? AtelierTone.amber : null,
                                selected: _filter == _OfferFilter.pending,
                                onTap: () => _setFilter(
                                  _filter == _OfferFilter.pending
                                      ? _OfferFilter.all
                                      : _OfferFilter.pending,
                                ),
                              ),
                              MaisonStat(
                                label: 'Offers',
                                value:
                                    '${state.total > items.length ? state.total : items.length}',
                                caption: _filter == _OfferFilter.all
                                    ? 'All time'
                                    : _filter.label,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              MaisonPinnedBar(
                height: 64,
                gutter: gutter,
                child: AtelierSegmented<_OfferFilter>(
                  dense: true,
                  segments: [
                    for (final f in _OfferFilter.values)
                      AtelierSegment(value: f, label: f.label),
                  ],
                  selected: _filter,
                  onChanged: _setFilter,
                ),
              ),
              MaisonRefreshHairline(
                visible: state.isLoading && items.isNotEmpty,
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(gutter, 6, gutter, 32),
                sliver: _body(context, state),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, OfferListState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const SliverToBoxAdapter(
        child: MaisonCentered(
          child: AtelierSkeletonList(count: 3, height: 180),
        ),
      );
    }
    if (state.errorMessage != null && state.items.isEmpty) {
      return SliverToBoxAdapter(
        child: AtelierErrorState(
          title: 'Offers unavailable',
          message: state.errorMessage!,
          onRetry: _refresh,
        ),
      );
    }
    if (state.items.isEmpty) {
      return SliverToBoxAdapter(
        child: _filter == _OfferFilter.all
            ? MaisonEmptyState(
                cut: GemCut.cushion,
                title: 'No offers yet',
                message:
                    'Stones that take offers show Make an offer on their '
                    'page. The seller has 24 hours to answer.',
                actionLabel: 'Browse diamonds',
                actionIcon: Icons.diamond_outlined,
                onAction: () => context.go(AppRouteNames.home),
              )
            : AtelierEmptyState(
                icon: Icons.filter_alt_off_outlined,
                title: 'No ${_filter.label.toLowerCase()} offers',
                message: 'Nothing in this view right now.',
                actionLabel: 'Show all',
                onAction: () => _setFilter(_OfferFilter.all),
              ),
      );
    }

    final rows = <Widget>[];
    String? month;
    var i = 0;
    for (final offer in state.items) {
      final label = maisonMonthLabel(offer.createdAt);
      if (label != month) {
        rows.add(MaisonGroupLabel(label: label));
        month = label;
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Reveal(
            key: ValueKey(offer.id),
            index: i < 8 ? i : 0,
            child: BuyerOfferCard(
              offer: offer,
              busy: _busy.contains(offer.id),
              onOpen: () => _open(offer),
              onPay: () => _pay(offer),
              onExpired: _refresh,
            ),
          ),
        ),
      );
      i++;
    }
    rows.add(
      MaisonListFooter(
        loadingMore: state.isLoadingMore,
        hasMore: state.hasMore,
        errorMessage: state.errorMessage,
        onLoadMore: _loadMore,
        endLabel: 'That’s every offer',
      ),
    );
    return SliverList.builder(
      itemCount: rows.length,
      itemBuilder: (context, index) => MaisonCentered(child: rows[index]),
    );
  }
}

/// One offer: the stone, the amount, where it stands and — while accepted
/// and unpaid — Pay now with the time left.
class BuyerOfferCard extends StatelessWidget {
  const BuyerOfferCard({
    required this.offer,
    required this.busy,
    required this.onOpen,
    required this.onPay,
    this.onExpired,
    super.key,
  });

  final ProductOffer offer;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onPay;
  final VoidCallback? onExpired;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final tone = buyerOfferTone(offer);
    final payable = offer.isPayable;
    final meta = [
      offer.productTypeLabel,
      if (offer.stockNumber != null)
        context.tr(RemainingL10n.stockWithNumber, {
          'stockNumber': offer.stockNumber!,
        }),
    ];

    return AtelierCard(
      onTap: onOpen,
      semanticLabel: 'Offer on ${offer.displayTitle}',
      borderColor: payable ? p.gold.withValues(alpha: 0.5) : null,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AtelierThumb(url: offer.imageUrl, size: 64),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AtelierPill(
                      label: offer.displayStatusLabel,
                      tone: tone,
                      icon: buyerOfferIcon(offer),
                      dense: true,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      offer.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AtelierType.display(p.ink, size: 18),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      meta.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtelierType.caption(p.muted, size: 11.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'YOUR OFFER',
                    style: AtelierType.overline(p.muted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    maisonUsd(offer.amount),
                    style: AtelierType.display(
                      offer.isPaid ? p.emerald : p.ink,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (offer.message != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: p.gold, width: 2)),
              ),
              child: Text(
                '“${offer.message}”',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AtelierType.body(
                  p.inkSoft,
                  size: 13,
                ).copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              AtelierKeyValue(
                label: 'Made',
                value: offer.createdAt != null
                    ? atelierDate(offer.createdAt!)
                    : offer.createdAtLabel,
              ),
              if (offer.acceptedAt != null)
                AtelierKeyValue(
                  label: 'Accepted',
                  value: atelierDate(offer.acceptedAt!),
                ),
              if (offer.paidAt != null)
                AtelierKeyValue(
                  label: 'Paid',
                  value: atelierDate(offer.paidAt!),
                ),
            ],
          ),
          if (offer.status.isPending) ...[
            const SizedBox(height: 14),
            Text(
              'The seller has 24 hours to answer. Offers they don’t answer '
              'expire.',
              style: AtelierType.caption(p.muted, size: 11.5),
            ),
          ],
          if (offer.isWithGemworld) ...[
            const SizedBox(height: 14),
            const AtelierNotice(
              text:
                  'GemWorld is arranging your payment. The stone stays held '
                  'for you, with no time limit, until the order is paid or '
                  'cancelled.',
              tone: AtelierTone.gold,
              icon: Icons.support_agent_outlined,
            ),
          ],
          AnimatedSize(
            duration: AtelierMotion.base,
            curve: AtelierMotion.emphasized,
            child: payable
                ? Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: OfferCountdown(
                      expiresAt: offer.paymentExpiresAt,
                      onExpired: onExpired,
                      builder: (context, left) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AtelierButton(
                            label: context.tr(DiamondFlowL10n.offerPayNow),
                            icon: Icons.lock_outline_rounded,
                            variant: AtelierButtonVariant.gold,
                            loading: busy,
                            expand: true,
                            onPressed: onPay,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${formatOfferTimeLeft(left)} left to pay at '
                            'your offer price. The stone is held for you '
                            'until then.',
                            textAlign: TextAlign.center,
                            style: AtelierType.caption(p.muted, size: 11.5),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
