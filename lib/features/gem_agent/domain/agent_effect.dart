import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_navigation.dart';
import '../../../core/router/navigator_keys.dart';

/// App-side action a tool asks for once it has finished its work
/// (navigate, open a sheet, prime a screen). Applied by the controller
/// after the agent UI has stepped aside, never inside the engine.
abstract class AgentEffect {
  const AgentEffect();

  Future<void> apply(Ref ref);
}

/// Opens [route] on the root navigator, reusing it when already open.
/// [replaceStack] uses `go`, needed for shell routes whose scoped state
/// must survive sibling navigation (e.g. results → edit filters).
class NavigateEffect extends AgentEffect {
  const NavigateEffect(this.route, {this.replaceStack = false});

  final String route;
  final bool replaceStack;

  @override
  Future<void> apply(Ref ref) async {
    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    if (replaceStack) {
      AppNavigation.resetTo(context, route);
    } else {
      AppNavigation.open(context, route);
    }
  }
}

/// Opens a workspace page (seller / buyer account area) whose state lives in
/// its query string, e.g. `/seller/orders?tab=pending&from=2026-10-29`.
///
/// Shell siblings are switched with `go`, so the page rebuilds with the new
/// query even when it is already on screen; other pages stack like
/// [NavigateEffect].
class OpenPageEffect extends AgentEffect {
  const OpenPageEffect(this.location);

  final String location;

  @override
  Future<void> apply(Ref ref) async {
    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    final router = GoRouter.of(context);
    final current = router.routerDelegate.currentConfiguration.uri.toString();
    if (current == location) return;
    final path = AppNavigation.canonicalPath(location);
    final peer =
        path.startsWith('/seller/') ||
        AppNavigation.canonicalPath(current) == path;
    if (peer) {
      router.go(location);
    } else {
      AppNavigation.open(context, location);
    }
  }
}

/// Runs [effects] in order.
class CompositeEffect extends AgentEffect {
  const CompositeEffect(this.effects);

  final List<AgentEffect> effects;

  @override
  Future<void> apply(Ref ref) async {
    for (final effect in effects) {
      await effect.apply(ref);
    }
  }
}
