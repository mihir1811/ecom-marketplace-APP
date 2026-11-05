import 'package:flutter_test/flutter_test.dart';
import 'package:gemworld/core/router/route_names.dart';
import 'package:gemworld/features/jewelry/data/mappers/jewelry_mapper.dart';
import 'package:gemworld/features/jewelry/data/mappers/marketplace_mapper.dart';
import 'package:gemworld/features/jewelry_checkout/data/mappers/jewelry_checkout_mapper.dart';
import 'package:gemworld/features/jewelry_reviews/data/jewelry_review_mapper.dart';
import 'package:gemworld/features/notifications/domain/models/app_notification.dart';
import 'package:gemworld/features/notifications/domain/notification_open_target.dart';

void main() {
  test('maps a public review page (guide sample)', () {
    final page = JewelryReviewMapper.page({
      'summary': {
        'average': 4.25,
        'count': 4,
        'breakdown': {'1': 0, '2': 1, '3': 0, '4': 0, '5': 3},
      },
      'items': [
        {
          'id': '0b6e3a52-1d4f-4c2e-9a7b-5f8c1e2d3a4b',
          'rating': 5,
          'title': 'Even prettier in person',
          'body': 'The stone catches the light beautifully.',
          'imageUrls': ['https://x/a.jpg'],
          'createdAt': '2026-11-03T10:16:00.000Z',
          'editedAt': null,
          'buyerName': 'Asha M.',
          'piece': {
            'title': 'Oval ring',
            'imageUrl': 'https://x/p.webp',
            'options': {'Metal': '18K Yellow gold', 'Ring size': '7'},
            'listingSlug': null,
          },
          'sellerReply': 'Thank you, Asha!',
          'sellerRepliedAt': '2026-11-03T10:30:00.000Z',
        },
      ],
      'total': 4,
      'page': 1,
      'limit': 1,
    });
    expect(page.summary.average, 4.25);
    expect(page.summary.breakdown[5], 3);
    expect(page.hasMore, isTrue);
    final r = page.items.single;
    expect(r.buyerName, 'Asha M.');
    expect(r.piece.listingSlug, isNull);
    expect(r.piece.options['Ring size'], '7');
    expect(r.hasReply, isTrue);
  });

  test('seller list carries order, hidden and counts', () {
    final page = JewelryReviewMapper.page({
      'summary': {
        'average': 3.67,
        'count': 3,
        'breakdown': {'3': 1, '4': 2},
        'unanswered': 1,
        'hidden': 1,
      },
      'items': [
        {
          'id': 'r1',
          'rating': 2,
          'buyerName': 'Ravi Kumar Sharma',
          'piece': {'title': 'Ring'},
          'order': {'id': 'o1', 'orderNumber': 'JW-261103-K7Q2P'},
          'hidden': true,
          'hiddenReason': "Reviews can't include phone numbers.",
        },
      ],
      'total': 1,
      'page': 1,
      'limit': 10,
    });
    expect(page.summary.unanswered, 1);
    expect(page.summary.hidden, 1);
    expect(page.summary.breakdown[1], 0);
    expect(page.items.single.orderNumber, 'JW-261103-K7Q2P');
    expect(page.items.single.hidden, isTrue);
  });

  test('order lines carry review and canReview; old lines default', () {
    final order = JewelryCheckoutMapper.order({
      'id': 'o1',
      'items': [
        {
          'id': 'line-1',
          'status': 'DELIVERED',
          'review': {
            'id': 'rev-1',
            'rating': 4,
            'title': 'Lovely, a little snug',
            'editableUntil': '2026-12-03T10:16:00.000Z',
            'canEdit': true,
            'hidden': false,
          },
          'canReview': false,
        },
        {'id': 'line-2', 'status': 'DELIVERED', 'canReview': true},
        {'id': 'line-3', 'status': 'SHIPPED'},
      ],
    });
    expect(order.items[0].review?.rating, 4);
    expect(order.items[0].review?.canEdit, isTrue);
    expect(order.items[1].canReview, isTrue);
    expect(order.items[1].review, isNull);
    expect(order.items[2].canReview, isFalse);
  });

  test('listing and shop stars come from string ratingAverage', () {
    final listing = MarketplaceMapper.listing({
      'id': 'l1',
      'slug': 'ring',
      'title': 'Ring',
      'ratingAverage': '4.67',
      'ratingCount': 3,
      'shop': {'slug': 's', 'name': 'S', 'ratingAverage': '5', 'ratingCount': 1},
    });
    expect(listing.ratingAverage, closeTo(4.67, 1e-9));
    expect(listing.shop?.ratingAverage, 5);
    final jewelry = JewelryMapper.fromListing(listing);
    expect(jewelry.rating, closeTo(4.67, 1e-9));
    expect(jewelry.reviewCount, 3);

    final none = JewelryMapper.fromListing(
      MarketplaceMapper.listing({'id': 'l2', 'slug': 'x', 'title': 'X'}),
    );
    expect(none.rating, isNull);
  });

  AppNotification push(String type) => AppNotification(
    id: '1',
    type: type,
    title: '',
    body: '',
    link: 'https://jewelry.gemworld.in/orders/o1',
    data: const {
      'entityType': 'MARKETPLACE_REVIEW',
      'reviewId': 'rev-1',
      'orderId': 'o1',
    },
    isRead: false,
    createdAt: DateTime.utc(2026, 11, 4),
  );

  test('review pushes open the seller list or the buyer order', () {
    final received = notificationOpenTarget(
      push('MARKETPLACE_REVIEW_RECEIVED'),
      isSeller: true,
    );
    expect(
      (received as NotificationInApp).route,
      AppRouteNames.jewelryShopReviewsPath(reviewId: 'rev-1'),
    );
    final replied = notificationOpenTarget(
      push('MARKETPLACE_REVIEW_REPLIED'),
      isSeller: false,
    );
    expect(
      (replied as NotificationInApp).route,
      AppRouteNames.jewelryOrderDetailPath('o1'),
    );
  });
}
