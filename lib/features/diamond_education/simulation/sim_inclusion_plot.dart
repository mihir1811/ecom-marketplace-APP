import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/painting.dart';

import '../domain/diamond_grades.dart';
import 'sim_inclusions.dart';
import 'sim_renderer.dart';

/// Where an inclusion landed on screen in the last frame, for its label.
class SimInclusionAnchor {
  SimInclusionAnchor(this.inclusion, this.at, this.radius, this.depth);

  final SimInclusion inclusion;

  /// Its centre, logical pixels.
  final Offset at;

  /// Its symbol's radius on screen, logical pixels.
  final double radius;

  /// World depth toward the viewer: positive on the near half.
  final double depth;
}

/// Plots clarity characteristics in the line drawing with GIA's key to
/// symbols, as a grading report's diagram does: red for internal
/// characteristics, green for external ones, both where a feature is
/// partly each (a cavity, a knot, an indented natural). Each symbol sits
/// where the inclusion is, in the same perspective as [SimWireRenderer],
/// sized after it and turned with it; those on the far side are fainter.
class SimInclusionPlot {
  /// GIA's red, brightened to read on the dark stage.
  static const red = Color(0xFFFF5252);

  /// GIA's green (a teal on the report), brightened likewise.
  static const green = Color(0xFF2CC9A0);

  /// GIA draws extra facets in black; on the dark stage, a light ink.
  static const ink = Color(0xFFD5D9DF);

  /// The key colour of [type]: red inside, green on the surface.
  static Color colorOf(InclusionType type) => type.isExternal ? green : red;

  /// Anchors from the last [paint], in the order inclusions were given.
  final List<SimInclusionAnchor> anchors = [];

  static const _d0 = SimRenderer.eyeDistance;

  /// Plots [inclusions] for model → world rotation [rot] (row major, as
  /// [SimView.rotationInto] fills it), [scale] logical pixels per model
  /// unit at the stone's centre, centred at [centre].
  void paint(
    Canvas canvas,
    List<SimInclusion> inclusions, {
    required Float64List rot,
    required double scale,
    required Offset centre,
    double opacity = 1,
  }) {
    anchors.clear();
    if (inclusions.isEmpty || scale <= 0) return;
    Offset project(double x, double y, double z) {
      final wx = rot[0] * x + rot[1] * y + rot[2] * z;
      final wy = rot[3] * x + rot[4] * y + rot[5] * z;
      final wz = rot[6] * x + rot[7] * y + rot[8] * z;
      final k = scale * _d0 / (_d0 - wz);
      return Offset(centre.dx + wx * k, centre.dy - wy * k);
    }

    final order = <(int, double)>[];
    for (final (i, c) in inclusions.indexed) {
      final wz = rot[6] * c.x + rot[7] * c.y + rot[8] * c.z;
      final k = scale * _d0 / (_d0 - wz);
      final at = project(c.x, c.y, c.z);
      // Along its axis on screen; a fracture's trace lies square to its
      // plane's normal.
      final a = project(
        c.x - c.ax * c.size,
        c.y - c.ay * c.size,
        c.z - c.az * c.size,
      );
      final b = project(
        c.x + c.ax * c.size,
        c.y + c.ay * c.size,
        c.z + c.az * c.size,
      );
      var angle = math.atan2(b.dy - a.dy, b.dx - a.dx);
      final type = c.kind.type.plotAs;
      if (_planar(c.kind)) angle += math.pi / 2;
      // Carets at the girdle point out of the stone.
      if (_pointsOut(type)) {
        angle = math.atan2(at.dy - centre.dy, at.dx - centre.dx) + math.pi / 2;
      }
      final r = (c.size * c.kind.reach * k * 0.85).clamp(6.0, 30.0);
      anchors.add(SimInclusionAnchor(c, at, r, wz));
      order.add((i, wz));
      _items[i] = (type, at, r, angle);
    }
    if (opacity <= 0.001) return;
    // Far first, so the nearer ones lie over them.
    order.sort((p, q) => p.$2.compareTo(q.$2));
    for (final (i, wz) in order) {
      // A bleached crystal is plotted as part of its drill hole.
      if (!inclusions[i].kind.labelled) continue;
      final (type, at, r, angle) = _items[i]!;
      drawSymbol(
        canvas,
        type,
        at,
        r,
        angle: angle,
        alpha: opacity * (wz >= 0 ? 1 : 0.55),
      );
    }
    _items.clear();
  }

  final Map<int, (InclusionType, Offset, double, double)> _items = {};

  /// Kinds whose axis is a plane's normal rather than their run.
  static bool _planar(SimInclusionKind k) => switch (k) {
    SimInclusionKind.feather ||
    SimInclusionKind.openFeather ||
    SimInclusionKind.filledFeather ||
    SimInclusionKind.cleavage ||
    SimInclusionKind.graining ||
    SimInclusionKind.cloud ||
    SimInclusionKind.burnMark => true,
    _ => false,
  };

  static bool _pointsOut(InclusionType t) => switch (t) {
    InclusionType.chip ||
    InclusionType.natural ||
    InclusionType.nick ||
    InclusionType.extraFacet => true,
    _ => false,
  };

  static final Paint _stroke = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  static final Paint _fill = Paint()..isAntiAlias = true;

  /// Draws [type]'s GIA key symbol centred at [at], [r] logical pixels
  /// to its tips, turned by [angle] (radians, clockwise on screen).
  static void drawSymbol(
    Canvas canvas,
    InclusionType type,
    Offset at,
    double r, {
    double angle = 0,
    double alpha = 1,
  }) {
    if (alpha <= 0.001) return;
    final t = type.plotAs;
    final w = (r * 0.11).clamp(1.3, 2.4);
    Paint line(Color c, [double scale = 1]) => _stroke
      ..color = c.withValues(alpha: c.a * alpha)
      ..strokeWidth = w * scale;
    Paint dot(Color c) => _fill..color = c.withValues(alpha: c.a * alpha);
    final main = colorOf(t);

    canvas
      ..save()
      ..translate(at.dx, at.dy);
    // Point-like symbols stay upright, as on a report.
    if (!_upright(t)) canvas.rotate(angle);
    Offset p(double x, double y) => Offset(x * r, y * r);

    switch (t) {
      case InclusionType.bruise:
        final s = line(main);
        canvas
          ..drawLine(p(-0.45, -0.45), p(0.45, 0.45), s)
          ..drawLine(p(-0.45, 0.45), p(0.45, -0.45), s);
      case InclusionType.cavity:
        final oval = Rect.fromCenter(
          center: Offset.zero,
          width: 1.9 * r,
          height: 1.35 * r,
        );
        canvas
          ..save()
          ..clipPath(Path()..addOval(oval));
        final h = line(red, 0.75);
        for (var x = -1.6; x <= 1.0; x += 0.32) {
          canvas.drawLine(p(x, 0.8), p(x + 0.8, -0.8), h);
        }
        canvas
          ..restore()
          ..drawOval(oval, line(green));
      case InclusionType.chip:
        canvas.drawPath(
          Path()
            ..moveTo(-0.75 * r, 0.4 * r)
            ..lineTo(-0.1 * r, -0.45 * r)
            ..lineTo(0.55 * r, 0.4 * r),
          line(main),
        );
      case InclusionType.cleavage:
        final s = line(main);
        canvas
          ..drawLine(p(-0.7, 0.25), p(0.25, -0.55), s)
          ..drawLine(p(-0.25, 0.55), p(0.7, -0.25), s);
      case InclusionType.cloud:
        final s = line(main, 0.9);
        for (var i = 0; i < 16; i++) {
          final a = i / 16 * 2 * math.pi;
          final q = p(math.cos(a), 0.62 * math.sin(a));
          canvas.drawCircle(q, s.strokeWidth * 0.62, dot(main));
        }
      case InclusionType.crystal:
        canvas.drawPath(
          Path()
            ..moveTo(-0.62 * r, 0.05 * r)
            ..cubicTo(-0.7 * r, -0.5 * r, 0.2 * r, -0.62 * r, 0.6 * r, -0.2 * r)
            ..cubicTo(0.9 * r, 0.15 * r, 0.45 * r, 0.6 * r, -0.05 * r, 0.52 * r)
            ..cubicTo(
              -0.4 * r,
              0.48 * r,
              -0.58 * r,
              0.32 * r,
              -0.62 * r,
              0.05 * r,
            ),
          line(main),
        );
      case InclusionType.feather:
        canvas.drawPath(
          Path()
            ..moveTo(-r, 0.45 * r)
            ..cubicTo(
              -0.45 * r,
              0.45 * r,
              -0.25 * r,
              -0.3 * r,
              0.25 * r,
              -0.4 * r,
            )
            ..quadraticBezierTo(0.7 * r, -0.5 * r, r, -0.38 * r),
          line(main),
        );
      case InclusionType.grainCenter:
        final s = line(main);
        canvas
          ..drawLine(p(-0.85, 0), p(0.85, 0), s)
          ..drawLine(p(-0.3, -0.4), p(0.3, 0.4), s)
          ..drawLine(p(-0.3, 0.4), p(0.3, -0.4), s);
      case InclusionType.indentedNatural:
        canvas
          ..drawPath(_blob(r), line(red))
          ..drawPath(_blob(r, 0.45), line(green, 0.85));
      case InclusionType.knot:
        canvas
          ..drawPath(_blob(r), line(green))
          ..drawPath(_blob(r, 0.45), line(red, 0.85));
      case InclusionType.graining || InclusionType.surfaceGraining:
        _dashed(canvas, r, line(main, 0.9));
      case InclusionType.laserDrillHole:
        canvas
          ..drawCircle(Offset.zero, 0.42 * r, line(green))
          ..drawCircle(Offset.zero, w * 0.75, dot(green));
      case InclusionType.needle:
        canvas.drawLine(p(-0.6, 0), p(0.6, 0), line(main));
      case InclusionType.pinpoint || InclusionType.pit:
        canvas.drawCircle(Offset.zero, w * 1.05, dot(main));
      case InclusionType.twinningWisp:
        final s = line(main);
        canvas
          ..drawPath(
            Path()
              ..moveTo(-0.95 * r, 0.25 * r)
              ..quadraticBezierTo(0.1 * r, 0.3 * r, 0.85 * r, -0.4 * r),
            s,
          )
          ..drawLine(p(-0.72, -0.05), p(-0.58, 0.6), s)
          ..drawLine(p(0.45, -0.6), p(0.85, 0.0), s);
      case InclusionType.abrasion:
        final s = line(main, 0.75);
        for (var x = -0.85; x <= 0.86; x += 0.17) {
          canvas.drawLine(p(x - 0.08, 0.16), p(x + 0.08, -0.16), s);
        }
      case InclusionType.natural:
        canvas.drawPath(
          Path()
            ..moveTo(-0.85 * r, 0.42 * r)
            ..lineTo(0, -0.42 * r)
            ..lineTo(0.85 * r, 0.42 * r),
          line(main),
        );
      case InclusionType.nick:
        canvas.drawPath(
          Path()
            ..moveTo(-0.35 * r, -0.4 * r)
            ..lineTo(0, 0.35 * r)
            ..lineTo(0.35 * r, -0.4 * r),
          line(main),
        );
      case InclusionType.polishLines:
        final s = line(main, 0.85);
        for (var i = -2; i <= 2; i++) {
          final x = i * 0.3;
          canvas.drawLine(p(x - 0.22, 0.5), p(x + 0.22, -0.5), s);
        }
      case InclusionType.burnMark:
        final s = line(main, 0.85);
        final path = Path()..moveTo(-0.9 * r, 0.3 * r);
        for (var i = 0; i < 3; i++) {
          final x = -0.6 + i * 0.6;
          path
            ..quadraticBezierTo((x - 0.3) * r, -0.5 * r, x * r, -0.45 * r)
            ..quadraticBezierTo((x + 0.32) * r, -0.35 * r, (x + 0.05) * r, 0.0)
            ..quadraticBezierTo(
              (x - 0.2) * r,
              0.1 * r,
              (x + 0.3) * r,
              0.25 * r,
            );
        }
        canvas.drawPath(path, s);
      case InclusionType.scratch:
        canvas.drawPath(
          Path()
            ..moveTo(-0.85 * r, 0.12 * r)
            ..quadraticBezierTo(-0.2 * r, 0.05 * r, 0.05 * r, 0.25 * r)
            ..quadraticBezierTo(0.35 * r, -0.05 * r, 0.85 * r, -0.25 * r),
          line(main),
        );
      default:
        // Extra facet: a tall, narrow caret.
        canvas.drawPath(
          Path()
            ..moveTo(-0.38 * r, 0.75 * r)
            ..lineTo(0, -0.75 * r)
            ..lineTo(0.38 * r, 0.75 * r),
          line(ink),
        );
    }
    canvas.restore();
  }

  static bool _upright(InclusionType t) => switch (t) {
    InclusionType.bruise ||
    InclusionType.pinpoint ||
    InclusionType.pit ||
    InclusionType.laserDrillHole ||
    InclusionType.knot ||
    InclusionType.indentedNatural => true,
    _ => false,
  };

  /// An irregular pentagon, as GIA draws a knot's or an indented
  /// natural's outline; [k] shrinks it for the inner one.
  static Path _blob(double r, [double k = 1]) {
    const pts = [
      (-0.45, -0.7),
      (0.3, -0.85),
      (0.6, -0.05),
      (0.2, 0.8),
      (-0.6, 0.15),
    ];
    final path = Path()..moveTo(pts[0].$1 * r * k, pts[0].$2 * r * k);
    for (final q in pts.skip(1)) {
      path.lineTo(q.$1 * r * k, q.$2 * r * k);
    }
    return path..close();
  }

  /// A gently curved dashed line, as GIA draws graining.
  static void _dashed(Canvas canvas, double r, Paint s) {
    const n = 5;
    for (var i = 0; i < n; i++) {
      final a = -1 + i * 2 / n, b = a + 1.2 / n;
      double y(double x) => 0.28 * x * x - 0.12 - 0.12 * x;
      canvas.drawLine(Offset(a * r, y(a) * r), Offset(b * r, y(b) * r), s);
    }
  }
}
