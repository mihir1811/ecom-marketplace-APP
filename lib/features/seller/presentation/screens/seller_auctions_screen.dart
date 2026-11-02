import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/gem3d/gem_mesh.dart';
import '../../../../core/widgets/gem3d/gem_renderer.dart';
import '../../../auction/application/auction_providers.dart';
import '../../../auction/data/repositories/auction_repository_impl.dart';
import '../../../auction/domain/models/auction_models.dart';
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

  /// `?tab=` on the route: `active`, `upcoming`, `ended` or `decision`.
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

  bool get _deciding => _status == _decisionTab;

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
    'active' || 'upcoming' || 'ended' || _decisionTab => tab,
    _ => null,
  };

  AuctionFeedQuery get _query => AuctionFeedQuery(
    kind: AuctionFeedKind.seller,
    status: _deciding ? null : _status,
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
    String count(int? v) => v == null ? '—' : '$v';

    return AtelierPage(
      onRefresh: _refresh,
      onNearEnd: () {
        if (feed.hasMore && !feed.isLoadingMore && !feed.isLoading) {
          ref.read(auctionFeedProvider(_query).notifier).loadMore();
        }
      },
      children: [
        AtelierHero(
          title: context.tr(RemainingL10n.auctions),
          cut: GemCut.emerald,
          look: GemLook.ice,
          action: AtelierButton(
            label: 'Create auction',
            icon: Icons.add_rounded,
            variant: AtelierButtonVariant.gold,
            onPressed: _create,
          ),
          footer: AtelierHeroStats(
            stats: [
              AtelierHeroStat(
                label: 'Live now',
                value: count(standing?.active),
                tone: (standing?.active ?? 0) > 0 ? AtelierTone.emerald : null,
              ),
              AtelierHeroStat(
                label: 'Needs decision',
                value: count(standing?.needsDecision),
                tone: (standing?.needsDecision ?? 0) > 0
                    ? AtelierTone.amber
                    : null,
              ),
              AtelierHeroStat(label: 'Sold', value: count(standing?.sold)),
              AtelierHeroStat(
                label: 'Bids received',
                value: count(standing?.bids),
              ),
            ],
          ),
        ),
        if (standingAsync.hasError) ...[
          const SizedBox(height: AtelierSpace.s12),
          AtelierNotice(
            text: standingAsync.error is Failure
                ? (standingAsync.error! as Failure).message
                : 'Could not load auction outcomes.',
            tone: AtelierTone.ruby,
            icon: Icons.error_outline_rounded,
            actionLabel: context.tr(RemainingL10n.retry),
            onAction: () => ref.invalidate(sellerAuctionStandingProvider),
          ),
        ] else if ((standing?.needsDecision ?? 0) > 0 && !_deciding) ...[
          const SizedBox(height: AtelierSpace.s12),
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
        ],
        const SizedBox(height: AtelierSpace.s16),
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
          child: _deciding
              ? KeyedSubtree(
                  key: ValueKey(
                    '$_status-${standingAsync.valueOrNull == null}',
                  ),
                  child: _decisionBody(standingAsync),
                )
              : KeyedSubtree(
                  key: ValueKey(
                    '$_status-${feed.isLoading && feed.items.isEmpty}',
                  ),
                  child: _body(context, feed),
                ),
        ),
      ],
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

  Widget _decisionBody(AsyncValue<SellerAuctionStanding> standing) {
    final items = standing.valueOrNull?.awaitingDecision;
    if (items == null) {
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
                    onSelectWinner: (bid) => _selectWinner(items[i], bid),
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

  Future<void> _accept(AuctionListing a) async {
    final ok = await showAtelierConfirm(
      context: context,
      title: 'Accept the outcome?',
      message:
          'Sell ${a.title} to the highest bidder for '
          '${auctionBidAmount(a.currentBid)}.',
      confirmLabel: 'Accept',
      icon: Icons.handshake_outlined,
    );
    if (!ok) return;
    // The backend needs the bid being accepted; an empty body is a 400.
    if (!_bids.containsKey(a.id)) await _loadBids(a.id);
    if (!mounted) return;
    final top = (_bids[a.id] ?? a.bids)
        .where((b) => b.id.isNotEmpty && !b.id.startsWith('live:'))
        .fold<AuctionBid?>(
          null,
          (best, b) => best == null || b.amount > best.amount ? b : best,
        );
    if (top == null) {
      showAtelierToast(
        context,
        _bidErrors[a.id] ?? 'Could not load the bids. Try again.',
        tone: AtelierTone.ruby,
      );
      return;
    }
    await _act(
      a,
      () => ref
          .read(auctionRepositoryProvider)
          .accept(auctionId: a.id, bidId: top.id),
    );
  }

  Future<void> _selectWinner(AuctionListing a, AuctionBid bid) async {
    final ok = await showAtelierConfirm(
      context: context,
      title: 'Choose this bidder?',
      message:
          '${bid.buyerName ?? 'This bidder'} wins ${a.title} at '
          '${auctionBidAmount(bid.amount)}.',
      confirmLabel: 'Select winner',
      icon: Icons.emoji_events_outlined,
    );
    if (ok) {
      await _act(
        a,
        () => ref
            .read(auctionRepositoryProvider)
            .selectWinner(auctionId: a.id, bidderId: bid.buyerId),
      );
    }
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
    DateTime? start;
    DateTime? end;
    if (action == 'restart') {
      final now = DateTime.now();
      start = now.add(const Duration(minutes: 5));
      end = now.add(const Duration(days: 7));
    }
    await _act(
      a,
      () => ref
          .read(auctionRepositoryProvider)
          .reject(
            auctionId: a.id,
            action: action,
            startTime: start,
            endTime: end,
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
              const SizedBox(width: 10),
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
              const SizedBox(width: 8),
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
          const SizedBox(height: 8),
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
              const SizedBox(width: 8),
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
          if (_winnerLine(a) case final line?) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  line.icon,
                  size: 13,
                  color: line.done ? p.emerald : p.amber,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    line.text,
                    style: AtelierType.caption(p.inkSoft, size: 11),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              _BidsToggle(
                expanded: expanded,
                count: bidCount,
                onTap: onToggleBids,
              ),
              const SizedBox(width: 8),
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
                    label: 'Accept',
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
                    padding: const EdgeInsets.only(top: 8),
                    child: _BidLadder(
                      bids: bids,
                      loading: loadingBids,
                      error: bidError,
                      canSelect: a.awaitingSellerDecision && !acting,
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

/// Under the winner on a sold auction: where their cart payment stands, or
/// that the last winner declined or let the 24 hours run out.
({IconData icon, String text, bool done})? _winnerLine(AuctionListing a) {
  switch (a.winPayment) {
    case AuctionWinPayment.paid:
      return (
        icon: Icons.verified_rounded,
        text: 'Paid by the winner. Ship it from your orders.',
        done: true,
      );
    case AuctionWinPayment.withGemworld:
      return (
        icon: Icons.support_agent_outlined,
        text: 'Awaiting payment: GemWorld is arranging it with the winner.',
        done: false,
      );
    case AuctionWinPayment.due:
    case AuctionWinPayment.expired:
      final due = a.paymentDueAt;
      return (
        icon: Icons.hourglass_top_rounded,
        text: due == null
            ? 'Awaiting payment from the winner.'
            : 'Awaiting payment: the winner has until ${auctionWhen(due)} '
                  'to check out, or the item comes back to you.',
        done: false,
      );
    case AuctionWinPayment.none:
      if (a.awaitingSellerDecision && a.declinedWinnerIds.isNotEmpty) {
        return (
          icon: Icons.replay_rounded,
          text:
              'The last winner declined or didn’t pay in time. Accept the '
              'next bidder, restart or remove the auction.',
          done: false,
        );
      }
      if (a.awaitingSellerDecision) {
        final reserve = a.reservePrice;
        return (
          icon: Icons.gavel_rounded,
          text: a.highestBidAmount == null
              ? 'Ended without bids. Relist it or remove the listing.'
              : reserve != null && !a.isReserveMet
              ? 'Ended below your reserve of ${auctionBidAmount(reserve)}. '
                    'Accept the highest bid, pick another bidder or reject.'
              : 'Bidding closed. Accept the highest bid, pick another bidder '
                    'or reject.',
          done: false,
        );
      }
      return null;
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
        padding: const EdgeInsets.symmetric(horizontal: 10),
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
  });

  final List<AuctionBid>? bids;
  final bool loading;
  final String? error;
  final bool canSelect;
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
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SkeletonBox(width: 22, height: 22, radius: 11),
                  SizedBox(width: 10),
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
                  horizontal: 10,
                  vertical: 6,
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
                    const SizedBox(width: 10),
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
                    Text(
                      auctionBidAmount(list[i].amount),
                      style: AtelierType.figure(
                        i == 0 ? p.gold : p.ink,
                        size: 13.5,
                      ),
                    ),
                    if (canSelect) ...[
                      const SizedBox(width: 8),
                      AtelierButton(
                        label: 'Select',
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
