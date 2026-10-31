import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/buyer/application/wishlist_provider.dart';
import '../../../../features/comparison/presentation/widgets/compare_dock_button.dart';
import '../../../../features/gem_agent/application/gem_agent_controller.dart';
import '../../../auth/auth_providers.dart';
import '../../../router/app_navigation.dart';
import '../../../router/route_names.dart';
import '../../../theme/luxe_tokens.dart';
import '../app_drawer_stage.dart';
import '../top_bar/section_top_bar.dart';
import 'app_bottom_nav_bar.dart';
import 'app_bottom_nav_destinations.dart';
import 'app_category_menu.dart';
import 'tab_reveal_transition.dart';

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

/// Floats the [AppBottomNavBar] dock over the app's navigator.
///
/// On comparable catalog listings a round [CompareDockButton] joins the
/// dock's row after Profile. Once the dock has slid in and settled, the
/// button peels off its end like chewing gum while the dock narrows to make
/// room.
///
/// The dock lives outside every page, so it stays put through page
/// transitions and scrolling, and its spring state carries across tab
/// switches. Pages run full height behind it; their [MediaQuery] bottom
/// padding grows to clear the expanded dock, so padded pages stay clear of
/// it and pages that scroll behind it can still reach their last item.
/// Scrolling a page towards its end folds the dock into its compact form;
/// scrolling back, reaching the top, a tap on the dock or a route change
/// unfolds it. Off the tab and catalog listing screens the dock slides
/// away. The side drawer opens behind the page ([AppDrawerStage]) and the
/// dock rides along with the receding page; end drawers live inside pages,
/// under the dock, so while one is open the dock steps aside
/// ([reportDrawer]).
///
/// Switching tabs grows the next page out of the touch point on the bar
/// ([TabRevealController]). The shared [SectionTopBar] stays put above the
/// switch; only its section icons change.
class AppBottomNavHost extends ConsumerStatefulWidget {
  const AppBottomNavHost({
    required this.router,
    required this.child,
    super.key,
  });

  final GoRouter router;
  final Widget child;

  /// Whether a page's end drawer is open; the dock steps aside while it is.
  static final drawerOpen = ValueNotifier<bool>(false);

  /// Wire to [Scaffold.onDrawerChanged] / [Scaffold.onEndDrawerChanged].
  static void reportDrawer(bool open) {
    // Scaffold reports while building or disposing; publish after the frame.
    SchedulerBinding.instance.addPostFrameCallback(
      (_) => drawerOpen.value = open,
    );
  }

  @override
  ConsumerState<AppBottomNavHost> createState() => _AppBottomNavHostState();
}

class _AppBottomNavHostState extends ConsumerState<AppBottomNavHost>
    with TickerProviderStateMixin {
  late final _reveal = TabRevealController(vsync: this);

  /// Last pointer-down on the bar (global): where the next page grows from.
  Offset? _touch;

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

  /// 1 while the compare button holds its place in the dock's row. It only
  /// runs once the dock is fully in view: a short beat, then the button
  /// peels off the dock's end (the bar's built-in timeline).
  late final AnimationController _compareSlot = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2850),
    reverseDuration: const Duration(milliseconds: 350),
  );
  late final Animation<double> _compareShown = CurvedAnimation(
    parent: _compareSlot,
    curve: const Interval(0.088, 1),
  );

  /// 1 while a drawer is open: the dock fades and sinks out of its way.
  late final AnimationController _veil = AnimationController(
    vsync: this,
    duration: LuxeMotion.fast,
    value: AppBottomNavHost.drawerOpen.value ? 1 : 0,
  );

  // Keeps the bar's spring state when the popup scrim wraps / unwraps it.
  final _barKey = GlobalKey();

  String _path = '/';
  AppBottomNavTab? _tab;

  /// No route resolved yet: the first one snaps instead of animating.
  bool _awaitingFirstRoute = false;

  /// Last tab shown, kept while the bar slides away so it doesn't re-pop.
  AppBottomNavTab? _shownTab;

  /// The category menu while it is up; the bar pops its Categories bubble.
  AppCategoryMenuRoute? _categoriesMenu;

  /// Dock folded down while the page scrolls towards its end.
  bool _compact = false;

  /// Vertical scroll travel in one direction since it last turned.
  double _travel = 0;

  @override
  void initState() {
    super.initState();
    _path = _currentPath();
    _tab = AppBottomNav.tabFor(_path);
    _shownTab = _tab;
    _show.value = AppBottomNav.isVisibleOn(_path) ? 1 : 0;
    _compareSlot.value = AppBottomNav.comparesOn(_path) ? 1 : 0;
    _show.addStatusListener(_onShowStatus);
    _awaitingFirstRoute =
        widget.router.routerDelegate.currentConfiguration.isEmpty;
    widget.router.routerDelegate.addListener(_onRoute);
    appPopupRouteObserver.top.addListener(_onPopup);
    AppBottomNavHost.drawerOpen.addListener(_onDrawer);
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_onRoute);
    appPopupRouteObserver.top.removeListener(_onPopup);
    AppBottomNavHost.drawerOpen.removeListener(_onDrawer);
    _reveal.dispose();
    _show
      ..removeStatusListener(_onShowStatus)
      ..dispose();
    _veil.dispose();
    _compareSlot.dispose();
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
    // Somebody else navigated mid-switch (deep link, redirect, back).
    if (_reveal.active.value && AppBottomNav.tabFor(path) == null) {
      _reveal.stop();
    }
    final first = _awaitingFirstRoute;
    _awaitingFirstRoute = false;
    if (path == _path && !first) return;
    final tab = AppBottomNav.tabFor(path);
    final visible = AppBottomNav.isVisibleOn(path);
    setState(() {
      _path = path;
      _tab = tab;
      if (tab != null) _shownTab = tab;
      _compact = false;
      _travel = 0;
    });
    // A drawer pick navigates away before its drawer reports closing.
    AppBottomNavHost.drawerOpen.value = false;
    final still = first || MediaQuery.disableAnimationsOf(context);
    if (!visible) {
      still ? _show.value = 0 : _show.reverse();
    } else {
      still ? _show.value = 1 : _show.forward();
    }
    final compares = AppBottomNav.comparesOn(path);
    if (still) {
      _compareSlot.value = compares ? 1 : 0;
    } else if (!compares) {
      _compareSlot.reverse();
    } else if (_show.isCompleted) {
      _emergeCompare();
    }
    // Otherwise the dock is still sliding in; [_onShowStatus] follows up.
  }

  /// The compare button never enters alongside the dock: it waits for the
  /// dock to settle, then peels off it.
  void _onShowStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed &&
        mounted &&
        AppBottomNav.comparesOn(_path)) {
      _emergeCompare();
    }
  }

  void _emergeCompare() {
    if (_compareSlot.status == AnimationStatus.forward ||
        _compareSlot.isCompleted) {
      return;
    }
    _compareSlot.forward();
  }

  void _onDrawer() {
    if (!mounted) return;
    final open = AppBottomNavHost.drawerOpen.value;
    if (MediaQuery.disableAnimationsOf(context)) {
      _veil.value = open ? 1 : 0;
    } else {
      open ? _veil.forward() : _veil.reverse();
    }
  }

  void _onPopup() {
    if (mounted) setState(() {});
  }

  bool get _animate => !MediaQuery.disableAnimationsOf(context);

  // Fold after this much travel towards the end, unfold after this much back.
  static const _foldAfter = 28.0;
  static const _unfoldAfter = 18.0;

  bool _onScroll(ScrollUpdateNotification n) {
    final m = n.metrics;
    final delta = n.scrollDelta;
    if (m.axis != Axis.vertical ||
        delta == null ||
        !AppBottomNav.isVisibleOn(_path)) {
      return false;
    }
    if (m.pixels <= m.minScrollExtent + _foldAfter) {
      _expand();
      return false;
    }
    // Overscroll bounce is not the user turning around.
    if (m.outOfRange || delta == 0) return false;
    if (delta.sign != _travel.sign) _travel = 0;
    _travel += delta;
    if (_travel > _foldAfter) {
      _setCompact(true);
    } else if (_travel < -_unfoldAfter) {
      _setCompact(false);
    }
    return false;
  }

  void _setCompact(bool compact) {
    if (_compact == compact || (compact && _categoriesMenu != null)) return;
    setState(() => _compact = compact);
  }

  void _expand() {
    _travel = 0;
    _setCompact(false);
  }

  void _select(AppBottomNavDestination destination) {
    if (_path == destination.route) return;
    if (_animate) _reveal.reveal(_touch ?? _tabCentre(destination));
    // Peer destinations: replace the stack so back never walks other tabs.
    widget.router.go(destination.route);
  }

  /// Fallback origin (keyboard / semantics activation): the tab's slot.
  Offset _tabCentre(AppBottomNavDestination destination) {
    final size = MediaQuery.sizeOf(context);
    final slots = AppBottomNav.slots.length;
    final i = AppBottomNav.slots.indexOf(destination);
    final dock = AppBottomNavBar.extent(
      MediaQuery.viewPaddingOf(context).bottom,
    );
    return Offset(size.width * (i + 0.5) / slots, size.height - dock / 2);
  }

  /// A bar tap while the category menu is up: close it, then go there.
  void _selectFromMenu(AppBottomNavDestination destination) {
    _closeCategories();
    _select(destination);
  }

  Future<void> _openCategories() async {
    final navigator = widget.router.routerDelegate.navigatorKey.currentState;
    if (navigator == null || _categoriesMenu != null) return;
    final menu = AppCategoryMenuRoute.of(navigator);
    setState(() {
      _categoriesMenu = menu;
      _compact = false;
    });
    final route = await navigator.push(menu);
    if (!mounted) return;
    if (identical(_categoriesMenu, menu)) {
      setState(() => _categoriesMenu = null);
    }
    final context = widget.router.routerDelegate.navigatorKey.currentContext;
    if (route != null && context != null && context.mounted) {
      context.openRoute(route);
    }
  }

  void _closeCategories() {
    final menu = _categoriesMenu;
    if (menu == null) return;
    setState(() => _categoriesMenu = null);
    if (menu.isCurrent) {
      menu.navigator?.pop();
    } else if (menu.isActive) {
      menu.navigator?.removeRoute(menu);
    }
  }

  void _openAgent() {
    _closeCategories();
    ref.read(gemAgentControllerProvider.notifier).open();
  }

  void _openCompare() => widget.router.push(AppRouteNames.comparison);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final inset = media.viewPadding.bottom;
    final extent = AppBottomNavBar.extent(inset);
    final clearance = AppBottomNavBar.clearance(inset);
    final open = _categoriesMenu != null;
    final agentOpen = ref.watch(
      gemAgentControllerProvider.select((s) => s.isOpen),
    );
    final compare = CompareDockButton(
      visible: AppBottomNav.comparesOn(_path) && !open,
      diamondListing: AppBottomNav.isDiamondListing(_path),
      onOpen: _openCompare,
    );

    return AnimatedBuilder(
      animation: Listenable.merge([_slot, _veil, AppDrawerStage.progress]),
      builder: (context, bar) {
        final shown = _slot.value;
        final veil = Curves.easeOutCubic.transform(_veil.value);
        final staged = AppDrawerStage.progress.value;
        // The dock rides on the page as it recedes for the side drawer.
        final dockTop = media.size.height - extent;
        final ride = Matrix4.translationValues(0, -dockTop, 0)
          ..multiply(AppDrawerStage.frontTransform(media.size, staged))
          ..multiply(Matrix4.translationValues(0, dockTop, 0));
        // Pages run behind the floating dock; their bottom padding clears it.
        double clear(double bottom) =>
            bottom + (math.max(bottom, clearance) - bottom) * shown;
        final pageMedia = media.copyWith(
          padding: media.padding.copyWith(bottom: clear(media.padding.bottom)),
          viewPadding: media.viewPadding.copyWith(
            bottom: clear(media.viewPadding.bottom),
          ),
        );
        return Stack(
          children: [
            Positioned.fill(
              child: MediaQuery(
                data: pageMedia,
                child: NotificationListener<ScrollUpdateNotification>(
                  onNotification: _onScroll,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      TabRevealTransition(
                        controller: _reveal,
                        child: widget.child,
                      ),
                      // Every tab shows the same top bar: hold a copy over
                      // the switch so only the page changes underneath.
                      ValueListenableBuilder<bool>(
                        valueListenable: _reveal.active,
                        builder: (context, active, _) => active
                            ? Align(
                                alignment: Alignment.topCenter,
                                child: SizedBox(
                                  height:
                                      media.padding.top + SectionTopBar.height,
                                  // Outside the navigator: give its tooltips
                                  // an overlay of their own.
                                  child: IgnorePointer(
                                    child: Overlay(
                                      initialEntries: [
                                        OverlayEntry(
                                          builder: (_) =>
                                              SectionTopBar(location: _path),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: extent,
              child: Transform(
                transform: ride,
                child: Offstage(
                  offstage: shown == 0 || veil == 1,
                  child: Listener(
                    onPointerDown: (e) => _touch = e.position,
                    child: IgnorePointer(
                      ignoring: veil > 0 || staged > 0,
                      child: Opacity(
                        opacity: 1 - veil,
                        child: Transform.translate(
                          // Bubble included, the dock sinks fully out of view.
                          offset: Offset(
                            0,
                            (1 - shown) * (extent + 48) + veil * 24,
                          ),
                          child: bar,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      // The category menu belongs to the bar: the bar stays live over it,
      // and a tab tap closes the menu and opens that tab.
      child: _BarWithPopupScrim(
        popup: open ? null : appPopupRouteObserver.top.value,
        child: _LiveBar(
          barKey: _barKey,
          tab: _tab ?? _shownTab,
          bottomInset: inset,
          onSelect: open ? _selectFromMenu : _select,
          onAgent: _openAgent,
          agentOpen: agentOpen,
          onCategories: open ? _closeCategories : _openCategories,
          categoriesOpen: open,
          compact: _compact && !open,
          onExpand: _expand,
          trailing: compare,
          trailingShown: _compareShown,
        ),
      ),
    );
  }
}

/// Bar with the live wishlist count (signed-in only).
class _LiveBar extends ConsumerWidget {
  const _LiveBar({
    required this.barKey,
    required this.tab,
    required this.bottomInset,
    required this.onSelect,
    required this.onAgent,
    required this.agentOpen,
    required this.onCategories,
    required this.categoriesOpen,
    required this.compact,
    required this.onExpand,
    required this.trailing,
    required this.trailingShown,
  });

  final GlobalKey barKey;
  final AppBottomNavTab? tab;
  final double bottomInset;
  final ValueChanged<AppBottomNavDestination> onSelect;
  final VoidCallback onAgent;
  final bool agentOpen;
  final VoidCallback onCategories;
  final bool categoriesOpen;
  final bool compact;
  final VoidCallback onExpand;
  final Widget trailing;
  final Animation<double> trailingShown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(authProvider.select((s) => s.isAuthenticated));
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
        onAgent: onAgent,
        agentOpen: agentOpen,
        onCategories: onCategories,
        categoriesOpen: categoriesOpen,
        compact: compact,
        onExpand: onExpand,
        trailing: trailing,
        trailingShown: trailingShown,
        badges: {AppBottomNavTab.wishlist: saved},
      ),
    );
  }
}

/// Steps the bar out of the way while a sheet, dialog or menu is open, so
/// the popup sits above it. The bar stays mounted (state, fold and counts
/// untouched) and comes back as soon as the popup closes.
class _BarWithPopupScrim extends StatelessWidget {
  const _BarWithPopupScrim({required this.popup, required this.child});

  final PopupRoute<dynamic>? popup;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final animation = popup?.animation ?? kAlwaysDismissedAnimation;
    final hidden = popup != null;
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        // No route animation (or already settled): fully hidden.
        final t = !hidden
            ? 0.0
            : popup!.animation == null
            ? 1.0
            : animation.value.clamp(0.0, 1.0);
        return IgnorePointer(
          ignoring: hidden,
          child: Opacity(
            opacity: 1 - t,
            child: Transform.translate(offset: Offset(0, 24 * t), child: child),
          ),
        );
      },
    );
  }
}
