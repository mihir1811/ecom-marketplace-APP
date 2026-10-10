import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../haptics/app_haptics.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/luxe_tokens.dart';
import '../../luxe/luxe_spring.dart';
import 'app_bottom_nav_destinations.dart';

/// Sticky bottom navigation for the buyer side.
///
/// The selected tab pops out of the bar: its icon rides an under-damped
/// spring up inside a disc of the bar's own surface, which rises out of the
/// top edge and stays joined to it by concave fillets, so bar and disc read
/// as one shape. The tab that loses focus drops back on a looser
/// spring, overshoots into a shallow dent and, as it meets the surface,
/// sends a damped wave along the top edge plus a faint ring that settles out.
///
/// Performance: one [Ticker] integrates every spring and wave, one
/// [CustomPainter] draws the surface, and nothing above the bar rebuilds.
/// The ticker stops as soon as everything is at rest.
///
/// With [onScrub] set, pressing and holding or dragging along the bar
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
    this.badges = const {},
    this.bottomInset = 0,
    super.key,
  });

  /// Hold before a press becomes a scrub.
  static const scrubHold = Duration(milliseconds: 240);

  /// Bar height above the system inset.
  static const double height = 66;

  /// How far below the bar top the edge can dip (the popped bubble's notch,
  /// a released tab's dent). Pages extend this far behind the bar so they,
  /// not an empty backdrop, show through the gap around the bubble.
  static const double notchDepth = _AppBottomNavBarState._notchDepth;

  final AppBottomNavTab? selected;
  final ValueChanged<AppBottomNavDestination> onSelect;
  final AppBottomNavScrub? onScrub;
  final VoidCallback? onCategories;
  final bool categoriesOpen;
  final Map<AppBottomNavTab, int> badges;

  /// System navigation inset the bar extends behind.
  final double bottomInset;

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

/// One tab's spring: 1 = popped out, 0 = at rest, < 0 = dented.
class _Lift {
  double x = 0, v = 0;
}

class _Ripple {
  _Ripple(this.index, this.born, this.strength);

  final int index;
  final double born;
  final double strength;
}

class _AppBottomNavBarState extends State<AppBottomNavBar>
    with SingleTickerProviderStateMixin {
  // Pop-out: a smooth rise with only a hint of overshoot.
  static const _popK = 220.0;
  static const _popZeta = 0.82;
  // Release: looser, so it sinks past rest into a dent before settling.
  static const _dropK = 360.0;
  static const _dropZeta = 0.34;

  static const _iconY = 25.0; // icon centre at rest, from the bar top
  static const _rise = 29.0; // how far a popped icon lifts
  static const _disc = 54.0; // bubble diameter
  static const _gap = 6.0; // air between the bubble and the bent edge
  static const _fillet = 14.0; // radius where the edge bends into the notch
  static const _lip = 3.0; // how far the edge curls up beside the bubble
  // Lowest point of a popped notch, plus room for the spring's overshoot.
  static const _notchDepth = _disc / 2 + _gap + _iconY - _rise + 3;
  static const _crown = 11.0; // depth of a released tab's dent
  static const _crownSpread = 0.64; // dent half-width, in slot widths

  static const _waveAmp = 3.2;
  static const _waveLength = 62.0;
  static const _waveSpeed = 300.0; // px/s
  static const _waveDecay = 0.34; // s
  static const _rippleLife = 0.95; // s

  // Created on first use, so a bar that never animates never owns one.
  Ticker? _ticker;
  final _repaint = _Repaint();
  final _lifts = [for (final _ in AppBottomNav.slots) _Lift()];
  final _ripples = <_Ripple>[];
  Duration _last = Duration.zero;
  double _time = 0;

  int get _selectedIndex {
    if (widget.categoriesOpen) return AppBottomNav.categoriesSlot;
    if (widget.selected == null) return -1;
    return AppBottomNav.slots.indexWhere((d) => d?.tab == widget.selected);
  }

  @override
  void initState() {
    super.initState();
    final i = _selectedIndex;
    if (i >= 0) _lifts[i].x = 1;
  }

  @override
  void didUpdateWidget(AppBottomNavBar old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected ||
        old.categoriesOpen != widget.categoriesOpen) {
      _wake();
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _repaint.dispose();
    super.dispose();
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
    _ripples.clear();
    _repaint.ping();
  }

  void _tick(Duration now) {
    final dt = LuxeSpring.frameDelta(now, _last);
    _last = now;
    final steps = LuxeSpring.subSteps(dt);
    final h = dt / steps;
    final selected = _selectedIndex;

    var energy = 0.0;
    for (var s = 0; s < steps; s++) {
      _time += h;
      energy = 0;
      for (var i = 0; i < _lifts.length; i++) {
        final lift = _lifts[i];
        final popped = i == selected;
        final before = lift.x;
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
        // Released tab meets the surface: start a ripple from it.
        if (!popped && before > 0 && lift.x <= 0 && lift.v < -1.5) {
          final strength = (-lift.v / 7).clamp(0.45, 1.0);
          _ripples.add(_Ripple(i, _time, strength));
          if (_ripples.length > 3) _ripples.removeAt(0);
        }
      }
    }
    _ripples.removeWhere((r) => _time - r.born > _rippleLife);

    if (energy < 0.002 && _ripples.isEmpty) {
      _ticker?.stop();
      _settle();
      return;
    }
    _repaint.ping();
  }

  /// Centre height of tab [i]'s notch circle, from the bar top: clear of the
  /// edge at rest, cradling the popped bubble with [_gap] to spare.
  double _notchY(int i) {
    const reach = _disc / 2 + _gap;
    return -reach + (reach + _iconY - _rise) * _lifts[i].x;
  }

  /// Offset of the top edge at [x] (negative = raised).
  double _surface(double x, double slot) {
    var bend = 0.0;
    var calm = 0.0;
    for (var i = 0; i < _lifts.length; i++) {
      final lift = _lifts[i].x;
      if (lift <= 0) continue;
      final n = _notch(x - slot * (i + 0.5), _notchY(i), lift.clamp(0.0, 1.0));
      bend += n.y;
      calm = math.max(calm, n.calm);
    }
    // Waves pass under the bubble rather than reach into the notch.
    return bend + _waves(x, slot) * (1 - calm);
  }

  /// The edge pushed away from a bubble: a notch around a circle centred
  /// [cy] below the bar top, eased in by fillets, with lips curling up beside
  /// it, at [dx] from its centre. [calm] is 1 in the notch, easing to 0 over
  /// the fillet.
  static ({double y, double calm}) _notch(double dx, double cy, double t) {
    const r = _disc / 2 + _gap, f = _fillet;
    // Fillet centres sit [f] below the bar, [r + f] from the notch centre.
    const reach = r + f;
    final drop = f - cy;
    if (drop >= reach) return (y: 0, calm: 0);
    final foot = math.sqrt(reach * reach - drop * drop);
    final d = dx.abs();
    final lip = -_lip * t * math.exp(-math.pow((d - foot) / 9, 2));
    if (d >= foot) return (y: lip, calm: 0);
    final tangent = foot * r / reach;
    if (d <= tangent) {
      return (y: lip + cy + math.sqrt(math.max(r * r - d * d, 0)), calm: 1);
    }
    final u = foot - d;
    return (
      y: lip + f - math.sqrt(math.max(f * f - u * u, 0)),
      calm: u / (foot - tangent),
    );
  }

  /// Dents of released tabs plus their release waves at [x].
  double _waves(double x, double slot) {
    var y = 0.0;
    for (var i = 0; i < _lifts.length; i++) {
      final lift = _lifts[i].x;
      if (lift >= 0) continue;
      final cx = slot * (i + 0.5);
      y -= _crown * lift * LuxeSpring.oval((x - cx) / (slot * _crownSpread));
    }
    for (final r in _ripples) {
      final age = _time - r.born;
      final d = (x - slot * (r.index + 0.5)).abs();
      final front = _waveSpeed * age;
      if (d > front) continue;
      // Feather the wavefront so the edge never kinks where it begins.
      final feather = ((front - d) / 28).clamp(0.0, 1.0);
      final envelope =
          r.strength * math.exp(-age / _waveDecay) * math.exp(-d / 150);
      final phase = 2 * math.pi * (front - d) / _waveLength;
      y += _waveAmp * envelope * feather * math.sin(phase);
    }
    return y;
  }

  void _onTap(int index) {
    final destination = AppBottomNav.slots[index];
    AppHaptics.selection();
    if (destination == null) {
      widget.onCategories?.call();
    } else {
      widget.onSelect(destination);
    }
  }

  /// Finger position in tab coordinates (the Categories slot squeezed out).
  double _slotAt(double x, double slot) =>
      AppBottomNav.tabCoordinate(x / slot - 0.5);

  int _indexAt(double x, double slot) =>
      (x / slot).floor().clamp(0, _lifts.length - 1);

  /// Taps select; a hold or horizontal drag becomes a scrub.
  Widget _gestures({required double slot, required Widget child}) {
    final scrub = widget.onScrub;
    final recognizers = <Type, GestureRecognizerFactory>{
      TapGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
            () => TapGestureRecognizer(debugOwner: this),
            (r) =>
                r.onTapUp = (d) => _onTap(_indexAt(d.localPosition.dx, slot)),
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
                    scrub.onStart(_slotAt(d.localPosition.dx, slot));
                  }
                  ..onLongPressMoveUpdate = (d) {
                    scrub.onUpdate(_slotAt(d.localPosition.dx, slot));
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
                  scrub.onStart(_slotAt(d.localPosition.dx, slot));
                }
                ..onUpdate = (d) {
                  scrub.onUpdate(_slotAt(d.localPosition.dx, slot));
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

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final selected = _selectedIndex;

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: SizedBox(
        height: AppBottomNavBar.height + widget.bottomInset,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final slot = constraints.maxWidth / _lifts.length;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _SurfacePainter(
                        state: this,
                        slot: slot,
                        fill: p.surface,
                        hairline: p.hairline,
                        accent: p.accent,
                        isDark: p.isDark,
                      ),
                    ),
                  ),
                ),
                for (var i = 0; i < _lifts.length; i++)
                  _TabVisual(
                    key: ValueKey(i),
                    state: this,
                    index: i,
                    slot: slot,
                    selected: i == selected,
                    badge: _badge(i),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: AppBottomNavBar.height,
                  child: _gestures(
                    slot: slot,
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
    required this.slot,
    required this.selected,
    required this.badge,
    super.key,
  });

  final _AppBottomNavBarState state;
  final int index;
  final double slot;
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
    const disc = _AppBottomNavBarState._disc;
    final cx = slot * (index + 0.5);

    return Positioned(
      left: cx - slot / 2,
      width: slot,
      top: -_AppBottomNavBarState._rise - disc / 2,
      height: AppBottomNavBar.height + _AppBottomNavBarState._rise + disc / 2,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: state._repaint,
          builder: (context, _) {
            final lift = state._lifts[index].x;
            final shown = lift.clamp(0.0, 1.0);
            // A dent presses the icon in only slightly.
            final travel = lift >= 0 ? lift : lift * 0.35;
            final iconY =
                _AppBottomNavBarState._rise +
                disc / 2 +
                _AppBottomNavBarState._iconY -
                _AppBottomNavBarState._rise * travel;
            final iconColor = Color.lerp(p.inkMuted, p.accent, shown)!;
            final labelColor = Color.lerp(p.inkMuted, p.accent, shown)!;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                if (shown > 0)
                  Positioned(
                    left: slot / 2 - disc / 2,
                    top: iconY - disc / 2,
                    width: disc,
                    height: disc,
                    child: Transform.scale(
                      scale: 0.6 + 0.4 * lift.clamp(0.0, 1.1),
                      child: Opacity(
                        opacity: shown,
                        child: _Bubble(palette: p),
                      ),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: iconY - 14,
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
                        size: 22 + 1.5 * shown,
                        color: iconColor,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 4,
                  right: 4,
                  top: _AppBottomNavBarState._rise + disc / 2 + 43,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: LuxeType.label(labelColor, size: 11).copyWith(
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          letterSpacing: 0.4,
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

/// The popped tab's floating bubble, free of the bar.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.palette});

  final LuxePalette palette;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.surface,
        boxShadow: [
          BoxShadow(
            color: palette.accent.withValues(
              alpha: palette.isDark ? 0.4 : 0.28,
            ),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.4 : 0.08),
            blurRadius: 8,
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

/// The bar's body: a top edge that rises into the popped tab's disc and
/// carries release waves, plus the fading rings of those waves.
class _SurfacePainter extends CustomPainter {
  _SurfacePainter({
    required this.state,
    required this.slot,
    required this.fill,
    required this.hairline,
    required this.accent,
    required this.isDark,
  }) : super(repaint: state._repaint);

  final _AppBottomNavBarState state;
  final double slot;
  final Color fill;
  final Color hairline;
  final Color accent;
  final bool isDark;

  // Fine enough to keep the disc and fillet arcs smooth.
  static const _sample = 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    final edge = Path()..moveTo(0, state._surface(0, slot));
    for (var x = _sample; x < size.width; x += _sample) {
      edge.lineTo(x, state._surface(x, slot));
    }
    edge.lineTo(size.width, state._surface(size.width, slot));

    final body = Path.from(edge)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    // Soft upward shadow so the bar floats over page content.
    canvas.drawPath(
      body.shift(const Offset(0, -1.5)),
      Paint()
        ..color = Colors.black.withValues(alpha: isDark ? 0.5 : 0.07)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawPath(body, Paint()..color = fill);

    // Release rings, kept on the bar's surface.
    if (state._ripples.isNotEmpty) {
      canvas.save();
      canvas.clipPath(body);
      for (final r in state._ripples) {
        final age = state._time - r.born;
        final centre = Offset(
          slot * (r.index + 0.5),
          _AppBottomNavBarState._iconY,
        );
        for (var k = 0; k < 2; k++) {
          final t =
              (age - k * 0.11) / (_AppBottomNavBarState._rippleLife * 0.8);
          if (t <= 0 || t >= 1) continue;
          final eased = Curves.easeOutCubic.transform(t);
          canvas.drawCircle(
            centre,
            12 + 44 * eased,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.3 * (1 - t) + 0.3
              ..color = accent.withValues(
                alpha: (k == 0 ? 0.38 : 0.22) * (1 - t) * r.strength,
              ),
          );
        }
      }
      canvas.restore();
    }

    canvas.drawPath(
      edge,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = hairline,
    );
  }

  @override
  bool shouldRepaint(_SurfacePainter old) =>
      old.slot != slot ||
      old.fill != fill ||
      old.hairline != hairline ||
      old.accent != accent ||
      old.isDark != isDark;
}
