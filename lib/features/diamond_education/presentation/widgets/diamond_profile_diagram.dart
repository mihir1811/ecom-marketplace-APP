import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/luxe_tokens.dart';
import '../../domain/diamond_proportions.dart';
import '../../domain/diamond_shape.dart';

/// Labels drawn on a [DiamondProfileDiagram]; null hides that label.
class DiamondProfileLabels {
  const DiamondProfileLabels({
    this.table,
    this.crown,
    this.girdle,
    this.pavilion,
    this.culet,
    this.depth,
    this.crownAngle,
    this.pavilionAngle,
  });

  final String? table, crown, girdle, pavilion, culet, depth;
  final String? crownAngle, pavilionAngle;
}

/// Side profile of a stone cut to [proportions], to scale, with optional
/// labels for its parts and measurements. Cheap enough to redraw on every
/// slider tick.
class DiamondProfileDiagram extends StatelessWidget {
  const DiamondProfileDiagram({
    required this.proportions,
    this.family = SimCutFamily.brilliant,
    this.labels = const DiamondProfileLabels(),
    this.height = 150,
    super.key,
  });

  final DiamondProportions proportions;
  final SimCutFamily family;
  final DiamondProfileLabels labels;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Semantics(
      image: true,
      label: [
        labels.table,
        labels.crownAngle,
        labels.pavilionAngle,
        labels.depth,
      ].whereType<String>().join(', '),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _ProfilePainter(
            proportions: proportions,
            family: family,
            labels: labels,
            ink: p.ink,
            muted: p.inkMuted,
            faint: p.hairline,
            accent: p.accent,
            textStyle: LuxeType.label(p.inkMuted, size: 11),
          ),
        ),
      ),
    );
  }
}

class _ProfilePainter extends CustomPainter {
  _ProfilePainter({
    required this.proportions,
    required this.family,
    required this.labels,
    required this.ink,
    required this.muted,
    required this.faint,
    required this.accent,
    required this.textStyle,
  });

  final DiamondProportions proportions;
  final SimCutFamily family;
  final DiamondProfileLabels labels;
  final Color ink, muted, faint, accent;
  final TextStyle textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final pr = proportions;
    final t = pr.tablePct / 100;
    final crown = pr.crownHeightPct / 50; // half-width units
    final pavilion = pr.pavilionDepthPct(family) / 50;
    final girdle = pr.girdle.percent / 50;
    final culet = pr.culetScale;
    final total = crown + girdle + pavilion;

    // Leave room for labels on both sides and above.
    final hasSide = labels.crown != null || labels.depth != null;
    final side = hasSide ? 78.0 : 18.0;
    final top = labels.table != null ? 22.0 : 6.0;
    final bottom = labels.culet != null ? 18.0 : 6.0;
    final scale = math.min(
      (size.width - side * 2) / 2,
      (size.height - top - bottom) / total,
    );
    final cx = size.width / 2;
    final y0 = top + (size.height - top - bottom - total * scale) / 2;
    Offset at(double x, double y) => Offset(cx + x * scale, y0 + y * scale);

    final yTable = 0.0, yGirdleTop = crown, yGirdleBottom = crown + girdle;
    final yCulet = total;
    final outline = Path()
      ..moveTo(at(-t, yTable).dx, at(-t, yTable).dy)
      ..lineTo(at(t, yTable).dx, at(t, yTable).dy)
      ..lineTo(at(1, yGirdleTop).dx, at(1, yGirdleTop).dy)
      ..lineTo(at(1, yGirdleBottom).dx, at(1, yGirdleBottom).dy)
      ..lineTo(at(culet, yCulet).dx, at(culet, yCulet).dy)
      ..lineTo(at(-culet, yCulet).dx, at(-culet, yCulet).dy)
      ..lineTo(at(-1, yGirdleBottom).dx, at(-1, yGirdleBottom).dy)
      ..lineTo(at(-1, yGirdleTop).dx, at(-1, yGirdleTop).dy)
      ..close();

    canvas.drawPath(
      outline,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: 0.16),
            accent.withValues(alpha: 0.03),
          ],
        ).createShader(Offset.zero & size),
    );
    // Facet lines inside the profile, as a jeweller's diagram shows them.
    final facet = Paint()
      ..color = faint
      ..strokeWidth = 0.8;
    canvas
      ..drawLine(at(-t, yTable), at(0, yCulet), facet)
      ..drawLine(at(t, yTable), at(0, yCulet), facet)
      ..drawLine(at(-1, yGirdleTop), at(1, yGirdleTop), facet)
      ..drawLine(at(-1, yGirdleBottom), at(1, yGirdleBottom), facet);
    canvas.drawPath(
      outline,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeJoin = StrokeJoin.round,
    );

    final guide = Paint()
      ..color = muted.withValues(alpha: 0.6)
      ..strokeWidth = 0.8;

    void label(
      String text,
      Offset anchor, {
      Alignment align = Alignment.center,
    }) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        textAlign: TextAlign.center,
      )..layout(maxWidth: side + 40);
      final dx = anchor.dx - tp.width * (align.x + 1) / 2;
      final dy = anchor.dy - tp.height * (align.y + 1) / 2;
      tp.paint(canvas, Offset(dx, dy));
    }

    if (labels.table != null) {
      final a = at(-t, yTable), b = at(t, yTable);
      canvas
        ..drawLine(a.translate(0, -6), b.translate(0, -6), guide)
        ..drawLine(a.translate(0, -9), a.translate(0, -3), guide)
        ..drawLine(b.translate(0, -9), b.translate(0, -3), guide);
      label(labels.table!, Offset(cx, a.dy - 8), align: Alignment.bottomCenter);
    }

    // Angle arcs at the right girdle edge.
    void arc(double fromY, double toX, double toY, String text, bool up) {
      final o = at(1, fromY);
      final dir = at(toX, toY) - o;
      final angle = math.atan2(dir.dy, dir.dx);
      const r = 26.0;
      const start = math.pi;
      final sweep = angle - start + (angle < 0 ? 2 * math.pi : 0);
      canvas.drawArc(
        Rect.fromCircle(center: o, radius: r),
        start,
        sweep,
        false,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1,
      );
      label(
        text,
        o.translate(-r - 6, up ? -r * 0.55 : r * 0.55),
        align: Alignment.centerRight,
      );
    }

    if (labels.crownAngle != null) {
      arc(yGirdleTop, t, yTable, labels.crownAngle!, true);
    }
    if (labels.pavilionAngle != null) {
      arc(yGirdleBottom, culet, yCulet, labels.pavilionAngle!, false);
    }

    // Part names on the left, depth on the right.
    final left = at(-1, 0).dx - 10;
    if (labels.crown != null) {
      label(
        labels.crown!,
        Offset(left, at(0, crown / 2).dy),
        align: Alignment.centerRight,
      );
    }
    if (labels.girdle != null) {
      final y = at(0, (yGirdleTop + yGirdleBottom) / 2).dy;
      canvas.drawLine(Offset(left + 2, y), Offset(at(-1, 0).dx - 2, y), guide);
      label(labels.girdle!, Offset(left - 2, y), align: Alignment.centerRight);
    }
    if (labels.pavilion != null) {
      label(
        labels.pavilion!,
        Offset(left, at(0, yGirdleBottom + pavilion * 0.45).dy),
        align: Alignment.centerRight,
      );
    }
    if (labels.culet != null) {
      label(
        labels.culet!,
        at(0, yCulet).translate(0, 4),
        align: Alignment.topCenter,
      );
    }
    if (labels.depth != null) {
      final x = at(1, 0).dx + 12;
      final a = Offset(x, at(0, yTable).dy), b = Offset(x, at(0, yCulet).dy);
      canvas
        ..drawLine(a, b, guide)
        ..drawLine(a.translate(-3, 0), a.translate(3, 0), guide)
        ..drawLine(b.translate(-3, 0), b.translate(3, 0), guide);
      label(
        labels.depth!,
        Offset(x + 6, (a.dy + b.dy) / 2),
        align: Alignment.centerLeft,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProfilePainter old) =>
      old.proportions != proportions ||
      old.family != family ||
      old.labels != labels ||
      old.ink != ink ||
      old.accent != accent;
}
