import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../diamond_education/simulation/sim_renderer.dart';
import '../../geometry/jmath.dart';
import '../../physics/jewelry_physics.dart';
import '../../render/jewelry_camera.dart';
import '../../render/jewelry_renderer.dart';
import '../../scene/jewelry_scene.dart';

/// Camera presets for the jewelry viewport.
enum JewelryViewPreset { front, angled, side, top }

/// Commands shared by the viewport and the controls around it.
class JewelryViewportController extends ChangeNotifier {
  JewelryViewportController({this._autoRotate = true});

  bool _autoRotate;
  bool get autoRotate => _autoRotate;
  set autoRotate(bool v) {
    if (v == _autoRotate) return;
    _autoRotate = v;
    notifyListeners();
  }

  JewelryViewPreset _preset = JewelryViewPreset.angled;
  int _request = 0;
  JewelryViewPreset get preset => _preset;

  void show(JewelryViewPreset p) {
    _preset = p;
    _request++;
    notifyListeners();
  }
}

/// The live 3D piece on its display.
///
/// Drag to turn the camera (with inertia), pinch to zoom. Tap the piece
/// and a fingertip pushes it where you touched: it swings, rocks or
/// drapes under gravity, inertia and friction, and comes to rest. Drag
/// the piece itself to pull it and let go.
///
/// Renders only while something moves (physics, the camera or the
/// turntable), at reduced resolution then, and once more at full
/// resolution when everything is still.
class JewelryViewport extends StatefulWidget {
  const JewelryViewport({
    required this.scene,
    this.controller,
    this.interactive = true,
    this.drag = true,
    this.semanticLabel,
    super.key,
  });

  final JScene scene;
  final JewelryViewportController? controller;
  final bool interactive;

  /// Whether dragging turns the camera or pulls the piece; off inside a
  /// scrolling page, where taps still touch it.
  final bool drag;
  final String? semanticLabel;

  @override
  State<JewelryViewport> createState() => _JewelryViewportState();
}

enum _Drag { none, orbit, grab, pinch }

class _JewelryViewportState extends State<JewelryViewport>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final _renderer = JewelryRenderer();
  final _frame = ValueNotifier(0);
  late final JCamera _cam;

  double _yaw = 0, _pitch = 0, _zoom = 1;
  double _wYaw = 0, _wPitch = 0;
  double _turnDir = 1;
  Duration _last = Duration.zero;
  bool _moving = false;

  // Camera glides: to a preset, or to a new piece's framing.
  double _fromYaw = 0, _fromPitch = 0, _toYaw = 0, _toPitch = 0;
  V3 _fromFocus = V3.zero, _toFocus = V3.zero;
  double _fromRadius = 1, _toRadius = 1, _radius = 1;
  double _glide = 1;
  int _seenRequest = 0;

  _Drag _drag = _Drag.none;
  JTouch? _grabbed;
  V3 _grabPlane = V3.zero;
  double _pinchStart = 1;
  double _sincePoke = 10;

  JFraming get _framing => widget.scene.framing;

  @override
  void initState() {
    super.initState();
    final f = _framing;
    _yaw = f.yaw;
    _pitch = f.pitch;
    _radius = f.radius;
    _cam = JCamera(target: f.focus, yaw: _yaw, pitch: _pitch, distance: 100);
    _renderer.setScene(widget.scene);
    JewelryRenderer.loadProgram()
        .then((p) {
          if (!mounted) return;
          _renderer.program = p;
          _kick();
        })
        .catchError((Object _) {
          // Vertices are shaded on the CPU instead.
        });
    SimRenderer.loadProgram()
        .then((p) {
          if (!mounted) return;
          _renderer.diamondProgram = p;
          _kick();
        })
        .catchError((Object _) {});
    widget.controller?.addListener(_onController);
    _seenRequest = widget.controller?._request ?? 0;
  }

  ScrollPosition? _scroll;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      widget.controller?.autoRotate = false;
    }
    // Inside a scrolling page: pause while scrolled out of view.
    final next = Scrollable.maybeOf(context)?.position;
    if (next != _scroll) {
      _scroll?.removeListener(_kick);
      _scroll = next?..addListener(_kick);
    }
    _kick();
  }

  bool get _onScreen {
    if (_scroll == null) return true;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return true;
    final top = box.localToGlobal(Offset.zero).dy;
    return top < MediaQuery.sizeOf(context).height && top + box.size.height > 0;
  }

  @override
  void didUpdateWidget(JewelryViewport old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?.removeListener(_onController);
      widget.controller?.addListener(_onController);
    }
    if (!identical(old.scene, widget.scene)) {
      _renderer.setScene(widget.scene);
      if (!identical(old.scene.framing, widget.scene.framing)) {
        // A new piece glides into frame; a new type also resets the view.
        final f = widget.scene.framing;
        final retype = old.scene.design.type != widget.scene.design.type;
        _startGlide(
          yaw: retype ? f.yaw : _yaw,
          pitch: retype ? f.pitch : _pitch,
          focus: f.focus,
          radius: f.radius,
        );
        if (retype) _zoom = 1;
      }
      _kick();
    }
  }

  @override
  void dispose() {
    _scroll?.removeListener(_kick);
    widget.controller?.removeListener(_onController);
    _ticker.dispose();
    _frame.dispose();
    _renderer.dispose();
    super.dispose();
  }

  void _onController() {
    final c = widget.controller!;
    if (c._request != _seenRequest) {
      _seenRequest = c._request;
      final f = _framing;
      final (yaw, pitch) = switch (c.preset) {
        JewelryViewPreset.front => (0.0, 0.06),
        JewelryViewPreset.angled => (f.yaw, f.pitch),
        JewelryViewPreset.side => (math.pi / 2, 0.08),
        JewelryViewPreset.top => (_yaw, 1.25),
      };
      _startGlide(yaw: yaw, pitch: pitch, focus: _cam.target, radius: _radius);
      _zoom = 1;
    }
    _kick();
  }

  void _startGlide({
    required double yaw,
    required double pitch,
    required V3 focus,
    required double radius,
  }) {
    _fromYaw = _yaw;
    _fromPitch = _pitch;
    final limit = _framing.yawLimit;
    _toYaw = limit == null ? _nearestTurn(yaw) : yaw.clamp(-limit, limit);
    _toPitch = pitch.clamp(_framing.minPitch, _framing.maxPitch);
    _fromFocus = _cam.target;
    _toFocus = focus;
    _fromRadius = _radius;
    _toRadius = radius;
    _glide = 0;
    _wYaw = _wPitch = 0;
  }

  /// [yaw] moved by whole turns to be nearest the current yaw.
  double _nearestTurn(double yaw) {
    const tau = 2 * math.pi;
    return yaw + ((_yaw - yaw) / tau).round() * tau;
  }

  void _kick() {
    if (!mounted || !_onScreen) return;
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 1 / 60
        : ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 1 / 20);
    _last = elapsed;
    if (!_onScreen) {
      _ticker.stop();
      return;
    }
    var active = false;
    final physics = widget.scene.physics;
    _sincePoke += dt;
    if (!physics.isStatic &&
        (_grabbed != null || _sincePoke < 0.6 || physics.moving)) {
      physics.advance(dt);
      active = true;
    }
    final f = _framing;
    if (_glide < 1) {
      _glide = math.min(1, _glide + dt / 0.65);
      final e = Curves.easeInOutCubic.transform(_glide);
      _yaw = _fromYaw + (_toYaw - _fromYaw) * e;
      _pitch = _fromPitch + (_toPitch - _fromPitch) * e;
      _cam.target = _fromFocus.lerp(_toFocus, e);
      _radius = _fromRadius + (_toRadius - _fromRadius) * e;
      active = true;
    } else if (_drag == _Drag.none) {
      if (_wYaw.abs() > 0.005 || _wPitch.abs() > 0.005) {
        _yaw += _wYaw * dt;
        _pitch = (_pitch + _wPitch * dt).clamp(f.minPitch, f.maxPitch);
        final k = math.exp(-3.5 * dt);
        _wYaw *= k;
        _wPitch *= k;
        active = true;
      } else if (widget.controller?.autoRotate ?? !widget.interactive) {
        _yaw += 0.22 * _turnDir * dt;
        active = true;
      }
    }
    final limit = f.yawLimit;
    if (limit != null && _yaw.abs() > limit) {
      _yaw = _yaw.clamp(-limit, limit);
      _turnDir = -_yaw.sign;
      _wYaw = 0;
    }
    _moving = active;
    _frame.value++;
    if (!active) _ticker.stop();
  }

  // ---- Touch -------------------------------------------------------------

  /// What the finger at [at] lands on, if close enough to the piece.
  JTouch? _hit(Offset at) {
    JTouch? best;
    var bestD = 30.0;
    for (final t in widget.scene.physics.touchables()) {
      final p = _cam.project(t.world);
      if (p == null) continue;
      final d = (p - at).distance;
      if (d < bestD) {
        bestD = d;
        best = t;
      }
    }
    return best;
  }

  void _poke(Offset at) {
    final t = _hit(at);
    if (t == null) return;
    final p = _cam.project(t.world) ?? at;
    // A fingertip pushes in, a little up, and sideways away from where
    // it touched; dead centre it brushes past to one side.
    var lat = (-(at.dx - p.dx) / 18).clamp(-1.0, 1.0);
    if (lat.abs() < 0.2) lat = (at.dy.toInt().isEven ? 0.7 : -0.7);
    final dir = _cam.forward * 0.55 + _cam.right * lat + _cam.up * 0.35;
    widget.scene.physics.poke(t, dir, 230);
    _sincePoke = 0;
    widget.controller?.autoRotate = false;
    AppHaptics.light();
    _kick();
  }

  void _onScaleStart(ScaleStartDetails d) {
    _glide = 1;
    _wYaw = _wPitch = 0;
    if (d.pointerCount >= 2) {
      _drag = _Drag.pinch;
      _pinchStart = _zoom;
      return;
    }
    final t = _hit(d.localFocalPoint);
    if (t != null && !widget.scene.physics.isStatic) {
      _drag = _Drag.grab;
      _grabbed = t;
      _grabPlane = t.world;
      widget.scene.physics.grab(t, _grabPlane);
      widget.controller?.autoRotate = false;
    } else {
      _drag = _Drag.orbit;
    }
    _kick();
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    final f = _framing;
    if (d.pointerCount >= 2 && _drag != _Drag.pinch) {
      // A second finger arrived: release what was held and zoom.
      if (_drag == _Drag.grab) widget.scene.physics.release();
      _grabbed = null;
      _drag = _Drag.pinch;
      _pinchStart = _zoom / math.max(0.01, d.scale);
    }
    switch (_drag) {
      case _Drag.pinch:
        _zoom = (_pinchStart * d.scale).clamp(0.6, 6.0);
        _yaw -= d.focalPointDelta.dx * 0.006;
      case _Drag.grab:
        final target = _cam.onPlane(d.localFocalPoint, _grabPlane);
        widget.scene.physics.moveGrab(_grabbed!, target);
      case _Drag.orbit:
        _yaw -= d.focalPointDelta.dx * 0.0085;
        _pitch = (_pitch + d.focalPointDelta.dy * 0.0085).clamp(
          f.minPitch,
          f.maxPitch,
        );
        widget.controller?.autoRotate = false;
      case _Drag.none:
        break;
    }
    _kick();
  }

  void _onScaleEnd(ScaleEndDetails d) {
    if (_drag == _Drag.grab) {
      widget.scene.physics.release();
      _sincePoke = 0;
    } else if (_drag == _Drag.orbit) {
      final v = d.velocity.pixelsPerSecond;
      _wYaw = -v.dx * 0.0085 * 0.6;
      _wPitch = v.dy * 0.0085 * 0.6;
    }
    _grabbed = null;
    _drag = _Drag.none;
    _kick();
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    Widget view = RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ScenePainter(this, dpr),
      ),
    );
    if (widget.interactive) {
      view = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => _poke(d.localPosition),
        onScaleStart: widget.drag ? _onScaleStart : null,
        onScaleUpdate: widget.drag ? _onScaleUpdate : null,
        onScaleEnd: widget.drag ? _onScaleEnd : null,
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

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.state, this.dpr) : super(repaint: state._frame);

  final _JewelryViewportState state;
  final double dpr;

  @override
  void paint(Canvas canvas, Size size) {
    final s = state;
    s._cam
      ..yaw = s._yaw
      ..pitch = s._pitch
      ..distance = JCamera.fitDistance(s._radius, size) / s._zoom
      ..update(size);
    s._renderer.paint(
      canvas,
      size,
      s._cam,
      devicePixelRatio: dpr,
      // Fewer G-buffer pixels while moving; full resolution at rest.
      renderScale: s._moving ? math.min(dpr, 1.75) : dpr,
    );
  }

  @override
  bool shouldRepaint(covariant _ScenePainter old) =>
      old.state != state || old.dpr != dpr;
}
