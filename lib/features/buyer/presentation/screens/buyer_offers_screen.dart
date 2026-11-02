import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/account_access.dart';
import '../../../../core/error/failure.dart';
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
import '../../../product_offer/presentation/widgets/offer_counter_form.dart';
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
    ProductOfferStatus.pending =>
      offer.fromSeller ? AtelierTone.gold : AtelierTone.amber,
    ProductOfferStatus.accepted =>
      offer.isPayable || offer.isWithGemworld
          ? AtelierTone.gold
          : AtelierTone.neutral,
    ProductOfferStatus.rejected => AtelierTone.ruby,
    ProductOfferStatus.expired => AtelierTone.neutral,
    ProductOfferStatus.countered => AtelierTone.neutral,
  };
}

IconData buyerOfferIcon(ProductOffer offer) {
  if (offer.isPaid) return Icons.check_circle_rounded;
  return switch (offer.status) {
    ProductOfferStatus.pending =>
      offer.fromSeller ? Icons.swap_horiz_rounded : Icons.hourglass_top_rounded,
    ProductOfferStatus.accepted => Icons.handshake_outlined,
    ProductOfferStatus.rejected => Icons.cancel_outlined,
    ProductOfferStatus.expired => Icons.history_toggle_off_rounded,
    ProductOfferStatus.countered => Icons.swap_horiz_rounded,
  };
}

/// Buyer offers (GET /product-offer/mine): what is waiting on a seller, the
/// seller's counter-offers to answer, what was accepted and must be paid
/// within 24 hours, and what closed. A negotiation shows once, as its
/// latest move.
class BuyerOffersScreen extends ConsumerStatefulWidget {
  const BuyerOffersScreen({this.payOfferId, this.counterOfferId, super.key});

  /// Accepted offer to put in the bag and check out on open (from the
  /// `OFFER_ACCEPTED` push), as the website does for `?pay=<offerId>`.
  final String? payOfferId;

  /// Seller's counter-offer to answer on open (the `OFFER_COUNTERED` push,
  /// `?counter=<offerId>`).
  final String? counterOfferId;

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
      return;
    }
    final counterId = widget.counterOfferId?.trim();
    if (counterId != null && counterId.isNotEmpty) {
      _filter = _OfferFilter.pending;
      Future.microtask(() => _answerFromLink(counterId));
    }
  }

  /// Opens the seller's counter-offer from a push link to answer it.
  Future<void> _answerFromLink(String offerId) async {
    await _refresh();
    if (!mounted) return;
    final offer = ref
        .read(buyerOfferListProvider)
        .items
        .where((o) => o.id == offerId)
        .firstOrNull;
    if (offer == null || !offer.isOpenCounter) {
      showAtelierToast(
        context,
        'This counter-offer is no longer open. It may have expired after '
        '24 hours.',
        tone: AtelierTone.neutral,
      );
      return;
    }
    await _answer(offer);
  }

  /// Accept & pay, counter back or decline the seller's counter-offer.
  Future<void> _answer(ProductOffer offer) async {
    final choice = await showAtelierOptions<ProductOfferStatus>(
      context: context,
      title: 'Counter-offer · ${maisonUsd(offer.amount)}',
      subtitle: offer.displayTitle,
      options: [
        const AtelierOption(
          value: ProductOfferStatus.accepted,
          label: 'Accept & pay',
          icon: Icons.lock_outline_rounded,
          hint: 'You have 24 hours to pay at this price',
        ),
        if (!offer.attemptsExhausted)
          AtelierOption(
            value: ProductOfferStatus.countered,
            label: 'Counter',
            icon: Icons.swap_horiz_rounded,
            hint: offerAttemptsCaption(offer),
          ),
        const AtelierOption(
          value: ProductOfferStatus.rejected,
          label: 'Decline',
          icon: Icons.close_rounded,
          destructive: true,
        ),
      ],
    );
    if (choice == null || !mounted) return;
    switch (choice) {
      case ProductOfferStatus.accepted:
        await _acceptCounter(offer);
      case ProductOfferStatus.countered:
        await _counterBack(offer);
      case ProductOfferStatus.rejected:
        await _declineCounter(offer);
      default:
        return;
    }
  }

  Future<Result<ProductOffer, Failure>?> _sendAnswer(
    ProductOffer offer,
    ProductOfferStatus answer, {
    String? amount,
    String? message,
  }) async {
    if (!AccountAccess.guard(context, ref)) return null;
    setState(() => _busy.add(offer.id));
    final result = await ref
        .read(productOfferMutationProvider.notifier)
        .answerCounter(
          counterOfferId: offer.id,
          answer: answer,
          amount: amount,
          message: message,
        );
    if (!mounted) return null;
    setState(() => _busy.remove(offer.id));
    if (result case ResultFailure(:final failure)) {
      AppHaptics.error();
      showAtelierToast(context, failure.message, tone: AtelierTone.ruby);
      return null;
    }
    return result;
  }

  /// Accepting reserves the stone for 24 hours; like the website, go
  /// straight to the bag at the counter price.
  Future<void> _acceptCounter(ProductOffer offer) async {
    final ok = await showAtelierConfirm(
      context: context,
      title: 'Accept ${maisonUsd(offer.amount)}?',
      message:
          'The stone is held for you and you have 24 hours to pay at this '
          'price.',
      confirmLabel: 'Accept & pay',
      icon: Icons.handshake_outlined,
    );
    if (!ok || !mounted) return;
    final result = await _sendAnswer(offer, ProductOfferStatus.accepted);
    if (result case Success(value: final accepted)) {
      if (!mounted) return;
      await _pay(accepted);
    }
  }

  Future<void> _declineCounter(ProductOffer offer) async {
    final ok = await showAtelierConfirm(
      context: context,
      title: 'Decline this counter-offer?',
      message:
          'The seller will be told you passed on ${maisonUsd(offer.amount)}. '
          'You can make a new offer while you have attempts left.',
      confirmLabel: 'Decline',
      destructive: true,
      icon: Icons.do_not_disturb_rounded,
    );
    if (!ok || !mounted) return;
    final result = await _sendAnswer(offer, ProductOfferStatus.rejected);
    if (result == null || !mounted) return;
    AppHaptics.warning();
    showAtelierToast(context, 'Counter-offer declined.');
  }

  /// Counter back below the seller's price; uses one attempt.
  Future<void> _counterBack(ProductOffer offer) async {
    final input = await showOfferCounterSheet(
      context,
      title: 'Counter the seller',
      subtitle: 'Seller’s price ${maisonUsd(offer.amount)}',
      below: offer.amount,
      note: [
        'The seller has 24 hours to answer.',
        ?offerAttemptsCaption(offer),
      ].join(' '),
    );
    if (input == null || !mounted) return;
    final result = await _sendAnswer(
      offer,
      ProductOfferStatus.countered,
      amount: input.amount,
      message: input.message,
    );
    if (result == null || !mounted) return;
    AppHaptics.success();
    showAtelierToast(
      context,
      'Counter-offer sent. The seller has 24 hours to answer.',
      tone: AtelierTone.emerald,
    );
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
                padding: EdgeInsets.fromLTRB(gutter, 6, gutter, 12),
                sliver: SliverToBoxAdapter(
                  child: MaisonCentered(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MaisonHeader(
                          title: context.tr(DiamondFlowL10n.myOffers),
                          cut: GemCut.cushion,
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
                padding: EdgeInsets.fromLTRB(gutter, 5, gutter, 20),
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
          padding: const EdgeInsets.only(bottom: 10),
          child: Reveal(
            key: ValueKey(offer.id),
            index: i < 8 ? i : 0,
            child: BuyerOfferCard(
              offer: offer,
              busy: _busy.contains(offer.id),
              onOpen: () => _open(offer),
              onPay: () => _pay(offer),
              onAnswer: () => _answer(offer),
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
    this.onAnswer,
    this.onExpired,
    super.key,
  });

  final ProductOffer offer;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onPay;

  /// Opens accept / counter / decline for the seller's counter-offer.
  final VoidCallback? onAnswer;
  final VoidCallback? onExpired;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final tone = buyerOfferTone(offer);
    final payable = offer.isPayable;
    final counter = offer.isOpenCounter;
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
      borderColor: payable || counter ? p.gold.withValues(alpha: 0.5) : null,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AtelierThumb(url: offer.imageUrl, size: 64),
              const SizedBox(width: 8),
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
                    const SizedBox(height: 6),
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
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    offer.fromSeller ? 'SELLER’S PRICE' : 'YOUR OFFER',
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
          if (offer.history.isNotEmpty) ...[
            const SizedBox(height: 10),
            OfferExchangeLine(offer: offer, asSeller: false),
          ],
          if (offer.message != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
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
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 8,
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
          if (offer.isAwaitingSeller) ...[
            const SizedBox(height: 10),
            Text(
              'The seller has 24 hours to answer. Offers they don’t answer '
              'expire.',
              style: AtelierType.caption(p.muted, size: 11.5),
            ),
          ],
          if (counter)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: OfferCountdown(
                expiresAt: offer.answerExpiresAt,
                onExpired: onExpired,
                builder: (context, left) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AtelierButton(
                      label:
                          'Answer counter-offer · ${maisonUsd(offer.amount)}',
                      icon: Icons.swap_horiz_rounded,
                      variant: AtelierButtonVariant.gold,
                      loading: busy,
                      expand: true,
                      onPressed: onAnswer,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                        '${formatOfferTimeLeft(left)} left to accept, '
                            'decline or counter.',
                        ?offerAttemptsCaption(offer),
                      ].join(' '),
                      textAlign: TextAlign.center,
                      style: AtelierType.caption(p.muted, size: 11.5),
                    ),
                  ],
                ),
              ),
            ),
          if (offer.isWithGemworld) ...[
            const SizedBox(height: 10),
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
                    padding: const EdgeInsets.only(top: 12),
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
                          const SizedBox(height: 6),
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
