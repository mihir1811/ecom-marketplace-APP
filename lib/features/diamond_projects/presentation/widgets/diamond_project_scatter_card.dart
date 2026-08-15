import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/diamond_project_stats.dart';

/// Carat vs price-per-carat scatter with IQR outliers in red.
class DiamondProjectScatterCard extends StatelessWidget {
  const DiamondProjectScatterCard({required this.stats, super.key});

  final DiamondProjectStats stats;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        border: Border.all(color: AppColors.warmBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Carat vs price per carat',
              style: AppTypography.label.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: CustomPaint(
                painter: _ScatterPainter(stats.scatter),
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Row(
              children: [
                const CircleAvatar(
                  radius: 4,
                  backgroundColor: AppColors.error,
                ),
                const SizedBox(width: AppSpacing.s8),
                Flexible(
                  child: Text(
                    '${stats.outliers.length} \$/ct outliers (IQR method)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScatterPainter extends CustomPainter {
  _ScatterPainter(this.points);

  final List<DiamondProjectScatterPoint> points;

  static const _left = 56.0;
  static const _right = 12.0;
  static const _top = 12.0;
  static const _bottom = 28.0;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTWH(
      _left,
      _top,
      math.max(1, size.width - _left - _right),
      math.max(1, size.height - _top - _bottom),
    );

    final axis = Paint()
      ..color = AppColors.warmBorder
      ..strokeWidth = 1;
    canvas.drawLine(plot.bottomLeft, plot.bottomRight, axis);
    canvas.drawLine(plot.topLeft, plot.bottomLeft, axis);

    if (points.isEmpty) return;

    var dataMinX = points.first.item.carat;
    var dataMaxX = dataMinX;
    var dataMinY = points.first.item.ppc;
    var dataMaxY = dataMinY;
    for (final point in points) {
      final x = point.item.carat;
      final y = point.item.ppc;
      if (x < dataMinX) dataMinX = x;
      if (x > dataMaxX) dataMaxX = x;
      if (y < dataMinY) dataMinY = y;
      if (y > dataMaxY) dataMaxY = y;
    }

    // Same inclusive nice-tick algorithm for X and Y (equal step style).
    final xAxis = _niceAxis(dataMinX, dataMaxX, targetTicks: 4);
    final yAxis = _niceAxis(dataMinY, dataMaxY, targetTicks: 5);
    final minX = xAxis.min;
    final maxX = xAxis.max;
    final minY = yAxis.min;
    final maxY = yAxis.max;

    final grid = Paint()
      ..color = AppColors.warmBorder.withValues(alpha: 0.45)
      ..strokeWidth = 1;

    for (final tick in xAxis.ticks) {
      final dx = _map(tick, minX, maxX, plot.left, plot.right);
      canvas.drawLine(Offset(dx, plot.top), Offset(dx, plot.bottom), grid);
      canvas.drawLine(
        Offset(dx, plot.bottom),
        Offset(dx, plot.bottom + 4),
        axis,
      );
      _drawLabel(
        canvas,
        _formatCarat(tick),
        Offset(dx, plot.bottom + 6),
        align: Alignment.topCenter,
      );
    }

    for (final tick in yAxis.ticks) {
      final dy = _map(tick, minY, maxY, plot.bottom, plot.top);
      canvas.drawLine(Offset(plot.left, dy), Offset(plot.right, dy), grid);
      canvas.drawLine(
        Offset(plot.left - 4, dy),
        Offset(plot.left, dy),
        axis,
      );
      _drawLabel(
        canvas,
        _formatPpc(tick),
        Offset(plot.left - 6, dy),
        align: Alignment.centerRight,
      );
    }

    for (final point in points) {
      final dx = _map(point.item.carat, minX, maxX, plot.left, plot.right);
      final dy = _map(point.item.ppc, minY, maxY, plot.bottom, plot.top);
      canvas.drawCircle(
        Offset(dx, dy),
        point.isOutlier ? 3.5 : 2.4,
        Paint()
          ..color = point.isOutlier ? AppColors.error : AppColors.charcoal
          ..style = PaintingStyle.fill,
      );
    }
  }

  /// Pads data, then expands domain to inclusive nice ticks (X and Y share this).
  static ({double min, double max, List<double> ticks}) _niceAxis(
    double dataMin,
    double dataMax, {
    required int targetTicks,
  }) {
    if (!dataMin.isFinite || !dataMax.isFinite) {
      return (min: 0, max: 1, ticks: const [0, 0.5, 1]);
    }

    var lo = dataMin;
    var hi = dataMax;
    var span = hi - lo;
    if (span <= 1e-9) {
      final pad = math.max(lo.abs() * 0.15, 0.1);
      lo -= pad;
      hi += pad;
      span = hi - lo;
    } else {
      final pad = span * 0.12;
      lo -= pad;
      hi += pad;
      span = hi - lo;
    }

    // Aim for ~targetTicks inclusive labels (like 0.6 / 0.8 / 1.0 on X).
    var step = _niceStep(span / math.max(targetTicks - 1, 1));
    var axisMin = (lo / step).floor() * step;
    var axisMax = (hi / step).ceil() * step;

    // Ensure at least 3 steps so Y never collapses to a single mid label.
    var tickCount = ((axisMax - axisMin) / step).round();
    if (tickCount < 3) {
      step = _niceStep(span / 3);
      axisMin = (lo / step).floor() * step;
      axisMax = (hi / step).ceil() * step;
      tickCount = ((axisMax - axisMin) / step).round();
      while (tickCount < 3) {
        axisMax += step;
        tickCount = ((axisMax - axisMin) / step).round();
      }
    }

    final ticks = <double>[];
    for (var i = 0; i <= tickCount; i++) {
      final value = axisMin + step * i;
      if (value > axisMax + step * 1e-6) break;
      ticks.add(_roundTick(value, step));
    }
    if (ticks.length < 2) {
      ticks
        ..clear()
        ..add(_roundTick(axisMin, step))
        ..add(_roundTick(axisMax, step));
    }

    return (min: ticks.first, max: ticks.last, ticks: ticks);
  }

  static double _niceStep(double raw) {
    if (raw <= 0 || !raw.isFinite) return 1;
    final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final residual = raw / mag;
    final nice = residual <= 1
        ? 1.0
        : residual <= 2
            ? 2.0
            : residual <= 2.5
                ? 2.5
                : residual <= 5
                    ? 5.0
                    : 10.0;
    return nice * mag;
  }

  static double _roundTick(double value, double step) {
    if (step >= 1) return double.parse(value.toStringAsFixed(0));
    if (step >= 0.1) return double.parse(value.toStringAsFixed(1));
    if (step >= 0.01) return double.parse(value.toStringAsFixed(2));
    return double.parse(value.toStringAsFixed(3));
  }

  static double _map(
    double value,
    double min,
    double max,
    double outMin,
    double outMax,
  ) {
    if ((max - min).abs() < 1e-12) return (outMin + outMax) / 2;
    return outMin + ((value - min) / (max - min)) * (outMax - outMin);
  }

  static String _formatCarat(double value) {
    if (value.abs() >= 10) return '${value.toStringAsFixed(0)} ct';
    if ((value * 10).roundToDouble() == value * 10) {
      return '${value.toStringAsFixed(1)} ct';
    }
    return '${value.toStringAsFixed(2)} ct';
  }

  static String _formatPpc(double value) {
    if (value.abs() >= 10) return '\$${value.toStringAsFixed(0)}';
    return '\$${value.toStringAsFixed(1)}';
  }

  static void _drawLabel(
    Canvas canvas,
    String text,
    Offset anchor, {
    required Alignment align,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: AppTypography.caption.copyWith(
          color: AppColors.textMutedLight,
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final offset = Offset(
      anchor.dx - painter.width * ((align.x + 1) / 2),
      anchor.dy - painter.height * ((align.y + 1) / 2),
    );
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _ScatterPainter oldDelegate) =>
      oldDelegate.points != points;
}
