import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/chart_value_tooltip.dart';
import '../../domain/models/diamond_project_stats.dart';

/// Carat vs price-per-carat scatter with IQR outliers in red.
class DiamondProjectScatterCard extends StatefulWidget {
  const DiamondProjectScatterCard({required this.stats, super.key});

  final DiamondProjectStats stats;

  @override
  State<DiamondProjectScatterCard> createState() =>
      _DiamondProjectScatterCardState();
}

class _DiamondProjectScatterCardState extends State<DiamondProjectScatterCard> {
  int? _selectedIndex;

  @override
  void didUpdateWidget(covariant DiamondProjectScatterCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stats != widget.stats) {
      _selectedIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final axisColor = AppColors.border(context);
    final gridColor = axisColor.withValues(alpha: 0.45);
    final labelColor = AppColors.textMuted(context);
    final pointColor = AppColors.textPrimary(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(CatalogL10n.caratVsPpc),
              style: AppTypography.label.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onTapDown: (details) {
                      final index = _ScatterPainter.findNearestPoint(
                        widget.stats.scatter,
                        Size(constraints.maxWidth, constraints.maxHeight),
                        details.localPosition,
                      );
                      if (index == null) {
                        setState(() => _selectedIndex = null);
                        return;
                      }
                      setState(() {
                        _selectedIndex =
                            _selectedIndex == index ? null : index;
                      });
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CustomPaint(
                          painter: _ScatterPainter(
                            widget.stats.scatter,
                            axisColor: axisColor,
                            gridColor: gridColor,
                            labelColor: labelColor,
                            pointColor: pointColor,
                            selectedIndex: _selectedIndex,
                          ),
                          child: const SizedBox.expand(),
                        ),
                        if (_selectedIndex != null)
                          _scatterTooltip(
                            widget.stats.scatter[_selectedIndex!],
                            Size(constraints.maxWidth, constraints.maxHeight),
                          ),
                      ],
                    ),
                  );
                },
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
                    context.tr(CatalogL10n.ppcOutliers, {
                      'count': '${widget.stats.outliers.length}',
                    }),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary(context),
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

  Widget _scatterTooltip(
    DiamondProjectScatterPoint point,
    Size size,
  ) {
    if (widget.stats.scatter.isEmpty) return const SizedBox.shrink();

    final plot = _ScatterPainter.plotRect(size);
    final data = _ScatterPainter.dataBounds(widget.stats.scatter);
    final xAxis = _ScatterPainter.niceAxis(data.minX, data.maxX, targetTicks: 4);
    final yAxis = _ScatterPainter.niceAxis(data.minY, data.maxY, targetTicks: 5);
    final dx = _ScatterPainter.map(
      point.item.carat,
      xAxis.min,
      xAxis.max,
      plot.left,
      plot.right,
    );
    final dy = _ScatterPainter.map(
      point.item.ppc,
      yAxis.min,
      yAxis.max,
      plot.bottom,
      plot.top,
    );

    return Positioned(
      left: (dx - 56).clamp(0.0, size.width - 112),
      top: (dy - 52).clamp(0.0, size.height - 48),
      child: ChartValueTooltip(
        label: point.item.stockLabel,
        value:
            '${point.item.carat.toStringAsFixed(2)} ct · \$${point.item.ppc.toStringAsFixed(0)}/ct',
      ),
    );
  }
}

class _ScatterPainter extends CustomPainter {
  _ScatterPainter(
    this.points, {
    required this.axisColor,
    required this.gridColor,
    required this.labelColor,
    required this.pointColor,
    this.selectedIndex,
  });

  final List<DiamondProjectScatterPoint> points;
  final Color axisColor;
  final Color gridColor;
  final Color labelColor;
  final Color pointColor;
  final int? selectedIndex;

  static const _left = 56.0;
  static const _right = 12.0;
  static const _top = 12.0;
  static const _bottom = 28.0;

  static Rect plotRect(Size size) {
    return Rect.fromLTWH(
      _left,
      _top,
      math.max(1, size.width - _left - _right),
      math.max(1, size.height - _top - _bottom),
    );
  }

  static ({double minX, double maxX, double minY, double maxY}) dataBounds(
    List<DiamondProjectScatterPoint> points,
  ) {
    if (points.isEmpty) {
      return (minX: 0, maxX: 1, minY: 0, maxY: 1);
    }
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
    return (minX: dataMinX, maxX: dataMaxX, minY: dataMinY, maxY: dataMaxY);
  }

  static int? findNearestPoint(
    List<DiamondProjectScatterPoint> points,
    Size size,
    Offset position,
  ) {
    if (points.isEmpty) return null;
    final plot = plotRect(size);
    final data = dataBounds(points);
    final xAxis = niceAxis(data.minX, data.maxX, targetTicks: 4);
    final yAxis = niceAxis(data.minY, data.maxY, targetTicks: 5);
    var closestIndex = -1;
    var closestDistance = double.infinity;
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final dx = map(
        point.item.carat,
        xAxis.min,
        xAxis.max,
        plot.left,
        plot.right,
      );
      final dy = map(
        point.item.ppc,
        yAxis.min,
        yAxis.max,
        plot.bottom,
        plot.top,
      );
      final distance = (position - Offset(dx, dy)).distance;
      if (distance < closestDistance) {
        closestDistance = distance;
        closestIndex = i;
      }
    }
    return closestDistance <= 16 ? closestIndex : null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final plot = plotRect(size);

    final axis = Paint()
      ..color = axisColor
      ..strokeWidth = 1;
    canvas.drawLine(plot.bottomLeft, plot.bottomRight, axis);
    canvas.drawLine(plot.topLeft, plot.bottomLeft, axis);

    if (points.isEmpty) return;

    final data = dataBounds(points);
    final xAxis = niceAxis(data.minX, data.maxX, targetTicks: 4);
    final yAxis = niceAxis(data.minY, data.maxY, targetTicks: 5);
    final minX = xAxis.min;
    final maxX = xAxis.max;
    final minY = yAxis.min;
    final maxY = yAxis.max;

    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (final tick in xAxis.ticks) {
      final dx = map(tick, minX, maxX, plot.left, plot.right);
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
      final dy = map(tick, minY, maxY, plot.bottom, plot.top);
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

    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final dx = map(point.item.carat, minX, maxX, plot.left, plot.right);
      final dy = map(point.item.ppc, minY, maxY, plot.bottom, plot.top);
      final selected = selectedIndex == i;
      canvas.drawCircle(
        Offset(dx, dy),
        selected ? 5.5 : (point.isOutlier ? 3.5 : 2.4),
        Paint()
          ..color = point.isOutlier ? AppColors.error : pointColor
          ..style = PaintingStyle.fill,
      );
      if (selected) {
        canvas.drawCircle(
          Offset(dx, dy),
          7.5,
          Paint()
            ..color = AppColors.info
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  static ({double min, double max, List<double> ticks}) niceAxis(
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

    var step = _niceStep(span / math.max(targetTicks - 1, 1));
    var axisMin = (lo / step).floor() * step;
    var axisMax = (hi / step).ceil() * step;

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

  static double map(
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

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset anchor, {
    required Alignment align,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: AppTypography.caption.copyWith(
          color: labelColor,
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
      oldDelegate.points != points ||
      oldDelegate.axisColor != axisColor ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.labelColor != labelColor ||
      oldDelegate.pointColor != pointColor ||
      oldDelegate.selectedIndex != selectedIndex;
}
