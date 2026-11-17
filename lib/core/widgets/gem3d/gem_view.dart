import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../haptics/app_haptics.dart';
import 'gem_mesh.dart';
import 'gem_renderer.dart';

/// A single live 3D stone. Spins slowly on its own; when [interactive],
/// drag to turn it (with inertia) and tap to make it flash.
class GemView extends StatefulWidget {
  const GemView({
    super.key,
    this.cut = GemCut.round,
    this.look = GemLook.white,
    this.size = 120,
    this.spin = 0.45,
    this.tilt = 0.55,
    this.interactive = false,
    this.glints = true,
    this.semanticLabel,
  });

  final GemCut cut;
  final GemLook look;
  final double size;

  /// Idle turn speed, radians per second.
  final double spin;

  /// Resting forward tilt so the crown faces the viewer.
  final double tilt;
  final bool interactive;
  final bool glints;
  final String? semanticLabel;

  @override
  State<GemView> createState() => _GemViewState();
}

class _GemViewState extends State<GemView> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final _frame = ValueNotifier<int>(0);
  final _pose = GemPose();
  Duration _last = Duration.zero;
  double _time = 0;
  double _wy = 0, _wx = 0;
  double _flash = 0;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _pose
      ..rx = widget.tilt
      ..ry = math.Random().nextDouble() * math.pi;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.disableAnimationsOf(context);
    if (still && _ticker.isActive && !_dragging) {
      _ticker.stop();
    } else if (!still && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 1 / 60
        : ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 1 / 20);
    _last = elapsed;
    _time += dt;
    if (!_dragging) {
      final decay = math.exp(-2.2 * dt);
      _wy = widget.spin + (_wy - widget.spin) * decay;
      _wx *= decay;
      // Ease the tilt back to rest.
      _pose.rx += (widget.tilt - _pose.rx) * (1 - math.exp(-2.5 * dt));
    }
    _pose
      ..ry += _wy * dt
      ..rx += _wx * dt;
    _flash = math.max(0, _flash - dt * 1.8);
    _frame.value++;
    if (MediaQuery.disableAnimationsOf(context) &&
        !_dragging &&
        (_wy - widget.spin).abs() < 0.02 &&
        _wx.abs() < 0.02 &&
        _flash == 0) {
      _ticker.stop();
    }
  }

  void _ensureRunning() {
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget view = RepaintBoundary(
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _GemViewPainter(
          repaint: _frame,
          mesh: GemMesh.of(widget.cut),
          pose: _pose,
          look: widget.look,
          time: () => _time,
          flash: () => _flash,
          glints: widget.glints,
        ),
      ),
    );
    if (widget.interactive) {
      view = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptics.light();
          _flash = 1;
          _wy += 7 * (_wy >= 0 ? 1 : -1);
          _ensureRunning();
        },
        onPanStart: (_) {
          _dragging = true;
          _ensureRunning();
        },
        onPanUpdate: (d) {
          final k = 2.6 / widget.size;
          _pose
            ..ry += d.delta.dx * k * 1.4
            ..rx = (_pose.rx + d.delta.dy * k).clamp(-1.2, 1.6);
        },
        onPanEnd: (d) {
          _dragging = false;
          final k = 2.6 / widget.size;
          _wy = (d.velocity.pixelsPerSecond.dx * k * 1.4).clamp(-18.0, 18.0);
          _wx = (d.velocity.pixelsPerSecond.dy * k * 0.6).clamp(-6.0, 6.0);
        },
        onPanCancel: () => _dragging = false,
        child: view,
      );
    }
    return Semantics(
      image: true,
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel == null,
      child: view,
    );
  }
}

class _GemViewPainter extends CustomPainter {
  _GemViewPainter({
    required Listenable repaint,
    required this.mesh,
    required this.pose,
    required this.look,
    required this.time,
    required this.flash,
    required this.glints,
  }) : super(repaint: repaint);

  final GemMesh mesh;
  final GemPose pose;
  final GemLook look;
  final double Function() time;
  final double Function() flash;
  final bool glints;
  final _batch = GemBatch();

  @override
  void paint(Canvas canvas, Size size) {
    final camera = GemCamera(
      center: size.center(Offset.zero),
      unit: size.shortestSide * 0.42,
      distance: 7,
    );
    _batch
      ..reset()
      ..addGem(
        mesh: mesh,
        pose: pose,
        camera: camera,
        look: look,
        time: time(),
        flash: flash(),
        glint: glints,
      )
      ..paint(
        canvas,
        glintSprite: glints ? GemGlintSprite.image : null,
        glintScale: 0.9,
      );
  }

  @override
  bool shouldRepaint(covariant _GemViewPainter old) =>
      old.mesh != mesh || old.look != look || old.glints != glints;
}
