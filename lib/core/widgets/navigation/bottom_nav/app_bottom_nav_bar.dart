import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../haptics/app_haptics.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/luxe_tokens.dart';
import '../../luxe/luxe_spring.dart';
import 'app_bottom_nav_destinations.dart';

/// Floating bottom navigation dock for the buyer side.
///
/// A pill that hovers above the bottom edge. The selected tab pops out of
/// it: its icon rides an under-damped spring up inside a disc, and the
/// dock's outline swells around that disc on concave fillets, so dock and
/// disc read as one shape. The ring between the disc and the dock's body is
/// frosted glass: the page shows through it, blurred, with no fill of its
/// own. The tab that loses focus settles straight back into the dock.
///
/// With [compact] set the dock folds into a narrower, shorter pill without
/// labels; a tap on it then calls [onExpand] instead of switching tabs.
///
/// Performance: one [Ticker] integrates every spring, the outline is built
/// once per frame and shared by the painters and the glass clip, and nothing
/// above the dock rebuilds. The ticker stops as soon as everything is at
/// rest.
///
/// With [onScrub] set, pressing and holding or dragging along the dock
/// reports the finger continuously, in tab coordinates (0 = centre of the
/// first tab, 1 = the next, …), until it lifts. A plain tap still goes
/// through [onSelect].
///
/// The centre slot is the Categories action: tapping it calls
/// [onCategories], and while [categoriesOpen] it pops like a selected tab.
class AppBottomNavBar extends StatefulWidget {
  const AppBottomNavBar({
    required this.selected,
    required this.onSelect,
    this.onScrub,
    this.onCategories,
    this.categoriesOpen = false,
    this.compact = false,
    this.onExpand,
    this.badges = const {},
    this.bottomInset = 0,
    this.trailing,
    this.trailingShown,
    super.key,
  });

  /// Hold before a press becomes a scrub.
  static const scrubHold = Duration(milliseconds: 240);

  /// Dock height, expanded.
  static const double height = 64;

  /// Dock height while [compact].
  static const double compactHeight = 50;

  /// Air between the dock and the screen's bottom edge, for a system
  /// navigation inset of [inset].
  static double floatGap(double inset) => math.max(inset - 8, 0.0) + 12;

  /// Height of the box the bar lays out in: the dock and the air under it.
  /// The popped bubble rises above it.
  static double extent(double inset) => floatGap(inset) + height;

  /// Bottom padding a page needs to clear the expanded dock.
  static double clearance(double inset) => extent(inset) + 8;

  final AppBottomNavTab? selected;
  final ValueChanged<AppBottomNavDestination> onSelect;
  final AppBottomNavScrub? onScrub;
  final VoidCallback? onCategories;
  final bool categoriesOpen;

  /// Folded down while the page scrolls towards its end.
  final bool compact;

  /// A tap on the [compact] dock.
  final VoidCallback? onExpand;
  final Map<AppBottomNavTab, int> badges;

  /// System navigation inset the dock floats above.
  final double bottomInset;

  /// Round action in the dock's row, after the last tab (compare). The dock
  /// narrows and shifts left to make room, and folds it along with itself.
  final Widget? trailing;

  /// 0–1: how far [trailing] has made its room (it scales in with it).
  final Animation<double>? trailingShown;

  /// Diameter of [trailing] beside the expanded and the folded dock.
  static const double trailingSize = 56;
  static const double trailingCompactSize = 44;
  static const double trailingGap = 8;

  @override
  State<AppBottomNavBar> createState() => _AppBottomNavBarState();
}

/// Continuous finger reports from a press-and-hold or drag on the bar.
class AppBottomNavScrub {
  const AppBottomNavScrub({
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    required this.onCancel,
  });

  final ValueChanged<double> onStart;
  final ValueChanged<double> onUpdate;
  final VoidCallback onEnd;
  final VoidCallback onCancel;
}

class _Repaint extends ChangeNotifier {
  void ping() => notifyListeners();
}

/// One spring: x = 1 popped out (or folded), 0 = at rest.
class _Lift {
  double x = 0, v = 0;
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// The dock's metrics at fold [fold] (0 = expanded, 1 = compact), in the
/// bar box's coordinates.
class _Dock {
  factory _Dock(Size box, double fold, double inset, double trailing) {
    // Room kept on the right for the trailing button and its gap.
    final trail =
        _lerp(
          AppBottomNavBar.trailingSize,
          AppBottomNavBar.trailingCompactSize,
          fold,
        ) *
        trailing;
    final reserve = (trail + AppBottomNavBar.trailingGap) * trailing;
    final full = math.min(box.width - 2 * _side - reserve, _maxWidth);
    final width = _lerp(
      full,
      math.min(full, math.max(full * 0.7, 240.0)),
      fold,
    );
    final height = _lerp(
      AppBottomNavBar.height,
      AppBottomNavBar.compactHeight,
      fold,
    );
    final bottom = box.height - AppBottomNavBar.floatGap(inset);
    // Dock and button are centred as one group.
    final pill = Rect.fromLTWH(
      (box.width - width - reserve) / 2,
      bottom - height,
      width,
      height,
    );
    final disc = _lerp(54, 42, fold);
    return _Dock._(
      pill: pill,
      slot: (width - 2 * _pad) / AppBottomNav.slots.length,
      iconY: pill.top + _lerp(24, height / 2, fold),
      bubbleY: pill.top + _lerp(-4, 6, fold),
      disc: disc,
      reach: disc / 2 + _lerp(6, 5, fold),
      fillet: _lerp(14, 11, fold),
      iconSize: _lerp(22, 21, fold),
      labelTop: pill.top + _lerp(39, 33, fold),
      labelOpacity: (1 - fold * 1.8).clamp(0.0, 1.0),
      trailing: Rect.fromCenter(
        center: Offset(
          pill.right + AppBottomNavBar.trailingGap * trailing + trail / 2,
          pill.center.dy,
        ),
        width: trail,
        height: trail,
      ),
    );
  }

  const _Dock._({
    required this.pill,
    required this.slot,
    required this.iconY,
    required this.bubbleY,
    required this.disc,
    required this.reach,
    required this.fillet,
    required this.iconSize,
    required this.labelTop,
    required this.labelOpacity,
    required this.trailing,
  });

  static const _side = 14.0; // screen margin beside the expanded dock
  static const _maxWidth = 480.0;
  static const _pad = 6.0; // inner margin before the first tab

  final Rect pill;
  final double slot;

  /// Icon centre at rest.
  final double iconY;

  /// Centre of a fully popped bubble.
  final double bubbleY;
  final double disc;

  /// Bubble radius plus the glass gap around it.
  final double reach;

  /// Radius of the arcs where the outline bends around a bubble.
  final double fillet;
  final double iconSize;
  final double labelTop;
  final double labelOpacity;

  /// Where the trailing button sits (zero-sized while it has no room).
  final Rect trailing;

  double centerX(int i) => pill.left + _pad + slot * (i + 0.5);

  /// Tab under [x], measured from the pill's left edge.
  int indexAt(double x) =>
      ((x - _pad) / slot).floor().clamp(0, AppBottomNav.slots.length - 1);

  /// [x] from the pill's left edge, in tab coordinates.
  double slotAt(double x) =>
      AppBottomNav.tabCoordinate((x - _pad) / slot - 0.5);
}

/// The dock's outline for one frame: the [silhouette] (body, bubbles' glass
/// and fillets), the opaque [body] notched around each bubble, and the
/// [glass] between the two.
class _DockShape {
  factory _DockShape(_Dock dock, List<_Lift> lifts) {
    final pill = dock.pill;
    final r = pill.height / 2;
    final reach = dock.reach, f = dock.fillet;

    // Bubble centres relative to the flat top edge. At rest the swell sits a
    // full radius below the edge and the notch a full radius above it, so
    // neither bends the outline.
    final bubbles = <({double x, double up, double down})>[
      for (var i = 0; i < lifts.length; i++)
        if (lifts[i].x > 0.001)
          (
            x: dock.centerX(i),
            up: _lerp(reach, dock.bubbleY - pill.top, lifts[i].x),
            down: _lerp(-reach, dock.bubbleY - pill.top, lifts[i].x),
          ),
    ];

    final n = math.max(2, pill.width.ceil());
    final xs = List<double>.filled(n + 1, 0);
    final outer = List<double>.filled(n + 1, 0);
    final inner = List<double>.filled(n + 1, 0);
    final floor = List<double>.filled(n + 1, 0);
    for (var j = 0; j <= n; j++) {
      final x = pill.left + pill.width * j / n;
      final end = x < pill.left + r
          ? pill.left + r - x
          : x > pill.right - r
          ? x - (pill.right - r)
          : 0.0;
      final round = r - math.sqrt(math.max(r * r - end * end, 0));
      final edge = pill.top + round;
      var top = edge, cut = edge;
      for (final b in bubbles) {
        final d = (x - b.x).abs();
        final swell = _bend(d, -b.up, reach, f);
        if (swell != null) {
          // The fillets ease from the circle onto the (possibly rounding)
          // end of the pill, so the outline never steps.
          final w = swell.ease;
          top = math.min(top, pill.top - swell.y + w * round);
        }
        final notch = _bend(d, b.down, reach, f);
        if (notch != null) cut = math.max(cut, pill.top + notch.y);
      }
      xs[j] = x;
      floor[j] = pill.bottom - round;
      inner[j] = math.min(cut, floor[j]);
      outer[j] = math.min(top, inner[j]);
    }

    Path trace(List<double> over, List<double> under) {
      final path = Path()..moveTo(xs[0], over[0]);
      for (var j = 1; j <= n; j++) {
        path.lineTo(xs[j], over[j]);
      }
      for (var j = n; j >= 0; j--) {
        path.lineTo(xs[j], under[j]);
      }
      return path..close();
    }

    final rim = Path()..moveTo(xs[0], outer[0]);
    for (var j = 1; j <= n; j++) {
      rim.lineTo(xs[j], outer[j]);
    }

    return _DockShape._(
      silhouette: trace(outer, floor),
      body: trace(inner, floor),
      glass: trace(outer, inner),
      rim: rim,
      hasGlass: bubbles.isNotEmpty,
    );
  }

  const _DockShape._({
    required this.silhouette,
    required this.body,
    required this.glass,
    required this.rim,
    required this.hasGlass,
  });

  final Path silhouette;
  final Path body;
  final Path glass;

  /// The silhouette's top edge.
  final Path rim;
  final bool hasGlass;

  /// A flat edge pushed away from a circle of radius [r] centred [c] past
  /// it, joined by fillets of radius [f]: the edge's offset at [d] from the
  /// centre (towards the circle), or null where the edge stays flat. [ease]
  /// runs from 0 at the circle to 1 where the fillet lands on the edge.
  static ({double y, double ease})? _bend(
    double d,
    double c,
    double r,
    double f,
  ) {
    final reach = r + f;
    // Fillet centres sit [f] behind the edge, [reach] from the circle's.
    final drop = f - c;
    if (drop >= reach) return null;
    final foot = math.sqrt(reach * reach - drop * drop);
    if (d >= foot) return null;
    final tangent = foot * r / reach;
    if (d <= tangent) {
      return (y: c + math.sqrt(math.max(r * r - d * d, 0)), ease: 0);
    }
    final u = foot - d;
    final t = (d - tangent) / (foot - tangent);
    return (
      y: f - math.sqrt(math.max(f * f - u * u, 0)),
      ease: t * t * (3 - 2 * t),
    );
  }
}

class _AppBottomNavBarState extends State<AppBottomNavBar>
    with SingleTickerProviderStateMixin {
  // Pop-out: a smooth rise with only a hint of overshoot.
  static const _popK = 220.0;
  static const _popZeta = 0.82;
  // Release: critically damped, so it settles without dipping past rest.
  static const _dropK = 360.0;
  static const _dropZeta = 1.0;
  // Folding away is calm; coming back is quick, with a whisper of spring.
  static const _foldK = 380.0;
  static const _foldZeta = 1.0;
  static const _unfoldK = 620.0;
  static const _unfoldZeta = 0.82;

  /// Room above the box for the popped bubble and its swell.
  static const _overhang = 64.0;

  // Created on first use, so a bar that never animates never owns one.
  Ticker? _ticker;
  final _repaint = _Repaint();
  final _lifts = [for (final _ in AppBottomNav.slots) _Lift()];
  final _fold = _Lift();
  Duration _last = Duration.zero;

  Size _box = Size.zero;
  int _frame = 0;
  _DockShape? _shapeCache;
  ({int frame, Size box, double inset, double trailing})? _shapeKey;

  int get _selectedIndex {
    if (widget.categoriesOpen) return AppBottomNav.categoriesSlot;
    if (widget.selected == null) return -1;
    return AppBottomNav.slots.indexWhere((d) => d?.tab == widget.selected);
  }

  _Dock get _dock => _Dock(
    _box,
    _fold.x,
    widget.bottomInset,
    widget.trailingShown?.value ?? (widget.trailing == null ? 0 : 1),
  );

  _DockShape get _shape {
    final key = (
      frame: _frame,
      box: _box,
      inset: widget.bottomInset,
      trailing: widget.trailingShown?.value ?? 0,
    );
    if (_shapeKey != key) {
      _shapeKey = key;
      _shapeCache = _DockShape(_dock, _lifts);
    }
    return _shapeCache!;
  }

  @override
  void initState() {
    super.initState();
    final i = _selectedIndex;
    if (i >= 0) _lifts[i].x = 1;
    _fold.x = widget.compact ? 1 : 0;
    widget.trailingShown?.addListener(_ping);
  }

  @override
  void didUpdateWidget(AppBottomNavBar old) {
    super.didUpdateWidget(old);
    if (old.trailingShown != widget.trailingShown) {
      old.trailingShown?.removeListener(_ping);
      widget.trailingShown?.addListener(_ping);
    }
    if (old.selected != widget.selected ||
        old.categoriesOpen != widget.categoriesOpen ||
        old.compact != widget.compact) {
      _wake();
    }
  }

  @override
  void dispose() {
    widget.trailingShown?.removeListener(_ping);
    _ticker?.dispose();
    _repaint.dispose();
    super.dispose();
  }

  void _ping() {
    _frame++;
    _repaint.ping();
  }

  void _wake() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _settle();
      return;
    }
    final ticker = _ticker ??= createTicker(_tick);
    if (!ticker.isActive) {
      _last = Duration.zero;
      ticker.start();
    }
  }

  void _settle() {
    final selected = _selectedIndex;
    for (var i = 0; i < _lifts.length; i++) {
      _lifts[i]
        ..x = i == selected ? 1 : 0
        ..v = 0;
    }
    _fold
      ..x = widget.compact ? 1 : 0
      ..v = 0;
    _ping();
  }

  void _tick(Duration now) {
    final dt = LuxeSpring.frameDelta(now, _last);
    _last = now;
    final steps = LuxeSpring.subSteps(dt);
    final h = dt / steps;
    final selected = _selectedIndex;
    final compact = widget.compact;

    var energy = 0.0;
    for (var s = 0; s < steps; s++) {
      energy = 0;
      for (var i = 0; i < _lifts.length; i++) {
        final lift = _lifts[i];
        final popped = i == selected;
        energy += LuxeSpring.step(
          lift.x,
          lift.v,
          popped ? 1 : 0,
          popped ? _popK : _dropK,
          popped ? _popZeta : _dropZeta,
          h,
          (x, v) {
            lift
              ..x = x
              ..v = v;
          },
        );
      }
      energy += LuxeSpring.step(
        _fold.x,
        _fold.v,
        compact ? 1 : 0,
        compact ? _foldK : _unfoldK,
        compact ? _foldZeta : _unfoldZeta,
        h,
        (x, v) {
          _fold
            ..x = x
            ..v = v;
        },
      );
    }

    if (energy < 0.002) {
      _ticker?.stop();
      _settle();
      return;
    }
    _ping();
  }

  void _onTap(int index) {
    AppHaptics.selection();
    if (widget.compact && widget.onExpand != null) {
      widget.onExpand!();
      return;
    }
    final destination = AppBottomNav.slots[index];
    if (destination == null) {
      widget.onCategories?.call();
    } else {
      widget.onSelect(destination);
    }
  }

  /// Taps select; a hold or horizontal drag becomes a scrub. Positions are
  /// measured from the pill's left edge.
  Widget _gestures({required Widget child}) {
    final scrub = widget.compact ? null : widget.onScrub;
    final recognizers = <Type, GestureRecognizerFactory>{
      TapGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
            () => TapGestureRecognizer(debugOwner: this),
            (r) => r.onTapUp = (d) => _onTap(_dock.indexAt(d.localPosition.dx)),
          ),
      if (scrub != null) ...{
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(
                duration: AppBottomNavBar.scrubHold,
                debugOwner: this,
              ),
              (r) {
                r
                  ..onLongPressStart = (d) {
                    scrub.onStart(_dock.slotAt(d.localPosition.dx));
                  }
                  ..onLongPressMoveUpdate = (d) {
                    scrub.onUpdate(_dock.slotAt(d.localPosition.dx));
                  }
                  ..onLongPressEnd = (_) {
                    scrub.onEnd();
                  }
                  ..onLongPressCancel = scrub.onCancel;
              },
            ),
        HorizontalDragGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<
              HorizontalDragGestureRecognizer
            >(() => HorizontalDragGestureRecognizer(debugOwner: this), (r) {
              r
                ..dragStartBehavior = DragStartBehavior.down
                ..onStart = (d) {
                  scrub.onStart(_dock.slotAt(d.localPosition.dx));
                }
                ..onUpdate = (d) {
                  scrub.onUpdate(_dock.slotAt(d.localPosition.dx));
                }
                ..onEnd = (_) {
                  scrub.onEnd();
                }
                ..onCancel = scrub.onCancel;
            }),
      },
    };
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: recognizers,
      child: child,
    );
  }

  int _badge(int i) {
    final tab = AppBottomNav.slots[i]?.tab;
    return tab == null ? 0 : widget.badges[tab] ?? 0;
  }

  static String _labelKey(int i) =>
      AppBottomNav.slots[i]?.labelKey ?? AppBottomNav.categoriesLabelKey;

  /// A full-width layer reaching [_overhang] above the box.
  static Widget _layer(Widget child) => Positioned(
    left: 0,
    right: 0,
    top: -_overhang,
    bottom: 0,
    child: IgnorePointer(child: child),
  );

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final selected = _selectedIndex;

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: SizedBox(
        height: AppBottomNavBar.extent(widget.bottomInset),
        child: LayoutBuilder(
          builder: (context, constraints) {
            _box = constraints.biggest;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                _layer(
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: _DockPainter(
                        state: this,
                        front: false,
                        palette: p,
                      ),
                    ),
                  ),
                ),
                _layer(
                  ClipPath(
                    clipper: _GlassClipper(this),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: ColoredBox(
                        color: p.surface.withValues(
                          alpha: p.isDark ? 0.12 : 0.18,
                        ),
                      ),
                    ),
                  ),
                ),
                _layer(
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: _DockPainter(
                        state: this,
                        front: true,
                        palette: p,
                      ),
                    ),
                  ),
                ),
                for (var i = 0; i < _lifts.length; i++)
                  _TabVisual(
                    key: ValueKey(i),
                    state: this,
                    index: i,
                    selected: i == selected,
                    badge: _badge(i),
                  ),
                AnimatedBuilder(
                  animation: _repaint,
                  builder: (context, child) {
                    final pill = _dock.pill;
                    return Positioned(
                      left: pill.left,
                      width: pill.width,
                      top: pill.top - 8,
                      height: pill.height + 8,
                      child: child!,
                    );
                  },
                  child: _gestures(
                    child: Row(
                      children: [
                        for (var i = 0; i < _lifts.length; i++)
                          Expanded(
                            child: _TabHitArea(
                              label: context.tr(_labelKey(i)),
                              badge: _badge(i),
                              selected: i == selected,
                              onTap: () => _onTap(i),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (widget.trailing != null)
                  AnimatedBuilder(
                    animation: _repaint,
                    builder: (context, child) => Positioned.fromRect(
                      rect: _dock.trailing,
                      child: Opacity(
                        opacity: (widget.trailingShown?.value ?? 1).clamp(
                          0.0,
                          1.0,
                        ),
                        child: child,
                      ),
                    ),
                    child: widget.trailing,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Icon, disc, badge and label of one tab, driven by its spring.
class _TabVisual extends StatelessWidget {
  const _TabVisual({
    required this.state,
    required this.index,
    required this.selected,
    required this.badge,
    super.key,
  });

  final _AppBottomNavBarState state;
  final int index;
  final bool selected;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final destination = AppBottomNav.slots[index];
    final label = context.tr(_AppBottomNavBarState._labelKey(index));
    final icon = selected
        ? destination?.selectedIcon ?? AppBottomNav.categoriesSelectedIcon
        : destination?.icon ?? AppBottomNav.categoriesIcon;

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: state._repaint,
          builder: (context, _) {
            final dock = state._dock;
            final lift = state._lifts[index].x;
            final shown = lift.clamp(0.0, 1.0);
            final cx = dock.centerX(index);
            // The icon rides inside its bubble.
            final cy = _lerp(dock.iconY, dock.bubbleY, math.max(0.0, lift));
            final disc = dock.disc * (0.6 + 0.4 * lift.clamp(0.0, 1.1));
            final color = Color.lerp(p.inkMuted, p.accent, shown)!;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                if (shown > 0)
                  Positioned(
                    left: cx - disc / 2,
                    top: cy - disc / 2,
                    width: disc,
                    height: disc,
                    child: Opacity(
                      opacity: shown,
                      child: _Bubble(palette: p),
                    ),
                  ),
                Positioned(
                  left: cx - dock.slot / 2,
                  width: dock.slot,
                  top: cy - 14,
                  height: 28,
                  child: Center(
                    child: Badge(
                      isLabelVisible: badge > 0,
                      backgroundColor: p.ink,
                      textColor: p.canvas,
                      offset: const Offset(8, -6),
                      label: Text(badge > 99 ? '99+' : '$badge'),
                      child: Icon(
                        icon,
                        size: dock.iconSize + 1.5 * shown,
                        color: color,
                      ),
                    ),
                  ),
                ),
                if (dock.labelOpacity > 0)
                  Positioned(
                    left: cx - dock.slot / 2 + 2,
                    width: dock.slot - 4,
                    top: dock.labelTop,
                    child: Opacity(
                      opacity: dock.labelOpacity,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            label,
                            maxLines: 1,
                            style: LuxeType.label(color, size: 11).copyWith(
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The popped tab's bubble, floating in its glass ring.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.palette});

  final LuxePalette palette;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.surface,
        border: Border.all(color: palette.hairline, width: 0.6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.35 : 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

class _TabHitArea extends StatelessWidget {
  const _TabHitArea({
    required this.label,
    required this.badge,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: badge > 0 ? '$label, $badge' : label,
      excludeSemantics: true,
      // Pointer input is handled bar-wide (taps and scrubs).
      onTap: onTap,
      child: const Listener(
        behavior: HitTestBehavior.opaque,
        child: SizedBox.expand(),
      ),
    );
  }
}

/// Clips the backdrop blur to the whole dock: the page scrolling behind
/// shows through it, frosted.
class _GlassClipper extends CustomClipper<Path> {
  _GlassClipper(this.state) : super(reclip: state._repaint);

  final _AppBottomNavBarState state;

  @override
  Path getClip(Size size) {
    return state._shape.silhouette.shift(
      const Offset(0, _AppBottomNavBarState._overhang),
    );
  }

  @override
  bool shouldReclip(_GlassClipper old) => old.state != state;
}

/// Back layer: the dock's shadow, cast only outside its silhouette so it
/// never darkens what the glass shows. Front layer: the frosted body's tint
/// (the clear ring round a popped bubble stays untinted), the outline and
/// the glass rim's highlight.
class _DockPainter extends CustomPainter {
  _DockPainter({
    required this.state,
    required this.front,
    required this.palette,
  }) : super(repaint: state._repaint);

  final _AppBottomNavBarState state;
  final bool front;
  final LuxePalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final shape = state._shape;
    final p = palette;
    canvas.translate(0, _AppBottomNavBarState._overhang);

    if (!front) {
      final outside = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(
          Rect.fromLTWH(
            -40,
            -_AppBottomNavBarState._overhang - 40,
            size.width + 80,
            size.height + 80,
          ),
        )
        ..addPath(shape.silhouette, Offset.zero);
      canvas
        ..save()
        ..clipPath(outside)
        ..drawPath(
          shape.silhouette.shift(const Offset(0, 4)),
          Paint()
            ..color = Colors.black.withValues(alpha: p.isDark ? 0.45 : 0.1)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
        )
        ..restore();
      return;
    }

    // Translucent: the blurred page reads through, the tabs stay legible.
    canvas.drawPath(
      shape.body,
      Paint()..color = p.surface.withValues(alpha: p.isDark ? 0.62 : 0.68),
    );

    if (shape.hasGlass) {
      // A thin light rim along the glass, like the edge of a lens.
      canvas
        ..save()
        ..clipPath(shape.glass)
        ..drawPath(
          shape.rim,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = Colors.white.withValues(alpha: p.isDark ? 0.16 : 0.7),
        )
        ..restore();
    }

    canvas.drawPath(
      shape.silhouette,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = p.hairline,
    );
  }

  @override
  bool shouldRepaint(_DockPainter old) =>
      old.state != state || old.front != front || old.palette != palette;
}
