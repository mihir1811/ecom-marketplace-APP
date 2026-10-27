import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/core/auth/auth_controller.dart';
import 'package:gemstone/core/auth/auth_providers.dart';
import 'package:gemstone/core/auth/auth_state.dart';
import 'package:gemstone/core/auth/auth_user.dart';
import 'package:gemstone/core/error/failure.dart';
import 'package:gemstone/core/error/result.dart';
import 'package:gemstone/core/haptics/app_haptics.dart';
import 'package:gemstone/core/l10n/app_localizations.dart';
import 'package:gemstone/core/theme/app_palette.dart';
import 'package:gemstone/core/theme/app_theme.dart';
import 'package:gemstone/features/cart/data/repositories/delivery_repository_impl.dart';
import 'package:gemstone/features/cart/domain/models/delivery_address.dart';
import 'package:gemstone/features/cart/domain/repositories/delivery_repository.dart';
import 'package:gemstone/features/live_shows/data/live_show_socket.dart';
import 'package:gemstone/features/live_shows/data/repositories/live_show_repository_impl.dart';
import 'package:gemstone/features/live_shows/domain/models/live_show_models.dart';
import 'package:gemstone/features/live_shows/domain/repositories/live_show_repository.dart';
import 'package:gemstone/features/live_shows/presentation/screens/live_show_screen.dart';

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

class _QuietSocket extends LiveShowSocket {
  _QuietSocket(super.showId);

  @override
  Stream<LiveShowEvent> get events => const Stream.empty();

  @override
  Stream<void> get resync => const Stream.empty();

  @override
  void connect() {}

  @override
  void disconnect() {}

  @override
  void dispose() {}
}

class _Repo implements LiveShowRepository {
  _Repo({this.ended = false});

  final bool ended;

  @override
  Future<Result<LiveShow, Failure>> show(String showId) async => Success(
    LiveShow(
      id: showId,
      // A provider with no in-app player keeps native video out of tests.
      provider: LiveProvider.awsIvsRealtime,
      title: 'Friday ovals: 1-3 ct, G-H VS',
      isLive: !ended,
      isStreaming: true,
      viewerCount: 1280,
      seller: const LiveSeller(id: 's1', companyName: 'Shree Gems'),
    ),
  );

  @override
  Future<Result<ShowAuction, Failure>> auction(String showId) async => Success(
    ShowAuction(
      serverTime: DateTime.now().toUtc(),
      current: LiveAuctionLot(
        id: 'lot-1',
        status: LotStatus.running,
        title: '1.50ct Oval G VS1',
        productType: 'diamond',
        productId: 'p-1',
        startingBid: 140000,
        bidStep: 2000,
        minNextBid: 154000,
        currentBid: 152000,
        bidCount: 3,
        leaderName: 'Rahul M.',
        endsAt: DateTime.now().toUtc().add(const Duration(minutes: 9)),
      ),
      upNext: const [
        LiveAuctionLot(
          id: 'lot-2',
          status: LotStatus.queued,
          title: '2.01ct Cushion F VVS2',
          productType: 'diamond',
          productId: 'p-2',
          startingBid: 300000,
          bidStep: 5000,
          minNextBid: 300000,
        ),
      ],
    ),
  );

  @override
  Future<Result<MyShowState, Failure>> me(String showId) async => const Success(
    MyShowState(
      wallet: LiveWallet(
        balance: 500000,
        heldAmount: 152000,
        availableBalance: 348000,
      ),
      hasDeliveryAddress: true,
    ),
  );

  @override
  Future<Result<List<LiveChatMessage>, Failure>> chat(String showId) async =>
      const Success([
        LiveChatMessage(
          id: 'c1',
          body: 'Is the 1.5 ct oval eye clean?',
          authorName: 'Rahul M.',
        ),
        LiveChatMessage(
          id: 'c2',
          body: 'Yes, fully eye clean.',
          authorName: 'Shree Gems',
          isSeller: true,
        ),
      ]);

  @override
  Future<Result<List<LiveShow>, Failure>> shows() async => const Success([]);

  @override
  Future<Result<LiveViewerToken, Failure>> viewerToken(String showId) async =>
      const Success(LiveViewerToken(token: 't'));

  @override
  Future<Result<LiveBidResult, LiveBidError>> bid({
    required String lotId,
    required int amount,
  }) async => const ResultFailure(
    LiveBidError(code: LiveBidErrorCode.network, message: 'offline'),
  );

  @override
  Future<Result<LiveChatMessage, LiveActionError>> sendChat({
    required String showId,
    required String body,
  }) async => const ResultFailure(LiveActionError(message: 'offline'));

  @override
  Future<Result<void, LiveActionError>> like({
    required String showId,
    required int count,
  }) async => const Success(null);
}

class _Delivery implements DeliveryRepository {
  static const _home = DeliveryAddress(
    id: 'a1',
    fullName: 'Asha Patel',
    phone: '9999999999',
    line1: '12 MG Road',
    city: 'Surat',
    state: 'Gujarat',
    postalCode: '395001',
    country: 'India',
    isDefault: true,
  );

  @override
  Future<Result<CartDeliveryState, Failure>> getCartDelivery({
    CancelToken? cancelToken,
  }) async => const Success(
    CartDeliveryState(selectedAddress: _home, addresses: [_home]),
  );

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(
  WidgetTester tester, {
  bool ended = false,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(_SignedIn.new),
        liveShowRepositoryProvider.overrideWithValue(_Repo(ended: ended)),
        liveShowSocketFactoryProvider.overrideWithValue(_QuietSocket.new),
        deliveryRepositoryProvider.overrideWithValue(_Delivery()),
      ],
      child: MaterialApp(
        theme: AppTheme.build(AppPalette.ivory),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const LiveShowScreen(showId: 'show-1'),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUp(() => AppHaptics.debugDisable = true);
  tearDown(() => AppHaptics.debugDisable = false);

  testWidgets('stage shows seller, item, bids, wallet and comments', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Shree Gems'), findsWidgets);
    expect(find.text('1.50ct Oval G VS1'), findsOneWidget);
    expect(find.text('₹1,52,000'), findsOneWidget);
    expect(find.text('Bid ₹1,54,000'), findsOneWidget);
    expect(find.text('₹1,56,000'), findsOneWidget);
    expect(find.text('₹1,58,000'), findsOneWidget);
    expect(find.textContaining('Free to bid'), findsOneWidget);
    expect(
      find.textContaining('Wins ship to Asha Patel, Surat'),
      findsOneWidget,
    );
    expect(find.textContaining('eye clean'), findsWidgets);
    expect(find.text('SELLER'), findsOneWidget);
    expect(find.text('1.3K'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // First bid explains holds and auto-pay before it is sent.
    await tester.tap(find.text('Bid ₹1,54,000'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Bid ₹1,54,000?'), findsOneWidget);
    await tester.tap(find.text('Not now'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Bid ₹1,54,000?'), findsNothing);

    // Minimise the dock to a single row.
    await tester.tap(find.byTooltip('Minimise'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Bid ₹1,54,000'), findsOneWidget);
    expect(find.text('₹1,56,000'), findsNothing);
    expect(tester.takeException(), isNull);

    await _teardown(tester);
  });

  testWidgets('an ended show keeps the screen with an ended state', (
    tester,
  ) async {
    await _pump(tester, ended: true);
    expect(find.text('This live show has ended'), findsOneWidget);
    expect(find.text('Browse live shows'), findsOneWidget);
    expect(find.text('LIVE'), findsNothing);
    expect(tester.takeException(), isNull);
    await _teardown(tester);
  });

  testWidgets('stage holds on a small phone with large text', (tester) async {
    await _pump(tester, size: const Size(360, 740), textScale: 1.3);
    expect(find.text('Bid ₹1,54,000'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _teardown(tester);
  });
}
