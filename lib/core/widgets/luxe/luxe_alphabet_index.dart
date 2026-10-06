import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../haptics/app_haptics.dart';
import '../../theme/luxe_tokens.dart';

/// Side A–Z index with a "repelling finger" bulge.
///
/// While a finger rests on the strip, the letters around it lift off the
/// column and wrap round the finger on a semicircle, as if pushed away by
/// an opposite gravity; letters further out stay in the column, so the
/// chain never breaks. Every letter rides its own under-damped spring, so
/// the bulge follows the finger with a soft, bouncy lag and snaps back with
/// a little overshoot on release. A loupe bubble shows the current letter.
///
/// Performance: one [Ticker] integrates all springs and repaints a single
/// [CustomPainter] (text layouts are cached), so a drag costs one paint per
/// frame and nothing rebuilds. The ticker stops once everything settles.
class LuxeAlphabetIndex extends StatefulWidget {
  const LuxeAlphabetIndex({
    required this.letters,
    required this.enabled,
    required this.onLetter,
    super.key,
    this.width = 30,
  });

  final List<String> letters;

  /// Letters that currently have content; others draw faint.
  final Set<String> enabled;

  /// Fires when the finger lands on a new letter (enabled or not).
  final ValueChanged<String> onLetter;
  final double width;

  @override
  State<LuxeAlphabetIndex> createState() => _LuxeAlphabetIndexState();
}

/// Repaint signal for the painter.
class _Repaint extends ChangeNotifier {
  void ping() => notifyListeners();
}

/// One under-damped spring per axis (x, y, scale).
class _LetterBody {
  double dx = 0, dy = 0, s = 1;
  double vx = 0, vy = 0, vs = 0;
}

class _LuxeAlphabetIndexState extends State<LuxeAlphabetIndex>
    with SingleTickerProviderStateMixin {
  // Spring tuning: letters bounce a little, the finger trace is near
  // critically damped (smooth but immediate), the bulge itself overshoots.
  static const _letterK = 560.0;
  static const _letterZeta = 0.52;
  static const _fingerK = 1400.0;
  static const _fingerZeta = 0.9;
  static const _bulgeK = 260.0;
  static const _bulgeZeta = 0.48;

  static const _maxSlot = 18.0;

  /// Radius of the arc the letters wrap around the finger on.
  static const _arcRadius = 58.0;

  late final Ticker _ticker = createTicker(_tick);
  final _repaint = _Repaint();
  late List<_LetterBody> _bodies = _makeBodies();

  Duration _last = Duration.zero;
  double? _fingerTarget; // raw finger y in local space, null when lifted
  double _finger = 0, _fingerV = 0;
  double _bulge = 0, _bulgeV = 0;
  int _active = -1;

  // Layout, refreshed on every build.
  double _height = 0;
  double get _slot => widget.letters.isEmpty
      ? _maxSlot
      : math.min(_maxSlot, _height / widget.letters.length);
  double get _top => (_height - _slot * widget.letters.length) / 2;
  double _restY(int i) => _top + _slot * (i + 0.5);

  List<_LetterBody> _makeBodies() => [
    for (var i = 0; i < widget.letters.length; i++) _LetterBody(),
  ];

  @override
  void didUpdateWidget(LuxeAlphabetIndex old) {
    super.didUpdateWidget(old);
    if (old.letters.length != widget.letters.length) _bodies = _makeBodies();
    if (!setEquals(old.enabled, widget.enabled)) _wake();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  bool get _still => MediaQuery.disableAnimationsOf(context);

  void _wake() {
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
    _repaint.ping();
  }

  // ---------------------------------------------------------------- input

  void _down(Offset local) {
    final first = _fingerTarget == null;
    _fingerTarget = local.dy;
    if (first) {
      _finger = local.dy;
      _fingerV = 0;
      AppHaptics.light();
    }
    _pick(local.dy);
    _wake();
  }

  void _up() {
    _fingerTarget = null;
    _active = -1;
    _wake();
  }

  void _pick(double y) {
    if (widget.letters.isEmpty) return;
    final i = ((y - _top) / _slot).floor().clamp(0, widget.letters.length - 1);
    if (i == _active) return;
    _active = i;
    final letter = widget.letters[i];
    if (widget.enabled.contains(letter)) {
      AppHaptics.selection();
    }
    widget.onLetter(letter);
  }

  // ---------------------------------------------------------------- physics

  static double _springStep(
    double x,
    double v,
    double target,
    double k,
    double zeta,
    double dt,
    void Function(double x, double v) out,
  ) {
    final c = 2 * zeta * math.sqrt(k);
    final a = k * (target - x) - c * v;
    final nv = v + a * dt;
    final nx = x + nv * dt;
    out(nx, nv);
    return (target - nx).abs() + nv.abs() * 0.02;
  }

  void _tick(Duration now) {
    var dt = _last == Duration.zero
        ? 1 / 60
        : (now - _last).inMicroseconds / 1e6;
    _last = now;
    dt = dt.clamp(1 / 240, 1 / 30);

    // Sub-step so stiff springs stay stable on slow frames.
    final steps = (dt / (1 / 240)).ceil();
    final h = dt / steps;
    var energy = 0.0;
    for (var s = 0; s < steps; s++) {
      energy = _step(h);
    }
    _repaint.ping();
    if (_fingerTarget == null && energy < 0.002) {
      _ticker.stop();
      _bulge = 0;
      _bulgeV = 0;
      for (final b in _bodies) {
        b
          ..dx = 0
          ..dy = 0
          ..s = 1
          ..vx = 0
          ..vy = 0
          ..vs = 0;
      }
      _repaint.ping();
    }
  }

  double _step(double dt) {
    var energy = 0.0;
    final touching = _fingerTarget != null;
    if (touching) {
      energy += _springStep(
        _finger,
        _fingerV,
        _fingerTarget!,
        _fingerK,
        _fingerZeta,
        dt,
        (x, v) {
          _finger = x;
          _fingerV = v;
        },
      );
    }
    energy += _springStep(
      _bulge,
      _bulgeV,
      touching && !_still ? 1 : 0,
      _bulgeK,
      _bulgeZeta,
      dt,
      (x, v) {
        _bulge = x;
        _bulgeV = v;
      },
    );

    final slot = _slot;
    const r = _arcRadius;
    // Rest spacing maps onto the arc so that ±r of column becomes a
    // half circle: the letters spread ~1.6× apart round the finger.
    const l = r / (math.pi / 2);
    for (var i = 0; i < _bodies.length; i++) {
      final b = _bodies[i];
      final rest = _restY(i);
      final dy = rest - _finger;
      final phi = dy / l;
      final phiC = phi.clamp(-math.pi / 2, math.pi / 2);
      // Flat top inside the arc, smooth hand-off back to the column.
      final edge = (phi.abs() - math.pi / 2 * 0.85) / (math.pi / 2 * 0.4);
      final w = edge <= 0 ? 1.0 : (edge >= 1 ? 0.0 : 1 - _smooth(edge));
      final arcX = -r * math.cos(phiC);
      final arcY = _finger + r * math.sin(phiC);
      final amt = _bulge * w;
      final tx = arcX * amt;
      final ty = (arcY - rest) * amt;
      final near = math.exp(-math.pow(dy / slot, 2) * 1.1);
      final ts = 1 + _bulge * (0.38 * w + 0.85 * near);

      energy += _springStep(b.dx, b.vx, tx, _letterK, _letterZeta, dt, (x, v) {
        b
          ..dx = x
          ..vx = v;
      });
      energy += _springStep(b.dy, b.vy, ty, _letterK, _letterZeta, dt, (x, v) {
        b
          ..dy = x
          ..vy = v;
      });
      energy += _springStep(b.s, b.vs, ts, _letterK, _letterZeta, dt, (x, v) {
        b
          ..s = x
          ..vs = v;
      });
    }
    return energy;
  }

  static double _smooth(double t) => t * t * (3 - 2 * t);

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        _height = constraints.maxHeight;
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) => _down(e.localPosition),
          onPointerMove: (e) {
            if (_fingerTarget == null) return;
            _fingerTarget = e.localPosition.dy.clamp(0.0, _height);
            _pick(_fingerTarget!);
            _wake();
          },
          onPointerUp: (_) => _up(),
          onPointerCancel: (_) => _up(),
          // Claims vertical drags so the sheet and list stay put.
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragStart: (_) {},
            onVerticalDragUpdate: (_) {},
            child: RepaintBoundary(
              child: CustomPaint(
                size: Size(widget.width, _height),
                painter: _IndexPainter(
                  state: this,
                  ink: p.inkMuted,
                  faint: p.inkFaint.withValues(alpha: 0.55),
                  accent: p.accent,
                  onAccent: p.onAccent,
                  thread: p.hairline,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _IndexPainter extends CustomPainter {
  _IndexPainter({
    required this.state,
    required this.ink,
    required this.faint,
    required this.accent,
    required this.onAccent,
    required this.thread,
  }) : super(repaint: state._repaint);

  final _LuxeAlphabetIndexState state;
  final Color ink;
  final Color faint;
  final Color accent;
  final Color onAccent;
  final Color thread;

  static final _cache = <String, TextPainter>{};

  static TextPainter _text(String s, Color c, double size, FontWeight w) {
    final key = '$s|${c.toARGB32()}|$size|${w.value}';
    return _cache.putIfAbsent(key, () {
      if (_cache.length > 400) _cache.clear();
      return TextPainter(
        text: TextSpan(
          text: s,
          style: LuxeType.label(c, size: size).copyWith(fontWeight: w),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = state;
    final letters = s.widget.letters;
    if (letters.isEmpty) return;
    final cx = size.width / 2;
    final bulge = s._bulge.clamp(0.0, 1.2);

    final centres = [
      for (var i = 0; i < letters.length; i++)
        Offset(cx + s._bodies[i].dx, s._restY(i) + s._bodies[i].dy),
    ];

    // The thread: a hairline through every letter, so the chain reads as
    // one strand as it bends round the finger.
    if (bulge > 0.02) {
      final path = Path()..moveTo(centres.first.dx, centres.first.dy);
      for (var i = 1; i < centres.length; i++) {
        final mid = Offset.lerp(centres[i - 1], centres[i], 0.5)!;
        path.quadraticBezierTo(
          centres[i - 1].dx,
          centres[i - 1].dy,
          mid.dx,
          mid.dy,
        );
      }
      path.lineTo(centres.last.dx, centres.last.dy);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = thread.withValues(alpha: (bulge * 0.9).clamp(0.0, 1.0)),
      );
    }

    for (var i = 0; i < letters.length; i++) {
      final letter = letters[i];
      final on = s.widget.enabled.contains(letter);
      final active = i == s._active;
      final color = active && on ? accent : (on ? ink : faint);
      final tp = _text(
        letter,
        color,
        10.5,
        active ? FontWeight.w700 : FontWeight.w600,
      );
      final scale = s._bodies[i].s;
      canvas
        ..save()
        ..translate(centres[i].dx, centres[i].dy)
        ..scale(scale);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    // Loupe bubble left of the arc with the current letter.
    if (bulge > 0.02 && s._active >= 0) {
      final letter = letters[s._active];
      final on = s.widget.enabled.contains(letter);
      final r = 24.0 * bulge.clamp(0.0, 1.1);
      final y = s._finger.clamp(r, size.height - r);
      final c = Offset(cx - _LuxeAlphabetIndexState._arcRadius - 50, y);
      canvas.drawCircle(
        c.translate(0, 3),
        r,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.18 * bulge.clamp(0, 1))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(c, r, Paint()..color = on ? accent : faint);
      final tp = _text(letter, onAccent, 22, FontWeight.w600);
      final k = r / 24;
      canvas
        ..save()
        ..translate(c.dx, c.dy)
        ..scale(k);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_IndexPainter old) =>
      old.state != state ||
      old.ink != ink ||
      old.faint != faint ||
      old.accent != accent ||
      old.thread != thread;
}
