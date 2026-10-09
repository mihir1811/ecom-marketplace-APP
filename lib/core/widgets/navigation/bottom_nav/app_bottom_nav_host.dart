import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/buyer/application/wishlist_provider.dart';
import '../../../../features/cart/application/cart_provider.dart';
import '../../../auth/auth_providers.dart';
import '../../../router/app_navigation.dart';
import '../../../router/route_names.dart';
import '../../../theme/luxe_tokens.dart';
import 'app_bottom_nav_bar.dart';
import 'app_bottom_nav_destinations.dart';

/// Tracks dialogs, sheets and menus on the root navigator so the bar (which
/// sits outside the navigator) dims and blocks taps with them.
class AppPopupRouteObserver extends NavigatorObserver {
  final ValueNotifier<PopupRoute<dynamic>?> top = ValueNotifier(null);
  final _stack = <PopupRoute<dynamic>>[];

  void _sync() {
    final next = _stack.isEmpty ? null : _stack.last;
    if (top.value == next) return;
    // Navigator reports during build; publish once the frame is done.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        top.value = _stack.isEmpty ? null : _stack.last;
      });
    } else {
      top.value = next;
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute) {
      _stack.add(route);
      _sync();
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _forget(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _forget(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) _stack.remove(oldRoute);
    if (newRoute is PopupRoute) _stack.add(newRoute);
    _sync();
  }

  void _forget(Route<dynamic> route) {
    if (_stack.remove(route)) _sync();
  }
}

/// Registered on the root [GoRouter].
final appPopupRouteObserver = AppPopupRouteObserver();

/// Places the sticky [AppBottomNavBar] under the app's navigator.
///
/// The bar lives outside every page, so it stays put through page
/// transitions and its spring state carries across tab switches. Pages are
/// laid out above it (never behind it): the navigator gets the remaining
/// height and the bottom insets the bar already covers are removed from its
/// [MediaQuery]. On screens without the bar (detail, checkout, auth, seller)
/// the bar slides away and the page reclaims the space.
class AppBottomNavHost extends ConsumerStatefulWidget {
  const AppBottomNavHost({
    required this.router,
    required this.child,
    super.key,
  });

  final GoRouter router;
  final Widget child;

  @override
  ConsumerState<AppBottomNavHost> createState() => _AppBottomNavHostState();
}

class _AppBottomNavHostState extends ConsumerState<AppBottomNavHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _show = AnimationController(
    vsync: this,
    duration: LuxeMotion.medium,
    reverseDuration: LuxeMotion.fast,
  );
  late final Animation<double> _slot = CurvedAnimation(
    parent: _show,
    curve: LuxeMotion.settle,
    reverseCurve: Curves.easeInCubic,
  );

  // Keeps the bar's spring state when the popup scrim wraps / unwraps it.
  final _barKey = GlobalKey();

  String _path = '/';
  AppBottomNavTab? _tab;

  /// No route resolved yet: the first one snaps instead of animating.
  bool _awaitingFirstRoute = false;

  /// Last tab shown, kept while the bar slides away so it doesn't re-pop.
  AppBottomNavTab? _shownTab;

  @override
  void initState() {
    super.initState();
    _path = _currentPath();
    _tab = AppBottomNav.tabFor(_path);
    _shownTab = _tab;
    _show.value = _tab == null ? 0 : 1;
    _awaitingFirstRoute =
        widget.router.routerDelegate.currentConfiguration.isEmpty;
    widget.router.routerDelegate.addListener(_onRoute);
    appPopupRouteObserver.top.addListener(_onPopup);
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_onRoute);
    appPopupRouteObserver.top.removeListener(_onPopup);
    _show.dispose();
    super.dispose();
  }

  /// Top-most location, including pushed routes (the configuration's own
  /// uri ignores imperative pushes).
  String _currentPath() {
    final delegate = widget.router.routerDelegate;
    final config = delegate.currentConfiguration;
    if (config.isEmpty) return AppRouteNames.home;
    String location;
    try {
      location = delegate.state.uri.toString();
    } catch (_) {
      location = config.uri.toString();
    }
    return AppNavigation.canonicalPath(location);
  }

  void _onRoute() {
    if (!mounted) return;
    // The router reports its initial route while this ancestor is building.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _onRoute());
      return;
    }
    final path = _currentPath();
    final first = _awaitingFirstRoute;
    _awaitingFirstRoute = false;
    if (path == _path && !first) return;
    final tab = AppBottomNav.tabFor(path);
    setState(() {
      _path = path;
      _tab = tab;
      if (tab != null) _shownTab = tab;
    });
    final still = first || MediaQuery.disableAnimationsOf(context);
    if (tab == null) {
      still ? _show.value = 0 : _show.reverse();
    } else {
      still ? _show.value = 1 : _show.forward();
    }
  }

  void _onPopup() {
    if (mounted) setState(() {});
  }

  void _select(AppBottomNavDestination destination) {
    if (_path == destination.route) return;
    // Peer destinations: replace the stack so back never walks other tabs.
    widget.router.go(destination.route);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final inset = media.viewPadding.bottom;
    final barExtent = AppBottomNavBar.height + inset;

    return AnimatedBuilder(
      animation: _slot,
      builder: (context, bar) {
        final slot = barExtent * _slot.value;
        // The bar covers the bottom system inset and sits under the
        // keyboard, so neither should be applied again inside pages.
        final pageMedia = media.copyWith(
          padding: media.padding.copyWith(
            bottom: math.max(0.0, media.padding.bottom - slot),
          ),
          viewPadding: media.viewPadding.copyWith(
            bottom: math.max(0.0, media.viewPadding.bottom - slot),
          ),
          viewInsets: media.viewInsets.copyWith(
            bottom: math.max(0.0, media.viewInsets.bottom - slot),
          ),
        );
        return Column(
          children: [
            Expanded(
              child: MediaQuery(data: pageMedia, child: widget.child),
            ),
            SizedBox(
              height: slot,
              child: Offstage(
                offstage: _slot.value == 0,
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  minHeight: barExtent,
                  maxHeight: barExtent,
                  child: bar,
                ),
              ),
            ),
          ],
        );
      },
      child: _BarWithPopupScrim(
        popup: appPopupRouteObserver.top.value,
        child: _LiveBar(
          barKey: _barKey,
          tab: _tab ?? _shownTab,
          bottomInset: inset,
          onSelect: _select,
        ),
      ),
    );
  }
}

/// Bar with live cart / wishlist counts (signed-in only).
class _LiveBar extends ConsumerWidget {
  const _LiveBar({
    required this.barKey,
    required this.tab,
    required this.bottomInset,
    required this.onSelect,
  });

  final GlobalKey barKey;
  final AppBottomNavTab? tab;
  final double bottomInset;
  final ValueChanged<AppBottomNavDestination> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(authProvider.select((s) => s.isAuthenticated));
    final cart = signedIn ? ref.watch(cartItemCountProvider) : 0;
    final saved = signedIn ? ref.watch(wishlistCountProvider) : 0;
    // Outside the navigator there is no page Material: supply the text
    // defaults here.
    return Material(
      type: MaterialType.transparency,
      child: AppBottomNavBar(
        key: barKey,
        selected: tab,
        bottomInset: bottomInset,
        onSelect: onSelect,
        badges: {AppBottomNavTab.cart: cart, AppBottomNavTab.wishlist: saved},
      ),
    );
  }
}

/// While a dialog / sheet / menu is open the bar takes on its barrier (only
/// over the bar's own pixels) and a tap on it behaves like a barrier tap.
class _BarWithPopupScrim extends StatelessWidget {
  const _BarWithPopupScrim({required this.popup, required this.child});

  final PopupRoute<dynamic>? popup;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final route = popup;
    if (route == null) return child;

    final barrier = route.barrierColor;
    final Color? tint = barrier != null && barrier.a > 0
        ? barrier
        // Full-screen overlays without a barrier (spotlight search) veil
        // the bar like their own frosted backdrop.
        : route is RawDialogRoute
        ? LuxePalette.of(context).canvas.withValues(alpha: 0.9)
        : null;
    final animation = route.animation;

    Widget tinted = child;
    if (tint != null && animation != null) {
      tinted = AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, child) => ColorFiltered(
          colorFilter: ColorFilter.mode(
            tint.withValues(alpha: tint.a * animation.value),
            BlendMode.srcATop,
          ),
          child: child,
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        tinted,
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: route.barrierDismissible
                ? () => route.navigator?.maybePop()
                : null,
          ),
        ),
      ],
    );
  }
}
