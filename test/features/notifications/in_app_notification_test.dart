import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/core/auth/auth_controller.dart';
import 'package:gemstone/core/auth/auth_providers.dart';
import 'package:gemstone/core/auth/auth_state.dart';
import 'package:gemstone/core/theme/app_theme.dart';
import 'package:gemstone/features/notifications/application/in_app_notification_provider.dart';
import 'package:gemstone/features/notifications/data/mappers/notification_mapper.dart';
import 'package:gemstone/features/notifications/domain/models/app_notification.dart';
import 'package:gemstone/features/notifications/presentation/widgets/in_app_notification_host.dart';

AppNotification _push(String id, {String? thread, String title = 'Title'}) {
  return NotificationMapper.fromPush(
    {'notificationId': id, 'type': 'AUCTION_OUTBID', 'threadId': ?thread},
    title: title,
    body: 'Body $id',
  );
}

class _SignedOutAuth extends AuthController {
  @override
  AuthState build() => const AuthState();
}

void main() {
  group('NotificationMapper.fromPush', () {
    test('reads ids and text from the FCM data and notification blocks', () {
      final sent = DateTime.utc(2026, 9, 29, 6, 14);
      final n = NotificationMapper.fromPush(
        {
          'notificationId': '8b2f4c1d',
          'type': 'AUCTION_OUTBID',
          'link': '/auctions/2d7e9a10',
          'auctionId': '2d7e9a10',
          'threadId': 'auction_2d7e9a10',
        },
        title: "You've been outbid",
        body: 'A higher bid was placed.',
        sentTime: sent,
      );
      expect(n.id, '8b2f4c1d');
      expect(n.type, 'AUCTION_OUTBID');
      expect(n.link, '/auctions/2d7e9a10');
      expect(n.data['auctionId'], '2d7e9a10');
      expect(n.title, "You've been outbid");
      expect(n.isRead, isFalse);
      expect(n.createdAt, sent);
    });

    test('falls back to data title/body for data-only pushes', () {
      final n = NotificationMapper.fromPush({
        'type': 'ADMIN_BROADCAST',
        'title': 'Sale',
        'body': 'Up to 20% off',
      });
      expect(n.id, isEmpty);
      expect(n.link, isEmpty);
      expect(n.title, 'Sale');
      expect(n.body, 'Up to 20% off');
    });
  });

  group('InAppNotificationController', () {
    late ProviderContainer container;
    InAppNotificationController controller() =>
        container.read(inAppNotificationProvider.notifier);
    InAppNotificationState state() => container.read(inAppNotificationProvider);

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('shows one banner and queues the rest in order', () {
      controller()
        ..show(_push('a'))
        ..show(_push('b'))
        ..show(_push('c'));
      expect(state().current?.id, 'a');
      expect(state().queue.map((n) => n.id), ['b', 'c']);

      controller().dismiss();
      expect(state().current?.id, 'b');
      controller().dismiss();
      controller().dismiss();
      expect(state().current, isNull);
      expect(state().queue, isEmpty);
    });

    test('drops duplicate deliveries of the same notification', () {
      controller()
        ..show(_push('a'))
        ..show(_push('a'))
        ..show(_push('b'))
        ..show(_push('b'));
      expect(state().current?.id, 'a');
      expect(state().queue.map((n) => n.id), ['b']);
    });

    test('collapses pushes for the same thread to the newest', () {
      controller()
        ..show(_push('a', thread: 'auction_1'))
        ..show(_push('b', thread: 'auction_1'))
        ..show(_push('c', thread: 'auction_2'))
        ..show(_push('d', thread: 'auction_2'));
      expect(state().current?.id, 'b');
      expect(state().queue.map((n) => n.id), ['d']);
    });

    test('caps the queue', () {
      for (final id in ['a', 'b', 'c', 'd', 'e', 'f']) {
        controller().show(_push(id));
      }
      expect(state().current?.id, 'a');
      expect(state().queue.length, InAppNotificationController.maxQueued);
      expect(state().queue.last.id, 'f');
    });

    test('hands out a pending tap once', () {
      controller().requestOpen(_push('a'));
      expect(controller().takePendingOpen()?.id, 'a');
      expect(controller().takePendingOpen(), isNull);
    });
  });

  group('InAppNotificationHost', () {
    Future<ProviderContainer> pumpHost(WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [authProvider.overrideWith(_SignedOutAuth.new)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: TextField()),
            builder: (context, child) => Stack(
              fit: StackFit.expand,
              children: [child!, const InAppNotificationHost()],
            ),
          ),
        ),
      );
      return container;
    }

    testWidgets('slides in, then closes by itself', (tester) async {
      final container = await pumpHost(tester);
      container
          .read(inAppNotificationProvider.notifier)
          .show(_push('a', title: 'New bid'));
      await tester.pumpAndSettle();
      expect(find.text('New bid'), findsOneWidget);

      // Still readable well after it appeared…
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('New bid'), findsOneWidget);

      // …then it goes away on its own.
      await tester.pump(InAppNotificationHost.visibleFor);
      await tester.pumpAndSettle();
      expect(find.text('New bid'), findsNothing);
      expect(container.read(inAppNotificationProvider).current, isNull);
    });

    testWidgets('close button dismisses right away', (tester) async {
      final container = await pumpHost(tester);
      container
          .read(inAppNotificationProvider.notifier)
          .show(_push('a', title: 'New bid'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('New bid'), findsNothing);
    });

    testWidgets('shows queued banners one after another', (tester) async {
      final container = await pumpHost(tester);
      container.read(inAppNotificationProvider.notifier)
        ..show(_push('a', title: 'First'))
        ..show(_push('b', title: 'Second'));
      await tester.pumpAndSettle();
      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsNothing);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('First'), findsNothing);
      expect(find.text('Second'), findsOneWidget);
    });

    testWidgets('does not take focus from a field being typed in', (
      tester,
    ) async {
      final container = await pumpHost(tester);
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'bid 150');
      final field = tester.widget<EditableText>(find.byType(EditableText));
      expect(field.focusNode.hasFocus, isTrue);

      container
          .read(inAppNotificationProvider.notifier)
          .show(_push('a', title: 'New bid'));
      await tester.pumpAndSettle();
      expect(find.text('New bid'), findsOneWidget);
      expect(field.focusNode.hasFocus, isTrue);
      expect(find.text('bid 150'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(field.focusNode.hasFocus, isTrue);
    });
  });
}
