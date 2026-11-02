import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/navigation/top_bar/top_bar_create_action.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../auction/application/auction_providers.dart';
import '../../../auction/data/repositories/auction_repository_impl.dart';
import '../../../auction/domain/models/auction_models.dart';
import '../../../auction/presentation/auction_seller_outcome.dart';
import '../../../auction/presentation/widgets/auction_card.dart';
import '../../../auction/presentation/widgets/auction_clock.dart';
import '../../../auction/presentation/widgets/auction_product_context.dart';
import '../atelier/atelier_components.dart';
import '../atelier/atelier_feedback.dart';
import '../atelier/atelier_motion.dart';
import '../atelier/atelier_studio.dart';
import '../atelier/atelier_theme.dart';
import '../widgets/seller_auction_create_sheet.dart';

/// Auction house: live lots with countdowns, outcomes awaiting a decision,
/// bid ladders and one-tap creation.
class SellerAuctionsScreen extends ConsumerStatefulWidget {
  const SellerAuctionsScreen({this.initialTab, super.key});

  /// `?tab=` on the route: `active`, `upcoming`, `ended`, `sold` or
  /// `decision`.
  final String? initialTab;

  @override
  ConsumerState<SellerAuctionsScreen> createState() =>
      _SellerAuctionsScreenState();
}

class _SellerAuctionsScreenState extends ConsumerState<SellerAuctionsScreen> {
  String? _status;
  final Set<String> _expanded = {};
  final Map<String, List<AuctionBid>> _bids = {};
  final Map<String, String> _bidErrors = {};
  final Set<String> _loadingBids = {};
  final Set<String> _acting = {};

  /// Client-side tab: the finished lots from the standing scan that wait on
  /// the seller. The backend has no status filter for them.
  static const _decisionTab = 'decision';

  /// Client-side tab: sold lots from the standing scan.
  static const _soldTab = 'sold';

  bool get _deciding => _status == _decisionTab;

  /// Tabs listed from the standing scan instead of the paged feed.
  bool get _fromStanding => _deciding || _status == _soldTab;

  @override
  void initState() {
    super.initState();
    _status = _tabFrom(widget.initialTab);
    if (_deciding) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _deciding) _openDecisionBids();
      });
    }
  }

  @override
  void didUpdateWidget(SellerAuctionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab) {
      _setStatus(_tabFrom(widget.initialTab));
    }
  }

  static String? _tabFrom(String? tab) => switch (tab) {
    'active' || 'upcoming' || 'ended' || _soldTab || _decisionTab => tab,
    _ => null,
  };

  AuctionFeedQuery get _query => AuctionFeedQuery(
    kind: AuctionFeedKind.seller,
    status: _fromStanding ? null : _status,
  );

  Future<void> _refresh() async {
    ref.invalidate(sellerAuctionStandingProvider);
    _bids.clear();
    _bidErrors.clear();
    await ref.read(auctionFeedProvider(_query).notifier).refresh();
    if (!mounted) return;
    // Open ladders would otherwise read "No bids yet" after the reset.
    for (final id in _expanded.toList()) {
      _loadBids(id);
    }
  }

  Future<void> _create() async {
    final created = await showSellerAuctionCreateSheet(context);
    if (created && mounted) await _refresh();
  }

  void _setStatus(String? status) {
    if (status == _status) return;
    setState(() => _status = status);
    if (status == _decisionTab) _openDecisionBids();
  }

  /// Opens the bid ladder on every lot awaiting a decision so the seller can
  /// accept or pick a bidder straight away.
  void _openDecisionBids() {
    final awaiting =
        ref.read(sellerAuctionStandingProvider).valueOrNull?.awaitingDecision ??
        const <AuctionListing>[];
    if (awaiting.isEmpty) return;
    setState(() => _expanded.addAll(awaiting.map((a) => a.id)));
    for (final a in awaiting) {
      if (!_bids.containsKey(a.id)) _loadBids(a.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(auctionFeedProvider(_query));
    final standingAsync = ref.watch(sellerAuctionStandingProvider);
    final standing = standingAsync.asData?.value;
    ref.listen(sellerAuctionStandingProvider, (_, next) {
      if (_deciding && next.hasValue && !next.isLoading) _openDecisionBids();
    });
    return TopBarCreateAction(
      create: TopBarCreate(
        label: 'Auction',
        tooltip: 'Create auction',
        onPressed: _create,
      ),
      child: AtelierPage(
        onRefresh: _refresh,
        onNearEnd: () {
          if (feed.hasMore && !feed.isLoadingMore && !feed.isLoading) {
            ref.read(auctionFeedProvider(_query).notifier).loadMore();
          }
        },
        children: [
          if (standingAsync.hasError) ...[
            AtelierNotice(
              text: standingAsync.error is Failure
                  ? (standingAsync.error! as Failure).message
                  : 'Could not load auction outcomes.',
              tone: AtelierTone.ruby,
              icon: Icons.error_outline_rounded,
              actionLabel: context.tr(RemainingL10n.retry),
              onAction: () => ref.invalidate(sellerAuctionStandingProvider),
            ),
            const SizedBox(height: AtelierSpace.s16),
          ] else if ((standing?.needsDecision ?? 0) > 0 && !_deciding) ...[
            Reveal(
              index: 1,
              child: AtelierNotice(
                text: standing!.needsDecision == 1
                    ? 'One finished auction is waiting for your decision.'
                    : '${standing.needsDecision} finished auctions are waiting '
                          'for your decision.',
                tone: AtelierTone.amber,
                icon: Icons.gavel_rounded,
                actionLabel: 'Review',
                onAction: () => _setStatus(_decisionTab),
              ),
            ),
            const SizedBox(height: AtelierSpace.s16),
          ],
          Reveal(
            index: 2,
            child: AtelierSegmented<String?>(
              segments: [
                AtelierSegment(
                  value: null,
                  label: context.tr(RemainingL10n.all),
                  count: standing?.total,
                ),
                AtelierSegment(
                  value: 'active',
                  label: 'Live',
                  icon: Icons.sensors_rounded,
                  count: standing?.active,
                ),
                AtelierSegment(
                  value: 'upcoming',
                  label: 'Upcoming',
                  icon: Icons.schedule_rounded,
                  count: standing?.upcoming,
                ),
                AtelierSegment(
                  value: 'ended',
                  label: 'Ended',
                  icon: Icons.flag_outlined,
                  count: standing?.ended,
                ),
                AtelierSegment(
                  value: _soldTab,
                  label: 'Sold',
                  icon: Icons.sell_outlined,
                  count: standing?.sold,
                ),
                if ((standing?.needsDecision ?? 0) > 0 || _deciding)
                  AtelierSegment(
                    value: _decisionTab,
                    label: 'Needs decision',
                    icon: Icons.gavel_rounded,
                    count: standing?.needsDecision,
                  ),
              ],
              selected: _status,
              onChanged: _setStatus,
            ),
          ),
          const SizedBox(height: AtelierSpace.s12),
          AnimatedSwitcher(
            duration: AtelierMotion.base,
            switchInCurve: AtelierMotion.emphasized,
            child: _fromStanding
                ? KeyedSubtree(
                    key: ValueKey(
                      '$_status-${standingAsync.valueOrNull == null}',
                    ),
                    child: _deciding
                        ? _decisionBody(standingAsync)
                        : _soldBody(standingAsync),
                  )
                : KeyedSubtree(
                    key: ValueKey(
                      '$_status-${feed.isLoading && feed.items.isEmpty}',
                    ),
                    child: _body(context, feed),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, AuctionFeedState feed) {
    final p = context.atelier;
    if (feed.isLoading && feed.items.isEmpty) {
      return const AtelierSkeletonList(count: 3, height: 120);
    }
    if (feed.errorMessage != null && feed.items.isEmpty) {
      return AtelierErrorState(
        title: 'Auctions unavailable',
        message: feed.errorMessage!,
        onRetry: _refresh,
      );
    }
    if (feed.items.isEmpty) {
      return AtelierEmptyState(
        icon: Icons.gavel_outlined,
        title: _status == null ? 'No auctions yet' : 'Nothing here',
        message: context.tr(RemainingL10n.noAuctionsFilter),
        actionLabel: 'Create auction',
        onAction: _create,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _grid(feed.items),
        const SizedBox(height: AtelierSpace.s12),
        if (feed.isLoadingMore)
          Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 1.8, color: p.gold),
            ),
          )
        else if (feed.errorMessage != null)
          AtelierNotice(
            text: feed.errorMessage!,
            tone: AtelierTone.ruby,
            icon: Icons.error_outline_rounded,
            actionLabel: context.tr(RemainingL10n.retry),
            onAction: () =>
                ref.read(auctionFeedProvider(_query).notifier).loadMore(),
          )
        else if (feed.hasMore)
          Center(
            child: AtelierButton(
              label: context.tr(RemainingL10n.loadMore),
              compact: true,
              variant: AtelierButtonVariant.ghost,
              onPressed: () =>
                  ref.read(auctionFeedProvider(_query).notifier).loadMore(),
            ),
          ),
      ],
    );
  }

  /// Loading / error stand-in while the standing scan has no data yet.
  Widget? _standingPending(AsyncValue<SellerAuctionStanding> standing) {
    if (standing.valueOrNull != null) return null;
    if (standing.hasError) {
      return AtelierErrorState(
        title: 'Auctions unavailable',
        message: standing.error is Failure
            ? (standing.error! as Failure).message
            : 'Could not load auction outcomes.',
        onRetry: _refresh,
      );
    }
    return const AtelierSkeletonList(count: 2, height: 120);
  }

  Widget _soldBody(AsyncValue<SellerAuctionStanding> standing) {
    final pending = _standingPending(standing);
    if (pending != null) return pending;
    final items = standing.requireValue.soldAuctions;
    if (items.isEmpty) {
      return AtelierEmptyState(
        icon: Icons.sell_outlined,
        title: 'Nothing sold yet',
        message: 'Auctions that end in a sale show up here.',
        actionLabel: 'See all auctions',
        onAction: () => _setStatus(null),
      );
    }
    return _grid(items);
  }

  Widget _decisionBody(AsyncValue<SellerAuctionStanding> standing) {
    final pending = _standingPending(standing);
    if (pending != null) return pending;
    final items = standing.requireValue.awaitingDecision;
    if (items.isEmpty) {
      return AtelierEmptyState(
        icon: Icons.task_alt_rounded,
        title: 'All decided',
        message: 'No finished auctions are waiting for you.',
        actionLabel: 'See all auctions',
        onAction: () => _setStatus(null),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AtelierNotice(
          text:
              'Bidding has closed on these lots. Accept the highest bid, '
              'select another bidder from the list, or reject to restart or '
              'remove the auction.',
          tone: AtelierTone.amber,
          icon: Icons.info_outline_rounded,
        ),
        const SizedBox(height: AtelierSpace.s12),
        _grid(items),
      ],
    );
  }

  Widget _grid(List<AuctionListing> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 920 ? 2 : 1;
        const gap = AtelierSpace.s12;
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
                  child: _AuctionCard(
                    auction: items[i],
                    expanded: _expanded.contains(items[i].id),
                    bids: _bids[items[i].id],
                    bidError: _bidErrors[items[i].id],
                    loadingBids: _loadingBids.contains(items[i].id),
                    acting: _acting.contains(items[i].id),
                    onToggleBids: () => _toggle(items[i].id),
                    onRetryBids: () => _loadBids(items[i].id),
                    onOpen: () => context.openRoute(
                      AppRouteNames.auctionDetailPath(items[i].id),
                    ),
                    onEnd: () => _end(items[i]),
                    onAccept: () => _accept(items[i]),
                    onReject: () => _reject(items[i]),
                    onMore: () => _more(items[i]),
                    onSelectWinner: (bid) => _acceptBid(items[i], bid),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _toggle(String id) async {
    setState(() {
      if (!_expanded.remove(id)) _expanded.add(id);
    });
    if (_expanded.contains(id) && !_bids.containsKey(id)) await _loadBids(id);
  }

  Future<void> _loadBids(String id) async {
    if (_loadingBids.contains(id)) return;
    setState(() {
      _loadingBids.add(id);
      _bidErrors.remove(id);
    });
    final result = await ref.read(auctionRepositoryProvider).bids(id);
    if (!mounted) return;
    setState(() {
      _loadingBids.remove(id);
      switch (result) {
        case Success(:final value):
          _bids[id] = [...value]..sort((a, b) => b.amount.compareTo(a.amount));
        case ResultFailure(:final failure):
          _bidErrors[id] = failure.message;
      }
    });
  }

  Future<void> _end(AuctionListing a) async {
    final ok = await showAtelierConfirm(
      context: context,
      title: 'End this auction now?',
      message:
          'Bidding on ${a.title} closes immediately at the current price of '
          '${auctionBidAmount(a.currentBid)}.',
      confirmLabel: 'End auction',
      destructive: true,
      icon: Icons.stop_circle_outlined,
    );
    if (ok) {
      await _act(a, () => ref.read(auctionRepositoryProvider).end(a.id));
    }
  }

  /// Sells to the highest bidder who has not declined: the top bid, or the
  /// next one after a winner declined or let the 24 hours run out.
  Future<void> _accept(AuctionListing a) async {
    if (!_bids.containsKey(a.id)) await _loadBids(a.id);
    if (!mounted) return;
    final next = a.eligibleBids(_bids[a.id]).firstOrNull;
    if (next == null) {
      showAtelierToast(
        context,
        _bidErrors[a.id] ??
            'No eligible bidders remain. Restart or remove the auction.',
        tone: AtelierTone.ruby,
      );
      return;
    }
    await _acceptBid(a, next);
  }

  /// `POST /auction/:id/accept` with `{ bidId }`. The winner gets the item
  /// in their cart at this bid and 24 hours to check out.
  Future<void> _acceptBid(AuctionListing a, AuctionBid bid) async {
    final reserve = a.reservePrice;
    final below = reserve != null && bid.amount < reserve;
    final ok = await showAtelierConfirm(
      context: context,
      title: 'Sell to this bidder?',
      message:
          '${bid.buyerName ?? 'This bidder'} wins ${a.title} at '
          '${auctionBidAmount(bid.amount)}'
          '${below ? ', below your reserve of ${auctionBidAmount(reserve)}' : ''}. '
          'It goes into their cart and they have 24 hours to pay, or it '
          'comes back to you.',
      confirmLabel: 'Accept',
      icon: Icons.handshake_outlined,
    );
    if (!ok) return;
    await _act(
      a,
      () => ref
          .read(auctionRepositoryProvider)
          .accept(auctionId: a.id, bidId: bid.id),
    );
  }

  Future<void> _more(AuctionListing a) async {
    final action = await showAtelierOptions<String>(
      context: context,
      title: a.title,
      subtitle: a.phaseLabel,
      options: [
        const AtelierOption(
          value: 'open',
          label: 'Open auction',
          icon: Icons.open_in_new_rounded,
          hint: 'See the public lot page',
        ),
        if (a.awaitingSellerDecision || a.isEnded)
          const AtelierOption(
            value: 'reject',
            label: 'Reject outcome',
            icon: Icons.replay_rounded,
            hint: 'Restart the auction or remove the listing',
          ),
        if (!a.isSold)
          const AtelierOption(
            value: 'delete',
            label: 'Delete auction',
            icon: Icons.delete_outline_rounded,
            destructive: true,
          ),
      ],
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'open':
        context.openRoute(AppRouteNames.auctionDetailPath(a.id));
      case 'reject':
        await _reject(a);
      case 'delete':
        final ok = await showAtelierConfirm(
          context: context,
          title: 'Delete this auction?',
          message:
              '${a.title} and its bids will be removed. This can’t be '
              'undone.',
          confirmLabel: context.tr(RemainingL10n.delete),
          destructive: true,
        );
        if (ok) {
          await _act(a, () => ref.read(auctionRepositoryProvider).delete(a.id));
        }
    }
  }

  Future<void> _reject(AuctionListing a) async {
    final action = await showAtelierOptions<String>(
      context: context,
      title: 'Reject outcome',
      options: const [
        AtelierOption(
          value: 'restart',
          label: 'Restart auction',
          icon: Icons.restart_alt_rounded,
          hint: 'Relists in 5 minutes for 7 days with the same bids floor',
        ),
        AtelierOption(
          value: 'remove',
          label: 'Remove listing',
          icon: Icons.remove_circle_outline_rounded,
          hint: 'Takes the stone off auction',
          destructive: true,
        ),
      ],
    );
    if (action == null || !mounted) return;
    final window = action == 'restart' ? auctionRestartWindow() : null;
    await _act(
      a,
      () => ref
          .read(auctionRepositoryProvider)
          .reject(
            auctionId: a.id,
            action: action,
            startTime: window?.start,
            endTime: window?.end,
            minimumBid: a.minimumBid,
            reservePrice: a.reservePrice,
          ),
    );
  }

  Future<void> _act(
    AuctionListing a,
    Future<Result<AuctionMutation, Failure>> Function() call,
  ) async {
    setState(() => _acting.add(a.id));
    final result = await call();
    if (!mounted) return;
    setState(() => _acting.remove(a.id));
    switch (result) {
      case Success(:final value):
        AppHaptics.success();
        showAtelierToast(context, value.message, tone: AtelierTone.emerald);
        _bids.remove(a.id);
        await _refresh();
      case ResultFailure(:final failure):
        AppHaptics.error();
        showAtelierToast(context, failure.message, tone: AtelierTone.ruby);
    }
  }
}

AtelierTone _phaseTone(AuctionListing a) {
  if (a.isSold) return AtelierTone.emerald;
  if (a.awaitingSellerDecision) return AtelierTone.amber;
  if (a.isUpcoming) return AtelierTone.sapphire;
  if (a.isLive) return AtelierTone.ruby;
  return AtelierTone.neutral;
}

class _AuctionCard extends StatelessWidget {
  const _AuctionCard({
    required this.auction,
    required this.expanded,
    required this.loadingBids,
    required this.acting,
    required this.onToggleBids,
    required this.onRetryBids,
    required this.onOpen,
    required this.onEnd,
    required this.onAccept,
    required this.onReject,
    required this.onMore,
    required this.onSelectWinner,
    this.bids,
    this.bidError,
  });

  final AuctionListing auction;
  final bool expanded;
  final bool loadingBids;
  final bool acting;
  final List<AuctionBid>? bids;
  final String? bidError;
  final VoidCallback onToggleBids;
  final VoidCallback onRetryBids;
  final VoidCallback onOpen;
  final VoidCallback onEnd;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onMore;
  final ValueChanged<AuctionBid> onSelectWinner;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final a = auction;
    final contextLine = auctionProductContextLine(a);
    final deadline = auctionDeadline(a);
    final hasBids = a.highestBidAmount != null;
    final hasDeclined = a.declinedWinnerIds.isNotEmpty;
    final outcome = auctionSellerOutcome(a);
    final bidCount = bids?.length ?? a.bids.length;
    final reserve = a.reservePrice;
    final when = a.isUpcoming && a.startTime != null
        ? 'Starts ${auctionWhen(a.startTime!)}'
        : a.endTime != null
        ? '${a.isEnded ? 'Ended' : 'Ends'} ${auctionWhen(a.endTime!)}'
        : null;
    final floor = reserve == null
        ? 'Min ${auctionBidAmount(a.minimumBid)}'
        : a.isReserveMet
        ? 'Reserve met'
        : 'Reserve ${auctionBidAmount(reserve)}';

    return AtelierCard(
      onTap: onOpen,
      semanticLabel: 'Auction ${a.title}',
      borderColor: a.awaitingSellerDecision
          ? p.amber.withValues(alpha: 0.45)
          : null,
      padding: const EdgeInsets.all(AtelierSpace.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AtelierThumb(
                url: a.imageUrl,
                size: 40,
                icon: Icons.gavel_rounded,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtelierType.display(p.ink, size: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (contextLine.isNotEmpty) contextLine,
                        if (a.stockNumber != null) a.stockNumber!,
                      ].join(' · ').ifEmpty(a.productType),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtelierType.caption(p.muted, size: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AtelierPill(
                    label: a.phaseLabel,
                    tone: _phaseTone(a),
                    dense: true,
                  ),
                  if (deadline != null && !a.isEnded) ...[
                    const SizedBox(height: 3),
                    AuctionCountdown(
                      deadline: deadline,
                      short: true,
                      style: AtelierType.figure(p.ink, size: 11),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                a.isSold
                    ? 'Sold '
                    : hasBids
                    ? 'High bid '
                    : 'Opening ',
                style: AtelierType.caption(p.muted, size: 11),
              ),
              Text(
                auctionBidAmount(a.winningAmount ?? a.currentBid),
                style: AtelierType.figure(p.ink, size: 16),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$bidCount bid${bidCount == 1 ? '' : 's'} · ',
                      ),
                      TextSpan(
                        text: floor,
                        style: TextStyle(
                          color: reserve != null && a.isReserveMet
                              ? p.emerald
                              : null,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: AtelierType.caption(p.muted, size: 11),
                ),
              ),
            ],
          ),
          if (a.winnerName != null &&
              a.winPayment != AuctionWinPayment.none) ...[
            const SizedBox(height: 5),
            Row(
              children: [
                Icon(Icons.emoji_events_outlined, size: 13, color: p.gold),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Winner: ${a.winnerName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AtelierType.label(p.ink, size: 12),
                  ),
                ),
              ],
            ),
          ],
          if (outcome case final line?) ...[
            const SizedBox(height: 5),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  line.icon,
                  size: 13,
                  color: line.done ? p.emerald : p.amber,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    line.text,
                    style: AtelierType.caption(p.inkSoft, size: 11),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              _BidsToggle(
                expanded: expanded,
                count: bidCount,
                onTap: onToggleBids,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  when ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtelierType.caption(p.muted, size: 11),
                ),
              ),
              if (a.awaitingSellerDecision) ...[
                AtelierButton(
                  label: hasBids ? 'Reject' : 'Relist',
                  compact: true,
                  variant: AtelierButtonVariant.ghost,
                  onPressed: acting ? null : onReject,
                ),
                if (hasBids) ...[
                  const SizedBox(width: 4),
                  AtelierButton(
                    label: hasDeclined ? 'Accept next' : 'Accept',
                    icon: Icons.check_rounded,
                    compact: true,
                    variant: AtelierButtonVariant.gold,
                    loading: acting,
                    onPressed: onAccept,
                  ),
                ],
              ] else if (a.isLive)
                AtelierButton(
                  label: 'End now',
                  compact: true,
                  variant: AtelierButtonVariant.secondary,
                  loading: acting,
                  onPressed: onEnd,
                )
              else if (acting)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                    color: p.gold,
                  ),
                ),
              AtelierIconButton(
                icon: Icons.more_horiz_rounded,
                tooltip: 'More actions',
                size: 32,
                onPressed: acting ? null : onMore,
              ),
            ],
          ),
          AnimatedSize(
            duration: AtelierMotion.slow,
            curve: AtelierMotion.emphasized,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: _BidLadder(
                      bids: bids,
                      loading: loadingBids,
                      error: bidError,
                      canSelect: a.awaitingSellerDecision && !acting,
                      declinedIds: a.declinedWinnerIds,
                      onRetry: onRetryBids,
                      onSelect: onSelectWinner,
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}

class _BidsToggle extends StatelessWidget {
  const _BidsToggle({
    required this.expanded,
    required this.count,
    required this.onTap,
  });

  final bool expanded;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Pressable(
      onTap: onTap,
      semanticLabel: expanded ? 'Hide bids' : 'Show bids',
      borderRadius: BorderRadius.circular(AtelierRadius.pill),
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: expanded ? p.goldSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(AtelierRadius.pill),
          border: Border.all(color: expanded ? p.gold : p.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bids', style: AtelierType.label(p.ink, size: 12)),
            const SizedBox(width: 2),
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: AtelierMotion.base,
              curve: AtelierMotion.emphasized,
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: p.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BidLadder extends StatelessWidget {
  const _BidLadder({
    required this.bids,
    required this.loading,
    required this.error,
    required this.canSelect,
    required this.onRetry,
    required this.onSelect,
    this.declinedIds = const [],
  });

  final List<AuctionBid>? bids;
  final bool loading;
  final String? error;
  final bool canSelect;

  /// Bidders who declined the win or let the 24 hours run out; they can't
  /// be accepted again.
  final List<String> declinedIds;
  final VoidCallback onRetry;
  final ValueChanged<AuctionBid> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    if (loading) {
      return Column(
        children: [
          for (var i = 0; i < 3; i++)
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SkeletonBox(width: 22, height: 22, radius: 11),
                  SizedBox(width: 8),
                  Expanded(child: SkeletonBox(height: 12)),
                  SizedBox(width: 30),
                  SkeletonBox(width: 60, height: 12),
                ],
              ),
            ),
        ],
      );
    }
    if (error != null) {
      return AtelierNotice(
        text: error!,
        tone: AtelierTone.ruby,
        icon: Icons.error_outline_rounded,
        actionLabel: 'Retry',
        onAction: onRetry,
      );
    }
    final list = bids ?? const <AuctionBid>[];
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          'No bids yet.',
          style: AtelierType.caption(p.muted, size: 11.5),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AtelierRadius.md),
        border: Border.all(color: p.hairline),
      ),
      child: Column(
        children: [
          for (var i = 0; i < list.length; i++) ...[
            if (i > 0) Container(height: 1, color: p.hairline),
            Reveal(
              index: i < 6 ? i : 0,
              offset: 6,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == 0 ? p.goldSoft : p.sunken,
                        border: i == 0
                            ? Border.all(color: p.gold.withValues(alpha: 0.5))
                            : null,
                      ),
                      child: i == 0
                          ? Icon(
                              Icons.emoji_events_rounded,
                              size: 13,
                              color: p.gold,
                            )
                          : Text(
                              '${i + 1}',
                              style: AtelierType.figure(p.inkSoft, size: 10.5),
                            ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            list[i].buyerName ?? list[i].buyerId,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AtelierType.label(p.ink, size: 12.5),
                          ),
                          if (list[i].createdAt != null)
                            Text(
                              auctionWhen(list[i].createdAt!),
                              style: AtelierType.caption(p.muted, size: 10.5),
                            ),
                        ],
                      ),
                    ),
                    if (declinedIds.contains(list[i].buyerId)) ...[
                      const AtelierPill(
                        label: 'Declined',
                        tone: AtelierTone.ruby,
                        dense: true,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      auctionBidAmount(list[i].amount),
                      style: AtelierType.figure(
                        i == 0 ? p.gold : p.ink,
                        size: 13.5,
                      ),
                    ),
                    if (canSelect &&
                        list[i].id.isNotEmpty &&
                        !declinedIds.contains(list[i].buyerId)) ...[
                      const SizedBox(width: 6),
                      AtelierButton(
                        label: 'Accept',
                        compact: true,
                        variant: AtelierButtonVariant.secondary,
                        onPressed: () => onSelect(list[i]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
