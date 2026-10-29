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

/// Make an Offer API guide, Oct 28 2026.
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
