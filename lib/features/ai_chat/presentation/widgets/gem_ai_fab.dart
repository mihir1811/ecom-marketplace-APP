import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/gem3d/gem_view.dart';

/// Gem AI launcher orb: obsidian glass with a live, turning diamond.
class GemAiFab extends StatelessWidget {
  const GemAiFab({super.key, this.lifted = false});

  final bool lifted;

  static const double size = 60;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: LuxeMotion.fast,
      curve: LuxeMotion.press,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.35, -0.45),
          radius: 1.05,
          colors: [Color(0xFF2B2A30), Color(0xFF0A0A0D)],
        ),
        border: Border.all(
          color: LuxeStage.gold.withValues(alpha: lifted ? 0.85 : 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: lifted ? 0.42 : 0.3),
            blurRadius: lifted ? 30 : 18,
            offset: Offset(0, lifted ? 16 : 8),
          ),
          BoxShadow(
            color: LuxeStage.gold.withValues(alpha: lifted ? 0.32 : 0.16),
            blurRadius: lifted ? 26 : 16,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const GemView(size: 34, spin: 0.7, tilt: 0.5, glints: true),
          Text(
            context.tr(RemainingL10n.gemAi2).toUpperCase(),
            maxLines: 1,
            style: LuxeType.eyebrow(
              LuxeStage.gold,
            ).copyWith(fontSize: 7.5, letterSpacing: 1.4, height: 1.1),
          ),
        ],
      ),
    );
  }
}

/// Edge-docking geometry for the Gem AI orb.
///
/// The orb rests only against the left or right edge (never mid-screen);
/// near the top or bottom it snaps into the corner.
class GemAiDockGeometry {
  const GemAiDockGeometry(this.screen, this.insets);

  final Size screen;
  final EdgeInsets insets;

  static const double size = GemAiFab.size;
  static const double edge = 14;
  static const double cornerZone = 72;

  /// Insets the orb must clear: safe area plus the keyboard.
  static EdgeInsets insetsOf(MediaQueryData media) {
    final padding = media.padding;
    return padding.copyWith(
      bottom: math.max(padding.bottom, media.viewInsets.bottom),
    );
  }

  double get minY => insets.top + 12;
  double get maxY => math.max(minY, screen.height - insets.bottom - size - 12);

  double xFor({required bool right}) => right
      ? screen.width - insets.right - size - edge
      : insets.left + edge;

  double yFor(double fraction) =>
      minY + (maxY - minY) * fraction.clamp(0.0, 1.0);

  double fractionOf(double y) =>
      maxY == minY ? 1 : ((y - minY) / (maxY - minY)).clamp(0.0, 1.0);

  Offset rest({required bool right, required double fraction}) =>
      Offset(xFor(right: right), yFor(fraction));

  /// Where a release at [pos] with [velocity] (px/s) docks.
  ({bool right, double y}) resolve(Offset pos, Offset velocity) {
    final projectedX = pos.dx + size / 2 + velocity.dx * 0.16;
    final right = projectedX > screen.width / 2;
    var y = (pos.dy + velocity.dy * 0.1).clamp(minY, maxY);
    if (y - minY < cornerZone) y = minY;
    if (maxY - y < cornerZone) y = maxY;
    return (right: right, y: y);
  }
}

/// Draggable, magnetically docking host for [GemAiFab].
///
/// Drag lifts the orb and shows a glow on the edge it will dock to. On
/// release a spring carries it to that edge (or corner); on contact it
/// squashes, rings and plays [AppHaptics.magneticSnap].
class GemAiDock extends StatefulWidget {
  const GemAiDock({
    super.key,
    required this.hidden,
    required this.right,
    required this.fraction,
    required this.onPressed,
    required this.onDocked,
    required this.semanticLabel,
  });

  /// Hidden (scaled away) while the chat panel is open.
  final bool hidden;
  final bool right;
  final double fraction;
  final VoidCallback onPressed;
  final void Function(bool right, double fraction) onDocked;
  final String semanticLabel;

  @override
  State<GemAiDock> createState() => _GemAiDockState();
}

class _GemAiDockState extends State<GemAiDock> with TickerProviderStateMixin {
  late final Ticker _spring = createTicker(_tickSpring);
  late final AnimationController _impact = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  );

  Offset _pos = Offset.zero;
  Offset _vel = Offset.zero;
  Offset _target = Offset.zero;
  Offset _impactAt = Offset.zero;
  bool _targetRight = true;
  bool _dragging = false;
  bool _springing = false;
  bool _impacted = false;
  bool _inMagnetZone = false;
  Duration _last = Duration.zero;

  bool get _active => _dragging || _springing;

  @override
  void dispose() {
    _spring.dispose();
    _impact.dispose();
    super.dispose();
  }

  GemAiDockGeometry _geometry() => GemAiDockGeometry(
    MediaQuery.sizeOf(context),
    GemAiDockGeometry.insetsOf(MediaQuery.of(context)),
  );

  void _onPanStart(DragStartDetails d) {
    final geo = _geometry();
    _spring.stop();
    if (!_active) {
      _pos = geo.rest(right: widget.right, fraction: widget.fraction);
    }
    _springing = false;
    _inMagnetZone = true;
    AppHaptics.selection();
    setState(() => _dragging = true);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final geo = _geometry();
    final next = _pos + d.delta;
    const s = GemAiDockGeometry.size;
    setState(() {
      _pos = Offset(
        next.dx.clamp(-s * 0.3, geo.screen.width - s * 0.7),
        next.dy.clamp(geo.minY - 40, geo.maxY + 40),
      );
    });
    final centre = _pos.dx + s / 2;
    final fromEdge = math.min(centre, geo.screen.width - centre);
    final inZone = fromEdge < 72;
    if (inZone && !_inMagnetZone) AppHaptics.selection();
    _inMagnetZone = inZone;
  }

  void _onPanEnd(DragEndDetails d) {
    final geo = _geometry();
    final v = d.velocity.pixelsPerSecond;
    final dock = geo.resolve(_pos, v);
    _targetRight = dock.right;
    _target = Offset(geo.xFor(right: dock.right), dock.y);
    _vel = Offset(
      v.dx.clamp(-2600.0, 2600.0),
      v.dy.clamp(-2600.0, 2600.0),
    );
    _impacted = false;
    _last = Duration.zero;
    setState(() {
      _dragging = false;
      _springing = true;
    });
    _spring.start();
  }

  void _tickSpring(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 1 / 60
        : ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 1 / 30);
    _last = elapsed;
    const k = 340.0;
    final c = 2 * 0.68 * math.sqrt(k);
    final before = _target.dx - _pos.dx;
    // Two half steps keep the spring stable on slow frames.
    for (var i = 0; i < 2; i++) {
      final h = dt / 2;
      final acc = (_target - _pos) * k - _vel * c;
      _vel += acc * h;
      _pos += _vel * h;
    }
    final after = _target.dx - _pos.dx;
    final crossed = before != 0 && (before.sign != after.sign || after.abs() < 1);
    if (!_impacted && crossed) _land();

    if ((_target - _pos).distance < 0.5 && _vel.distance < 8) {
      _pos = _target;
      _spring.stop();
      if (!_impacted) _land();
      _springing = false;
      final geo = _geometry();
      widget.onDocked(_targetRight, geo.fractionOf(_target.dy));
    }
    setState(() {});
  }

  void _land() {
    _impacted = true;
    _impactAt = _target + const Offset(GemAiDockGeometry.size / 2, GemAiDockGeometry.size / 2);
    AppHaptics.magneticSnap();
    _impact.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final geo = _geometry();
    const s = GemAiDockGeometry.size;
    final pos = _active
        ? _pos
        : geo.rest(right: widget.right, fraction: widget.fraction);
    final still = MediaQuery.disableAnimationsOf(context);
    final dockRight = _dragging
        ? pos.dx + s / 2 > geo.screen.width / 2
        : _targetRight;
    final centre = pos.dx + s / 2;
    final proximity = _dragging
        ? (1 - math.min(centre, geo.screen.width - centre) /
                  (geo.screen.width / 2))
              .clamp(0.0, 1.0)
        : 0.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Edge glow previews the side the orb will dock to.
        if (_dragging)
          Positioned(
            top: (pos.dy + s / 2 - 120).clamp(0.0, geo.screen.height - 240),
            height: 240,
            left: dockRight ? null : 0,
            right: dockRight ? 0 : null,
            width: 4,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      LuxeStage.gold.withValues(alpha: 0),
                      LuxeStage.gold.withValues(alpha: 0.35 + 0.6 * proximity),
                      LuxeStage.gold.withValues(alpha: 0),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: LuxeStage.gold.withValues(
                        alpha: 0.25 + 0.35 * proximity,
                      ),
                      blurRadius: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        // Contact ring when the orb lands on the edge.
        AnimatedBuilder(
          animation: _impact,
          builder: (context, _) {
            final t = _impact.value;
            if (t == 0 || t == 1 || still) return const SizedBox.shrink();
            final r = s / 2 + 34 * Curves.easeOutCubic.transform(t);
            return Positioned(
              left: _impactAt.dx - r,
              top: _impactAt.dy - r,
              width: r * 2,
              height: r * 2,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: LuxeStage.gold.withValues(alpha: 0.7 * (1 - t)),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        Positioned(
          left: pos.dx,
          top: pos.dy,
          child: IgnorePointer(
            ignoring: widget.hidden,
            child: AnimatedScale(
              scale: widget.hidden ? 0.2 : 1,
              duration: LuxeMotion.medium,
              curve: widget.hidden ? Curves.easeInCubic : LuxeMotion.settle,
              child: AnimatedOpacity(
                opacity: widget.hidden ? 0 : 1,
                duration: LuxeMotion.fast,
                child: Semantics(
                  button: true,
                  label: widget.semanticLabel,
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      AppHaptics.light();
                      widget.onPressed();
                    },
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    onPanCancel: () {
                      if (_dragging) {
                        _onPanEnd(DragEndDetails());
                      }
                    },
                    child: AnimatedBuilder(
                      animation: _impact,
                      builder: (context, child) {
                        // Squash against the edge, then rebound.
                        final t = _impact.value;
                        final bump = still
                            ? 0.0
                            : math.sin(math.pi * t) * math.pow(1 - t, 1.4);
                        return Transform(
                          alignment: _targetRight
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          transform: Matrix4.diagonal3Values(
                            (_dragging ? 1.1 : 1) - 0.16 * bump,
                            (_dragging ? 1.1 : 1) + 0.1 * bump,
                            1,
                          ),
                          child: child,
                        );
                      },
                      child: GemAiFab(lifted: _dragging),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
