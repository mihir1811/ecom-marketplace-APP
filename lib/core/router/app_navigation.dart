import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'route_names.dart';

/// App-wide navigation using only GoRouter push/pop/go (never [Navigator.removeRoute]).
abstract final class AppNavigation {
  /// Opens [location], reusing an existing stack entry when that path is already open.
  static void open(
    BuildContext context,
    String location, {
    Object? extra,
  }) {
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

  /// Pops the current screen, or returns home when there is nothing to pop.
  static void back(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    final path = canonicalPath(
      router.routerDelegate.currentConfiguration.uri.toString(),
    );
    if (path != AppRouteNames.home) {
      router.go(AppRouteNames.home);
    }
  }

  /// Replaces the entire stack (logout, auth completion, gate redirects).
  static void resetTo(
    BuildContext context,
    String location, {
    Object? extra,
  }) {
    GoRouter.of(context).go(location, extra: extra);
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

  void goBack() => AppNavigation.back(this);

  void resetTo(String location, {Object? extra}) =>
      AppNavigation.resetTo(this, location, extra: extra);
}
