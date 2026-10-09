import 'dart:math' as math;

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
/// spring up into a champagne disc while the bar's top edge swells into a
/// soft crown beneath it (the same spring + oval profile as the brand
/// directory's A–Z index). The tab that loses focus drops back on a looser
/// spring, overshoots into a shallow dent and, as it meets the surface,
/// sends a damped wave along the top edge plus a faint ring that settles out.
///
/// Performance: one [Ticker] integrates every spring and wave, one
/// [CustomPainter] draws the surface, and nothing above the bar rebuilds.
/// The ticker stops as soon as everything is at rest.
class AppBottomNavBar extends StatefulWidget {
  const AppBottomNavBar({
    required this.selected,
    required this.onSelect,
    this.badges = const {},
    this.bottomInset = 0,
    super.key,
  });

  /// Bar height above the system inset.
  static const double height = 66;

  final AppBottomNavTab? selected;
  final ValueChanged<AppBottomNavDestination> onSelect;
  final Map<AppBottomNavTab, int> badges;

  /// System navigation inset the bar extends behind.
  final double bottomInset;

  @override
  State<AppBottomNavBar> createState() => _AppBottomNavBarState();
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
  // Pop-out: lively with one visible overshoot (cf. the index bulge).
  static const _popK = 260.0;
  static const _popZeta = 0.5;
  // Release: looser, so it sinks past rest into a dent before settling.
  static const _dropK = 360.0;
  static const _dropZeta = 0.34;

  static const _iconY = 25.0; // icon centre at rest, from the bar top
  static const _rise = 27.0; // how far a popped icon lifts
  static const _disc = 50.0;
  static const _crown = 11.0; // surface swell under the popped tab
  static const _crownSpread = 0.64; // crown half-width, in slot widths

  static const _waveAmp = 3.2;
  static const _waveLength = 62.0;
  static const _waveSpeed = 300.0; // px/s
  static const _waveDecay = 0.34; // s
  static const _rippleLife = 0.95; // s

  // Created on first use, so a bar that never animates never owns one.
  Ticker? _ticker;
  final _repaint = _Repaint();
  final _lifts = [for (final _ in AppBottomNav.destinations) _Lift()];
  final _ripples = <_Ripple>[];
  Duration _last = Duration.zero;
  double _time = 0;

  int get _selectedIndex => widget.selected == null
      ? -1
      : AppBottomNav.destinations.indexWhere((d) => d.tab == widget.selected);

  @override
  void initState() {
    super.initState();
    final i = _selectedIndex;
    if (i >= 0) _lifts[i].x = 1;
  }

  @override
  void didUpdateWidget(AppBottomNavBar old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected) _wake();
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

  /// Offset of the top edge at [x] (negative = raised).
  double _surface(double x, double slot) {
    var y = 0.0;
    for (var i = 0; i < _lifts.length; i++) {
      final lift = _lifts[i].x;
      if (lift == 0) continue;
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
    final destination = AppBottomNav.destinations[index];
    AppHaptics.selection();
    widget.onSelect(destination);
  }

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
                    key: ValueKey(AppBottomNav.destinations[i].tab),
                    state: this,
                    index: i,
                    slot: slot,
                    selected: i == selected,
                    badge: widget.badges[AppBottomNav.destinations[i].tab] ?? 0,
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: AppBottomNavBar.height,
                  child: Row(
                    children: [
                      for (var i = 0; i < _lifts.length; i++)
                        Expanded(
                          child: _TabHitArea(
                            label: context.tr(
                              AppBottomNav.destinations[i].labelKey,
                            ),
                            badge:
                                widget.badges[AppBottomNav
                                    .destinations[i]
                                    .tab] ??
                                0,
                            selected: i == selected,
                            onTap: () => _onTap(i),
                          ),
                        ),
                    ],
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
    final destination = AppBottomNav.destinations[index];
    final label = context.tr(destination.labelKey);
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
            final iconColor = Color.lerp(p.inkMuted, p.onAccent, shown)!;
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
                      scale: 0.55 + 0.45 * lift.clamp(0.0, 1.2),
                      child: Opacity(
                        opacity: shown,
                        child: _Disc(palette: p),
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
                        selected ? destination.selectedIcon : destination.icon,
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

class _Disc extends StatelessWidget {
  const _Disc({required this.palette});

  final LuxePalette palette;

  @override
  Widget build(BuildContext context) {
    final accent = palette.accent;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(accent, Colors.white, 0.18)!, accent],
        ),
        border: Border.all(color: palette.surface, width: 3),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: palette.isDark ? 0.32 : 0.38),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.4 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// The bar's body: a top edge that swells under the popped tab and carries
/// release waves, plus the fading rings of those waves.
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

  static const _sample = 3.0;

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

    // Champagne glow pooled under the popped tab.
    for (var i = 0; i < state._lifts.length; i++) {
      final lift = state._lifts[i].x.clamp(0.0, 1.0);
      if (lift <= 0.01) continue;
      final c = Offset(slot * (i + 0.5), 0);
      canvas.drawCircle(
        c,
        slot * 0.6,
        Paint()
          ..shader = RadialGradient(
            colors: [
              accent.withValues(alpha: 0.16 * lift),
              accent.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: c, radius: slot * 0.6)),
      );
    }

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
