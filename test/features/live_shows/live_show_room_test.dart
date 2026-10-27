import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/core/auth/auth_controller.dart';
import 'package:gemstone/core/auth/auth_providers.dart';
import 'package:gemstone/core/auth/auth_state.dart';
import 'package:gemstone/core/auth/auth_user.dart';
import 'package:gemstone/core/error/failure.dart';
import 'package:gemstone/core/error/result.dart';
import 'package:gemstone/features/live_shows/application/live_show_room.dart';
import 'package:gemstone/features/live_shows/data/live_show_socket.dart';
import 'package:gemstone/features/live_shows/data/repositories/live_show_repository_impl.dart';
import 'package:gemstone/features/live_shows/domain/models/live_show_models.dart';
import 'package:gemstone/features/live_shows/domain/repositories/live_show_repository.dart';

const _showId = 'show-1';

class _SignedIn extends AuthController {
  @override
  AuthState build() => const AuthState(
    user: AuthUser(
      id: 'me',
      fullName: 'Me',
      username: 'me',
      email: 'me@example.com',
      role: 'buyer',
    ),
  );
}

class _FakeSocket extends LiveShowSocket {
  _FakeSocket(super.showId);

  final pushes = StreamController<LiveShowEvent>.broadcast();
  final reconnects = StreamController<void>.broadcast();

  @override
  Stream<LiveShowEvent> get events => pushes.stream;

  @override
  Stream<void> get resync => reconnects.stream;

  @override
  void connect() {}

  @override
  void disconnect() {}

  @override
  void dispose() {
    pushes.close();
    reconnects.close();
  }
}

LiveAuctionLot _lot({
  LotStatus status = LotStatus.running,
  double? currentBid,
  int bidCount = 0,
  double minNextBid = 140000,
}) => LiveAuctionLot(
  id: 'lot-1',
  status: status,
  title: '1.50ct Oval',
  productType: 'diamond',
  productId: 'p-1',
  startingBid: 140000,
  bidStep: 2000,
  minNextBid: minNextBid,
  currentBid: currentBid,
  bidCount: bidCount,
  endsAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
);

class _FakeRepo implements LiveShowRepository {
  MyShowState mine = const MyShowState(
    wallet: LiveWallet(
      balance: 500000,
      heldAmount: 0,
      availableBalance: 500000,
    ),
    hasDeliveryAddress: true,
  );
  Completer<Result<LiveBidResult, LiveBidError>>? pendingBid;
  Result<LiveBidResult, LiveBidError>? bidReply;
  final likes = <int>[];

  @override
  Future<Result<List<LiveShow>, Failure>> shows() async => const Success([]);

  @override
  Future<Result<LiveShow, Failure>> show(String showId) async => const Success(
    LiveShow(
      id: _showId,
      provider: LiveProvider.livekit,
      title: 'Friday ovals',
      isLive: true,
      isStreaming: true,
      viewerCount: 10,
      seller: LiveSeller(id: 's1', companyName: 'Shree Gems'),
    ),
  );

  @override
  Future<Result<ShowAuction, Failure>> auction(String showId) async =>
      Success(ShowAuction(serverTime: DateTime.now().toUtc(), current: _lot()));

  @override
  Future<Result<MyShowState, Failure>> me(String showId) async => Success(mine);

  @override
  Future<Result<LiveBidResult, LiveBidError>> bid({
    required String lotId,
    required int amount,
  }) {
    if (bidReply != null) return Future.value(bidReply!);
    pendingBid = Completer();
    return pendingBid!.future;
  }

  @override
  Future<Result<List<LiveChatMessage>, Failure>> chat(String showId) async =>
      const Success([]);

  @override
  Future<Result<LiveChatMessage, LiveActionError>> sendChat({
    required String showId,
    required String body,
  }) async => Success(LiveChatMessage(id: 'c1', body: body, authorName: 'Me'));

  @override
  Future<Result<void, LiveActionError>> like({
    required String showId,
    required int count,
  }) async {
    likes.add(count);
    return const Success(null);
  }

  @override
  Future<Result<LiveViewerToken, Failure>> viewerToken(String showId) async =>
      const Success(LiveViewerToken(token: 't'));
}

void main() {
  late _FakeRepo repo;
  late _FakeSocket socket;
  late ProviderContainer container;
  late List<LiveNotice> notices;

  LiveShowRoomController room() =>
      container.read(liveShowRoomProvider(_showId).notifier);
  LiveShowRoomState state() => container.read(liveShowRoomProvider(_showId));

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() async {
    repo = _FakeRepo();
    container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(_SignedIn.new),
        liveShowRepositoryProvider.overrideWithValue(repo),
        liveShowSocketFactoryProvider.overrideWithValue((id) {
          socket = _FakeSocket(id);
          return socket;
        }),
      ],
    );
    container.listen(liveShowRoomProvider(_showId), (_, _) {});
    notices = [];
    room().notices.listen(notices.add);
    await settle();
    await settle();
  });

  tearDown(() => container.dispose());

  test('loads the show, the auction and my state', () {
    expect(state().show?.title, 'Friday ovals');
    expect(state().current?.id, 'lot-1');
    expect(state().me?.wallet.availableBalance, 500000);
  });

  test('a push for my own bid is not an outbid', () async {
    final placing = room().placeBid(140000);
    await settle();
    // The push for my bid lands before the POST returns.
    socket.pushes.add(
      LiveLotEvent(_lot(currentBid: 140000, bidCount: 1, minNextBid: 142000)),
    );
    await settle();
    repo.pendingBid!.complete(
      Success(
        LiveBidResult(
          lot: _lot(currentBid: 140000, bidCount: 1, minNextBid: 142000),
          wallet: const LiveWallet(
            balance: 500000,
            heldAmount: 140000,
            availableBalance: 360000,
          ),
        ),
      ),
    );
    expect(await placing, isA<LiveBidPlaced>());
    expect(notices, isEmpty);
    expect(state().leadingAmount('lot-1'), 140000);
    expect(state().me?.wallet.availableBalance, 360000);
  });

  test('a higher bid from someone else is an outbid', () async {
    repo.mine = const MyShowState(
      wallet: LiveWallet(
        balance: 500000,
        heldAmount: 140000,
        availableBalance: 360000,
      ),
      leading: [LiveLeading(lotId: 'lot-1', amount: 140000)],
      hasDeliveryAddress: true,
    );
    await room().refreshMe();
    // The server releases the hold the moment someone outbids.
    repo.mine = const MyShowState(
      wallet: LiveWallet(
        balance: 500000,
        heldAmount: 0,
        availableBalance: 500000,
      ),
      hasDeliveryAddress: true,
    );
    socket.pushes.add(
      LiveLotEvent(_lot(currentBid: 142000, bidCount: 2, minNextBid: 144000)),
    );
    await settle();
    expect(notices.single, isA<LiveOutbidNotice>());
    expect(state().leadingAmount('lot-1'), isNull);
    expect(state().current?.currentBid, 142000);
    await settle();
    expect(state().me?.wallet.availableBalance, 500000);
  });

  test('a SOLD push at my amount is a win', () async {
    repo.mine = const MyShowState(
      wallet: LiveWallet(
        balance: 500000,
        heldAmount: 140000,
        availableBalance: 360000,
      ),
      leading: [LiveLeading(lotId: 'lot-1', amount: 140000)],
      hasDeliveryAddress: true,
    );
    await room().refreshMe();
    socket.pushes.add(
      LiveLotEvent(
        _lot(status: LotStatus.sold, currentBid: 140000, bidCount: 1),
      ),
    );
    await settle();
    expect(notices.single, isA<LiveWonNotice>());
    expect(state().current, isNull);
    expect(state().results.first.status, LotStatus.sold);
  });

  test('asks for a top-up when the bid does not fit the wallet', () async {
    repo.mine = const MyShowState(
      wallet: LiveWallet(
        balance: 100000,
        heldAmount: 0,
        availableBalance: 100000,
      ),
      hasDeliveryAddress: true,
    );
    await room().refreshMe();
    final outcome = await room().placeBid(140000);
    expect(outcome, isA<LiveBidNeedsTopUp>());
    expect((outcome as LiveBidNeedsTopUp).shortfall, 40000);
  });

  test('asks for an address before the first bid', () async {
    repo.mine = const MyShowState(
      wallet: LiveWallet(
        balance: 500000,
        heldAmount: 0,
        availableBalance: 500000,
      ),
    );
    await room().refreshMe();
    expect(await room().placeBid(140000), isA<LiveBidNeedsAddress>());
  });

  test('BID_TOO_LOW prefills the new minimum', () async {
    repo.bidReply = const ResultFailure(
      LiveBidError(
        code: LiveBidErrorCode.bidTooLow,
        message: 'Someone bid first',
        minBid: 144000,
      ),
    );
    final outcome = await room().placeBid(140000);
    expect(outcome, isA<LiveBidRejected>());
    expect((outcome as LiveBidRejected).minBid, 144000);
  });

  test('hearts are batched and my own are not floated back', () async {
    final floated = <int>[];
    room().hearts.listen(floated.add);
    for (var i = 0; i < 25; i++) {
      room().tapHeart();
    }
    expect(repo.likes, [25]);
    // The next push includes my 25 plus 3 from others.
    socket.pushes.add(const LiveLikesEvent(28));
    await settle();
    expect(floated, [3]);
  });

  test('a reconnect refetches', () async {
    repo.mine = const MyShowState(
      wallet: LiveWallet(balance: 9, heldAmount: 0, availableBalance: 9),
    );
    socket.reconnects.add(null);
    await settle();
    await settle();
    expect(state().me?.wallet.balance, 9);
  });
}
