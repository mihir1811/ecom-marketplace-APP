import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/core/error/failure.dart';
import 'package:gemstone/core/network/api_error.dart';
import 'package:gemstone/core/router/route_names.dart';
import 'package:gemstone/features/notifications/domain/models/app_notification.dart';
import 'package:gemstone/features/notifications/domain/notification_open_target.dart';
import 'package:gemstone/features/payment/application/payment_checkout_provider.dart';
import 'package:gemstone/features/product_offer/data/mappers/product_offer_mapper.dart';
import 'package:gemstone/features/product_offer/domain/models/product_offer.dart';

/// Make an Offer API guide, Oct 30 2026.
void main() {
  ProductOffer offer(Map<String, dynamic> fields) =>
      ProductOfferMapper.fromJson({
        'id': 'of-1',
        'productId': 'p-1',
        'productType': 'diamond',
        'buyerId': 'u-1',
        'sellerId': 's-1',
        'amount': 7500,
        'createdAt': '2026-10-28T10:00:00.000Z',
        ...fields,
      });

  final inADay = DateTime.now().toUtc().add(const Duration(hours: 20));

  group('offer states', () {
    test('accepted, unpaid, inside the window is payable', () {
      final o = offer({
        'status': 'ACCEPTED',
        'paymentExpiresAt': inADay.toIso8601String(),
      });
      expect(o.isPayable, isTrue);
      expect(o.isWithGemworld, isFalse);
    });

    test('GemWorld arranging: no Pay now, no countdown', () {
      final o = offer({
        'status': 'ACCEPTED',
        'paymentExpiresAt': null,
        'paymentWithGemworld': true,
      });
      expect(o.isPayable, isFalse);
      expect(o.isWithGemworld, isTrue);
      expect(o.displayStatusLabel, 'With GemWorld');
      final rules = ProductOfferEligibility(offers: [o], maxAttempts: 5);
      expect(rules.withGemworld, isNotNull);
      expect(rules.canSubmit, isFalse);
    });

    test('ACCEPTED with paidAt is paid', () {
      final o = offer({
        'status': 'ACCEPTED',
        'paidAt': '2026-10-28T12:00:00.000Z',
      });
      expect(o.isPaid, isTrue);
      expect(o.displayStatusLabel, 'Paid');
    });

    test('seller sees belowMinimum', () {
      expect(
        offer({'status': 'PENDING', 'belowMinimum': true}).belowMinimum,
        isTrue,
      );
      expect(offer({'status': 'PENDING'}).belowMinimum, isFalse);
    });

    test('every status counts towards the attempt cap', () {
      final rules = ProductOfferEligibility(
        offers: [
          offer({'status': 'REJECTED'}),
          offer({'status': 'EXPIRED'}),
        ],
        maxAttempts: 2,
      );
      expect(rules.limitReached, isTrue);
      expect(rules.canSubmit, isFalse);
    });
  });

  group('counter-offers', () {
    test('seller counter-offer waits for the buyer', () {
      final o = offer({
        'status': 'PENDING',
        'fromSeller': true,
        'amount': 950,
        'counterToId': 'of-0',
        'history': [
          {
            'id': 'of-0',
            'amount': 800,
            'fromSeller': false,
            'message': null,
            'status': 'COUNTERED',
            'createdAt': '2026-10-28T09:00:00.000Z',
          },
        ],
        'attemptsUsed': 2,
        'maxAttempts': 5,
        'product': {'id': 'p-1', 'title': '1.02ct Round', 'listedPrice': 1200},
      });
      expect(o.isOpenCounter, isTrue);
      expect(o.isAwaitingSeller, isFalse);
      expect(o.displayStatusLabel, 'Counter-offer');
      expect(o.counterToId, 'of-0');
      expect(o.history.single.amount, 800);
      expect(o.history.single.status, ProductOfferStatus.countered);
      expect(o.attemptsExhausted, isFalse);
      expect(o.listPrice, 1200);
      expect(
        o.answerExpiresAt,
        DateTime.parse('2026-10-29T10:00:00.000Z').toLocal(),
      );
    });

    test('open counter blocks a new offer but is not "pending"', () {
      final rules = ProductOfferEligibility(
        offers: [
          offer({'status': 'PENDING', 'fromSeller': true}),
          offer({'status': 'COUNTERED'}),
        ],
        maxAttempts: 5,
      );
      expect(rules.openCounter, isNotNull);
      expect(rules.hasPending, isFalse);
      expect(rules.canSubmit, isFalse);
      expect(rules.attemptsLeft, 3);
    });

    test('attempts exhausted when used reaches max', () {
      final o = offer({
        'status': 'PENDING',
        'attemptsUsed': 5,
        'maxAttempts': 5,
      });
      expect(o.attemptsExhausted, isTrue);
    });

    test('OFFER_COUNTERED opens the counter-offer', () {
      final n = AppNotification(
        id: 'n-2',
        type: 'OFFER_COUNTERED',
        title: '',
        body: '',
        link: '/user/offers?counter=of-9',
        data: const {},
        isRead: false,
        createdAt: DateTime(2026, 10, 30),
      );
      final target = notificationOpenTarget(n, isSeller: false);
      expect(
        target is NotificationInApp ? target.route : null,
        AppRouteNames.buyerOfferCounterPath('of-9'),
      );
    });

    test('seller counter pushes land on Offers received', () {
      for (final type in [
        'OFFER_COUNTERED_BY_BUYER',
        'OFFER_COUNTER_ACCEPTED',
        'OFFER_COUNTER_DECLINED',
      ]) {
        final n = AppNotification(
          id: 'n-3',
          type: type,
          title: '',
          body: '',
          link: '',
          data: const {},
          isRead: false,
          createdAt: DateTime(2026, 10, 30),
        );
        final target = notificationOpenTarget(n, isSeller: true);
        expect(
          target is NotificationInApp ? target.route : null,
          AppRouteNames.sellerOffers,
        );
      }
    });
  });

  group('OFFER_ACCEPTED push', () {
    AppNotification push(String link, Map<String, String> data) =>
        AppNotification(
          id: 'n-1',
          type: 'OFFER_ACCEPTED',
          title: '',
          body: '',
          link: link,
          data: data,
          isRead: false,
          createdAt: DateTime(2026, 10, 28),
        );

    String? route(AppNotification n) =>
        switch (notificationOpenTarget(n, isSeller: false)) {
          NotificationInApp(:final route) => route,
          _ => null,
        };

    test('pays the offer from the link', () {
      expect(
        route(push('/user/offers?pay=of-1', const {})),
        AppRouteNames.buyerOfferPayPath('of-1'),
      );
    });

    test('falls back to data.offerId', () {
      expect(
        route(push('', const {'offerId': 'of-2', 'entityType': 'OFFER'})),
        AppRouteNames.buyerOfferPayPath('of-2'),
      );
    });
  });

  test('CONTACT_GEMWORLD_REQUIRED keeps its code', () {
    final failure = ApiError.fromDio(
      DioException(
        requestOptions: RequestOptions(path: '/payment/create-order'),
        response: Response(
          requestOptions: RequestOptions(path: '/payment/create-order'),
          statusCode: 400,
          data: {
            'statusCode': 400,
            'message':
                'Orders over ₹1,00,000 can\'t be paid online. Use Contact '
                'GemWorld and our team will arrange it with you.',
            'code': 'CONTACT_GEMWORLD_REQUIRED',
          },
        ),
      ),
    );
    expect(failure, isA<ValidationFailure>());
    expect(PaymentCheckoutNotifier.needsContactGemworld(failure), isTrue);
    expect(
      PaymentCheckoutNotifier.needsContactGemworld(
        const ValidationFailure('Your cart is empty.'),
      ),
      isFalse,
    );
  });
}
