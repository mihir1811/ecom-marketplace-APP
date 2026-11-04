import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/error/result.dart';
import '../data/live_show_socket.dart';
import '../data/repositories/live_show_repository_impl.dart';
import '../domain/live_format.dart';
import '../domain/models/live_show_models.dart';
import '../domain/repositories/live_show_repository.dart';
import '../../../core/riverpod/dispose_tolerant.dart';

/// One line of the stage feed: a comment, or an auction moment built from
/// lot pushes.
class LiveFeedItem {
  const LiveFeedItem({
    required this.id,
    required this.body,
    this.author,
    this.isSeller = false,
    this.isMoment = false,
  });

  final String id;
  final String? author;
  final String body;
  final bool isSeller;
  final bool isMoment;
}

/// One-shot things the screen tells the viewer about.
sealed class LiveNotice {
  const LiveNotice();
}

class LiveOutbidNotice extends LiveNotice {
  const LiveOutbidNotice(this.lot);
  final LiveAuctionLot lot;
}

class LiveWonNotice extends LiveNotice {
  const LiveWonNotice(this.lot);
  final LiveAuctionLot lot;
}

/// What happened to a bid the viewer tried to place.
sealed class LiveBidOutcome {
  const LiveBidOutcome();
}

class LiveBidPlaced extends LiveBidOutcome {
  const LiveBidPlaced(this.amount);
  final int amount;
}

/// Not enough free in the wallet: open top-up for [shortfall] rupees.
class LiveBidNeedsTopUp extends LiveBidOutcome {
  const LiveBidNeedsTopUp(this.shortfall);
  final double shortfall;
}

class LiveBidNeedsAddress extends LiveBidOutcome {
  const LiveBidNeedsAddress();
}

class LiveBidNeedsSignIn extends LiveBidOutcome {
  const LiveBidNeedsSignIn();
}

class LiveBidRejected extends LiveBidOutcome {
  const LiveBidRejected(this.message, {this.minBid});
  final String message;

  /// Prefill for a retry after `BID_TOO_LOW`.
  final double? minBid;
}

class LiveShowRoomState {
  const LiveShowRoomState({
    this.show,
    this.isLoading = true,
    this.errorMessage,
    this.auction,
    this.clockOffset = Duration.zero,
    this.me,
    this.feed = const [],
    this.placingAmount,
    this.chatMutedLocally = false,
    this.chatClosed = false,
  });

  final LiveShow? show;
  final bool isLoading;
  final String? errorMessage;
  final ShowAuction? auction;

  /// `serverTime - now` from the last auction fetch.
  final Duration clockOffset;
  final MyShowState? me;
  final List<LiveFeedItem> feed;

  /// Amount of the bid in flight, if any.
  final int? placingAmount;
  final bool chatMutedLocally;
  final bool chatClosed;

  LiveAuctionLot? get current => auction?.current;
  List<LiveAuctionLot> get upNext => auction?.upNext ?? const [];
  List<LiveAuctionLot> get results => auction?.results ?? const [];
  bool get hasEnded => show?.hasEnded ?? false;
  bool get chatMuted => chatMutedLocally || (me?.chatMuted ?? false);

  DateTime serverNow() => DateTime.now().toUtc().add(clockOffset);

  Duration remaining(LiveAuctionLot lot) {
    final ends = lot.endsAt;
    if (ends == null) return Duration.zero;
    final left = ends.difference(serverNow());
    return left.isNegative ? Duration.zero : left;
  }

  /// Amount the viewer leads [lotId] at, or `null`.
  double? leadingAmount(String lotId) => me?.leadingAmount(lotId);

  LiveShowRoomState copyWith({
    LiveShow? show,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    ShowAuction? auction,
    Duration? clockOffset,
    MyShowState? me,
    bool clearMe = false,
    List<LiveFeedItem>? feed,
    int? placingAmount,
    bool clearPlacing = false,
    bool? chatMutedLocally,
    bool? chatClosed,
  }) {
    return LiveShowRoomState(
      show: show ?? this.show,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      auction: auction ?? this.auction,
      clockOffset: clockOffset ?? this.clockOffset,
      me: clearMe ? null : (me ?? this.me),
      feed: feed ?? this.feed,
      placingAmount: clearPlacing
          ? null
          : (placingAmount ?? this.placingAmount),
      chatMutedLocally: chatMutedLocally ?? this.chatMutedLocally,
      chatClosed: chatClosed ?? this.chatClosed,
    );
  }
}

final liveShowRoomProvider = NotifierProvider.autoDispose
    .family<LiveShowRoomController, LiveShowRoomState, String>(
      LiveShowRoomController.new,
    );

/// Everything one open show screen needs: the show (polled every 15 s),
/// its auction on the server clock, the viewer's wallet and leads, the
/// comment feed and hearts, all kept live by the show's socket room.
class LiveShowRoomController extends Notifier<LiveShowRoomState>
    with DisposeTolerantNotifier<LiveShowRoomState> {
  LiveShowRoomController(this.arg);

  /// The family argument this notifier was created for.
  final String arg;

  static const _showPoll = Duration(seconds: 15);
  static const _feedLimit = 60;
  static const _heartFlushAt = 25;
  static const _heartFlushAfter = Duration(milliseconds: 600);
  static const _maxHeartsPerPush = 6;

  late LiveShowSocket _socket;
  final _subs = <StreamSubscription<Object?>>[];
  final _notices = StreamController<LiveNotice>.broadcast();
  final _hearts = StreamController<int>.broadcast();
  Timer? _poll;
  Timer? _heartTimer;
  var _pendingHearts = 0;
  var _ownUnseenHearts = 0;
  var _paused = false;
  DateTime? _lastChatAt;

  /// Amount of the bid being sent, so its own push is not an outbid.
  int? _sending;

  LiveShowRepository get _repo => ref.read(liveShowRepositoryProvider);

  bool get _signedIn => ref.read(authProvider).isAuthenticated;

  /// Outbid and win moments for the viewer.
  Stream<LiveNotice> get notices => _notices.stream;

  /// Hearts from other viewers to float (already capped per push).
  Stream<int> get hearts => _hearts.stream;

  @override
  LiveShowRoomState build() {
    _socket = ref.read(liveShowSocketFactoryProvider)(arg);
    _subs
      ..add(_socket.events.listen(_onEvent))
      ..add(_socket.resync.listen((_) => unawaited(_resync())));
    ref.listen(authProvider.select((s) => s.isAuthenticated), (_, signedIn) {
      if (signedIn) {
        unawaited(refreshMe());
      } else {
        state = state.copyWith(clearMe: true);
      }
    });
    ref.onDispose(() {
      _poll?.cancel();
      _heartTimer?.cancel();
      _flushHearts();
      for (final s in _subs) {
        s.cancel();
      }
      _socket.dispose();
      _notices.close();
      _hearts.close();
    });
    _socket.connect();
    _startPolling();
    Future<void>.microtask(_load);
    return const LiveShowRoomState();
  }

  // ── Loading ────────────────────────────────────────────────────────────

  Future<void> _load() async {
    await Future.wait([refreshShow(), refreshAuction(), _loadChat()]);
    if (!ref.mounted) return;
    await refreshMe();
    if (!ref.mounted) return;
  }

  Future<void> retry() {
    state = state.copyWith(isLoading: true, clearError: true);
    return _load();
  }

  Future<void> _resync() async {
    await Future.wait([refreshShow(), refreshAuction(), _loadChat()]);
    if (!ref.mounted) return;
    await refreshMe();
    if (!ref.mounted) return;
  }

  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(_showPoll, (_) {
      if (_paused || state.hasEnded) return;
      unawaited(refreshShow());
    });
  }

  Future<void> refreshShow() async {
    final result = await _repo.show(arg);
    if (!ref.mounted) return;
    switch (result) {
      case Success(:final value):
        state = state.copyWith(show: value, isLoading: false, clearError: true);
        if (value.hasEnded) _poll?.cancel();
      case ResultFailure(:final failure):
        state = state.copyWith(
          isLoading: false,
          errorMessage: state.show == null ? failure.message : null,
        );
    }
  }

  Future<void> refreshAuction() async {
    final result = await _repo.auction(arg);
    if (!ref.mounted) return;
    if (result case Success(:final value)) {
      state = state.copyWith(
        auction: value,
        clockOffset: value.serverTime.difference(DateTime.now().toUtc()),
      );
    }
  }

  Future<void> refreshMe() async {
    if (!_signedIn) return;
    final result = await _repo.me(arg);
    if (!ref.mounted) return;
    if (result case Success(:final value)) {
      state = state.copyWith(me: value);
    }
  }

  Future<void> _loadChat() async {
    final result = await _repo.chat(arg);
    if (!ref.mounted) return;
    if (result case Success(:final value)) {
      final moments = state.feed.where((f) => f.isMoment);
      final chat = [for (final m in value) _fromMessage(m)];
      final ids = {for (final c in chat) c.id};
      state = state.copyWith(
        feed: _trim([...chat, ...moments.where((m) => !ids.contains(m.id))]),
      );
    }
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────

  /// App went to the background: drop the socket and stop polling.
  void pause() {
    if (_paused) return;
    _paused = true;
    _flushHearts();
    _socket.disconnect();
  }

  /// Back in the foreground: reconnect and catch up.
  void resume() {
    if (!_paused) return;
    _paused = false;
    _socket.connect();
    unawaited(_resync());
  }

  // ── Socket ─────────────────────────────────────────────────────────────

  void _onEvent(LiveShowEvent event) {
    switch (event) {
      case LiveLotEvent(:final lot):
        _applyLot(lot);
      case LiveLineupEvent():
        unawaited(refreshAuction());
      case LiveChatEvent(:final message):
        if (state.feed.any((f) => f.id == message.id)) return;
        _appendFeed(_fromMessage(message));
      case LiveChatDeletedEvent(:final messageId):
        state = state.copyWith(
          feed: state.feed.where((f) => f.id != messageId).toList(),
        );
      case LiveLikesEvent(:final delta):
        final mine = math.min(_ownUnseenHearts, delta);
        _ownUnseenHearts -= mine;
        final others = math.min(delta - mine, _maxHeartsPerPush);
        if (others > 0 && !_hearts.isClosed) _hearts.add(others);
    }
  }

  void _applyLot(LiveAuctionLot lot) {
    final auction = state.auction;
    if (auction == null) {
      unawaited(refreshAuction());
      return;
    }
    final previous = auction.current?.id == lot.id
        ? auction.current
        : auction.upNext.where((l) => l.id == lot.id).firstOrNull;
    final leadAmount = state.leadingAmount(lot.id);
    final bid = lot.currentBid;
    final isOwnPush = bid != null && _sending != null && bid == _sending;

    ShowAuction next;
    if (lot.status == LotStatus.running) {
      next = ShowAuction(
        serverTime: auction.serverTime,
        current: lot,
        upNext: auction.upNext.where((l) => l.id != lot.id).toList(),
        results: auction.results,
      );
    } else if (lot.status.isFinal) {
      next = ShowAuction(
        serverTime: auction.serverTime,
        current: auction.current?.id == lot.id ? null : auction.current,
        upNext: auction.upNext.where((l) => l.id != lot.id).toList(),
        results: [lot, ...auction.results.where((l) => l.id != lot.id)],
      );
    } else {
      // A queued lot changed; the lineup push brings the full order.
      next = auction;
    }
    state = state.copyWith(auction: next);
    _momentFor(lot, previous);

    if (isOwnPush) {
      _setLeading(lot.id, bid.toDouble());
      return;
    }
    if (leadAmount == null || bid == null) {
      return;
    }
    if (lot.status == LotStatus.running && bid > leadAmount) {
      _setLeading(lot.id, null);
      if (!_notices.isClosed) _notices.add(LiveOutbidNotice(lot));
      unawaited(refreshMe());
    } else if (lot.status == LotStatus.sold && bid == leadAmount) {
      if (!_notices.isClosed) _notices.add(LiveWonNotice(lot));
      unawaited(_refreshMeForWin(lot.id));
    } else if (lot.status.isFinal) {
      unawaited(refreshMe());
    }
  }

  /// The order is created about a second after the result; poll briefly so
  /// "View order" can appear.
  Future<void> _refreshMeForWin(String lotId) async {
    for (var i = 0; i < 4; i++) {
      await refreshMe();
      if (!ref.mounted) return;
      if (state.me?.winFor(lotId) != null) return;
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (!ref.mounted) return;
    }
  }

  void _setLeading(String lotId, double? amount) {
    final me = state.me;
    if (me == null) return;
    final leading = [
      for (final l in me.leading)
        if (l.lotId != lotId) l,
      if (amount != null) LiveLeading(lotId: lotId, amount: amount),
    ];
    state = state.copyWith(me: me.copyWith(leading: leading));
  }

  void _momentFor(LiveAuctionLot lot, LiveAuctionLot? previous) {
    final String? body;
    switch (lot.status) {
      case LotStatus.running:
        if (previous == null || previous.status != LotStatus.running) {
          body = 'Bidding open: ${lot.title} from ${liveInr(lot.startingBid)}';
        } else if (lot.bidCount > previous.bidCount &&
            lot.recentBids.isNotEmpty) {
          final top = lot.recentBids.first;
          body = '${top.bidderName} bid ${liveInr(top.amount)}';
        } else {
          body = null;
        }
      case LotStatus.sold:
        body =
            'Sold to ${lot.leaderName ?? 'the top bidder'} for '
            '${liveInr(lot.currentBid ?? 0)}';
      case LotStatus.unsold:
        body = 'No bids on ${lot.title}';
      case LotStatus.cancelled || LotStatus.queued:
        body = null;
    }
    if (body == null) return;
    _appendFeed(
      LiveFeedItem(
        id: 'moment:${lot.id}:${lot.status.name}:${lot.bidCount}',
        body: body,
        isMoment: true,
      ),
    );
  }

  // ── Bidding ────────────────────────────────────────────────────────────

  /// Pre-flight checks, then `POST /live/auction/lots/:lotId/bids`.
  Future<LiveBidOutcome> placeBid(int amount) async {
    final lot = state.current;
    if (lot == null || lot.status != LotStatus.running) {
      return const LiveBidRejected('Bidding has closed on this item.');
    }
    if (!_signedIn) return const LiveBidNeedsSignIn();
    if (state.placingAmount != null) {
      return const LiveBidRejected('Your last bid is still being placed.');
    }
    // Always check the wallet fresh-ish: never send a bid the wallet can't
    // cover, and never send one blind when the wallet couldn't be read.
    var me = state.me;
    if (me == null) {
      await refreshMe();
      me = state.me;
    }
    if (me == null) {
      return const LiveBidRejected(
        "We couldn't check your wallet. Please try again.",
      );
    }
    if (me.isSeller) {
      return const LiveBidRejected('You cannot bid in your own show.');
    }
    if (me.leadingAmount(lot.id) != null) {
      return const LiveBidRejected("You're already the highest bidder.");
    }
    if (!me.hasDeliveryAddress) return const LiveBidNeedsAddress();
    final free = me.wallet.availableBalance;
    if (amount > free) return LiveBidNeedsTopUp(amount - free);
    if (amount < lot.minNextBid) {
      return LiveBidRejected(
        'The minimum bid is ${liveInr(lot.minNextBid)}.',
        minBid: lot.minNextBid,
      );
    }

    _sending = amount;
    state = state.copyWith(placingAmount: amount);
    final result = await _repo.bid(lotId: lot.id, amount: amount);
    state = state.copyWith(clearPlacing: true);
    switch (result) {
      case Success(:final value):
        _sending = null;
        final current = state.current;
        if (current?.id == value.lot.id &&
            (current!.currentBid ?? 0) <= (value.lot.currentBid ?? 0)) {
          final auction = state.auction!;
          state = state.copyWith(
            auction: ShowAuction(
              serverTime: auction.serverTime,
              current: value.lot,
              upNext: auction.upNext,
              results: auction.results,
            ),
          );
        }
        final wallet = value.wallet;
        if (wallet != null && state.me != null) {
          state = state.copyWith(me: state.me!.copyWith(wallet: wallet));
        }
        // A later outbid push may already have landed; only lead if not.
        if ((state.current?.currentBid ?? amount) <= amount) {
          _setLeading(lot.id, amount.toDouble());
        }
        return LiveBidPlaced(amount);
      case ResultFailure(:final failure):
        _sending = null;
        return _onBidError(failure);
    }
  }

  LiveBidOutcome _onBidError(LiveBidError e) {
    switch (e.code) {
      case LiveBidErrorCode.bidTooLow:
        unawaited(refreshAuction());
        return LiveBidRejected(e.message, minBid: e.minBid);
      case LiveBidErrorCode.insufficientWallet:
        return LiveBidNeedsTopUp(e.shortfall ?? 0);
      case LiveBidErrorCode.addressRequired:
        return const LiveBidNeedsAddress();
      case LiveBidErrorCode.lotClosed:
        unawaited(refreshAuction());
        return LiveBidRejected(e.message);
      case LiveBidErrorCode.alreadyLeading:
        unawaited(refreshMe());
        return LiveBidRejected(e.message);
      case LiveBidErrorCode.signInRequired:
        return const LiveBidNeedsSignIn();
      case LiveBidErrorCode.forbidden ||
          LiveBidErrorCode.invalid ||
          LiveBidErrorCode.network:
        return LiveBidRejected(e.message);
    }
  }

  // ── Chat and hearts ────────────────────────────────────────────────────

  /// Returns an error message to show, or `null` when sent.
  Future<String?> sendChat(String text) async {
    final body = text.trim();
    if (body.isEmpty) return null;
    if (body.length > 300) return 'Comments can be up to 300 characters.';
    final last = _lastChatAt;
    if (last != null &&
        DateTime.now().difference(last) < const Duration(seconds: 1)) {
      return "You're sending messages too fast";
    }
    _lastChatAt = DateTime.now();
    final result = await _repo.sendChat(showId: arg, body: body);
    switch (result) {
      case Success(:final value):
        if (!state.feed.any((f) => f.id == value.id)) {
          _appendFeed(_fromMessage(value));
        }
        return null;
      case ResultFailure(:final failure):
        if (failure.forbidden) {
          state = state.copyWith(chatMutedLocally: true);
        } else if (state.hasEnded) {
          state = state.copyWith(chatClosed: true);
        }
        return failure.message;
    }
  }

  /// One heart tap; batched to the server.
  void tapHeart() {
    if (!_signedIn || state.hasEnded) return;
    _pendingHearts += 1;
    if (_pendingHearts >= _heartFlushAt) {
      _flushHearts();
      return;
    }
    _heartTimer ??= Timer(_heartFlushAfter, _flushHearts);
  }

  void _flushHearts() {
    _heartTimer?.cancel();
    _heartTimer = null;
    final count = math.min(_pendingHearts, 50);
    _pendingHearts = 0;
    if (count <= 0) return;
    _ownUnseenHearts += count;
    unawaited(_repo.like(showId: arg, count: count));
  }

  // ── Feed helpers ───────────────────────────────────────────────────────

  LiveFeedItem _fromMessage(LiveChatMessage m) => LiveFeedItem(
    id: m.id,
    author: m.authorName,
    body: m.body,
    isSeller: m.isSeller,
  );

  void _appendFeed(LiveFeedItem item) {
    state = state.copyWith(feed: _trim([...state.feed, item]));
  }

  List<LiveFeedItem> _trim(List<LiveFeedItem> items) =>
      items.length > _feedLimit
      ? items.sublist(items.length - _feedLimit)
      : items;
}
