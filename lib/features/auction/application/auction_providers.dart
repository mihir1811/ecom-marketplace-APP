import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../payment/application/razorpay_checkout_service.dart';
import '../../rewards/application/rewards_provider.dart';
import '../data/auction_socket_client.dart';
import '../data/repositories/auction_repository_impl.dart';
import '../domain/models/auction_models.dart';

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

class AuctionFeedNotifier
    extends FamilyNotifier<AuctionFeedState, AuctionFeedQuery> {
  StreamSubscription<AuctionSocketEvent>? _socketSub;
  StreamSubscription<void>? _resyncSub;
  AuctionSocketClient? _socket;
  String? _sellerRoom;
  var _watchingLive = false;

  @override
  AuctionFeedState build(AuctionFeedQuery arg) {
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

class AuctionDetailNotifier
    extends AutoDisposeFamilyNotifier<AuctionDetailState, String> {
  late final RazorpayCheckoutService _razorpay;
  StreamSubscription<AuctionSocketEvent>? _socketSub;
  StreamSubscription<void>? _resyncSub;
  Timer? _socketRefresh;

  @override
  AuctionDetailState build(String arg) {
    _razorpay = RazorpayCheckoutService();
    final socket = ref.read(auctionSocketProvider);
    socket.watchAuction(arg);
    socket.watchLive();
    _socketSub = socket.events.listen(_onSocketEvent);
    _resyncSub = socket.resync.listen((_) => _scheduleSync());
    ref.onDispose(() {
      _socketRefresh?.cancel();
      _socketSub?.cancel();
      _resyncSub?.cancel();
      socket.unwatchAuction(arg);
      socket.unwatchLive();
      _razorpay.dispose();
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

  Future<String?> declineWin() {
    return _run(() => ref.read(auctionRepositoryProvider).declineWin(arg));
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

  /// Returns the success message, or the failure to show. Opens Razorpay
  /// when the server still expects a card payment.
  Future<Result<String, Failure>> pay({
    required bool useWallet,
    bool usePoints = false,
  }) async {
    if (state.isSubmitting) {
      return Result.failure(
        const ValidationFailure('Payment is already in progress.'),
      );
    }
    state = state.copyWith(isSubmitting: true, clearError: true);
    final created = await ref
        .read(auctionRepositoryProvider)
        .createPayment(
          auctionId: arg,
          useWallet: useWallet,
          usePoints: usePoints,
        );
    // Points move at create (no Razorpay step) or at verify; a failure such
    // as "Not enough reward points" also needs the fresh balance.
    switch (created) {
      case ResultFailure(:final failure):
        if (usePoints) refreshRewards(ref);
        return _payFailed(failure);
      case Success(:final value):
        final session = value;
        if (session.isFullyPaidByWallet) {
          if (usePoints) refreshRewards(ref);
          await refresh();
          return Result.success('Payment completed');
        }
        final paid = await _razorpay.open(session);
        switch (paid) {
          case ResultFailure(:final failure):
            return _payFailed(failure);
          case Success(:final value):
            final receipt = value;
            final verified = await ref
                .read(auctionRepositoryProvider)
                .verifyPayment(
                  auctionId: arg,
                  orderId: session.orderId,
                  razorpayOrderId: receipt.razorpayOrderId,
                  razorpayPaymentId: receipt.razorpayPaymentId,
                  razorpaySignature: receipt.razorpaySignature,
                );
            if (usePoints) refreshRewards(ref);
            switch (verified) {
              case ResultFailure(:final failure):
                return _payFailed(failure);
              case Success(:final value):
                await refresh();
                return Result.success(
                  value.message.isEmpty ? 'Payment completed' : value.message,
                );
            }
        }
    }
  }

  Result<String, Failure> _payFailed(Failure failure) {
    state = state.copyWith(isSubmitting: false, errorMessage: failure.message);
    return Result.failure(failure);
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
