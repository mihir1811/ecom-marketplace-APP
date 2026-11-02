import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../application/live_show_room.dart';
import '../../domain/live_format.dart';
import '../../domain/models/live_show_models.dart';
import '../live_show_actions.dart';
import 'live_bid_sheet.dart';
import 'live_countdown.dart';
import 'live_rolling_amount.dart';
import 'live_slide_to_bid.dart';
import 'live_stage_tokens.dart';
import 'live_toast.dart';

/// Compact auction bar over the video, built to leave the stream clear:
///  1. the piece (image ringed by its draining clock), its live price,
///     bid count and countdown — one glance;
///  2. "Custom" (exact amount, steps, quick picks) beside slide-to-bid at
///     the next minimum — one gesture;
///  3. a hairline strip with free-to-bid and ship-to, each fixable in place.
/// Swipe down or tap the handle to fold it to a single line.
class LiveAuctionDock extends ConsumerStatefulWidget {
  const LiveAuctionDock({
    required this.showId,
    required this.onOpenLineup,
    super.key,
  });

  final String showId;
  final VoidCallback onOpenLineup;

  @override
  ConsumerState<LiveAuctionDock> createState() => _LiveAuctionDockState();
}

class _LiveAuctionDockState extends ConsumerState<LiveAuctionDock>
    with SingleTickerProviderStateMixin {
  StreamSubscription<LiveNotice>? _notices;
  Timer? _closeTimer;
  String? _closeTimerFor;
  var _collapsed = false;
  var _flashOutbid = false;
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  /// The amount in the bid box, for [_amountFor]'s lot.
  int? _amount;
  String? _amountFor;

  LiveShowRoomController get _room =>
      ref.read(liveShowRoomProvider(widget.showId).notifier);

  @override
  void initState() {
    super.initState();
    _notices = _room.notices.listen((n) {
      if (n is! LiveOutbidNotice || !mounted) return;
      setState(() {
        _flashOutbid = true;
        _collapsed = false;
      });
      if (!MediaQuery.disableAnimationsOf(context)) {
        unawaited(_shake.forward(from: 0));
      }
      Timer(const Duration(milliseconds: 1800), () {
        if (mounted) setState(() => _flashOutbid = false);
      });
    });
  }

  @override
  void dispose() {
    _notices?.cancel();
    _closeTimer?.cancel();
    _shake.dispose();
    super.dispose();
  }

  /// Rebuild once when the lot's clock reaches 0 so bidding disables.
  void _armCloseTimer(LiveShowRoomState s) {
    final lot = s.current;
    final key = lot == null ? null : '${lot.id}@${lot.endsAt}';
    if (key == _closeTimerFor) return;
    _closeTimerFor = key;
    _closeTimer?.cancel();
    if (lot == null) return;
    final left = s.remaining(lot);
    if (left <= Duration.zero) return;
    _closeTimer = Timer(left, () {
      if (mounted) setState(() {});
    });
  }

  /// The bid box amount: the next minimum for a new lot, and never below
  /// the minimum once others bid past it.
  int _amountOf(LiveAuctionLot lot) {
    final min = lot.minNextBid.ceil();
    final amount = _amountFor == lot.id ? (_amount ?? min) : min;
    return math.max(amount, min);
  }

  void _setAmount(LiveAuctionLot lot, int amount) {
    AppHaptics.selection();
    setState(() {
      _amountFor = lot.id;
      _amount = math.max(amount, lot.minNextBid.ceil());
    });
  }

  Future<void> _bid(int amount) async {
    final outcome = await _room.placeBid(amount);
    if (!mounted) return;
    await _handle(outcome);
  }

  Future<void> _handle(LiveBidOutcome outcome) async {
    switch (outcome) {
      case LiveBidPlaced(:final amount):
        showLiveToast(
          context,
          'Bid placed at ${liveInr(amount)}',
          tone: LiveToastTone.success,
        );
      case LiveBidNeedsTopUp(:final shortfall):
        AppHaptics.warning();
        showLiveToast(
          context,
          'Not enough in your wallet. Add ${liveInr(shortfall.ceil())} to '
          'bid this much.',
          tone: LiveToastTone.info,
        );
        await openLiveTopUp(context, ref, widget.showId, shortfall: shortfall);
      case LiveBidNeedsAddress():
        showLiveToast(
          context,
          'Add a delivery address first. Wins ship there.',
          tone: LiveToastTone.info,
        );
        await openLiveAddress(context, ref, widget.showId);
      case LiveBidNeedsSignIn():
        openLiveSignIn(context);
      case LiveBidRejected(:final message, :final minBid):
        showLiveToast(context, message, tone: LiveToastTone.error);
        final lot = ref.read(liveShowRoomProvider(widget.showId)).current;
        if (minBid != null && lot != null) _setAmount(lot, minBid.ceil());
    }
  }

  /// Type an exact amount; the slider then confirms it.
  Future<void> _editAmount(LiveAuctionLot lot) async {
    final s = ref.read(liveShowRoomProvider(widget.showId));
    final amount = await showLiveBidSheet(
      context,
      lot: lot,
      initial: _amountOf(lot),
      freeToBid: s.me?.wallet.availableBalance,
    );
    if (amount == null || !mounted) return;
    _setAmount(lot, amount);
  }

  void _toggle(bool collapse) {
    if (collapse == _collapsed) return;
    AppHaptics.selection();
    setState(() => _collapsed = collapse);
  }

  @override
  Widget build(BuildContext context) {
    // Only the lot, wallet, bid in flight and clock: chat lines arrive far
    // more often and never change the dock.
    final room = liveShowRoomProvider(widget.showId);
    ref.watch(
      room.select((s) => (s.auction, s.me, s.placingAmount, s.clockOffset)),
    );
    final s = ref.read(room);
    final signedIn = ref.watch(authProvider.select((a) => a.isAuthenticated));
    _armCloseTimer(s);
    final lot = s.current;

    final Widget body;
    final String mode;
    if (lot == null) {
      mode = 'idle';
      body = _Idle(
        showId: widget.showId,
        state: s,
        signedIn: signedIn,
        onOpenLineup: widget.onOpenLineup,
      );
    } else if (_collapsed) {
      mode = 'mini';
      body = _Collapsed(
        state: s,
        lot: lot,
        amount: _amountOf(lot),
        signedIn: signedIn,
        onExpand: () => _toggle(false),
      );
    } else {
      mode = 'full:${lot.id}';
      body = _Expanded(
        showId: widget.showId,
        state: s,
        lot: lot,
        amount: _amountOf(lot),
        signedIn: signedIn,
        onCollapse: () => _toggle(true),
        onEditAmount: () => _editAmount(lot),
        onBid: _bid,
      );
    }

    // Never taller than ~45% of the screen; scrolls on tiny phones.
    final maxHeight = MediaQuery.sizeOf(context).height * 0.45;
    final dock = GestureDetector(
      onVerticalDragEnd: lot == null
          ? null
          : (d) {
              final v = d.primaryVelocity ?? 0;
              if (v > 250) _toggle(true);
              if (v < -250) _toggle(false);
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: LiveMotion.ease,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _flashOutbid
                  ? LiveStage.urgent.withValues(alpha: 0.45)
                  : Colors.black.withValues(alpha: 0.35),
              blurRadius: _flashOutbid ? 30 : 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: LiveGlass(
          radius: 24,
          border: Border.all(
            color: _flashOutbid ? LiveStage.urgent : LiveStage.hairlineStrong,
            width: _flashOutbid ? 1.6 : 1,
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 380),
            curve: LiveMotion.emphasized,
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: SingleChildScrollView(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 340),
                  switchInCurve: LiveMotion.ease,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, a) => FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0, 0.06),
                        end: Offset.zero,
                      ).animate(a),
                      child: child,
                    ),
                  ),
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      // Outgoing states keep their own height, pinned to the foot.
                      for (final p in previous)
                        Positioned(left: 0, right: 0, bottom: 0, child: p),
                      ?current,
                    ],
                  ),
                  child: KeyedSubtree(key: ValueKey(mode), child: body),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // Its clocks and slider repaint here without repainting the stage.
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _shake,
        builder: (context, child) {
          final t = _shake.value;
          final dx = t == 0 || t == 1
              ? 0.0
              : math.sin(t * math.pi * 7) * 7 * (1 - t);
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: dock,
      ),
    );
  }
}

// ── States ────────────────────────────────────────────────────────────────

class _Handle extends StatelessWidget {
  const _Handle({required this.onTap, required this.tooltip});

  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 16,
          child: Center(
            child: Container(
              width: 34,
              height: 4,
              decoration: BoxDecoration(
                color: LiveStage.hairlineStrong,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Idle extends StatelessWidget {
  const _Idle({
    required this.showId,
    required this.state,
    required this.signedIn,
    required this.onOpenLineup,
  });

  final String showId;
  final LiveShowRoomState state;
  final bool signedIn;
  final VoidCallback onOpenLineup;

  @override
  Widget build(BuildContext context) {
    final next = state.upNext.isEmpty ? null : state.upNext.first;
    final last = state.results.isEmpty ? null : state.results.first;
    final me = state.me;
    final browsable = state.upNext.isNotEmpty || state.results.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LivePressable(
            scale: 0.98,
            onTap: browsable ? onOpenLineup : null,
            semanticLabel: 'Open the lineup',
            child: Row(
              children: [
                LiveThumb(url: next?.image ?? last?.image, size: 44),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        next != null
                            ? 'UP NEXT · OPENS AT ${liveInr(next.startingBid)}'
                            : 'BETWEEN PIECES',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LiveType.eyebrow(
                          size: 9.5,
                          color: next != null ? LiveStage.champagne : null,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        next != null
                            ? next.title
                            : last != null
                            ? _resultLine(last)
                            : 'Bidding opens when the seller puts a piece up.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: next != null
                            ? LiveType.display(17)
                            : LiveType.body(13, color: LiveStage.ink),
                      ),
                    ],
                  ),
                ),
                if (browsable)
                  Icon(Icons.chevron_right_rounded, color: LiveStage.inkMuted),
              ],
            ),
          ),
          if (signedIn && me != null && !me.isSeller) ...[
            const SizedBox(height: 6),
            _AccountStrip(showId: showId, me: me),
          ],
        ],
      ),
    );
  }
}

String _resultLine(LiveAuctionLot lot) => switch (lot.status) {
  LotStatus.sold => 'Sold: ${lot.title} for ${liveInr(lot.currentBid ?? 0)}',
  LotStatus.unsold => 'No bids on ${lot.title}',
  _ => '${lot.title} was withdrawn',
};

class _Expanded extends ConsumerWidget {
  const _Expanded({
    required this.showId,
    required this.state,
    required this.lot,
    required this.amount,
    required this.signedIn,
    required this.onCollapse,
    required this.onEditAmount,
    required this.onBid,
  });

  final String showId;
  final LiveShowRoomState state;
  final LiveAuctionLot lot;
  final int amount;
  final bool signedIn;
  final VoidCallback onCollapse;
  final VoidCallback onEditAmount;
  final Future<void> Function(int amount) onBid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = state.me;
    final leading = state.leadingAmount(lot.id);
    final closed = state.remaining(lot) <= Duration.zero;
    final top = lot.recentBids.isEmpty ? null : lot.recentBids.first;
    final leader = lot.leaderName ?? top?.bidderName;
    final hasBids = lot.hasBids;
    final price = hasBids ? lot.currentBid! : lot.startingBid;

    final (String status, Color statusColor) = !hasBids
        ? ('Starting bid · be the first', LiveStage.inkMuted)
        : leading != null
        ? ('You are the top bidder', LiveStage.leading)
        : ('Top · ${leader ?? 'another buyer'}', LiveStage.inkMuted);
    final eyebrow = [
      if (lot.position > 0) 'LOT ${lot.position.toString().padLeft(2, '0')}',
      '${lot.bidCount} ${lot.bidCount == 1 ? 'BID' : 'BIDS'}',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Handle(onTap: onCollapse, tooltip: 'Minimise'),
          // One glance: piece, price, clock.
          LivePressable(
            scale: 0.98,
            semanticLabel: '${lot.title}. Open details.',
            onTap: () => openLiveLot(context, ref, lot),
            child: Row(
              children: [
                LiveCountdownRing(
                  endsAt: lot.endsAt,
                  startedAt: lot.startedAt,
                  durationSeconds: lot.durationSeconds,
                  serverNow: state.serverNow,
                  size: 52,
                  stroke: 2.2,
                  child: LiveThumb(url: lot.image, size: 40, radius: 12),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: LiveStage.live,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              eyebrow,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: LiveType.eyebrow(size: 9),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              lot.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: LiveType.display(17),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.north_east_rounded,
                            size: 12,
                            color: LiveStage.inkFaint,
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      AnimatedSwitcher(
                        duration: LiveMotion.base,
                        child: Text(
                          status,
                          key: ValueKey(status),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LiveType.label(
                            11.5,
                            color: statusColor,
                            weight: leading != null
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    LiveCountdown(
                      endsAt: lot.endsAt,
                      serverNow: state.serverNow,
                    ),
                    const SizedBox(height: 4),
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (r) =>
                          LiveStage.champagneGradient.createShader(r),
                      child: LiveRollingText(
                        liveInr(price),
                        semanticsLabel:
                            '${hasBids ? 'Current bid' : 'Starting bid'} '
                            '${liveInr(price)}',
                        style: LiveType.display(25, height: 1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // One gesture: custom amount, or slide at the next minimum.
          _Controls(
            showId: showId,
            state: state,
            lot: lot,
            amount: amount,
            signedIn: signedIn,
            leading: leading,
            closed: closed,
            onEditAmount: onEditAmount,
            onBid: onBid,
          ),
          if (signedIn && me != null && !me.isSeller) ...[
            const SizedBox(height: 6),
            _AccountStrip(showId: showId, me: me),
          ],
        ],
      ),
    );
  }
}

class _Controls extends ConsumerWidget {
  const _Controls({
    required this.showId,
    required this.state,
    required this.lot,
    required this.amount,
    required this.signedIn,
    required this.leading,
    required this.closed,
    required this.onEditAmount,
    required this.onBid,
  });

  final String showId;
  final LiveShowRoomState state;
  final LiveAuctionLot lot;
  final int amount;
  final bool signedIn;
  final double? leading;
  final bool closed;
  final VoidCallback onEditAmount;
  final Future<void> Function(int amount) onBid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!signedIn) {
      return LiveButton(
        label: 'Sign in to bid',
        icon: Icons.login_rounded,
        onTap: () => openLiveSignIn(context),
      );
    }
    if (state.me?.isSeller ?? false) {
      return _Banner(
        icon: Icons.storefront_outlined,
        color: LiveStage.inkMuted,
        text: 'This is your show, so bidding is off.',
      );
    }
    if (closed) {
      return const _Banner(
        icon: Icons.gavel_rounded,
        color: LiveStage.urgent,
        text: 'Going, going… closing this piece',
        pulse: true,
      );
    }
    if (leading != null) {
      return _Banner(
        icon: Icons.workspace_premium_rounded,
        color: LiveStage.leading,
        text: "You're the highest bidder at ${liveInr(leading!)}",
        strong: true,
      );
    }

    final room = ref.read(liveShowRoomProvider(showId).notifier);
    final placing = state.placingAmount;
    final me = state.me;
    final free = me?.wallet.availableBalance;
    final shortfall = free == null ? 0.0 : amount - free;
    final custom = amount != lot.minNextBid.ceil();

    // Why the slider is locked, and what tapping it does.
    final (String? lock, VoidCallback? fix) = switch (me) {
      null => ('Checking your wallet…', () => unawaited(room.refreshMe())),
      _ when !me.hasDeliveryAddress => (
        'Add a delivery address',
        () => unawaited(openLiveAddress(context, ref, showId)),
      ),
      _ when shortfall > 0 => (
        'Add ${liveInr(shortfall.ceil())} to bid',
        () => unawaited(
          openLiveTopUp(context, ref, showId, shortfall: shortfall),
        ),
      ),
      _ => (null, null),
    };

    return Row(
      children: [
        _CustomButton(
          amount: amount,
          custom: custom,
          short: shortfall > 0,
          onTap: onEditAmount,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: LiveSlideToBid(
            key: ValueKey('slide-${lot.id}'),
            label: 'Bid ${liveInr(amount)}',
            busy: placing != null,
            lockedLabel: lock,
            onLockedTap: fix,
            onSubmit: lock == null && placing == null
                ? () => onBid(amount)
                : null,
          ),
        ),
      ],
    );
  }
}

/// "Custom": opens the exact-amount pad with steps and quick picks. Lights
/// champagne once the bid is above the minimum.
class _CustomButton extends StatelessWidget {
  const _CustomButton({
    required this.amount,
    required this.custom,
    required this.short,
    required this.onTap,
  });

  final int amount;
  final bool custom;
  final bool short;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = short
        ? LiveStage.urgent
        : custom
        ? LiveStage.champagne
        : LiveStage.ink;
    final lit = custom || short;
    return Tooltip(
      message: 'Custom bid',
      child: LivePressable(
        scale: 0.94,
        semanticLabel:
            'Custom bid. Now ${liveInr(amount)}. Tap to change the amount.',
        onTap: onTap,
        child: AnimatedContainer(
          duration: LiveMotion.quick,
          width: 64,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: lit
                ? accent.withValues(alpha: 0.12)
                : LiveStage.ink.withValues(alpha: 0.06),
            border: Border.all(
              color: lit
                  ? accent.withValues(alpha: 0.6)
                  : LiveStage.hairlineStrong,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.tune_rounded, size: 18, color: accent),
              const SizedBox(height: 3),
              Text('Custom', style: LiveType.label(10.5, color: accent)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Collapsed extends StatelessWidget {
  const _Collapsed({
    required this.state,
    required this.lot,
    required this.amount,
    required this.signedIn,
    required this.onExpand,
  });

  final LiveShowRoomState state;
  final LiveAuctionLot lot;
  final int amount;
  final bool signedIn;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final leading = state.leadingAmount(lot.id);
    final closed = state.remaining(lot) <= Duration.zero;
    final canBid =
        signedIn &&
        leading == null &&
        !closed &&
        !(state.me?.isSeller ?? false) &&
        state.placingAmount == null;
    return Semantics(
      button: true,
      label: '${lot.title}. Expand bidding.',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onExpand,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              LiveCountdownRing(
                endsAt: lot.endsAt,
                startedAt: lot.startedAt,
                durationSeconds: lot.durationSeconds,
                serverNow: state.serverNow,
                size: 44,
                stroke: 2,
                child: LiveThumb(url: lot.image, size: 34, radius: 10),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lot.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LiveType.display(15),
                    ),
                    const SizedBox(height: 1),
                    if (leading != null)
                      Text(
                        'You lead at ${liveInr(leading)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LiveType.label(12, color: LiveStage.leading),
                      )
                    else
                      Row(
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: LiveRollingText(
                                liveInr(lot.currentBid ?? lot.startingBid),
                                style: LiveType.figure(
                                  12.5,
                                  color: LiveStage.champagne,
                                  weight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              '  ·  ${lot.bidCount} '
                              '${lot.bidCount == 1 ? 'bid' : 'bids'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: LiveType.body(11.5),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              LiveCountdown(endsAt: lot.endsAt, serverNow: state.serverNow),
              const SizedBox(width: 5),
              // Opens the full bar: a bid is always confirmed by sliding.
              if (canBid)
                Flexible(
                  child: LivePressable(
                    onTap: onExpand,
                    semanticLabel: 'Bid ${liveInr(amount)}',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LiveStage.champagneGradient,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Bid ${liveInr(amount)}',
                          style: LiveType.label(
                            12.5,
                            color: LiveStage.onChampagne,
                            weight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else
                Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: LiveStage.inkMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Wallet and address ────────────────────────────────────────────────────

/// Hairline strip: free-to-bid (with any hold) on the left, ship-to on the
/// right. Each half opens its fix in place.
class _AccountStrip extends ConsumerWidget {
  const _AccountStrip({required this.showId, required this.me});

  final String showId;
  final MyShowState me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = me.wallet;
    final hasAddress = me.hasDeliveryAddress;
    final address = hasAddress
        ? ref.watch(liveShipToProvider).asData?.value
        : null;
    final held = wallet.heldAmount > 0;
    final free = liveInr(wallet.availableBalance);
    final hold = liveInr(wallet.heldAmount);
    return Container(
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: LiveStage.ink.withValues(alpha: 0.035),
        border: Border.all(color: LiveStage.hairline),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StripHalf(
              icon: Icons.account_balance_wallet_outlined,
              text: held ? '$free free · $hold held' : '$free free to bid',
              action: 'Add',
              semanticLabel: held
                  ? 'Free to bid $free, $hold on hold for your leading '
                        'bids. Add funds.'
                  : 'Free to bid $free. Add funds.',
              onTap: () => openLiveTopUp(context, ref, showId),
            ),
          ),
          Container(width: 1, height: 18, color: LiveStage.hairline),
          Expanded(
            child: _StripHalf(
              icon: hasAddress
                  ? Icons.local_shipping_outlined
                  : Icons.error_outline_rounded,
              warn: !hasAddress,
              text: !hasAddress
                  ? 'No delivery address'
                  : address == null
                  ? 'Ships to saved address'
                  : 'Ships to ${address.city}',
              action: hasAddress ? 'Change' : 'Add',
              semanticLabel: !hasAddress
                  ? 'Add a delivery address to bid'
                  : address == null
                  ? 'Wins ship to your saved address. Change.'
                  : 'Wins ship to ${address.fullName}, ${address.city}. '
                        'Change.',
              onTap: () => openLiveAddress(context, ref, showId),
            ),
          ),
        ],
      ),
    );
  }
}

class _StripHalf extends StatelessWidget {
  const _StripHalf({
    required this.icon,
    required this.text,
    required this.action,
    required this.semanticLabel,
    required this.onTap,
    this.warn = false,
  });

  final IconData icon;
  final String text;
  final String action;
  final String semanticLabel;
  final VoidCallback onTap;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final accent = warn ? LiveStage.urgent : LiveStage.champagne;
    return LivePressable(
      scale: 0.97,
      semanticLabel: semanticLabel,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Icon(icon, size: 14, color: warn ? accent : LiveStage.inkFaint),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LiveType.body(
                  11.5,
                  color: warn ? LiveStage.ink : LiveStage.inkMuted,
                  weight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(action, style: LiveType.label(11, color: accent)),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.color,
    required this.text,
    this.strong = false,
    this.pulse = false,
  });

  final IconData icon;
  final Color color;
  final String text;
  final bool strong;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    Widget banner = Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: strong ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: LiveType.label(
                13.5,
                color: strong ? color : LiveStage.ink,
                weight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    // One glint when the lead is taken; a looping one would keep the
    // stage redrawing for as long as the viewer leads.
    if (!still && strong) {
      banner = banner.animate().shimmer(
        duration: 1600.ms,
        delay: 300.ms,
        color: Colors.white.withValues(alpha: 0.18),
      );
    }
    if (!still && pulse) {
      banner = banner
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .fade(begin: 0.6, end: 1, duration: 600.ms);
    }
    return Semantics(liveRegion: true, child: banner);
  }
}
