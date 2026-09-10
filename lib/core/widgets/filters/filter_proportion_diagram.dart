import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Which proportion to illustrate inside a filter info tooltip.
enum FilterProportionDiagramKind {
  length,
  width,
  height,
  ratio,
  table,
  depth,
  crownAngle,
  crownHeight,
  pavilionAngle,
  pavilionDepth,
  girdle,
  culet,
}

/// Crisp vector diagram for diamond/gem measurement tooltips.
///
/// Drawn with [CustomPaint] so it appears instantly (no asset decode flicker).
class FilterProportionDiagram extends StatelessWidget {
  const FilterProportionDiagram({
    required this.kind,
    this.size = 132,
    super.key,
  });

  final FilterProportionDiagramKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? AppColors.charcoalLight : AppColors.sandSurface,
        borderRadius: BorderRadius.circular(AppSpacing.r8),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s8),
          child: CustomPaint(
            painter: _ProportionPainter(
              kind: kind,
              outline: isDark ? AppColors.bronzeLight : AppColors.charcoal,
              fill: isDark
                  ? AppColors.bronze.withValues(alpha: 0.18)
                  : AppColors.bronzeLight.withValues(alpha: 0.35),
              accent: AppColors.bronze,
              label: isDark ? AppColors.warmWhite : AppColors.charcoal,
              muted: AppColors.textMuted(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProportionPainter extends CustomPainter {
  _ProportionPainter({
    required this.kind,
    required this.outline,
    required this.fill,
    required this.accent,
    required this.label,
    required this.muted,
  });

  final FilterProportionDiagramKind kind;
  final Color outline;
  final Color fill;
  final Color accent;
  final Color label;
  final Color muted;

  @override
  void paint(Canvas canvas, Size size) {
    switch (kind) {
      case FilterProportionDiagramKind.length:
      case FilterProportionDiagramKind.width:
      case FilterProportionDiagramKind.ratio:
        _paintTopDown(canvas, size);
      case FilterProportionDiagramKind.height:
      case FilterProportionDiagramKind.table:
      case FilterProportionDiagramKind.depth:
      case FilterProportionDiagramKind.crownAngle:
      case FilterProportionDiagramKind.crownHeight:
      case FilterProportionDiagramKind.pavilionAngle:
      case FilterProportionDiagramKind.pavilionDepth:
      case FilterProportionDiagramKind.girdle:
      case FilterProportionDiagramKind.culet:
        _paintProfile(canvas, size);
    }
  }

  void _paintTopDown(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 4;
    final rx = size.width * 0.32;
    final ry = size.height * 0.22;

    final stone = Path()
      ..addOval(Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2));
    canvas.drawPath(
      stone,
      Paint()
        ..color = fill
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      stone,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    final dimPaint = Paint()
      ..color = accent
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    switch (kind) {
      case FilterProportionDiagramKind.length:
        canvas.drawLine(Offset(cx, cy - ry - 10), Offset(cx, cy + ry + 10), dimPaint);
        _drawArrowHeads(canvas, Offset(cx, cy - ry - 10), Offset(cx, cy + ry + 10), dimPaint);
        _drawLabel(canvas, 'L', Offset(cx + 10, cy - ry - 14));
      case FilterProportionDiagramKind.width:
        canvas.drawLine(Offset(cx - rx - 10, cy), Offset(cx + rx + 10, cy), dimPaint);
        _drawArrowHeads(canvas, Offset(cx - rx - 10, cy), Offset(cx + rx + 10, cy), dimPaint);
        _drawLabel(canvas, 'W', Offset(cx + rx + 12, cy - 6));
      case FilterProportionDiagramKind.ratio:
        canvas.drawLine(Offset(cx, cy - ry - 8), Offset(cx, cy + ry + 8), dimPaint);
        canvas.drawLine(Offset(cx - rx - 8, cy), Offset(cx + rx + 8, cy), dimPaint);
        _drawLabel(canvas, 'L', Offset(cx + 8, cy - ry - 14));
        _drawLabel(canvas, 'W', Offset(cx + rx + 10, cy - 6));
        _drawLabel(canvas, 'L ÷ W', Offset(cx - 18, cy + ry + 18), muted: true);
      default:
        break;
    }
  }

  void _paintProfile(Canvas canvas, Size size) {
    final profile = _profilePath(size);
    final parts = _profileParts(size);

    canvas.drawPath(
      profile,
      Paint()
        ..color = fill
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      profile,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round,
    );

    final accentStroke = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final accentFill = Paint()
      ..color = accent.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;

    switch (kind) {
      case FilterProportionDiagramKind.height:
        canvas.drawLine(
          Offset(parts.right + 8, parts.tableY),
          Offset(parts.right + 8, parts.culetY),
          accentStroke,
        );
        _drawArrowHeads(
          canvas,
          Offset(parts.right + 8, parts.tableY),
          Offset(parts.right + 8, parts.culetY),
          accentStroke,
        );
        _drawLabel(canvas, 'H', Offset(parts.right + 12, (parts.tableY + parts.culetY) / 2 - 6));
      case FilterProportionDiagramKind.table:
        canvas.drawLine(
          Offset(parts.tableLeft, parts.tableY),
          Offset(parts.tableRight, parts.tableY),
          accentStroke..strokeWidth = 3,
        );
        _drawLabel(canvas, 'Table', Offset(parts.cx - 16, parts.tableY - 14));
      case FilterProportionDiagramKind.depth:
        canvas.drawLine(
          Offset(parts.left - 6, parts.girdleY),
          Offset(parts.right + 6, parts.girdleY),
          Paint()
            ..color = muted
            ..strokeWidth = 1,
        );
        canvas.drawLine(
          Offset(parts.right + 10, parts.tableY),
          Offset(parts.right + 10, parts.culetY),
          accentStroke,
        );
        _drawArrowHeads(
          canvas,
          Offset(parts.right + 10, parts.tableY),
          Offset(parts.right + 10, parts.culetY),
          accentStroke,
        );
        _drawLabel(canvas, 'Depth %', Offset(parts.cx - 22, parts.culetY + 10), muted: true);
      case FilterProportionDiagramKind.crownAngle:
        final start = Offset(parts.tableRight, parts.tableY);
        final end = Offset(parts.right, parts.girdleY);
        canvas.drawLine(start, end, accentStroke);
        _drawAngleArc(canvas, end, start, Offset(parts.right + 18, parts.girdleY), accentStroke);
        _drawLabel(canvas, '∠', Offset(parts.right + 4, parts.girdleY - 18));
      case FilterProportionDiagramKind.crownHeight:
        final crown = Path()
          ..moveTo(parts.tableLeft, parts.tableY)
          ..lineTo(parts.tableRight, parts.tableY)
          ..lineTo(parts.right, parts.girdleY)
          ..lineTo(parts.left, parts.girdleY)
          ..close();
        canvas.drawPath(crown, accentFill);
        canvas.drawLine(
          Offset(parts.left - 8, parts.tableY),
          Offset(parts.left - 8, parts.girdleY),
          accentStroke,
        );
        _drawLabel(canvas, 'Crown', Offset(parts.cx - 18, parts.tableY + 10));
      case FilterProportionDiagramKind.pavilionAngle:
        final start = Offset(parts.left, parts.girdleY);
        final end = Offset(parts.cx, parts.culetY);
        canvas.drawLine(start, end, accentStroke);
        _drawAngleArc(
          canvas,
          start,
          end,
          Offset(parts.left - 14, parts.girdleY),
          accentStroke,
        );
        _drawLabel(canvas, '∠', Offset(parts.left - 4, parts.girdleY + 10));
      case FilterProportionDiagramKind.pavilionDepth:
        final pavilion = Path()
          ..moveTo(parts.left, parts.girdleY)
          ..lineTo(parts.right, parts.girdleY)
          ..lineTo(parts.cx, parts.culetY)
          ..close();
        canvas.drawPath(pavilion, accentFill);
        canvas.drawLine(
          Offset(parts.right + 8, parts.girdleY),
          Offset(parts.right + 8, parts.culetY),
          accentStroke,
        );
        _drawLabel(canvas, 'Pavilion', Offset(parts.cx - 22, parts.girdleY + 16));
      case FilterProportionDiagramKind.girdle:
        canvas.drawLine(
          Offset(parts.left, parts.girdleY),
          Offset(parts.right, parts.girdleY),
          accentStroke..strokeWidth = 4,
        );
        _drawLabel(canvas, 'Girdle', Offset(parts.cx - 18, parts.girdleY - 14));
      case FilterProportionDiagramKind.culet:
        canvas.drawCircle(Offset(parts.cx, parts.culetY), 4.5, accentFill);
        canvas.drawCircle(
          Offset(parts.cx, parts.culetY),
          4.5,
          Paint()
            ..color = accent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8,
        );
        _drawLabel(canvas, 'Culet', Offset(parts.cx - 14, parts.culetY + 14));
      default:
        break;
    }
  }

  Path _profilePath(Size size) {
    final p = _profileParts(size);
    return Path()
      ..moveTo(p.tableLeft, p.tableY)
      ..lineTo(p.tableRight, p.tableY)
      ..lineTo(p.right, p.girdleY)
      ..lineTo(p.cx, p.culetY)
      ..lineTo(p.left, p.girdleY)
      ..close();
  }

  _ProfileParts _profileParts(Size size) {
    final cx = size.width / 2;
    final tableY = size.height * 0.18;
    final girdleY = size.height * 0.42;
    final culetY = size.height * 0.86;
    final halfTable = size.width * 0.18;
    final halfGirdle = size.width * 0.34;
    return _ProfileParts(
      cx: cx,
      tableY: tableY,
      girdleY: girdleY,
      culetY: culetY,
      tableLeft: cx - halfTable,
      tableRight: cx + halfTable,
      left: cx - halfGirdle,
      right: cx + halfGirdle,
    );
  }

  void _drawArrowHeads(Canvas canvas, Offset a, Offset b, Paint paint) {
    final dir = (b - a);
    final len = dir.distance;
    if (len < 1) return;
    final unit = dir / len;
    final normal = Offset(-unit.dy, unit.dx);
    const head = 5.0;
    canvas.drawLine(a, a + unit * head + normal * 3.5, paint);
    canvas.drawLine(a, a + unit * head - normal * 3.5, paint);
    canvas.drawLine(b, b - unit * head + normal * 3.5, paint);
    canvas.drawLine(b, b - unit * head - normal * 3.5, paint);
  }

  void _drawAngleArc(
    Canvas canvas,
    Offset vertex,
    Offset armA,
    Offset armB,
    Paint paint,
  ) {
    final a1 = math.atan2(armA.dy - vertex.dy, armA.dx - vertex.dx);
    final a2 = math.atan2(armB.dy - vertex.dy, armB.dx - vertex.dx);
    final rect = Rect.fromCircle(center: vertex, radius: 14);
    canvas.drawArc(rect, a1, _deltaAngle(a1, a2), false, paint..strokeWidth = 1.6);
  }

  double _deltaAngle(double from, double to) {
    var d = to - from;
    while (d > math.pi) {
      d -= 2 * math.pi;
    }
    while (d < -math.pi) {
      d += 2 * math.pi;
    }
    return d;
  }

  void _drawLabel(Canvas canvas, String text, Offset at, {bool muted = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: muted ? this.muted : label,
          fontSize: muted ? 10 : 11,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(covariant _ProportionPainter oldDelegate) {
    return oldDelegate.kind != kind ||
        oldDelegate.outline != outline ||
        oldDelegate.fill != fill ||
        oldDelegate.accent != accent ||
        oldDelegate.label != label ||
        oldDelegate.muted != muted;
  }
}

class _ProfileParts {
  const _ProfileParts({
    required this.cx,
    required this.tableY,
    required this.girdleY,
    required this.culetY,
    required this.tableLeft,
    required this.tableRight,
    required this.left,
    required this.right,
  });

  final double cx;
  final double tableY;
  final double girdleY;
  final double culetY;
  final double tableLeft;
  final double tableRight;
  final double left;
  final double right;
}
