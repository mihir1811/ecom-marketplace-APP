import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'confirm_app_exit.dart';
import 'route_names.dart';

/// App-wide navigation using only GoRouter push/pop/go (never [Navigator.removeRoute]).
abstract final class AppNavigation {
  static const _authRoutesReturningToLogin = <String>{
    AppRouteNames.register,
    AppRouteNames.forgotPassword,
    AppRouteNames.verifyOtp,
    AppRouteNames.resetPassword,
    AppRouteNames.recoverAccount,
  };

  /// Opens [location], reusing an existing stack entry when that path is already open.
  ///
  /// Use for detail / flow screens that should stack. Prefer [switchTo] for
  /// drawer / shell peer destinations so back never walks blank intermediate pages.
  static void open(BuildContext context, String location, {Object? extra}) {
    final router = GoRouter.of(context);
    final target = canonicalPath(location);
    final stack = _stackPaths(router);
    final current = stack.isEmpty ? AppRouteNames.home : stack.last;
    if (target == current) return;

    final existing = stack.lastIndexWhere((path) => path == target);
    if (existing >= 0) {
      var remaining = stack.length - 1 - existing;
      while (remaining > 0 && router.canPop()) {
        router.pop();
        remaining--;
      }
      return;
    }

    router.push(location, extra: extra);
  }

  /// Moves between auth peers (login ⇄ register) without stacking copies.
  ///
  /// Returns to [location] when it is already in the stack; otherwise replaces
  /// the current auth screen, or pushes when coming from a non-auth page.
  static void switchAuth(BuildContext context, String location) {
    final router = GoRouter.of(context);
    final target = canonicalPath(location);
    final stack = _stackPaths(router);
    final current = stack.isEmpty ? AppRouteNames.home : stack.last;
    if (target == current) return;

    final existing = stack.lastIndexWhere((path) => path == target);
    if (existing >= 0) {
      var remaining = stack.length - 1 - existing;
      while (remaining > 0 && router.canPop()) {
        router.pop();
        remaining--;
      }
      if (remaining == 0) return;
    }

    final onAuthScreen =
        current == AppRouteNames.login ||
        _authRoutesReturningToLogin.contains(current);
    if (onAuthScreen && router.canPop()) {
      router.pushReplacement(location);
    } else if (onAuthScreen) {
      router.go(location);
    } else {
      router.push(location);
    }
  }

  /// Replaces the current location without pushing (drawer / tab / shell peers).
  static void switchTo(BuildContext context, String location, {Object? extra}) {
    final router = GoRouter.of(context);
    final target = canonicalPath(location);
    final current = canonicalPath(
      router.routerDelegate.currentConfiguration.uri.toString(),
    );
    if (target == current) return;
    router.go(location, extra: extra);
  }

  /// Pops the current screen, or navigates safely when the stack is empty.
  ///
  /// Empty-stack order:
  /// 1. Optional [fallbackLocation] (e.g. auth sub-screens → login)
  /// 2. Auth recovery screens → login
  /// 3. Logical parent ([logicalParentOf]): detail → its list, seller tool →
  ///    seller dashboard
  /// 4. Any non-home / non-login route → home
  /// 5. Home or login → exit confirmation dialog (never exits silently)
  static Future<void> back(
    BuildContext context, {
    String? fallbackLocation,
  }) async {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }

    final path = canonicalPath(
      router.routerDelegate.currentConfiguration.uri.toString(),
    );

    final fallback = fallbackLocation == null
        ? null
        : canonicalPath(fallbackLocation);
    if (fallback != null && path != fallback) {
      router.go(fallback);
      return;
    }

    if (_authRoutesReturningToLogin.contains(path)) {
      router.go(AppRouteNames.login);
      return;
    }

    final parent = logicalParentOf(path);
    if (parent != null) {
      router.go(parent);
      return;
    }

    if (path != AppRouteNames.home && path != AppRouteNames.login) {
      router.go(AppRouteNames.home);
      return;
    }

    await requestAppExit(context);
  }

  /// Replaces the entire stack (logout, auth completion, gate redirects).
  static void resetTo(BuildContext context, String location, {Object? extra}) {
    GoRouter.of(context).go(location, extra: extra);
  }

  /// List pages whose children are detail / flow screens.
  static const _listParents = <String>[
    AppRouteNames.buyerOrders,
    AppRouteNames.buyerInquiries,
    AppRouteNames.buyerMessages,
    AppRouteNames.sellerOrders,
    AppRouteNames.sellerProducts,
    AppRouteNames.sellerInquiries,
    AppRouteNames.sellerChat,
  ];

  /// The screen one level "up" from [location], used when there is no
  /// history to pop (deep links, notification taps, after switching side).
  ///
  /// Returns null when the natural parent is home.
  static String? logicalParentOf(String location) {
    final path = canonicalPath(location);
    for (final parent in _listParents) {
      if (path.startsWith('$parent/')) return parent;
    }
    if (path == AppRouteNames.buyerAbout ||
        path == AppRouteNames.buyerPrivacy ||
        path == AppRouteNames.buyerTerms ||
        path == AppRouteNames.buyerPolicies ||
        path.startsWith('${AppRouteNames.buyerPolicies}/')) {
      return AppRouteNames.buyerSettings;
    }
    if (path == AppRouteNames.sellerAbout ||
        path == AppRouteNames.sellerPrivacy ||
        path == AppRouteNames.sellerTerms ||
        path == AppRouteNames.sellerPolicies ||
        path.startsWith('${AppRouteNames.sellerPolicies}/')) {
      return AppRouteNames.sellerSettings;
    }
    if (path.startsWith('/seller/') && path != AppRouteNames.sellerDashboard) {
      return AppRouteNames.sellerDashboard;
    }
    return null;
  }

  static String canonicalPath(String location) {
    final uri = Uri.parse(location);
    final path = uri.path.isEmpty ? AppRouteNames.home : uri.path;
    if (path.length > 1 && path.endsWith('/')) {
      return path.substring(0, path.length - 1);
    }
    return path;
  }

  static List<String> _stackPaths(GoRouter router) {
    final config = router.routerDelegate.currentConfiguration;
    final paths = <String>[];
    _collect(config.matches, paths);
    if (paths.isEmpty) {
      paths.add(canonicalPath(config.uri.toString()));
    }
    return paths;
  }

  static void _collect(List<RouteMatchBase> matches, List<String> paths) {
    for (final match in matches) {
      if (match is ImperativeRouteMatch) {
        _collect(match.matches.matches, paths);
        continue;
      }
      final loc = match.matchedLocation;
      if (loc.isEmpty) continue;
      final path = canonicalPath(loc);
      if (paths.isEmpty || paths.last != path) {
        paths.add(path);
      }
    }
  }
}

extension AppNavContext on BuildContext {
  void openRoute(String location, {Object? extra}) =>
      AppNavigation.open(this, location, extra: extra);

  void switchAuthRoute(String location) =>
      AppNavigation.switchAuth(this, location);

  void switchToRoute(String location, {Object? extra}) =>
      AppNavigation.switchTo(this, location, extra: extra);

  void goBack({String? fallbackLocation}) =>
      AppNavigation.back(this, fallbackLocation: fallbackLocation);

  void resetTo(String location, {Object? extra}) =>
      AppNavigation.resetTo(this, location, extra: extra);
}
