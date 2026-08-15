import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Cut silhouette used by fancy-color swatches.
enum FancyGemCut { emerald, oval, heart, princess, cushion }

/// Glossy gem silhouette matching the Fancy Colors row.
class FancyColorGemPainter extends CustomPainter {
  const FancyColorGemPainter({
    required this.cut,
    required this.fillColors,
    required this.isSelected,
    this.rainbow = false,
    this.splitTone = false,
  });

  final FancyGemCut cut;
  final List<Color> fillColors;
  final bool isSelected;
  final bool rainbow;
  final bool splitTone;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inset = size.shortestSide * 0.06;
    final gemRect = rect.deflate(inset);
    final path = _pathFor(cut, gemRect);

    canvas.drawShadow(path, Colors.black26, 3, false);

    final fill = Paint()
      ..style = PaintingStyle.fill
      ..shader = _fillShader(gemRect);
    canvas.drawPath(path, fill);

    canvas.save();
    canvas.clipPath(path);
    _paintHighlight(canvas, gemRect);
    canvas.restore();

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 1.8 : 0.8
      ..color = isSelected
          ? AppColors.bronze
          : _darken(fillColors.first, 0.22).withValues(alpha: 0.7);
    canvas.drawPath(path, stroke);
  }

  Shader _fillShader(Rect rect) {
    if (rainbow) {
      return const SweepGradient(
        colors: [
          Color(0xFFEF4444),
          Color(0xFFFACC15),
          Color(0xFF22C55E),
          Color(0xFF2563EB),
          Color(0xFFEC4899),
          Color(0xFFEF4444),
        ],
      ).createShader(rect);
    }
    if (splitTone && fillColors.length >= 2) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          fillColors[0],
          fillColors[0],
          fillColors[1],
          fillColors[1],
        ],
        stops: const [0.0, 0.5, 0.5, 1.0],
      ).createShader(rect);
    }
    final base = fillColors.first;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        _lighten(base, 0.28),
        base,
        _darken(base, 0.18),
      ],
      stops: const [0.0, 0.45, 1.0],
    ).createShader(rect);
  }

  void _paintHighlight(Canvas canvas, Rect rect) {
    final highlight = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.45),
        radius: 0.7,
        colors: [
          Colors.white.withValues(alpha: 0.45),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, highlight);
  }

  static Path _pathFor(FancyGemCut cut, Rect rect) {
    return switch (cut) {
      FancyGemCut.emerald => _octagon(rect, 0.22),
      FancyGemCut.oval => Path()
        ..addOval(
          Rect.fromCenter(
            center: rect.center,
            width: rect.width * 0.72,
            height: rect.height,
          ),
        ),
      FancyGemCut.heart => _heart(rect),
      FancyGemCut.princess => Path()..addRect(rect),
      FancyGemCut.cushion => Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            rect,
            Radius.circular(rect.shortestSide * 0.28),
          ),
        ),
    };
  }

  static Path _octagon(Rect rect, double cutFraction) {
    final cutX = rect.width * cutFraction;
    final cutY = rect.height * cutFraction;
    return Path()
      ..moveTo(rect.left + cutX, rect.top)
      ..lineTo(rect.right - cutX, rect.top)
      ..lineTo(rect.right, rect.top + cutY)
      ..lineTo(rect.right, rect.bottom - cutY)
      ..lineTo(rect.right - cutX, rect.bottom)
      ..lineTo(rect.left + cutX, rect.bottom)
      ..lineTo(rect.left, rect.bottom - cutY)
      ..lineTo(rect.left, rect.top + cutY)
      ..close();
  }

  static Path _heart(Rect rect) {
    final w = rect.width;
    final h = rect.height;
    final x = rect.left;
    final y = rect.top;
    return Path()
      ..moveTo(x + w * 0.5, y + h * 0.28)
      ..cubicTo(
        x + w * 0.12,
        y - h * 0.02,
        x - w * 0.08,
        y + h * 0.38,
        x + w * 0.5,
        y + h * 0.95,
      )
      ..cubicTo(
        x + w * 1.08,
        y + h * 0.38,
        x + w * 0.88,
        y - h * 0.02,
        x + w * 0.5,
        y + h * 0.28,
      )
      ..close();
  }

  static Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  static Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  bool shouldRepaint(covariant FancyColorGemPainter oldDelegate) {
    return oldDelegate.cut != cut ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.rainbow != rainbow ||
        oldDelegate.splitTone != splitTone ||
        oldDelegate.fillColors != fillColors;
  }
}
