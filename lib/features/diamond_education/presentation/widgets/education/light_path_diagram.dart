import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/theme/luxe_tokens.dart';

/// Profile of a round brilliant with real light paths traced through it
/// in 2D: rays fall straight into the table, reflect wherever they meet a
/// facet beyond diamond's critical angle (24.4°) and escape where they
/// don't. Light leaving through the crown returns to the eye (accent);
/// light leaving through the pavilion is lost (caution).
class LightPathDiagram extends StatelessWidget {
  const LightPathDiagram({
    required this.pavilionAngle,
    required this.label,
    this.highlight = false,
    super.key,
  });

  final double pavilionAngle;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Semantics(
      image: true,
      label: label,
      excludeSemantics: true,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: CustomPaint(
              painter: _LightPathPainter(
                pavilionAngle: pavilionAngle,
                outline: highlight ? p.accent : p.inkMuted,
                fill: p.accent.withValues(alpha: highlight ? 0.12 : 0.05),
                kept: p.accent,
                lost: p.caution,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: LuxeType.label(highlight ? p.ink : p.inkMuted, size: 12),
          ),
        ],
      ),
    );
  }
}

class _LightPathPainter extends CustomPainter {
  _LightPathPainter({
    required this.pavilionAngle,
    required this.outline,
    required this.fill,
    required this.kept,
    required this.lost,
  });

  final double pavilionAngle;
  final Color outline, fill, kept, lost;

  static const _ior = 2.42;

  @override
  void paint(Canvas canvas, Size size) {
    // Profile in half-width units, y up.
    const t = 0.57, girdle = 0.03;
    final crown = math.tan(34.5 * math.pi / 180) * (1 - t);
    final pavilion = math.tan(pavilionAngle * math.pi / 180);
    final pts = <Offset>[
      Offset(-t, girdle + crown),
      Offset(t, girdle + crown),
      const Offset(1, girdle),
      const Offset(1, -girdle),
      Offset(0, -girdle - pavilion),
      const Offset(-1, -girdle),
      const Offset(-1, girdle),
    ];
    final top = girdle + crown, bottom = -girdle - pavilion;
    final scale = math.min(
      size.width / 2.6,
      size.height / (top - bottom + 0.9),
    );
    final origin = Offset(
      size.width / 2,
      size.height / 2 + (top + bottom) / 2 * scale,
    );
    Offset screen(Offset q) =>
        Offset(origin.dx + q.dx * scale, origin.dy - q.dy * scale);

    final path = Path()..addPolygon(pts.map(screen).toList(), true);
    canvas
      ..drawPath(path, Paint()..color = fill)
      ..drawPath(
        path,
        Paint()
          ..color = outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );

    final critical = math.asin(1 / _ior);
    for (final x in const [-0.42, -0.2, 0.2, 0.42]) {
      var p = Offset(x, top + 0.45);
      var d = const Offset(0, -1);
      final segs = <Offset>[p];
      // Enters the table head on: no bend.
      p = Offset(x, top);
      segs.add(p);
      var escaped = false, returned = false;
      for (var bounce = 0; bounce < 6; bounce++) {
        // Nearest edge ahead.
        var best = double.infinity;
        var normal = Offset.zero;
        for (var i = 0; i < pts.length; i++) {
          final a = pts[i], b = pts[(i + 1) % pts.length];
          final e = b - a;
          final den = d.dx * e.dy - d.dy * e.dx;
          if (den.abs() < 1e-9) continue;
          final w = a - p;
          final s = (w.dx * e.dy - w.dy * e.dx) / den;
          final u = (w.dx * d.dy - w.dy * d.dx) / den;
          if (s > 1e-6 && u >= -1e-6 && u <= 1 + 1e-6 && s < best) {
            best = s;
            // The outline runs clockwise (y up): outward is e turned left.
            final n = Offset(-e.dy, e.dx);
            normal = n / n.distance;
          }
        }
        if (!best.isFinite) break;
        p = p + d * best;
        segs.add(p);
        final cosI = d.dx * normal.dx + d.dy * normal.dy;
        final angle = math.acos(cosI.clamp(-1.0, 1.0));
        if (angle > critical) {
          d = d - normal * (2 * cosI);
          continue;
        }
        // Escapes: refract out.
        final sinT = _ior * math.sin(angle);
        final tangent = d - normal * cosI;
        final tl = tangent.distance;
        final out = tl < 1e-9
            ? normal
            : normal * math.sqrt(1 - sinT * sinT) + tangent / tl * sinT;
        segs.add(p + out * 0.55);
        escaped = true;
        returned = normal.dy > 0.2;
        break;
      }
      final color = escaped && returned ? kept : lost;
      final ray = Paint()
        ..color = color.withValues(alpha: 0.9)
        ..strokeWidth = 1.3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final line = Path()..moveTo(screen(segs.first).dx, screen(segs.first).dy);
      for (final q in segs.skip(1)) {
        line.lineTo(screen(q).dx, screen(q).dy);
      }
      canvas.drawPath(line, ray);
      if (escaped) {
        canvas.drawCircle(screen(segs.last), 2.2, Paint()..color = color);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LightPathPainter old) =>
      old.pavilionAngle != pavilionAngle ||
      old.outline != outline ||
      old.kept != kept ||
      old.lost != lost;
}
