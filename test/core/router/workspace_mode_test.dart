import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/core/router/app_navigation.dart';
import 'package:gemstone/core/router/route_names.dart';
import 'package:gemstone/core/router/workspace_mode.dart';

void main() {
  group('workspaceForPath', () {
    test('seller workspace is every /seller page', () {
      expect(
        workspaceForPath(AppRouteNames.sellerDashboard),
        AppWorkspace.seller,
      );
      expect(
        workspaceForPath(AppRouteNames.sellerOrderDetailPath('o1')),
        AppWorkspace.seller,
      );
    });

    test('home, catalog, cart and /buyer pages are the buyer side', () {
      for (final path in [
        AppRouteNames.home,
        AppRouteNames.diamonds,
        AppRouteNames.cart,
        AppRouteNames.buyerOrders,
        AppRouteNames.productDetailPath('diamond', 'p1'),
        '/sellers-guide',
      ]) {
        expect(workspaceForPath(path), AppWorkspace.buyer, reason: path);
      }
    });
  });

  test('switching lands on the side\'s entry page', () {
    expect(
      workspaceEntryRoute(AppWorkspace.seller, pending: false),
      AppRouteNames.sellerDashboard,
    );
    expect(
      workspaceEntryRoute(AppWorkspace.seller, pending: true),
      AppRouteNames.sellerProfile,
    );
    expect(
      workspaceEntryRoute(AppWorkspace.buyer, pending: false),
      AppRouteNames.home,
    );
  });

  test('bar shortcuts stay on the current side', () {
    expect(
      notificationsRouteFor(AppWorkspace.buyer),
      AppRouteNames.buyerNotifications,
    );
    expect(
      notificationsRouteFor(AppWorkspace.seller),
      AppRouteNames.sellerNotifications,
    );
    expect(walletRouteFor(AppWorkspace.buyer), AppRouteNames.buyerWallet);
    expect(messagesRouteFor(AppWorkspace.seller), AppRouteNames.sellerChat);
  });

  group('logicalParentOf', () {
    test('detail pages go up to their list', () {
      expect(
        AppNavigation.logicalParentOf(AppRouteNames.buyerOrderDetailPath('1')),
        AppRouteNames.buyerOrders,
      );
      expect(
        AppNavigation.logicalParentOf(AppRouteNames.buyerInquiryNew),
        AppRouteNames.buyerInquiries,
      );
      expect(
        AppNavigation.logicalParentOf(
          AppRouteNames.sellerProductEditPath('p1'),
        ),
        AppRouteNames.sellerProducts,
      );
      expect(
        AppNavigation.logicalParentOf(AppRouteNames.sellerChatDetailPath('c')),
        AppRouteNames.sellerChat,
      );
    });

    test('seller tools go up to the dashboard; dashboard goes home', () {
      expect(
        AppNavigation.logicalParentOf(AppRouteNames.sellerWallet),
        AppRouteNames.sellerDashboard,
      );
      expect(
        AppNavigation.logicalParentOf(AppRouteNames.sellerDashboard),
        isNull,
      );
    });

    test('buyer top-level pages and auctions go home', () {
      expect(AppNavigation.logicalParentOf(AppRouteNames.buyerOrders), isNull);
      expect(
        AppNavigation.logicalParentOf(AppRouteNames.auctionDetailPath('a1')),
        isNull,
      );
      expect(
        AppNavigation.logicalParentOf(AppRouteNames.auctionActivity),
        isNull,
      );
    });
  });
}
