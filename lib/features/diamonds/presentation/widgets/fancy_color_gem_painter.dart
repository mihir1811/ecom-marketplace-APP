import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Top-down round brilliant drawn facet by facet in a fancy colour.
///
/// Each crown facet is shaded by how much it faces a light from the top
/// left, so the stone reads as cut and lit rather than a flat swatch. Use
/// [rainbow] for "Multi / Other" (hue turns around the stone) and
/// [splitTone] with two [fillColors] for bi-colour stones.
class FancyColorGemPainter extends CustomPainter {
  const FancyColorGemPainter({
    required this.fillColors,
    this.rainbow = false,
    this.splitTone = false,
    this.sparkle = 1,
  });

  final List<Color> fillColors;
  final bool rainbow;
  final bool splitTone;

  /// 0–1 strength of the white glints (raised while selected).
  final double sparkle;

  static const _light = -3 * math.pi / 4; // top-left

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 * 0.94;
    final rt = r * 0.52; // table
    final rs = r * 0.80; // star points

    Offset at(double a, double radius) =>
        c + Offset(math.cos(a), math.sin(a)) * radius;

    // Soft drop shadow under the girdle.
    canvas.drawCircle(
      c.translate(0, r * 0.08),
      r,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.12),
    );

    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.5, r * 0.022)
      ..color = Colors.white.withValues(alpha: 0.32);

    void facet(List<Offset> pts, double lift) {
      final path = Path()..addPolygon(pts, true);
      final centre = pts.reduce((a, b) => a + b) / pts.length.toDouble();
      final dir = math.atan2(centre.dy - c.dy, centre.dx - c.dx);
      final facing = math.cos(dir - _light); // -1 … 1
      final base = _hueAt(centre, c, dir);
      final shade = _shift(base, facing * 0.16 + lift);
      canvas.drawPath(path, Paint()..color = shade);
      canvas.drawPath(path, edge);
    }

    const n = 8;
    for (var i = 0; i < n; i++) {
      final a0 = i * 2 * math.pi / n;
      final a1 = (i + 1) * 2 * math.pi / n;
      const half = math.pi / n;
      final t0 = at(a0, rt);
      final t1 = at(a1, rt);
      final s0 = at(a0 + half, rs);
      final sPrev = at(a0 - half, rs);
      final g0 = at(a0, r);
      final gMid = at(a0 + half, r);
      final g1 = at(a1, r);
      // Upper girdle facets, bezel kite, then star facet on top.
      facet([s0, g0, gMid], -0.10);
      facet([s0, gMid, g1], -0.04);
      facet([t0, sPrev, g0, s0], 0.0);
      facet([t0, t1, s0], 0.08);
    }

    // Table with a bright, slightly off-centre glow.
    final table = Path()
      ..addPolygon([
        for (var i = 0; i < n; i++) at(i * 2 * math.pi / n, rt),
      ], true);
    final tableBase = _hueAt(c, c, 0);
    canvas.drawPath(
      table,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 0.95,
          colors: [_shift(tableBase, 0.26), _shift(tableBase, 0.04)],
        ).createShader(Rect.fromCircle(center: c, radius: rt)),
    );
    canvas.drawPath(table, edge);

    // Girdle rim.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, r * 0.04)
        ..color = _shift(_hueAt(c, c, math.pi / 4), -0.22),
    );

    // Glints.
    if (sparkle > 0) {
      _glint(canvas, at(_light, r * 0.42), r * 0.26 * sparkle);
      _glint(canvas, at(_light + 0.9, r * 0.66), r * 0.14 * sparkle);
      _glint(canvas, at(math.pi / 5, r * 0.3), r * 0.09 * sparkle);
    }
  }

  Color _hueAt(Offset p, Offset c, double angle) {
    if (rainbow) {
      final h = ((angle + math.pi) / (2 * math.pi) * 360) % 360;
      return HSLColor.fromAHSL(1, h, 0.78, 0.55).toColor();
    }
    if (splitTone && fillColors.length >= 2) {
      // Diagonal split: top-left one colour, bottom-right the other.
      return (p.dx - c.dx) + (p.dy - c.dy) < 0 ? fillColors[0] : fillColors[1];
    }
    return fillColors.first;
  }

  static Color _shift(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.04, 0.96))
        .toColor();
  }

  static void _glint(Canvas canvas, Offset o, double s) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.92);
    final path = Path()
      ..moveTo(o.dx, o.dy - s)
      ..quadraticBezierTo(o.dx, o.dy, o.dx + s, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + s)
      ..quadraticBezierTo(o.dx, o.dy, o.dx - s, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - s)
      ..close();
    canvas.drawPath(path, p);
    canvas.drawCircle(
      o,
      s * 0.55,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.5),
    );
  }

  @override
  bool shouldRepaint(covariant FancyColorGemPainter old) =>
      old.rainbow != rainbow ||
      old.splitTone != splitTone ||
      old.sparkle != sparkle ||
      !_sameColors(old.fillColors, fillColors);

  static bool _sameColors(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
