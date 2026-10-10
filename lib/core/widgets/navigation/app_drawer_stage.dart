import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../haptics/app_haptics.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_theme.dart';
import '../../theme/luxe_tokens.dart';

/// Side drawer that opens *behind* the page.
///
/// The page slides right, shrinks and turns slightly away in 3D, uncovering
/// the menu on a deep onyx backdrop; a faint ghost card trails behind it for
/// depth and the menu rows ease in one after another ([AppDrawerReveal]).
/// The page stays live as a card: tap it or swipe left to close. Like a
/// [Scaffold] drawer it opens from the left edge, and back closes it first.
///
/// The menu always renders in the dark theme, so it reads as one onyx and
/// champagne surface in both light and dark mode.
class AppDrawerStage extends StatefulWidget {
  const AppDrawerStage({required this.child, this.drawer, super.key});

  /// Menu shown behind the page; null disables the stage.
  final Widget? drawer;
  final Widget child;

  /// How far (0–1) the open stage is; the floating dock rides along with it.
  static final progress = ValueNotifier<double>(0);

  /// Nearest stage that has a drawer.
  static AppDrawerStageState? maybeOf(BuildContext context) {
    AppDrawerStageState? found;
    context.visitAncestorElements((element) {
      if (element is StatefulElement) {
        final state = element.state;
        if (state is AppDrawerStageState && state.hasDrawer) {
          found = state;
          return false;
        }
      }
      return true;
    });
    return found;
  }

  /// Menu width for a screen [width].
  static double drawerWidth(double width) => math.min(width * 0.66, 296);

  /// Clear air between the menu and the open page.
  static const double _gap = 22;

  /// Where the open page's near edge stops for a screen [width].
  static double pageInset(double width) => drawerWidth(width) + _gap;

  /// Page transform at open amount [t], in the page's own coordinates.
  static Matrix4 frontTransform(Size size, double t) =>
      _cardTransform(size, t, inset: pageInset(size.width), shrink: 0.26);

  static Matrix4 _cardTransform(
    Size size,
    double t, {
    required double inset,
    required double shrink,
  }) {
    if (t == 0) return Matrix4.identity();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final slide = inset * t;
    final scale = 1 - shrink * t;
    // Perspective about the screen centre; the card hinges on its left edge
    // and its far side turns away.
    return Matrix4.identity()
      ..translateByDouble(cx, cy, 0, 1)
      ..setEntry(3, 2, 0.0009)
      ..translateByDouble(-cx, -cy, 0, 1)
      ..translateByDouble(slide, cy, 0, 1)
      ..rotateY(-0.1 * t)
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(0, -cy, 0, 1);
  }

  @override
  State<AppDrawerStage> createState() => AppDrawerStageState();
}

class AppDrawerStageState extends State<AppDrawerStage>
    with SingleTickerProviderStateMixin {
  static const _openDuration = Duration(milliseconds: 640);
  static const _closeDuration = Duration(milliseconds: 460);

  /// Quick lift, long glide into place.
  static const _openCurve = Cubic(0.16, 1, 0.3, 1);

  /// Gathers, then settles the page back flat.
  static const _closeCurve = Cubic(0.45, 0, 0.15, 1);

  static const _radius = 30.0;
  static const _edgeWidth = 20.0;
  static const _flingVelocity = 365.0;

  late final AnimationController _controller = AnimationController(vsync: this)
    ..addListener(_publish);

  LocalHistoryEntry? _historyEntry;
  double _width = 0;

  bool get hasDrawer => widget.drawer != null;

  bool get isOpen => _controller.value > 0;

  /// Open amount, 0–1; drives the menu reveal.
  Animation<double> get animation => _controller;

  @override
  void didUpdateWidget(AppDrawerStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!hasDrawer && isOpen) {
      _removeHistoryEntry();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _removeHistoryEntry();
    if (AppDrawerStage.progress.value != 0 && _controller.value != 0) {
      AppDrawerStage.progress.value = 0;
    }
    _controller.dispose();
    super.dispose();
  }

  void _publish() => AppDrawerStage.progress.value = _controller.value;

  void open() {
    if (!hasDrawer) return;
    if (_controller.value == 0) AppHaptics.light();
    _addHistoryEntry();
    _animateTo(1);
  }

  void close() {
    _removeHistoryEntry();
    _animateTo(0);
  }

  void _animateTo(double target) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = target;
      return;
    }
    final opening = target == 1;
    final distance = (target - _controller.value).abs();
    if (distance == 0) return;
    _controller.animateTo(
      target,
      duration:
          (opening ? _openDuration : _closeDuration) * math.max(distance, 0.35),
      curve: opening ? _openCurve : _closeCurve,
    );
  }

  // Back closes the drawer before it leaves the page.
  void _addHistoryEntry() {
    if (_historyEntry != null) return;
    final route = ModalRoute.of(context);
    if (route == null) return;
    _historyEntry = LocalHistoryEntry(
      onRemove: _onHistoryEntryRemoved,
      impliesAppBarDismissal: false,
    );
    route.addLocalHistoryEntry(_historyEntry!);
  }

  void _removeHistoryEntry() {
    final entry = _historyEntry;
    _historyEntry = null;
    entry?.remove();
  }

  void _onHistoryEntryRemoved() {
    if (_historyEntry == null) return;
    _historyEntry = null;
    _animateTo(0);
  }

  void _dragStart(DragStartDetails _) {
    _controller.stop();
    _addHistoryEntry();
  }

  void _dragUpdate(DragUpdateDetails details) {
    final travel = AppDrawerStage.pageInset(_width);
    if (travel <= 0) return;
    _controller.value += (details.primaryDelta ?? 0) / travel;
  }

  void _dragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final opens = velocity.abs() >= _flingVelocity
        ? velocity > 0
        : _controller.value >= 0.5;
    opens ? open() : close();
  }

  @override
  Widget build(BuildContext context) {
    final edge = _edgeWidth + MediaQuery.paddingOf(context).left;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        _width = size.width;
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            final open = t > 0;
            return Stack(
              fit: StackFit.expand,
              children: [
                KeyedSubtree(
                  key: const ValueKey('backdrop'),
                  child: open && hasDrawer
                      ? _backdrop(size, t)
                      : const SizedBox.shrink(),
                ),
                KeyedSubtree(
                  key: const ValueKey('front'),
                  child: _front(size, t),
                ),
                if (hasDrawer)
                  Positioned(
                    key: const ValueKey('edge'),
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: edge,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      excludeFromSemantics: true,
                      dragStartBehavior: DragStartBehavior.down,
                      onHorizontalDragStart: _dragStart,
                      onHorizontalDragUpdate: _dragUpdate,
                      onHorizontalDragEnd: _dragEnd,
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _front(Size size, double t) {
    final open = t > 0;
    final radius = BorderRadius.circular(_radius * t);
    return Transform(
      transform: AppDrawerStage.frontTransform(size, t),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: open
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.42 * t),
                    blurRadius: 48,
                    spreadRadius: -6,
                    offset: Offset(-12 * t, 24 * t),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: radius,
          clipBehavior: open ? Clip.antiAlias : Clip.none,
          child: Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                child: IgnorePointer(
                  ignoring: open,
                  child: ExcludeSemantics(excluding: open, child: widget.child),
                ),
              ),
              if (open)
                Positioned.fill(
                  child: Semantics(
                    label: MaterialLocalizations.of(
                      context,
                    ).modalBarrierDismissLabel,
                    button: true,
                    onTap: close,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      excludeFromSemantics: true,
                      onTap: close,
                      onHorizontalDragStart: _dragStart,
                      onHorizontalDragUpdate: _dragUpdate,
                      onHorizontalDragEnd: _dragEnd,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: radius,
                          border: Border.all(
                            color: const Color(
                              0xFFD5B27A,
                            ).withValues(alpha: 0.28 * t),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// The page's bottom padding also clears the floating dock; the menu only
  /// needs the system inset.
  MediaQueryData _menuMedia(BuildContext context) {
    final media = MediaQuery.of(context);
    final view = View.of(context);
    final system = EdgeInsets.fromViewPadding(
      view.viewPadding,
      view.devicePixelRatio,
    ).bottom;
    return media.copyWith(
      padding: media.padding.copyWith(
        bottom: math.min(media.padding.bottom, system),
      ),
      viewPadding: media.viewPadding.copyWith(
        bottom: math.min(media.viewPadding.bottom, system),
      ),
    );
  }

  Widget _backdrop(Size size, double t) {
    final menuWidth = AppDrawerStage.drawerWidth(size.width);
    // Menu glides in from a little behind the page and grows to full size.
    final menuIn = const Interval(0, 0.75).transform(t);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: _dragStart,
        onHorizontalDragUpdate: _dragUpdate,
        onHorizontalDragEnd: _dragEnd,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                LuxeStage.vaultTop,
                LuxeStage.vault,
                LuxeStage.vaultBottom,
              ],
              stops: const [0, 0.55, 1],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: menuWidth,
                child: Opacity(
                  opacity: menuIn,
                  child: Transform(
                    alignment: Alignment.centerLeft,
                    transform: Matrix4.identity()
                      ..translateByDouble(-36 * (1 - t), 0, 0, 1)
                      ..scaleByDouble(0.92 + 0.08 * t, 0.92 + 0.08 * t, 1, 1),
                    child: Theme(
                      data: AppTheme.build(AppPalette.current.night),
                      child: MediaQuery(
                        data: _menuMedia(context),
                        child: widget.drawer!,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Eases one drawer row in as the stage opens, staggered by [index], and
/// back out (last first) as it closes. Shown as-is outside a stage.
class AppDrawerReveal extends StatelessWidget {
  const AppDrawerReveal({required this.index, required this.child, super.key});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final stage = context.findAncestorStateOfType<AppDrawerStageState>();
    if (stage == null ||
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
      return child;
    }
    final start = math.min(0.16 + index * 0.045, 0.6);
    final curve = Interval(
      start,
      math.min(start + 0.4, 1.0),
      curve: Curves.easeOutCubic,
    );
    return AnimatedBuilder(
      animation: stage.animation,
      child: child,
      builder: (context, child) {
        final v = curve.transform(stage.animation.value);
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(-28 * (1 - v), 0),
            child: child,
          ),
        );
      },
    );
  }
}

/// Closes the drawer hosting [context] (or pops, outside a stage).
void closeAppDrawer(BuildContext context) {
  final stage = AppDrawerStage.maybeOf(context);
  if (stage != null) {
    stage.close();
  } else {
    Navigator.of(context).maybePop();
  }
}
