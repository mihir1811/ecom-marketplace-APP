import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/haptics/app_haptics.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/theme/luxe_tokens.dart';
import '../../../application/diamond_simulator_controller.dart';
import '../../../domain/average_hand.dart';
import '../../../domain/diamond_grades.dart';
import '../../../domain/hand_model.dart';
import '../../../simulation/hand_renderer.dart';
import '../../../simulation/hand_ring_mesh.dart';
import '../../../simulation/sim_mesh.dart';
import '../../../simulation/sim_optics.dart';
import '../../../simulation/sim_renderer.dart';
import '../../../simulation/sim_inclusion_plot.dart';
import '../../../simulation/sim_wireframe.dart';
import 'diamond_sim_viewport.dart';

/// Logical pixels per millimetre on a typical phone (160 per inch), for
/// showing the hand at life size.
const _lifePxPerMm = 160 / 25.4;

/// The view the hand rises into: the back of the hand square on, fingers
/// straight up, so every stone sits centred across its finger; tipped a
/// touch so the depth reads.
const _yaw0 = 0.0, _pitch0 = 0.12;

/// How far the hand turns: half a turn about the vertical, back of the
/// hand always toward the viewer (the palm side shows nothing worth
/// comparing), and a moderate tip up or down.
const _yawMin = -math.pi / 2, _yawMax = math.pi / 2;
const _pitchMin = -0.75, _pitchMax = 1.0;

/// Up to four stones on the fingers of a realistic 3D hand
/// ([HandModel], drawn by [HandRenderer]), each set in a solitaire ring
/// at the base of its finger, so their face-up size reads true against
/// real fingers. Drag anywhere to turn the hand through half a turn (it
/// coasts on and settles against the limits); drag on the selected stone
/// to spin it about its table; tap a finger to pick or add a stone. The
/// hand hides a stone only where a finger or a claw really stands in
/// front of it.
class SimHandStage extends ConsumerStatefulWidget {
  const SimHandStage({
    required this.controller,
    this.topInset = 0,
    this.cover = EdgeInsets.zero,
    super.key,
  });

  final SimViewportController controller;

  /// Room taken at the top by overlaid chrome.
  final double topInset;

  /// Room taken below and to the right by open controls: the rings rise
  /// (or slide) into what is left, keeping their size where they fit.
  final EdgeInsets cover;

  @override
  ConsumerState<SimHandStage> createState() => _SimHandStageState();
}

class _SimHandStageState extends ConsumerState<SimHandStage>
    with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final AnimationController _zoom = AnimationController(
    vsync: this,
    duration: LuxeMotion.medium,
    value: widget.controller.lifeSize.value ? 1 : 0,
  );
  late final AnimationController _recentre = AnimationController(
    vsync: this,
    duration: LuxeMotion.reveal,
  )..addListener(_onRecentre);
  late final AnimationController _lift = AnimationController(
    vsync: this,
    duration: LuxeMotion.medium,
    value: 1,
  );
  late EdgeInsetsTween _coverTween = EdgeInsetsTween(
    begin: widget.cover,
    end: widget.cover,
  );

  /// The controls' cover as the hand glides clear of it.
  EdgeInsets get _cover =>
      _coverTween.transform(Curves.easeInOutCubic.transform(_lift.value));
  late final Ticker _spinTicker = createTicker(_tickSpin);
  late final Ticker _orbitTicker = createTicker(_tickOrbit);

  final HandRenderer _hand = HandRenderer();
  bool _handReady = false;

  final Map<HandFinger, double> _spin = {};
  double _velocity = 0;
  Duration _last = Duration.zero;

  double _yaw = _yaw0, _pitch = _pitch0;
  Offset _orbitVelocity = Offset.zero;
  Duration _orbitLast = Duration.zero;
  ({double yaw, double pitch}) _recentreFrom = (yaw: _yaw0, pitch: _pitch0);

  /// What the current drag does: turn the hand, or spin the stone.
  bool _spinningStone = false;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    widget.controller.lifeSize.addListener(_onLifeSize);
    widget.controller.handRecentre.addListener(_startRecentre);
    widget.controller.addListener(_onMode);
    _vector = widget.controller.vector;
    HandRenderer.load()
        .then((assets) {
          if (!mounted) return;
          setState(() {
            _hand.attach(assets);
            _handReady = true;
          });
        })
        .catchError((Object _) {
          // No hand on this device: the stones still show.
        });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _enter.value = 1;
      } else {
        _enter.forward();
      }
    });
  }

  @override
  void didUpdateWidget(SimHandStage old) {
    super.didUpdateWidget(old);
    if (widget.cover == _coverTween.end) return;
    _coverTween = EdgeInsetsTween(begin: _cover, end: widget.cover);
    if (MediaQuery.disableAnimationsOf(context)) {
      _lift.value = 1;
    } else {
      _lift.forward(from: 0);
    }
  }

  @override
  void dispose() {
    widget.controller.lifeSize.removeListener(_onLifeSize);
    widget.controller.handRecentre.removeListener(_startRecentre);
    widget.controller.removeListener(_onMode);
    widget.controller.handTurned.value = false;
    _enter.dispose();
    _zoom.dispose();
    _lift.dispose();
    _recentre.dispose();
    _spinTicker.dispose();
    _orbitTicker.dispose();
    _hand.dispose();
    super.dispose();
  }

  late bool _vector;

  void _onMode() {
    if (widget.controller.vector != _vector) {
      setState(() => _vector = widget.controller.vector);
    }
  }

  void _onLifeSize() {
    widget.controller.lifeSize.value ? _zoom.forward() : _zoom.reverse();
  }

  void _setView(double yaw, double pitch) {
    _yaw = yaw.clamp(_yawMin, _yawMax);
    _pitch = pitch.clamp(_pitchMin, _pitchMax);
    widget.controller.handTurned.value =
        (_wrap(_yaw - _yaw0)).abs() > 0.06 || (_pitch - _pitch0).abs() > 0.06;
  }

  /// [a] wrapped into −π..π.
  static double _wrap(double a) =>
      a - 2 * math.pi * ((a + math.pi) / (2 * math.pi)).floorToDouble();

  void _startRecentre() {
    _orbitTicker.stop();
    _orbitVelocity = Offset.zero;
    _recentreFrom = (yaw: _yaw0 + _wrap(_yaw - _yaw0), pitch: _pitch);
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => _setView(_yaw0, _pitch0));
      return;
    }
    _recentre.forward(from: 0);
  }

  void _onRecentre() {
    final k = Curves.easeInOutCubic.transform(_recentre.value);
    final from = _recentreFrom;
    setState(
      () => _setView(
        from.yaw + (_yaw0 - from.yaw) * k,
        from.pitch + (_pitch0 - from.pitch) * k,
      ),
    );
  }

  void _tickSpin(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 1 / 60
        : ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 1 / 20);
    _last = elapsed;
    final f = ref.read(simHandProvider).active;
    setState(() {
      _spin[f] = (_spin[f] ?? 0) + _velocity * dt;
      _velocity *= math.exp(-3 * dt);
    });
    if (_velocity.abs() < 0.01) {
      _spinTicker.stop();
      setState(() => _velocity = 0);
    }
  }

  /// The hand coasts on after a flick, slowing as if turning on a
  /// well-oiled stand.
  void _tickOrbit(Duration elapsed) {
    final dt = _orbitLast == Duration.zero
        ? 1 / 60
        : ((elapsed - _orbitLast).inMicroseconds / 1e6).clamp(0.0, 1 / 20);
    _orbitLast = elapsed;
    setState(() {
      _setView(_yaw + _orbitVelocity.dx * dt, _pitch + _orbitVelocity.dy * dt);
      _orbitVelocity *= math.exp(-3.2 * dt);
      // Settles against a limit instead of pressing on it.
      if ((_yaw <= _yawMin && _orbitVelocity.dx < 0) ||
          (_yaw >= _yawMax && _orbitVelocity.dx > 0)) {
        _orbitVelocity = Offset(0, _orbitVelocity.dy);
      }
      if ((_pitch <= _pitchMin && _orbitVelocity.dy < 0) ||
          (_pitch >= _pitchMax && _orbitVelocity.dy > 0)) {
        _orbitVelocity = Offset(_orbitVelocity.dx, 0);
      }
    });
    if (_orbitVelocity.distance < 0.02) {
      _orbitTicker.stop();
      _orbitVelocity = Offset.zero;
    }
  }

  /// The four fingers' extents at the starting view, millimetres around
  /// the pivot (screen axes, y down), for framing: the fingers centred,
  /// thumb and wrist left to the edges. The frame keeps this scale while
  /// the hand turns, so it never breathes in and out.
  static final Rect _extents = () {
    final cam = HandCamera(
      yaw: _yaw0,
      pitch: _pitch0,
      centre: Offset.zero,
      pxPerMm: 1,
    );
    var r = Rect.zero;
    var first = true;
    for (final p in HandModel.focus) {
      final at = cam.project(p).at;
      if (first) {
        r = Rect.fromPoints(at, at);
        first = false;
      } else {
        r = r.expandToInclude(Rect.fromPoints(at, at));
      }
    }
    return r;
  }();

  /// The ring seats at the starting view, as [_extents], with room round
  /// them for the stones and their claws.
  static final Rect _seatExtents = () {
    final cam = HandCamera(
      yaw: _yaw0,
      pitch: _pitch0,
      centre: Offset.zero,
      pxPerMm: 1,
    );
    Rect? r;
    for (final f in HandFinger.values) {
      final at = cam.project(HandModel.seat(f).position).at;
      final p = Rect.fromPoints(at, at);
      r = r == null ? p : r.expandToInclude(p);
    }
    return r!.inflate(10);
  }();

  /// The camera: the whole hand centred and in view, or life size centred
  /// on the selected stone. With controls open over the stage, the rings
  /// rise into the room left above them, the fingertips free to run off
  /// the top, and the hand shrinks only if the rings would not fit.
  HandCamera _camera(Size size, HandFinger active, double rise) {
    final cover = _cover;
    final width = math.max(120.0, size.width - cover.right);
    final usable = math.max(120.0, size.height - widget.topInset);
    final clear = math.max(120.0, usable - cover.bottom);
    final ext = _extents, seats = _seatExtents;
    final whole = math
        .min((width - 24) / ext.width, (usable - 16) / ext.height)
        .clamp(1.2, 9.0);
    final rings = math.min(
      (width - 24) / seats.width,
      (clear - 24) / seats.height,
    );
    final fit = math.min(whole, rings).clamp(1.2, 9.0);
    final z = Curves.easeInOutCubic.transform(_zoom.value);
    final px = fit + (_lifePxPerMm - fit) * z;
    // Where the rings sit: as the whole hand frames them, or higher, in
    // the middle of the room above the controls.
    final high = widget.topInset + clear * 0.55;
    final framed = Offset(width / 2, widget.topInset + usable * 0.52);
    final ringsAt = framed.dy + (seats.center.dy - ext.center.dy) * px;
    final lift = math.min(0.0, high - ringsAt);
    final target = Offset(framed.dx, math.min(framed.dy, high));
    final centre = framed - ext.center * px + Offset(0, lift);
    final roll = (1 - rise) * -0.12;
    if (z == 0) {
      return HandCamera(
        yaw: _yaw,
        pitch: _pitch,
        roll: roll,
        centre: centre,
        pxPerMm: px,
      );
    }
    final probe = HandCamera(
      yaw: _yaw,
      pitch: _pitch,
      roll: roll,
      centre: centre,
      pxPerMm: px,
    );
    final seat = probe.project(HandModel.seat(active).position).at;
    return HandCamera(
      yaw: _yaw,
      pitch: _pitch,
      roll: roll,
      centre: centre + (target - seat) * z,
      pxPerMm: px,
    );
  }

  /// Where a stone sits on [f] under [cam]: its centre on screen, scale,
  /// orientation and how much of it can be seen.
  ({Offset at, double px, SimView view, double visible}) _place(
    HandFinger f,
    HandCamera cam,
    DiamondSimulatorState? stone,
  ) {
    final seat = HandModel.seat(f);
    final centre = _stoneCentre(f, stone);
    final p = cam.project(centre);
    final view = cam.stoneView(seat.normal, seat.along, _spin[f] ?? 0);
    final visible = HandModel.visibility(
      seat,
      cam.eye,
      (centre - seat.position).length,
    );
    return (at: p.at, px: p.pxPerMm, view: view, visible: visible);
  }

  /// Where [f]'s stone sits: its culet just clear of the band, as in a
  /// claw head.
  HandVec _stoneCentre(HandFinger f, DiamondSimulatorState? stone) {
    final seat = HandModel.seat(f);
    if (stone == null) return seat.position;
    final ring = ref.read(simHandProvider).ring;
    return seat.position +
        seat.normal * (ring.thickness + 0.25 + _culetDepth(stone));
  }

  final Map<HandFinger, (Object, RingMesh)> _ringCache = {};

  /// The rings on the hand: one per stone, its claws turned with the
  /// stone's spin and fitted to its outline.
  List<HandRing> _rings(SimHand hand, DiamondSimulatorState active) {
    final out = <HandRing>[];
    final style = hand.ring;
    for (final f in HandFinger.values) {
      final stone = f == hand.active ? active : hand.parked[f];
      if (stone == null) continue;
      final seat = HandModel.seat(f);
      final spin = _spin[f] ?? 0;
      final key = (stone.mesh, stone.mmPerUnit, spin, style);
      final cached = _ringCache[f];
      final RingMesh mesh;
      if (cached != null && cached.$1 == key) {
        mesh = cached.$2;
      } else {
        // The stone's axes as [HandCamera.stoneView] turns it.
        final n = seat.normal, along = seat.along;
        final z = along.cross(n);
        final x = along * math.cos(spin) - z * math.sin(spin);
        mesh = buildRing(
          seat,
          style,
          RingHead(
            centre: _stoneCentre(f, stone),
            x: x,
            y: n,
            z: x.cross(n),
            claws: RingHead.clawsFor(stone.mesh, stone.mmPerUnit, style.prongs),
          ),
        );
        _ringCache[f] = (key, mesh);
      }
      out.add((seat: seat, mesh: mesh, bandWidth: style.bandWidth));
    }
    return out;
  }

  static final Expando<double> _culets = Expando();

  /// How far below its centre a stone's culet reaches, mm.
  static double _culetDepth(DiamondSimulatorState s) {
    final SimMesh mesh = s.mesh;
    final cached = _culets[mesh];
    final double low;
    if (cached != null) {
      low = cached;
    } else {
      var m = 0.0;
      final pos = mesh.positions;
      for (var i = 1; i < pos.length; i += 3) {
        m = math.min(m, pos[i]);
      }
      _culets[mesh] = low = -m;
    }
    return low * s.mmPerUnit;
  }

  HandFinger? _fingerAt(Offset local, HandCamera cam) {
    final hand = ref.read(simHandProvider);
    final active = ref.read(diamondSimulatorProvider);
    HandFinger? best;
    var bestD = math.max(28.0, 14 * cam.pxPerMm);
    for (final finger in HandFinger.values) {
      final stone = finger == hand.active ? active : hand.parked[finger];
      final at = _place(finger, cam, stone);
      if (at.visible < 0.3) continue;
      final d = (at.at - local).distance;
      if (d < bestD) {
        bestD = d;
        best = finger;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final hand = ref.watch(simHandProvider);
    final active = ref.watch(diamondSimulatorProvider);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final uv = active.lighting == SimLighting.ultraviolet;
    if (_handReady) _hand.setRings(_rings(hand, active), hand.ring.metal);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        HandCamera camNow() => _camera(
          size,
          hand.active,
          Curves.easeOutCubic.transform(_enter.value),
        );
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) {
            final f = _fingerAt(d.localPosition, camNow());
            if (f == null) return;
            AppHaptics.selection();
            ref.read(simHandProvider.notifier).select(f);
          },
          onPanStart: (d) {
            _dragging = true;
            _recentre.stop();
            final cam = camNow();
            final at = _place(hand.active, cam, active);
            final radius = active.mesh.radius * active.mmPerUnit * at.px + 18;
            _spinningStone =
                at.visible > 0.3 && (d.localPosition - at.at).distance < radius;
            if (_spinningStone) {
              _spinTicker.stop();
              _velocity = 0;
            } else {
              _orbitTicker.stop();
              _orbitVelocity = Offset.zero;
            }
          },
          onPanUpdate: (d) => setState(() {
            if (_spinningStone) {
              _spin[hand.active] =
                  (_spin[hand.active] ?? 0) + d.delta.dx * 0.012;
            } else {
              _setView(
                _yaw + d.delta.dx * 0.0085,
                _pitch + d.delta.dy * 0.0085,
              );
            }
          }),
          onPanEnd: (d) {
            _dragging = false;
            final v = d.velocity.pixelsPerSecond;
            if (_spinningStone) {
              _velocity = (v.dx * 0.012).clamp(-12.0, 12.0);
              if (_velocity.abs() > 0.05) {
                _last = Duration.zero;
                _spinTicker.start();
              } else {
                setState(() {});
              }
            } else {
              _orbitVelocity = Offset(
                (v.dx * 0.0085).clamp(-9.0, 9.0),
                (v.dy * 0.0085).clamp(-6.0, 6.0),
              );
              if (_orbitVelocity.distance > 0.08) {
                _orbitLast = Duration.zero;
                _orbitTicker.start();
              } else {
                setState(() {});
              }
            }
          },
          child: AnimatedBuilder(
            animation: Listenable.merge([_enter, _zoom, _lift]),
            builder: (context, _) {
              final rise = Curves.easeOutCubic.transform(_enter.value);
              final cam = _camera(size, hand.active, rise);
              final stones = CurvedAnimation(
                parent: _enter,
                curve: const Interval(0.55, 1, curve: Curves.easeOutBack),
              ).value;
              return Stack(
                clipBehavior: Clip.none,
                fit: StackFit.expand,
                children: [
                  // A dark stage, so the skin and the stones read; pitch
                  // black under ultraviolet, as in a darkened viewing box.
                  if (uv)
                    const ColoredBox(color: Color(0xFF000000))
                  else
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(0, -0.2),
                          radius: 1.1,
                          colors: [Color(0xFF1A1C1F), Color(0xFF060606)],
                        ),
                      ),
                    ),
                  Opacity(
                    opacity: rise.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, (1 - rise) * size.height * 0.6),
                      child: Stack(
                        clipBehavior: Clip.none,
                        fit: StackFit.expand,
                        children: [
                          if (_handReady)
                            RepaintBoundary(
                              child: CustomPaint(
                                painter: _HandPainter(
                                  renderer: _hand,
                                  version: _hand.version,
                                  camera: cam,
                                  dpr: dpr,
                                  ultraviolet: uv,
                                ),
                              ),
                            ),
                          for (final f in _paintOrder(cam))
                            ..._finger(
                              f,
                              cam,
                              f == hand.active ? active : hand.parked[f],
                              selected: f == hand.active,
                              appear: stones,
                              dpr: dpr,
                              ultraviolet: uv,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// Fingers far to near, so a nearer stone draws over a farther one.
  List<HandFinger> _paintOrder(HandCamera cam) {
    final list = [...HandFinger.values];
    final depth = {
      for (final f in list) f: cam.toCamera(HandModel.seat(f).position).z,
    };
    list.sort((a, b) => depth[a]!.compareTo(depth[b]!));
    return list;
  }

  List<Widget> _finger(
    HandFinger f,
    HandCamera cam,
    DiamondSimulatorState? stone, {
    required bool selected,
    required double appear,
    required double dpr,
    required bool ultraviolet,
  }) {
    final place = _place(f, cam, stone);
    // Never faded by the turn: the front layer hides what is covered.
    final shown = appear.clamp(0.0, 1.0);
    if (shown <= 0.01) return const [];
    final at = place.at;
    final p = LuxePalette.of(context);

    if (stone != null) {
      final radiusMm = stone.mesh.radius * stone.mmPerUnit;
      final side = radiusMm * 2 * place.px * 1.2 + 4;
      return [
        Positioned(
          left: at.dx - side / 2,
          top: at.dy - side / 2,
          width: side,
          height: side,
          child: IgnorePointer(
            child: Opacity(
              opacity: shown,
              child: Transform.scale(
                scale: 0.6 + 0.4 * appear,
                child: SimFingerStone(
                  stone: stone,
                  pxPerMm: place.px,
                  view: place.view,
                  moving: selected && (_dragging || _spinTicker.isActive),
                  vector: _vector,
                ),
              ),
            ),
          ),
        ),
        if (_handReady)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _HandFrontPainter(
                  renderer: _hand,
                  version: _hand.version,
                  camera: cam,
                  dpr: dpr,
                  ultraviolet: ultraviolet,
                  slot: f.index,
                  centre: _stoneCentre(f, stone),
                  radius: radiusMm,
                  clip: Rect.fromCenter(center: at, width: side, height: side),
                ),
              ),
            ),
          ),
      ];
    }
    return [
      Positioned(
        left: at.dx - 24,
        top: at.dy - 14,
        width: 48,
        height: 28,
        child: IgnorePointer(
          child: Opacity(
            opacity: shown,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: const Color(0x99000000),
                shape: StadiumBorder(
                  side: BorderSide(color: p.accent.withValues(alpha: 0.7)),
                ),
              ),
              child: Center(
                child: Text(
                  context.tr(EducationL10n.addStone),
                  style: LuxeType.label(p.ink, size: 11),
                ),
              ),
            ),
          ),
        ),
      ),
    ];
  }
}

class _HandPainter extends CustomPainter {
  _HandPainter({
    required this.renderer,
    required this.version,
    required this.camera,
    required this.dpr,
    required this.ultraviolet,
  });

  final HandRenderer renderer;

  /// [HandRenderer.version] when painted: the rings changed if it moved.
  final int version;
  final HandCamera camera;
  final double dpr;
  final bool ultraviolet;

  @override
  void paint(Canvas canvas, Size size) {
    renderer.paint(
      canvas,
      size,
      camera,
      devicePixelRatio: dpr,
      ultraviolet: ultraviolet,
    );
  }

  @override
  bool shouldRepaint(covariant _HandPainter old) {
    final a = old.camera, b = camera;
    return old.renderer != renderer ||
        old.version != version ||
        old.dpr != dpr ||
        old.ultraviolet != ultraviolet ||
        a.yaw != b.yaw ||
        a.pitch != b.pitch ||
        a.roll != b.roll ||
        a.centre != b.centre ||
        a.pxPerMm != b.pxPerMm;
  }
}

/// What of the hand stands in front of one stone, drawn over it.
class _HandFrontPainter extends CustomPainter {
  _HandFrontPainter({
    required this.renderer,
    required this.version,
    required this.camera,
    required this.dpr,
    required this.ultraviolet,
    required this.slot,
    required this.centre,
    required this.radius,
    required this.clip,
  });

  final HandRenderer renderer;
  final int version;
  final HandCamera camera;
  final double dpr;
  final bool ultraviolet;
  final int slot;
  final HandVec centre;
  final double radius;
  final Rect clip;

  @override
  void paint(Canvas canvas, Size size) {
    renderer.paintFront(
      canvas,
      size,
      camera,
      devicePixelRatio: dpr,
      ultraviolet: ultraviolet,
      slot: slot,
      centre: centre,
      radius: radius,
      clip: clip,
    );
  }

  @override
  bool shouldRepaint(covariant _HandFrontPainter old) {
    final a = old.camera, b = camera;
    return old.renderer != renderer ||
        old.version != version ||
        old.dpr != dpr ||
        old.ultraviolet != ultraviolet ||
        old.slot != slot ||
        old.clip != clip ||
        old.radius != radius ||
        old.centre.x != centre.x ||
        old.centre.y != centre.y ||
        old.centre.z != centre.z ||
        a.yaw != b.yaw ||
        a.pitch != b.pitch ||
        a.roll != b.roll ||
        a.centre != b.centre ||
        a.pxPerMm != b.pxPerMm;
  }
}

/// One traced stone at the hand's scale, seen as [view] shows it. Redraws
/// only when the stone, its view or the scale change; full quality once it
/// is still.
class SimFingerStone extends StatefulWidget {
  const SimFingerStone({
    required this.stone,
    required this.pxPerMm,
    required this.view,
    required this.moving,
    this.vector = false,
    super.key,
  });

  final DiamondSimulatorState stone;
  final double pxPerMm;
  final SimView view;
  final bool moving;

  /// Drawn as facet edges only (see [SimRenderMode.vector]).
  final bool vector;

  @override
  State<SimFingerStone> createState() => _SimFingerStoneState();
}

class _SimFingerStoneState extends State<SimFingerStone> {
  final _renderer = SimRenderer()..measureStats = false;
  final _wire = SimWireRenderer();
  final _inclusions = SimInclusionPlot();
  late SimWireStyle _wireStyle;
  int _version = 0;

  /// Whether the stone changed moments ago: while edits keep coming (a
  /// slider drag, quick taps) the CPU fallback samples coarser, and finer
  /// once they stop. The GPU always traces at full resolution.
  bool _settling = false;
  Timer? _settle;

  /// Whether the GPU tracer is in, or failed to load (then the CPU tracer
  /// draws). Until then nothing is drawn: never a coarse stand-in.
  bool _tracerSettled = false;

  @override
  void initState() {
    super.initState();
    _load(widget.stone, mesh: true);
    SimRenderer.loadProgram()
        .then((program) {
          if (!mounted) return;
          setState(() {
            _renderer.shader = program.fragmentShader();
            _tracerSettled = true;
            _version++;
          });
        })
        .catchError((Object _) {
          // The CPU tracer draws instead.
          if (!mounted) return;
          setState(() {
            _tracerSettled = true;
            _version++;
          });
        });
  }

  void _load(DiamondSimulatorState s, {required bool mesh}) {
    if (mesh) _renderer.setStone(s.mesh, s.inclusions);
    final optics = SimOptics.of(s.spec, s.lighting);
    _renderer.setOptics(optics);
    _wireStyle = SimWireStyle.of(optics);
    _version++;
  }

  @override
  void didUpdateWidget(SimFingerStone old) {
    super.didUpdateWidget(old);
    final a = old.stone, b = widget.stone;
    if (identical(a, b)) return;
    _load(
      b,
      mesh:
          !identical(a.mesh, b.mesh) || !identical(a.inclusions, b.inclusions),
    );
    _settling = true;
    _settle?.cancel();
    _settle = Timer(const Duration(milliseconds: 380), () {
      if (!mounted) return;
      setState(() {
        _settling = false;
        _version++;
      });
    });
  }

  @override
  void dispose() {
    _settle?.cancel();
    _renderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _FingerStonePainter(
          renderer: _renderer,
          wire: widget.vector ? _wire : null,
          inclusions: _inclusions,
          stone: widget.stone,
          wireStyle: _wireStyle,
          version: _version,
          pxPerUnit: widget.pxPerMm * widget.stone.mmPerUnit,
          view: widget.view,
          moving: widget.moving || _settling,
          ready: _tracerSettled,
          dpr: dpr,
        ),
      ),
    );
  }
}

class _FingerStonePainter extends CustomPainter {
  _FingerStonePainter({
    required this.renderer,
    required this.wire,
    required this.inclusions,
    required this.stone,
    required this.wireStyle,
    required this.version,
    required this.pxPerUnit,
    required this.view,
    required this.moving,
    required this.ready,
    required this.dpr,
  });

  final SimRenderer renderer;
  final SimWireRenderer? wire;
  final SimInclusionPlot inclusions;
  final DiamondSimulatorState stone;
  final SimWireStyle wireStyle;
  final int version;
  final double pxPerUnit, dpr;
  final SimView view;
  final bool moving, ready;

  @override
  void paint(Canvas canvas, Size size) {
    final wire = this.wire;
    if (wire != null) {
      wire.paint(
        canvas,
        size,
        mesh: stone.mesh,
        view: view,
        pxPerUnit: pxPerUnit,
        style: wireStyle,
        inclusions: stone.inclusions,
        inclusionPlot: inclusions,
      );
      return;
    }
    if (!ready) return;
    renderer.maxBounces = SimRenderer.bounces;
    renderer.paint(
      canvas,
      size,
      view: view,
      pxPerUnit: pxPerUnit,
      samplePx: moving ? 4 : 2.5,
      // Always one traced path per device pixel, spinning or still.
      devicePixelRatio: dpr,
    );
  }

  @override
  bool shouldRepaint(covariant _FingerStonePainter old) =>
      old.version != version ||
      old.wire != wire ||
      !identical(old.stone, stone) ||
      old.pxPerUnit != pxPerUnit ||
      old.view.tilt != view.tilt ||
      old.view.spin != view.spin ||
      old.view.roll != view.roll ||
      old.moving != moving ||
      old.ready != ready ||
      old.dpr != dpr;
}
