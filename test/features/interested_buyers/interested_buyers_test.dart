import 'package:flutter_test/flutter_test.dart';
import 'package:gemworld/core/router/route_names.dart';
import 'package:gemworld/features/interested_buyers/data/mappers/interested_buyer_mapper.dart';
import 'package:gemworld/features/interested_buyers/domain/models/interested_buyer.dart';
import 'package:gemworld/features/interested_buyers/presentation/widgets/interested_buyer_card.dart';
import 'package:gemworld/features/interested_buyers/presentation/widgets/interested_contact_sheets.dart';
import 'package:gemworld/features/notifications/domain/models/app_notification.dart';
import 'package:gemworld/features/notifications/domain/notification_open_target.dart';
import 'package:gemworld/features/product_offer/data/mappers/product_offer_mapper.dart';

Map<String, dynamic> _row({
  Map<String, dynamic>? lastContact,
  Object? offerBlock,
  bool canOffer = true,
  String? chatPath,
}) => {
  'id': '7d5c0c2e-0000-4000-8000-000000000001',
  'buyerName': 'Asha',
  'addedAt': '2026-11-23T08:00:00.000Z',
  'quantity': 1,
  'lineTotal': 1000,
  'product': {
    'id': 'd1',
    'type': 'diamond',
    'title': '1.01 ct Round',
    'image': null,
    'stockNumber': 'GW-1',
    'minimumOfferPrice': 900,
  },
  'lastContact': lastContact,
  'nextContactAt': lastContact == null ? null : '2026-12-01T08:00:00.000Z',
  'buyerReplied': false,
  'chatPath': chatPath,
  'openOffer': null,
  'canMessage': lastContact == null,
  'canOffer': canOffer,
  'offerBlock': offerBlock,
};

AppNotification _push(String type, {String link = '', String? offerId}) =>
    AppNotification(
      id: 'n1',
      type: type,
      title: '',
      body: '',
      link: link,
      data: {'entityType': 'OFFER', 'offerId': ?offerId},
      isRead: false,
      createdAt: DateTime(2026, 11, 24),
    );

void main() {
  group('InterestedBuyerMapper', () {
    test('reads rows, summary and paging', () {
      final page = InterestedBuyerMapper.pageFromJson({
        'success': true,
        'data': {
          'data': [
            _row(),
            _row(
              lastContact: {'kind': 'OFFER', 'at': '2026-11-24T08:00:00Z'},
              canOffer: false,
              offerBlock: 'contactLimit',
              chatPath: '/seller/chat?participantId=buyer-9&productId=d1',
            ),
          ],
          'summary': {
            'items': 12,
            'buyers': 9,
            'notContacted': 7,
            'totalValue': 48250.5,
          },
          'meta': {
            'total': 7,
            'lastPage': 2,
            'currentPage': 1,
            'perPage': 20,
            'prev': null,
            'next': 2,
          },
        },
      }, page: 1);

      expect(page.items, hasLength(2));
      expect(page.total, 7);
      expect(page.hasMore, isTrue);
      expect(page.summary.notContacted, 7);
      expect(page.summary.totalValue, 48250.5);

      final fresh = page.items.first;
      expect(fresh.buyerName, 'Asha');
      expect(fresh.lineTotal, 1000);
      expect(fresh.product.minimumOfferPrice, 900);
      expect(fresh.contacted, isFalse);
      expect(fresh.chatBuyerId, isNull);

      final contacted = page.items.last;
      expect(contacted.lastContact?.kind, InterestedContactKind.offer);
      expect(contacted.offerBlock, InterestedOfferBlock.contactLimit);
      expect(contacted.chatBuyerId, 'buyer-9');
      expect(
        interestedOfferBlockText(contacted),
        allOf(contains('recently'), contains('or sooner if they reply')),
      );
    });

    test('unknown offerBlock and missing name fall back safely', () {
      final row = InterestedBuyerMapper.rowFromJson({
        ..._row(offerBlock: 'somethingNew', canOffer: false),
        'buyerName': '  ',
      })!;
      expect(row.offerBlock, isNull);
      expect(row.buyerName, 'Buyer');
    });

    test('prefilled message names the buyer and the item', () {
      final row = InterestedBuyerMapper.rowFromJson(_row())!;
      expect(
        interestedMessageDraft(row),
        'Hi Asha, I saw 1.01 ct Round in your cart. Can I help with anything?',
      );
    });
  });

  group('private offers', () {
    test('privateOffer and an empty buyer email map cleanly', () {
      final offer = ProductOfferMapper.fromJson({
        'id': 'o1',
        'amount': 950,
        'status': 'PENDING',
        'fromSeller': true,
        'counterToId': null,
        'privateOffer': true,
        'buyer': {'name': 'Asha', 'email': ''},
        'seller': {'companyName': 'Shree Gems'},
      });
      expect(offer.privateOffer, isTrue);
      expect(offer.amount, 950);
      expect(offer.buyerEmail, isNull);
      expect(offer.sellerName, 'Shree Gems');
      expect(offer.isOpenCounter, isTrue);
      expect(offer.displayStatusLabel, 'Private offer');
    });

    test('pushes open the right screens', () {
      String route(AppNotification n, {bool isSeller = false}) =>
          (notificationOpenTarget(n, isSeller: isSeller) as NotificationInApp)
              .route;

      expect(
        route(
          _push(
            'PRIVATE_OFFER_RECEIVED',
            link: '/user/offers?counter=o1',
            offerId: 'o1',
          ),
        ),
        AppRouteNames.buyerOfferCounterPath('o1'),
      );
      expect(
        route(_push('PRIVATE_OFFER_ENDED', link: '/user/offers')),
        AppRouteNames.buyerOffers,
      );
      expect(
        route(_push('PRIVATE_OFFER_ACCEPTED'), isSeller: true),
        AppRouteNames.sellerOffers,
      );
      expect(
        route(_push('PRIVATE_OFFER_DECLINED'), isSeller: true),
        AppRouteNames.sellerOffers,
      );
    });
  });
}
