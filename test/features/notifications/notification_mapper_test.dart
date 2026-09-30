import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/core/router/route_names.dart';
import 'package:gemstone/features/notifications/data/mappers/notification_mapper.dart';
import 'package:gemstone/features/notifications/domain/models/app_notification.dart';
import 'package:gemstone/features/notifications/domain/notification_open_target.dart';

void main() {
  test('maps inbox envelope and unread count', () {
    final page = NotificationMapper.pageFromEnvelope(
      {
        'success': true,
        'data': {
          'data': [
            {
              'id': '5c1e8f3a',
              'type': 'ORDER_ACCEPTED',
              'title': 'Your order has been accepted',
              'body': 'Shree Gems accepted order #A1B2C3D4.',
              'imageUrl': null,
              'link': '/user/orders/9f0c2d4e',
              'data': {'entityType': 'ORDER', 'orderId': '9f0c2d4e'},
              'isRead': false,
              'readAt': null,
              'createdAt': '2026-09-29T06:14:31.002Z',
            },
          ],
          'meta': {
            'total': 1,
            'lastPage': 1,
            'currentPage': 1,
            'perPage': 20,
            'prev': null,
            'next': null,
          },
          'unreadCount': 1,
        },
      },
      page: 1,
      limit: 20,
    );

    expect(page.items, hasLength(1));
    expect(page.items.single.data['orderId'], '9f0c2d4e');
    expect(page.hasMore, isFalse);
    expect(page.unreadCount, 1);
    expect(
      NotificationMapper.unreadCountFromEnvelope({
        'data': {'count': 3},
      }),
      3,
    );
  });

  test('routes order and seller auction notifications', () {
    final order = AppNotification(
      id: '1',
      type: 'ORDER_REJECTED',
      title: 'Rejected',
      body: '',
      link: '',
      data: const {'orderId': 'order-1'},
      isRead: false,
      createdAt: DateTime.utc(2026, 9, 29),
    );
    final target = notificationOpenTarget(order, isSeller: false);
    expect(target, isA<NotificationInApp>());
    expect(
      (target as NotificationInApp).route,
      AppRouteNames.buyerOrderDetailPath('order-1'),
    );

    final auction = AppNotification(
      id: '2',
      type: 'AUCTION_NEW_BID',
      title: 'New bid',
      body: '',
      link: '/auctions/abc',
      data: const {'auctionId': 'abc'},
      isRead: false,
      createdAt: DateTime.utc(2026, 9, 29),
    );
    expect(
      notificationOpenTarget(auction, isSeller: true),
      isA<NotificationInApp>().having(
        (t) => t.route,
        'route',
        AppRouteNames.sellerAuctions,
      ),
    );

    final outbid = AppNotification(
      id: '2b',
      type: 'AUCTION_OUTBID',
      title: 'Outbid',
      body: '',
      link: '/auctions/abc',
      data: const {'auctionId': 'abc'},
      isRead: false,
      createdAt: DateTime.utc(2026, 9, 29),
    );
    expect(
      notificationOpenTarget(outbid, isSeller: false),
      isA<NotificationInApp>().having(
        (t) => t.route,
        'route',
        AppRouteNames.auctionDetailPath('abc'),
      ),
    );

    final broadcast = AppNotification(
      id: '3',
      type: 'ADMIN_BROADCAST',
      title: 'News',
      body: '',
      link: 'https://gemworld.example/sale',
      data: const {},
      isRead: true,
      createdAt: DateTime.utc(2026, 9, 29),
    );
    expect(
      notificationOpenTarget(broadcast, isSeller: false),
      isA<NotificationExternal>(),
    );
  });
}
