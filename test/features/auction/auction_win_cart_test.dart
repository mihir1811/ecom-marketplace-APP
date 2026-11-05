import 'package:flutter_test/flutter_test.dart';
import 'package:gemworld/core/router/route_names.dart';
import 'package:gemworld/features/auction/data/mappers/auction_mapper.dart';
import 'package:gemworld/features/auction/domain/models/auction_models.dart';
import 'package:gemworld/features/cart/data/mappers/cart_mapper.dart';
import 'package:gemworld/features/notifications/domain/models/app_notification.dart';
import 'package:gemworld/features/notifications/domain/notification_open_target.dart';

/// Auction wins are paid from the cart (app API guide, Oct 28 2026).
void main() {
  AuctionListing auction(Map<String, dynamic> fields) =>
      AuctionMapper.listingFromJson({
        'id': 'au-1',
        'productType': 'diamond',
        'productId': 'p-1',
        'winnerId': 'u-1',
        'winningAmount': 350,
        ...fields,
      });

  group('winner payment state', () {
    test('PENDING with a future deadline is due', () {
      final due = DateTime.now().toUtc().add(const Duration(hours: 5));
      final a = auction({
        'winnerStatus': 'PENDING',
        'paymentDueAt': due.toIso8601String(),
        'paymentWithGemworld': false,
      });
      expect(a.winPayment, AuctionWinPayment.due);
      expect(a.paymentDueAt!.isAtSameMomentAs(due), isTrue);
    });

    test('PENDING past the deadline is expired', () {
      final a = auction({
        'winnerStatus': 'PENDING',
        'paymentDueAt': DateTime.now()
            .toUtc()
            .subtract(const Duration(minutes: 1))
            .toIso8601String(),
      });
      expect(a.winPayment, AuctionWinPayment.expired);
    });

    test('GemWorld arranging wins over a missing deadline', () {
      final a = auction({
        'winnerStatus': 'PENDING',
        'paymentDueAt': null,
        'paymentWithGemworld': true,
      });
      expect(a.winPayment, AuctionWinPayment.withGemworld);
    });

    test('PAID and no accepted winner', () {
      expect(
        auction({'winnerStatus': 'PAID'}).winPayment,
        AuctionWinPayment.paid,
      );
      expect(
        auction({'winnerStatus': null}).winPayment,
        AuctionWinPayment.none,
      );
    });
  });

  group('cart line', () {
    test('won line is priced at the bid with its pay-by time', () {
      final item = CartMapper.cartItemFromJson({
        'id': 'ca-1',
        'productId': 'p-1',
        'productType': 'diamond',
        'quantity': 1,
        'specifications': {'auctionId': 'au-1'},
        'auctionWin': {
          'auctionId': 'au-1',
          'winningAmount': 350,
          'payBy': '2026-10-29T09:58:12.073Z',
        },
        'product': {
          'price': 350,
          'totalPrice': 1200,
          'listedPrice': 1200,
          'inStock': true,
          'availabilityStatus': 'available',
        },
      });
      expect(item.isAuctionWin, isTrue);
      expect(item.displayPriceUsd, 350);
      expect(item.auctionPayBy, DateTime.parse('2026-10-29T09:58:12.073Z'));
      expect(item.quantityEditable, isFalse);
      expect(item.isAvailable, isTrue);
      expect(item.isOfferLine, isFalse);
    });

    test('lapsed win comes back unavailable', () {
      final item = CartMapper.cartItemFromJson({
        'id': 'ca-1',
        'productId': 'p-1',
        'productType': 'diamond',
        'specifications': {'auctionId': 'au-1'},
        'auctionWin': null,
        'product': {'price': 1200, 'inStock': false},
      });
      expect(item.isAuctionWin, isTrue);
      expect(item.isAvailable, isFalse);
      expect(item.auctionPayBy, isNull);
    });
  });

  group('notifications', () {
    AppNotification push(
      String type, {
      String link = '',
      Map<String, String>? data,
    }) => AppNotification(
      id: 'n-1',
      type: type,
      title: '',
      body: '',
      link: link,
      data: data ?? const {},
      isRead: false,
      createdAt: DateTime(2026, 10, 29),
    );

    String? route(AppNotification n, {bool isSeller = false}) =>
        switch (notificationOpenTarget(n, isSeller: isSeller)) {
          NotificationInApp(:final route) => route,
          _ => null,
        };

    test('AUCTION_WON opens the cart', () {
      expect(
        route(
          push('AUCTION_WON', link: '/user/cart', data: {'auctionId': 'au-1'}),
        ),
        AppRouteNames.cart,
      );
    });

    test('AUCTION_WIN_UNPAID opens the auction', () {
      expect(
        route(push('AUCTION_WIN_UNPAID', data: {'auctionId': 'au-1'})),
        AppRouteNames.auctionDetailPath('au-1'),
      );
    });

    test('AUCTION_WINNER_UNPAID_SELLER opens seller auctions', () {
      expect(
        route(
          push('AUCTION_WINNER_UNPAID_SELLER', link: '/seller/auctions'),
          isSeller: true,
        ),
        AppRouteNames.sellerAuctions,
      );
    });
  });
}
