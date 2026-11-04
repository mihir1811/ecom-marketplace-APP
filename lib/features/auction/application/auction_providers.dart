import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../cart/application/cart_provider.dart';
import '../data/auction_socket_client.dart';
import '../data/repositories/auction_repository_impl.dart';
import '../domain/models/auction_models.dart';
import '../../../core/riverpod/dispose_tolerant.dart';

enum AuctionFeedKind { live, wins, activity, seller }

/// Cache key for a paginated auction list.
class AuctionFeedQuery {
  const AuctionFeedQuery({
    required this.kind,
    this.outcome = 'all',
    this.status,
    this.productType,
  });

  final AuctionFeedKind kind;
  final String outcome;
  final String? status;
  final String? productType;

  @override
  bool operator ==(Object other) {
    return other is AuctionFeedQuery &&
        other.kind == kind &&
        other.outcome == outcome &&
        other.status == status &&
        other.productType == productType;
  }

  @override
  int get hashCode => Object.hash(kind, outcome, status, productType);
}

class AuctionFeedState {
  const AuctionFeedState({
    this.items = const [],
    this.page = 0,
    this.hasMore = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.summary,
  });

  final List<AuctionListing> items;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final AuctionActivitySummary? summary;

  AuctionFeedState copyWith({
    List<AuctionListing>? items,
    int? page,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    AuctionActivitySummary? summary,
    bool clearError = false,
  }) {
    return AuctionFeedState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      summary: summary ?? this.summary,
    );
  }
}

final auctionFeedProvider =
    NotifierProvider.family<
      AuctionFeedNotifier,
      AuctionFeedState,
      AuctionFeedQuery
    >(AuctionFeedNotifier.new);

class AuctionFeedNotifier extends Notifier<AuctionFeedState>
    with DisposeTolerantNotifier<AuctionFeedState> {
  AuctionFeedNotifier(this.arg);

  /// The family argument this notifier was created for.
  final AuctionFeedQuery arg;

  StreamSubscription<AuctionSocketEvent>? _socketSub;
  StreamSubscription<void>? _resyncSub;
  AuctionSocketClient? _socket;
  String? _sellerRoom;
  var _watchingLive = false;

  @override
  AuctionFeedState build() {
    ref.onDispose(_stopSocket);
    _startSocket();
    Future<void>.microtask(refresh);
    return const AuctionFeedState(isLoading: true);
  }

  void _startSocket() {
    final socket = ref.read(auctionSocketProvider);
    _socket = socket;
    switch (arg.kind) {
      case AuctionFeedKind.live:
        _watchingLive = true;
        socket.watchLive();
      case AuctionFeedKind.seller:
        final sellerId = ref.read(authProvider).sellerId;
        if (sellerId == null || sellerId.isEmpty) return;
        _sellerRoom = sellerId;
        socket.watchSeller(sellerId);
      case AuctionFeedKind.wins:
      case AuctionFeedKind.activity:
        return;
    }
    _socketSub = socket.events.listen(_onSocketEvent);
    _resyncSub = socket.resync.listen((_) => unawaited(refreshQuiet()));
  }

  void _stopSocket() {
    _socketSub?.cancel();
    _resyncSub?.cancel();
    final socket = _socket;
    if (socket == null) return;
    if (_watchingLive) socket.unwatchLive();
    final sellerId = _sellerRoom;
    if (sellerId != null) socket.unwatchSeller(sellerId);
  }

  void _onSocketEvent(AuctionSocketEvent event) {
    final id = event.auctionId.toLowerCase();
    final current = state.items
        .where((item) => item.id.toLowerCase() == id)
        .firstOrNull;
    if (current == null) {
      // A new or not-yet-loaded auction changed: only a lifecycle update
      // (created, ended, deleted) can add or remove a card here.
      if (event.kind == AuctionSocketKind.updated) unawaited(refreshQuiet());
      return;
    }
    final amount = event.amount;
    if (event.kind == AuctionSocketKind.bid && amount != null && amount > 0) {
      if (amount <= (current.highestBidAmount ?? 0)) {
        // Same bid seen twice, or a cancellation lowered the price.
        if (amount < (current.highestBidAmount ?? 0)) {
          unawaited(refreshQuiet());
        }
        return;
      }
      state = state.copyWith(
        items: [
          for (final item in state.items)
            if (identical(item, current)) item.applyLiveBid(amount) else item,
        ],
      );
      return;
    }
    unawaited(refreshQuiet());
  }

  /// Reloads the first page without the full-screen loading state.
  Future<void> refreshQuiet() async {
    final result = await _load(page: 1);
    if (!ref.mounted) return;
    switch (result) {
      case Success(:final value):
        state = state.copyWith(
          items: value.items,
          page: value.currentPage,
          hasMore: value.hasMore,
          isLoading: false,
        );
      case ResultFailure(:final failure):
        if (failure is NetworkFailure && failure.isCancelled) return;
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _load(page: 1);
    if (!ref.mounted) return;
    switch (result) {
      case Success(:final value):
        state = AuctionFeedState(
          items: value.items,
          page: value.currentPage,
          hasMore: value.hasMore,
          summary: value.summary,
        );
      case ResultFailure(:final failure):
        if (failure is NetworkFailure && failure.isCancelled) return;
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    final result = await _load(page: state.page + 1);
    if (!ref.mounted) return;
    switch (result) {
      case Success(:final value):
        state = state.copyWith(
          items: [...state.items, ...value.items],
          page: value.currentPage,
          hasMore: value.hasMore,
          isLoadingMore: false,
        );
      case ResultFailure(:final failure):
        state = state.copyWith(
          isLoadingMore: false,
          errorMessage: failure.message,
        );
    }
  }

  Future<Result<AuctionPage, Failure>> _load({required int page}) {
    final repo = ref.read(auctionRepositoryProvider);
    final query = arg;
    return switch (query.kind) {
      AuctionFeedKind.live => repo.live(
        page: page,
        productType: query.productType,
      ),
      AuctionFeedKind.wins => repo.myWins(
        page: page,
        productType: query.productType,
      ),
      AuctionFeedKind.activity => repo.myActivity(
        page: page,
        productType: query.productType,
        outcome: query.outcome,
      ),
      AuctionFeedKind.seller => repo.sellerAuctions(
        page: page,
        productType: query.productType,
        status: query.status,
      ),
    };
  }
}

final auctionSettingsProvider = FutureProvider<AuctionSettings>((ref) async {
  final result = await ref.watch(auctionRepositoryProvider).settings();
  return switch (result) {
    Success(:final value) => value,
    ResultFailure(:final failure) => throw failure,
  };
});

final sellerAuctionStandingProvider = FutureProvider<SellerAuctionStanding>((
  ref,
) async {
  final result = await ref.watch(auctionRepositoryProvider).sellerStanding();
  return switch (result) {
    Success(:final value) => value,
    ResultFailure(:final failure) => throw failure,
  };
});

final auctionPenaltyProvider = FutureProvider<AuctionPenalty>((ref) async {
  final result = await ref.watch(auctionRepositoryProvider).myPenalty();
  return switch (result) {
    Success(:final value) => value,
    ResultFailure(:final failure) => throw failure,
  };
});

class AuctionDetailState {
  const AuctionDetailState({
    this.auction,
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.myBidId,
  });

  final AuctionListing? auction;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? myBidId;

  AuctionDetailState copyWith({
    AuctionListing? auction,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? myBidId,
    bool clearError = false,
    bool clearBid = false,
  }) {
    return AuctionDetailState(
      auction: auction ?? this.auction,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      myBidId: clearBid ? null : (myBidId ?? this.myBidId),
    );
  }
}

final auctionDetailProvider = NotifierProvider.autoDispose
    .family<AuctionDetailNotifier, AuctionDetailState, String>(
      AuctionDetailNotifier.new,
    );

class AuctionDetailNotifier extends Notifier<AuctionDetailState>
    with DisposeTolerantNotifier<AuctionDetailState> {
  AuctionDetailNotifier(this.arg);

  /// The family argument this notifier was created for.
  final String arg;

  StreamSubscription<AuctionSocketEvent>? _socketSub;
  StreamSubscription<void>? _resyncSub;
  Timer? _socketRefresh;
  Timer? _deadlineRefresh;

  @override
  AuctionDetailState build() {
    final socket = ref.read(auctionSocketProvider);
    socket.watchAuction(arg);
    socket.watchLive();
    _socketSub = socket.events.listen(_onSocketEvent);
    _resyncSub = socket.resync.listen((_) => _scheduleSync());
    ref.onDispose(() {
      _socketRefresh?.cancel();
      _deadlineRefresh?.cancel();
      _socketSub?.cancel();
      _resyncSub?.cancel();
      socket.unwatchAuction(arg);
      socket.unwatchLive();
    });
    Future<void>.microtask(refresh);
    return const AuctionDetailState(isLoading: true);
  }

  void _onSocketEvent(AuctionSocketEvent event) {
    if (event.auctionId.toLowerCase() != arg.toLowerCase()) return;
    final amount = event.amount;
    final auction = state.auction;
    // Only a new top bid is shown straight from the event. A lower amount
    // (or 0) means a bid was cancelled; the sync below brings that in.
    if (event.kind == AuctionSocketKind.bid &&
        amount != null &&
        amount > 0 &&
        auction != null &&
        amount > (auction.highestBidAmount ?? 0)) {
      state = state.copyWith(auction: auction.applyLiveBid(amount));
    }
    _scheduleSync();
  }

  /// One targeted `GET /auction/{id}` for what the event does not carry
  /// (bidder names, bid ids, reserve, status). Bursts of events, including
  /// the same bid delivered through both the auction and live rooms,
  /// collapse into a single request.
  void _scheduleSync() {
    _socketRefresh?.cancel();
    _socketRefresh = Timer(const Duration(milliseconds: 400), () {
      unawaited(refresh(silent: true));
    });
  }

  Future<void> refresh({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(
        isLoading: state.auction == null,
        clearError: true,
      );
    }
    final result = await ref.read(auctionRepositoryProvider).byId(arg);
    if (!ref.mounted) return;
    switch (result) {
      case Success(:final value):
        final current = state.auction;
        state = state.copyWith(
          auction: silent && current != null
              ? current.keepingPendingBids(value)
              : value,
          isLoading: false,
          isSubmitting: false,
        );
        _watchDeadline(value);
      case ResultFailure(:final failure):
        if (silent) return;
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
    }
  }

  Future<String?> placeBid(double amount) {
    return _run(
      () => ref
          .read(auctionRepositoryProvider)
          .placeBid(auctionId: arg, amount: amount),
      onSuccess: (value) => value.bidId,
    );
  }

  Future<String?> cancelBid(String bidId) async {
    final message = await _run(
      () => ref.read(auctionRepositoryProvider).cancelBid(bidId),
    );
    if (message != null) state = state.copyWith(clearBid: true);
    return message;
  }

  /// The backend releases an unpaid win within a minute of `paymentDueAt`;
  /// reload once it should have, so the screen leaves "Time is up".
  void _watchDeadline(AuctionListing auction) {
    _deadlineRefresh?.cancel();
    _deadlineRefresh = null;
    final due = auction.paymentDueAt;
    final payment = auction.winPayment;
    if (due == null ||
        (payment != AuctionWinPayment.due &&
            payment != AuctionWinPayment.expired)) {
      return;
    }
    final untilDue = due.difference(DateTime.now());
    final wait =
        (untilDue.isNegative ? Duration.zero : untilDue) +
        const Duration(seconds: 65);
    _deadlineRefresh = Timer(wait, () => unawaited(refresh(silent: true)));
  }

  /// Declining also takes the item out of the cart and may change the
  /// buyer's warning count.
  Future<String?> declineWin() async {
    final message = await _run(
      () => ref.read(auctionRepositoryProvider).declineWin(arg),
    );
    if (message != null) {
      ref.invalidate(auctionPenaltyProvider);
      unawaited(
        ref
            .read(cartProvider.notifier)
            .refresh(mode: CartLoadMode.light, force: true),
      );
    }
    return message;
  }

  /// Puts the win back in the cart at the winning bid (the buyer may have
  /// removed it) before checkout opens. `POST /cart/add` succeeds whether or
  /// not the line was already there. On failure the auction reloads, so a
  /// lapsed, paid or GemWorld-arranged win shows its real state.
  Future<Result<void, Failure>> addWinToCart() async {
    final auction = state.auction;
    if (auction == null || state.isSubmitting) {
      return Result.failure(
        const ValidationFailure('Please wait a moment and try again.'),
      );
    }
    state = state.copyWith(isSubmitting: true, clearError: true);
    final added = await ref
        .read(cartProvider.notifier)
        .addProduct(
          productId: auction.productId,
          productType: auction.productType,
          specifications: {'auctionId': auction.id},
        );
    if (added case ResultFailure()) await refresh(silent: true);
    state = state.copyWith(isSubmitting: false);
    return added;
  }

  Future<String?> endAuction() {
    return _run(() => ref.read(auctionRepositoryProvider).end(arg));
  }

  Future<String?> accept({String? bidId}) {
    return _run(
      () => ref
          .read(auctionRepositoryProvider)
          .accept(auctionId: arg, bidId: bidId),
    );
  }

  Future<String?> reject({
    required String action,
    DateTime? startTime,
    DateTime? endTime,
    double? minimumBid,
    double? reservePrice,
  }) {
    return _run(
      () => ref
          .read(auctionRepositoryProvider)
          .reject(
            auctionId: arg,
            action: action,
            startTime: startTime,
            endTime: endTime,
            minimumBid: minimumBid,
            reservePrice: reservePrice,
          ),
    );
  }

  Future<String?> selectWinner(String bidderId) {
    return _run(
      () => ref
          .read(auctionRepositoryProvider)
          .selectWinner(auctionId: arg, bidderId: bidderId),
    );
  }

  Future<String?> deleteAuction() {
    return _run(() => ref.read(auctionRepositoryProvider).delete(arg));
  }

  Future<String?> _run(
    Future<Result<AuctionMutation, Failure>> Function() call, {
    String? Function(AuctionMutation value)? onSuccess,
  }) async {
    if (state.isSubmitting) return null;
    state = state.copyWith(isSubmitting: true, clearError: true);
    final result = await call();
    switch (result) {
      case ResultFailure(:final failure):
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: failure.message,
        );
        return null;
      case Success(:final value):
        final bidId = onSuccess?.call(value);
        if (bidId != null) {
          state = state.copyWith(myBidId: bidId);
        }
        await refresh();
        return value.message;
    }
  }
}
