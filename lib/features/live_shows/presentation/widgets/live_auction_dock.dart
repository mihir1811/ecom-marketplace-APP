import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../application/live_show_room.dart';
import '../../domain/live_format.dart';
import '../../domain/models/live_show_models.dart';
import '../live_show_actions.dart';
import 'live_bid_sheet.dart';
import 'live_countdown.dart';
import 'live_slide_to_bid.dart';
import 'live_stage_tokens.dart';

/// Bottom bidding card over the video: the item up now with its current
/// bid, bid count, next minimum and server-clock countdown; a bid amount
/// box with −/+ steps and quick picks; and a slide-to-bid track that stays
/// locked until the amount fits the wallet's "Free to bid". Wallet and
/// ship-to can be fixed in a sheet without leaving the show. Collapses to
/// a single row.
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

class _LiveAuctionDockState extends ConsumerState<LiveAuctionDock> {
  StreamSubscription<LiveNotice>? _notices;
  Timer? _closeTimer;
  String? _closeTimerFor;
  var _collapsed = false;
  var _flashOutbid = false;

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
      Timer(const Duration(milliseconds: 1600), () {
        if (mounted) setState(() => _flashOutbid = false);
      });
    });
  }

  @override
  void dispose() {
    _notices?.cancel();
    _closeTimer?.cancel();
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
        AppHaptics.success();
        showLuxeToast(context, 'Bid placed at ${liveInr(amount)}');
      case LiveBidNeedsTopUp(:final shortfall):
        AppHaptics.warning();
        showLuxeToast(
          context,
          'Not enough in your wallet. Add ${liveInr(shortfall.ceil())} to '
          'bid this much.',
          tone: LuxeTone.info,
        );
        await openLiveTopUp(context, ref, widget.showId, shortfall: shortfall);
      case LiveBidNeedsAddress():
        showLuxeToast(
          context,
          'Add a delivery address first. Wins ship there.',
          tone: LuxeTone.info,
        );
        await openLiveAddress(context, ref, widget.showId);
      case LiveBidNeedsSignIn():
        openLiveSignIn(context);
      case LiveBidRejected(:final message, :final minBid):
        showLuxeToast(context, message, tone: LuxeTone.error);
        final lot = ref.read(liveShowRoomProvider(widget.showId)).current;
        if (minBid != null && lot != null) _setAmount(lot, minBid.ceil());
    }
  }

  /// Type an amount on a number pad; the slider then confirms it.
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

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(liveShowRoomProvider(widget.showId));
    final signedIn = ref.watch(authProvider.select((a) => a.isAuthenticated));
    _armCloseTimer(s);
    final lot = s.current;

    final Widget body;
    if (lot == null) {
      body = _Idle(
        showId: widget.showId,
        state: s,
        signedIn: signedIn,
        onOpenLineup: widget.onOpenLineup,
      );
    } else if (_collapsed) {
      body = _Collapsed(
        state: s,
        lot: lot,
        amount: _amountOf(lot),
        signedIn: signedIn,
        onExpand: () => setState(() => _collapsed = false),
      );
    } else {
      body = _Expanded(
        showId: widget.showId,
        state: s,
        lot: lot,
        amount: _amountOf(lot),
        signedIn: signedIn,
        onCollapse: () => setState(() => _collapsed = true),
        onAmount: (a) => _setAmount(lot, a),
        onEditAmount: () => _editAmount(lot),
        onBid: _bid,
        onOpenLineup: widget.onOpenLineup,
      );
    }

    // Never taller than about 60% of the screen; scrolls on small phones.
    final maxHeight = MediaQuery.sizeOf(context).height * 0.6;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: LiveStage.glassStrong,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _flashOutbid ? LiveStage.urgent : LiveStage.glassBorder,
              width: _flashOutbid ? 2 : 1,
            ),
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: SingleChildScrollView(child: body),
            ),
          ),
        ),
      ),
    );
  }
}

// ── States ────────────────────────────────────────────────────────────────

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onOpenLineup,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(
              children: [
                _Thumb(url: next?.image, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        next != null ? 'UP NEXT' : 'NO ITEM UP RIGHT NOW',
                        style: _eyebrow,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        next != null
                            ? '${next.title} · from ${liveInr(next.startingBid)}'
                            : last != null
                            ? _resultLine(last)
                            : 'Bidding opens when the seller puts an item up.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.upNext.isNotEmpty || state.results.isNotEmpty)
                  Icon(Icons.chevron_right_rounded, color: LiveStage.inkMuted),
              ],
            ),
          ),
        ),
        if (signedIn && me != null && !me.isSeller)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 8, 10),
            child: _WalletLine(showId: showId, wallet: me.wallet),
          ),
      ],
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
    required this.onAmount,
    required this.onEditAmount,
    required this.onBid,
    required this.onOpenLineup,
  });

  final String showId;
  final LiveShowRoomState state;
  final LiveAuctionLot lot;
  final int amount;
  final bool signedIn;
  final VoidCallback onCollapse;
  final ValueChanged<int> onAmount;
  final VoidCallback onEditAmount;
  final Future<void> Function(int amount) onBid;
  final VoidCallback onOpenLineup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = state.me;
    final leading = state.leadingAmount(lot.id);
    final closed = state.remaining(lot) <= Duration.zero;
    final top = lot.recentBids.isEmpty ? null : lot.recentBids.first;
    final leader = lot.leaderName ?? top?.bidderName;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => openLiveLot(context, ref, lot),
                child: _Thumb(url: lot.image, size: 48),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => openLiveLot(context, ref, lot),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              lot.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: LiveStage.inkFaint,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        lot.hasBids
                            ? (leading != null
                                  ? 'You are the top bidder'
                                  : 'Top bidder: ${leader ?? 'another buyer'}')
                            : 'Be the first to bid',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: leading != null
                              ? LiveStage.leading
                              : LiveStage.inkMuted,
                          fontSize: 12,
                          fontWeight: leading != null
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  LiveCountdown(endsAt: lot.endsAt, serverNow: state.serverNow),
                  const SizedBox(height: 6),
                  _IconChip(
                    icon: Icons.keyboard_arrow_down_rounded,
                    tooltip: 'Minimise',
                    onTap: onCollapse,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          _Stats(lot: lot),
          const SizedBox(height: 12),
          _Actions(
            showId: showId,
            state: state,
            lot: lot,
            amount: amount,
            signedIn: signedIn,
            leading: leading,
            closed: closed,
            onAmount: onAmount,
            onEditAmount: onEditAmount,
            onBid: onBid,
          ),
          if (signedIn && me != null && !me.isSeller) ...[
            const SizedBox(height: 10),
            _WalletLine(showId: showId, wallet: me.wallet),
            const SizedBox(height: 4),
            _ShipToLine(showId: showId, hasAddress: me.hasDeliveryAddress),
          ],
          if (state.upNext.isNotEmpty) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: onOpenLineup,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Text('UP NEXT', style: _eyebrow),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.upNext.map((l) => l.title).join('  ·  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: LiveStage.inkMuted, fontSize: 12),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: LiveStage.inkMuted,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Current (or starting) bid, bid count and the next minimum, side by side.
class _Stats extends StatelessWidget {
  const _Stats({required this.lot});

  final LiveAuctionLot lot;

  @override
  Widget build(BuildContext context) {
    final hasBids = lot.hasBids;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LiveStage.glassBorder),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: _Stat(
                label: hasBids ? 'CURRENT BID' : 'STARTING BID',
                value: liveInr(hasBids ? lot.currentBid! : lot.startingBid),
                pulseKey: lot.currentBid,
                gold: true,
              ),
            ),
            VerticalDivider(width: 1, color: LiveStage.glassBorder),
            Expanded(
              flex: 3,
              child: _Stat(label: 'BIDS', value: '${lot.bidCount}'),
            ),
            VerticalDivider(width: 1, color: LiveStage.glassBorder),
            Expanded(
              flex: 5,
              child: _Stat(
                label: 'NEXT MIN',
                value: liveInr(lot.minNextBid.ceil()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.gold = false,
    this.pulseKey,
  });

  final String label;
  final String value;
  final bool gold;

  /// Pops the value when this changes (a new bid).
  final Object? pulseKey;

  @override
  Widget build(BuildContext context) {
    final text = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        value,
        maxLines: 1,
        style: TextStyle(
          color: gold ? LiveStage.gold : Colors.white,
          fontSize: gold ? 18 : 15,
          fontWeight: FontWeight.w800,
          height: 1.1,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: _eyebrow.copyWith(fontSize: 9.5)),
          const SizedBox(height: 3),
          if (pulseKey == null)
            text
          else
            TweenAnimationBuilder<double>(
              key: ValueKey(pulseKey),
              tween: Tween(begin: 1.2, end: 1),
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: text,
            ),
        ],
      ),
    );
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({
    required this.showId,
    required this.state,
    required this.lot,
    required this.amount,
    required this.signedIn,
    required this.leading,
    required this.closed,
    required this.onAmount,
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
  final ValueChanged<int> onAmount;
  final VoidCallback onEditAmount;
  final Future<void> Function(int amount) onBid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!signedIn) {
      return _BidButton(
        label: 'Sign in to bid',
        icon: Icons.login_rounded,
        onTap: () => openLiveSignIn(context),
      );
    }
    if (state.me?.isSeller ?? false) {
      return _Banner(
        icon: Icons.storefront_rounded,
        color: LiveStage.inkMuted,
        text: 'This is your show, so bidding is off.',
      );
    }
    if (closed) {
      return const _BidButton(label: 'Closing…', onTap: null);
    }
    if (leading != null) {
      return _Banner(
        icon: Icons.emoji_events_rounded,
        color: LiveStage.leading,
        text: "You're the highest bidder at ${liveInr(leading!)}",
        strong: true,
      );
    }

    final room = ref.read(liveShowRoomProvider(showId).notifier);
    final min = lot.minNextBid.ceil();
    final rawStep = lot.bidStep.ceil();
    final step = rawStep > 0 ? rawStep : 100;
    final placing = state.placingAmount;
    final me = state.me;
    final free = me?.wallet.availableBalance;
    final shortfall = free == null ? 0.0 : amount - free;

    // Why the slider is locked, and what tapping it does.
    final (String? lock, VoidCallback? fix) = switch (me) {
      null => ('Checking your wallet…', () => unawaited(room.refreshMe())),
      _ when !me.hasDeliveryAddress => (
        'Add a delivery address to bid',
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _RoundStep(
              icon: Icons.remove_rounded,
              tooltip: 'Lower by ${liveInr(step)}',
              onTap: amount - step >= min
                  ? () => onAmount(amount - step)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AmountBox(
                amount: amount,
                short: shortfall > 0,
                onTap: onEditAmount,
              ),
            ),
            const SizedBox(width: 8),
            _RoundStep(
              icon: Icons.add_rounded,
              tooltip: 'Raise by ${liveInr(step)}',
              onTap: () => onAmount(amount + step),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final (i, (label, value)) in [
              ('Min', min),
              if (rawStep > 0) ('+1 step', min + step),
              if (rawStep > 0) ('+2 steps', min + step * 2),
            ].indexed) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: _PickChip(
                  hint: label,
                  label: liveInr(value),
                  selected: amount == value,
                  short: free != null && value > free,
                  onTap: () => onAmount(value),
                ),
              ),
            ],
          ],
        ),
        if (shortfall > 0 && free != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 15,
                color: LiveStage.urgent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Not enough in your wallet. Free to bid ${liveInr(free)}.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 10),
        LiveSlideToBid(
          key: ValueKey('slide-${lot.id}'),
          label: 'Slide to bid ${liveInr(amount)}',
          busy: placing != null,
          lockedLabel: lock,
          onLockedTap: fix,
          onSubmit: lock == null && placing == null
              ? () => onBid(amount)
              : null,
        ),
        const SizedBox(height: 6),
        Text(
          'Bids are binding. The amount is held in your wallet while you '
          'lead, and a win pays automatically.',
          textAlign: TextAlign.center,
          style: TextStyle(color: LiveStage.inkFaint, fontSize: 10.5),
        ),
      ],
    );
  }
}

/// The bid amount; tap to type one on a number pad.
class _AmountBox extends StatelessWidget {
  const _AmountBox({
    required this.amount,
    required this.short,
    required this.onTap,
  });

  final int amount;
  final bool short;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = short ? LiveStage.urgent : LiveStage.gold;
    return Semantics(
      button: true,
      label: 'Your bid ${liveInr(amount)}. Tap to enter an amount.',
      excludeSemantics: true,
      child: Material(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: border.withValues(alpha: 0.7),
                width: 1.4,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('YOUR BID', style: _eyebrow.copyWith(fontSize: 9)),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          liveInr(amount),
                          style: TextStyle(
                            color: short ? LiveStage.urgent : Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.edit_rounded, size: 16, color: LiveStage.inkMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundStep extends StatelessWidget {
  const _RoundStep({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: onTap != null,
        label: tooltip,
        child: InkResponse(
          onTap: onTap,
          radius: 28,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(color: LiveStage.glassBorder),
            ),
            child: Icon(
              icon,
              color: onTap == null ? LiveStage.inkFaint : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Quick pick that fills the bid box (the slider still confirms).
class _PickChip extends StatelessWidget {
  const _PickChip({
    required this.hint,
    required this.label,
    required this.selected,
    required this.short,
    required this.onTap,
  });

  final String hint;
  final String label;
  final bool selected;
  final bool short;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gold = LiveStage.gold;
    return Semantics(
      button: true,
      selected: selected,
      label: '$hint, $label',
      excludeSemantics: true,
      child: Material(
        color: selected
            ? gold.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? gold : LiveStage.glassBorder,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: short
                          ? LiveStage.inkFaint
                          : (selected ? gold : Colors.white),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                Text(
                  hint,
                  style: TextStyle(color: LiveStage.inkFaint, fontSize: 10),
                ),
              ],
            ),
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
    return InkWell(
      onTap: onExpand,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        child: Row(
          children: [
            _Thumb(url: lot.image, size: 38),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lot.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    leading != null
                        ? 'You lead at ${liveInr(leading)}'
                        : '${liveInr(lot.currentBid ?? lot.startingBid)} · '
                              '${lot.bidCount} '
                              '${lot.bidCount == 1 ? 'bid' : 'bids'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: leading != null
                          ? LiveStage.leading
                          : LiveStage.gold,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            LiveCountdown(endsAt: lot.endsAt, serverNow: state.serverNow),
            const SizedBox(width: 8),
            // Opens the full card: bids are always confirmed by sliding.
            if (canBid)
              Flexible(
                child: _MiniBid(label: liveInr(amount), onTap: onExpand),
              )
            else
              Icon(Icons.keyboard_arrow_up_rounded, color: LiveStage.inkMuted),
          ],
        ),
      ),
    );
  }
}

// ── Wallet and address ────────────────────────────────────────────────────

class _WalletLine extends ConsumerWidget {
  const _WalletLine({required this.showId, required this.wallet});

  final String showId;
  final LiveWallet wallet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muted = TextStyle(color: LiveStage.inkMuted, fontSize: 12);
    return Row(
      children: [
        Icon(
          Icons.account_balance_wallet_outlined,
          size: 15,
          color: LiveStage.inkMuted,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Free to bid '),
                    TextSpan(
                      text: liveInr(wallet.availableBalance),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: muted,
              ),
              if (wallet.heldAmount > 0)
                Text(
                  '${liveInr(wallet.heldAmount)} on hold for your leading bids',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: muted.copyWith(
                    fontSize: 11,
                    color: LiveStage.inkFaint,
                  ),
                ),
            ],
          ),
        ),
        _LinkButton(
          label: 'Add funds',
          onTap: () => openLiveTopUp(context, ref, showId),
        ),
      ],
    );
  }
}

class _ShipToLine extends ConsumerWidget {
  const _ShipToLine({required this.showId, required this.hasAddress});

  final String showId;
  final bool hasAddress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final address = hasAddress
        ? ref.watch(liveShipToProvider).asData?.value
        : null;
    final text = !hasAddress
        ? 'Add a delivery address to bid'
        : address == null
        ? 'Wins ship to your saved address'
        : 'Wins ship to ${address.fullName}, ${address.city}';
    return Row(
      children: [
        Icon(
          hasAddress
              ? Icons.local_shipping_outlined
              : Icons.error_outline_rounded,
          size: 15,
          color: hasAddress ? LiveStage.inkMuted : LiveStage.urgent,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: hasAddress ? LiveStage.inkMuted : Colors.white,
              fontSize: 12,
            ),
          ),
        ),
        _LinkButton(
          label: hasAddress ? 'Change' : 'Add',
          onTap: () => openLiveAddress(context, ref, showId),
        ),
      ],
    );
  }
}

// ── Pieces ────────────────────────────────────────────────────────────────

final _eyebrow = TextStyle(
  color: Colors.white.withValues(alpha: 0.55),
  fontSize: 10.5,
  fontWeight: FontWeight.w700,
  letterSpacing: 1.4,
);

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url, required this.size});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: size,
        height: size,
        color: Colors.white.withValues(alpha: 0.08),
        child: url == null || url!.isEmpty
            ? Icon(
                Icons.diamond_outlined,
                color: LiveStage.inkFaint,
                size: size * 0.45,
              )
            : AppNetworkImage(url: url!, memCacheWidth: (size * dpr).round()),
      ),
    );
  }
}

class _BidButton extends StatelessWidget {
  const _BidButton({required this.label, required this.onTap, this.icon});

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final gold = LiveStage.gold;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: enabled ? 1 : 0.55,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                colors: [gold, Color.lerp(gold, Colors.white, 0.25)!],
              ),
              boxShadow: [
                BoxShadow(
                  color: gold.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: enabled ? onTap : null,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 19, color: const Color(0xFF16140F)),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF16140F),
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniBid extends StatelessWidget {
  const _MiniBid({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LiveStage.gold,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Bid $label',
              style: const TextStyle(
                color: Color(0xFF16140F),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
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
  });

  final IconData icon;
  final Color color;
  final String text;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: strong ? 0.16 : 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.5)),
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
                style: TextStyle(
                  color: strong ? color : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 20,
        child: Container(
          width: 30,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Icon(icon, size: 18, color: LiveStage.inkMuted),
        ),
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: LiveStage.gold,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
