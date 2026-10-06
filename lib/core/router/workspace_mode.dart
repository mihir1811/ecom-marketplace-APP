import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../haptics/app_haptics.dart';
import 'route_names.dart';

/// The two sides of the app a signed-in user can be on.
///
/// The side is derived from the current location (never stored), so it can
/// never drift out of sync with what is on screen: every `/seller/...` page is
/// the seller workspace, everything else (home, catalog, cart, `/buyer/...`)
/// is the buyer side.
enum AppWorkspace { buyer, seller }

AppWorkspace workspaceForPath(String path) =>
    path == '/seller' || path.startsWith('/seller/')
    ? AppWorkspace.seller
    : AppWorkspace.buyer;

/// The side currently on screen. Reads the router (not the nearest route),
/// so it also works from dialogs and sheets on the root navigator.
AppWorkspace currentWorkspace(BuildContext context) => workspaceForPath(
  GoRouter.of(context).routerDelegate.currentConfiguration.uri.path,
);

/// Where the seller side opens. Verification-pending sellers cannot use the
/// dashboard yet, so they land on their profile (which explains the status).
String sellerEntryRoute({required bool pending}) =>
    pending ? AppRouteNames.sellerProfile : AppRouteNames.sellerDashboard;

/// Landing page for [target].
String workspaceEntryRoute(AppWorkspace target, {required bool pending}) =>
    target == AppWorkspace.seller
    ? sellerEntryRoute(pending: pending)
    : AppRouteNames.home;

String notificationsRouteFor(AppWorkspace workspace) =>
    workspace == AppWorkspace.seller
    ? AppRouteNames.sellerNotifications
    : AppRouteNames.buyerNotifications;

String walletRouteFor(AppWorkspace workspace) =>
    workspace == AppWorkspace.seller
    ? AppRouteNames.sellerWallet
    : AppRouteNames.buyerWallet;

String messagesRouteFor(AppWorkspace workspace) =>
    workspace == AppWorkspace.seller
    ? AppRouteNames.sellerChat
    : AppRouteNames.buyerMessages;

/// Moves to the other side of the app with a fresh stack, so back from the
/// new side never walks through the previous side's pages.
///
/// Call after closing any open drawer; [router] is captured up front so this
/// stays safe even if the caller's context is torn down by the navigation.
void switchWorkspace(
  GoRouter router,
  AppWorkspace target, {
  required bool pending,
}) {
  AppHaptics.selection();
  router.go(workspaceEntryRoute(target, pending: pending));
}

/// Closes the drawer hosting [context] (if any) and switches side.
void switchWorkspaceFrom(
  BuildContext context,
  AppWorkspace target, {
  required bool pending,
}) {
  final router = GoRouter.of(context);
  final scaffold = Scaffold.maybeOf(context);
  if (scaffold != null && scaffold.isDrawerOpen) {
    scaffold.closeDrawer();
  }
  switchWorkspace(router, target, pending: pending);
}
