import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import '../../../domain/average_hand.dart';

/// Paints [AverageHand] as a smooth, deep-toned hand: the back of a left
/// hand, fingers spread, nails, soft shading, a warm rim where the skin
/// turns away and a faint glow parting it from the dark stage. Dark so
/// white stones on the fingers stand out. Drawn in millimetres around the
/// ring finger's ring seat, at [origin] and [pxPerMm].
class SimHandPainter extends CustomPainter {
  SimHandPainter({required this.origin, required this.pxPerMm});

  final Offset origin;
  final double pxPerMm;

  static Offset _o(HandPoint p) => Offset(p.x, p.y);

  static final Path _silhouette = () {
    final p = [for (final q in AverageHand.outline) _o(q)];
    final path = Path()..moveTo(p[0].dx, p[0].dy);
    final n = p.length;
    // Catmull–Rom through the traced points.
    for (var i = 0; i < n; i++) {
      final p0 = p[(i - 1 + n) % n], p1 = p[i];
      final p2 = p[(i + 1) % n], p3 = p[(i + 2) % n];
      final c1 = p1 + (p2 - p0) / 6, c2 = p2 - (p3 - p1) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    return path..close();
  }();

  static final _digits = [
    AverageHand.little,
    AverageHand.ring,
    AverageHand.middle,
    AverageHand.index,
    AverageHand.thumb,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final px = pxPerMm;
    canvas
      ..save()
      ..translate(origin.dx, origin.dy)
      ..scale(px)
      // A faint warm glow parts the hand from the dark stage.
      ..drawPath(
        _silhouette,
        Paint()
          ..color = const Color(0x24FFE3CF)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 28 / px),
      )
      // Deep skin, a little lighter over the back of the hand.
      ..drawPath(
        _silhouette,
        Paint()
          ..shader = ui.Gradient.radial(
            const Offset(8, 22),
            95,
            const [Color(0xFF5A3D2E), Color(0xFF47301F), Color(0xFF2E1F16)],
            const [0, 0.55, 1],
          ),
      )
      ..save()
      ..clipPath(_silhouette)
      // Shade where the skin turns away, then a warm rim light on it.
      ..drawPath(
        _silhouette,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8 / px
          ..color = const Color(0x8C170F0A)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 / px),
      )
      ..drawPath(
        _silhouette,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4 / px
          ..color = const Color(0x40F2C7A6)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1.2 / px),
      );
    for (final d in _digits) {
      _nail(canvas, d, px);
    }
    canvas
      ..restore()
      ..drawPath(
        _silhouette,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1 / px
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0x66C9A184),
      )
      ..restore();
  }

  /// A nail just short of [d]'s tip, along its direction there.
  static void _nail(Canvas canvas, HandDigit d, double px) {
    final w = d.widthAt(d.length * 0.86) * 0.78;
    final h = w * 1.05;
    final a = d.at(d.length - h / 2 - 1.1);
    final b = d.at(d.length - h / 2 - 0.1);
    final angle = math.atan2(b.x - a.x, -(b.y - a.y));
    final nail = RRect.fromRectAndCorners(
      Rect.fromCenter(center: Offset.zero, width: w, height: h),
      topLeft: Radius.circular(w * 0.42),
      topRight: Radius.circular(w * 0.42),
      bottomLeft: Radius.circular(w * 0.22),
      bottomRight: Radius.circular(w * 0.22),
    );
    canvas
      ..save()
      ..translate(a.x, a.y)
      ..rotate(angle)
      ..drawRRect(
        nail,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, -h / 2),
            Offset(0, h / 2),
            const [Color(0xFF8E6C5C), Color(0xFF6E4E3F)],
          ),
      )
      ..drawRRect(
        nail,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1 / px
          ..color = const Color(0xFF24170F),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(covariant SimHandPainter old) =>
      old.origin != origin || old.pxPerMm != pxPerMm;
}
