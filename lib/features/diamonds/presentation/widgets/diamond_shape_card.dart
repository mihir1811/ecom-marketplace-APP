import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'diamond_svg_data.dart';

/// Enum representing all supported diamond shape types.
enum DiamondShapeType {
  round,
  cushion,
  emerald,
  pear,
  oval,
  princess,
  marquise,
  heart,
  radiant,
  asscher,
  trilliant,
  baguette,
  flanders,
  shield,
  polki,
  roseCut,
  taperedBaguette,
  trapezoid,
  halfMoon,
  bullet,
  lozenge,
}

/// CustomPainter that draws diamond shape outlines as vector drawings.
class DiamondShapePainter extends CustomPainter {
  const DiamondShapePainter({
    required this.shape,
    required this.strokeColor,
    this.fillColor,
    this.strokeWidth = 1.5,
  });

  final DiamondShapeType shape;
  final Color strokeColor;
  final Color? fillColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = fillColor != null
        ? (Paint()
          ..color = fillColor!
          ..style = PaintingStyle.fill)
        : null;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final w = size.width;
    final h = size.height;

    final path = _getPath(shape, cx, cy, w, h);

    if (fillPaint != null) {
      canvas.drawPath(path, fillPaint);
    }
    canvas.drawPath(path, paint);

    _drawInternalFacets(canvas, size, paint);
  }

  Path _getPath(DiamondShapeType shape, double cx, double cy, double w, double h) {
    switch (shape) {
      case DiamondShapeType.round:
        return _roundPath(cx, cy, w, h);
      case DiamondShapeType.cushion:
        return _cushionPath(cx, cy, w, h);
      case DiamondShapeType.emerald:
        return _emeraldPath(cx, cy, w, h);
      case DiamondShapeType.pear:
        return _pearPath(cx, cy, w, h);
      case DiamondShapeType.oval:
        return _ovalPath(cx, cy, w, h);
      case DiamondShapeType.princess:
        return _princessPath(cx, cy, w, h);
      case DiamondShapeType.marquise:
        return _marquisePath(cx, cy, w, h);
      case DiamondShapeType.heart:
        return _heartPath(cx, cy, w, h);
      case DiamondShapeType.radiant:
        return _radiantPath(cx, cy, w, h);
      case DiamondShapeType.asscher:
        return _asscherPath(cx, cy, w, h);
      case DiamondShapeType.trilliant:
        return _trilliantPath(cx, cy, w, h);
      case DiamondShapeType.baguette:
        return _baguettePath(cx, cy, w, h);
      case DiamondShapeType.flanders:
        return _flandersPath(cx, cy, w, h);
      case DiamondShapeType.shield:
        return _shieldPath(cx, cy, w, h);
      case DiamondShapeType.polki:
        return _polkiPath(cx, cy, w, h);
      case DiamondShapeType.roseCut:
        return _roseCutPath(cx, cy, w, h);
      case DiamondShapeType.taperedBaguette:
        return _taperedBaguettePath(cx, cy, w, h);
      case DiamondShapeType.trapezoid:
        return _trapezoidPath(cx, cy, w, h);
      case DiamondShapeType.halfMoon:
        return _halfMoonPath(cx, cy, w, h);
      case DiamondShapeType.bullet:
        return _bulletPath(cx, cy, w, h);
      case DiamondShapeType.lozenge:
        return _lozengePath(cx, cy, w, h);
    }
  }

  Path _roundPath(double cx, double cy, double w, double h) {
    final r = math.min(w, h) / 2 * 0.85;
    return Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
  }

  Path _cushionPath(double cx, double cy, double w, double h) {
    final rw = w * 0.42;
    final rh = h * 0.42;
    final corner = math.min(rw, rh) * 0.35;
    final path = Path();
    path.moveTo(cx - rw + corner, cy - rh);
    path.lineTo(cx + rw - corner, cy - rh);
    path.quadraticBezierTo(cx + rw, cy - rh, cx + rw, cy - rh + corner);
    path.lineTo(cx + rw, cy + rh - corner);
    path.quadraticBezierTo(cx + rw, cy + rh, cx + rw - corner, cy + rh);
    path.lineTo(cx - rw + corner, cy + rh);
    path.quadraticBezierTo(cx - rw, cy + rh, cx - rw, cy + rh - corner);
    path.lineTo(cx - rw, cy - rh + corner);
    path.quadraticBezierTo(cx - rw, cy - rh, cx - rw + corner, cy - rh);
    path.close();
    return path;
  }

  Path _emeraldPath(double cx, double cy, double w, double h) {
    final rw = w * 0.40;
    final rh = h * 0.44;
    final cut = math.min(rw, rh) * 0.28;
    return Path()
      ..moveTo(cx - rw + cut, cy - rh)
      ..lineTo(cx + rw - cut, cy - rh)
      ..lineTo(cx + rw, cy - rh + cut)
      ..lineTo(cx + rw, cy + rh - cut)
      ..lineTo(cx + rw - cut, cy + rh)
      ..lineTo(cx - rw + cut, cy + rh)
      ..lineTo(cx - rw, cy + rh - cut)
      ..lineTo(cx - rw, cy - rh + cut)
      ..close();
  }

  Path _pearPath(double cx, double cy, double w, double h) {
    final path = Path();
    final topY = cy - h * 0.42;
    final botY = cy + h * 0.42;
    final midW = w * 0.38;
    path.moveTo(cx, topY);
    path.quadraticBezierTo(cx + midW * 0.5, topY + h * 0.1, cx + midW, cy + h * 0.05);
    path.quadraticBezierTo(cx + midW * 1.1, botY - h * 0.05, cx, botY);
    path.quadraticBezierTo(cx - midW * 1.1, botY - h * 0.05, cx - midW, cy + h * 0.05);
    path.quadraticBezierTo(cx - midW * 0.5, topY + h * 0.1, cx, topY);
    path.close();
    return path;
  }

  Path _ovalPath(double cx, double cy, double w, double h) {
    final rx = w * 0.40;
    final ry = h * 0.44;
    return Path()..addOval(Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2));
  }

  Path _princessPath(double cx, double cy, double w, double h) {
    final s = math.min(w, h) * 0.40;
    return Path()
      ..moveTo(cx, cy - s)
      ..lineTo(cx + s, cy)
      ..lineTo(cx, cy + s)
      ..lineTo(cx - s, cy)
      ..close();
  }

  Path _marquisePath(double cx, double cy, double w, double h) {
    final path = Path();
    final rx = w * 0.44;
    final ry = h * 0.20;
    path.moveTo(cx, cy - h * 0.42);
    path.quadraticBezierTo(cx + rx, cy - ry, cx + rx * 0.8, cy);
    path.quadraticBezierTo(cx + rx, cy + ry, cx, cy + h * 0.42);
    path.quadraticBezierTo(cx - rx, cy + ry, cx - rx * 0.8, cy);
    path.quadraticBezierTo(cx - rx, cy - ry, cx, cy - h * 0.42);
    path.close();
    return path;
  }

  Path _heartPath(double cx, double cy, double w, double h) {
    final path = Path();
    final topY = cy - h * 0.18;
    final botY = cy + h * 0.42;
    final bumpW = w * 0.28;
    path.moveTo(cx, botY);
    path.quadraticBezierTo(cx - w * 0.44, cy + h * 0.02, cx - bumpW, topY - h * 0.06);
    path.quadraticBezierTo(cx - bumpW * 0.6, topY - h * 0.26, cx, topY - h * 0.08);
    path.quadraticBezierTo(cx + bumpW * 0.6, topY - h * 0.26, cx + bumpW, topY - h * 0.06);
    path.quadraticBezierTo(cx + w * 0.44, cy + h * 0.02, cx, botY);
    path.close();
    return path;
  }

  Path _radiantPath(double cx, double cy, double w, double h) {
    final rw = w * 0.40;
    final rh = h * 0.44;
    final cut = math.min(rw, rh) * 0.22;
    return Path()
      ..moveTo(cx - rw + cut, cy - rh)
      ..lineTo(cx + rw - cut, cy - rh)
      ..lineTo(cx + rw, cy - rh + cut)
      ..lineTo(cx + rw, cy + rh - cut)
      ..lineTo(cx + rw - cut, cy + rh)
      ..lineTo(cx - rw + cut, cy + rh)
      ..lineTo(cx - rw, cy + rh - cut)
      ..lineTo(cx - rw, cy - rh + cut)
      ..close();
  }

  Path _asscherPath(double cx, double cy, double w, double h) {
    final s = math.min(w, h) * 0.40;
    final cut = s * 0.28;
    return Path()
      ..moveTo(cx - s + cut, cy - s)
      ..lineTo(cx + s - cut, cy - s)
      ..lineTo(cx + s, cy - s + cut)
      ..lineTo(cx + s, cy + s - cut)
      ..lineTo(cx + s - cut, cy + s)
      ..lineTo(cx - s + cut, cy + s)
      ..lineTo(cx - s, cy + s - cut)
      ..lineTo(cx - s, cy - s + cut)
      ..close();
  }

  Path _trilliantPath(double cx, double cy, double w, double h) {
    final path = Path();
    path.moveTo(cx, cy - h * 0.42);
    path.lineTo(cx + w * 0.40, cy + h * 0.36);
    path.lineTo(cx - w * 0.40, cy + h * 0.36);
    path.close();
    return path;
  }

  Path _baguettePath(double cx, double cy, double w, double h) {
    final rw = w * 0.22;
    final rh = h * 0.44;
    return Path()
      ..moveTo(cx - rw, cy - rh)
      ..lineTo(cx + rw, cy - rh)
      ..lineTo(cx + rw, cy + rh)
      ..lineTo(cx - rw, cy + rh)
      ..close();
  }

  Path _flandersPath(double cx, double cy, double w, double h) {
    final path = Path();
    path.moveTo(cx, cy - h * 0.44);
    path.lineTo(cx + w * 0.36, cy - h * 0.10);
    path.lineTo(cx + w * 0.30, cy + h * 0.40);
    path.lineTo(cx, cy + h * 0.20);
    path.lineTo(cx - w * 0.30, cy + h * 0.40);
    path.lineTo(cx - w * 0.36, cy - h * 0.10);
    path.close();
    return path;
  }

  Path _shieldPath(double cx, double cy, double w, double h) {
    final path = Path();
    path.moveTo(cx, cy - h * 0.44);
    path.lineTo(cx + w * 0.40, cy - h * 0.16);
    path.lineTo(cx + w * 0.34, cy + h * 0.28);
    path.lineTo(cx, cy + h * 0.44);
    path.lineTo(cx - w * 0.34, cy + h * 0.28);
    path.lineTo(cx - w * 0.40, cy - h * 0.16);
    path.close();
    return path;
  }

  Path _polkiPath(double cx, double cy, double w, double h) {
    final path = Path();
    final rx = w * 0.40;
    final ry = h * 0.38;
    path.moveTo(cx - rx * 0.2, cy - ry);
    path.quadraticBezierTo(cx + rx * 0.8, cy - ry * 0.9, cx + rx, cy - ry * 0.2);
    path.quadraticBezierTo(cx + rx * 0.9, cy + ry * 0.7, cx + rx * 0.3, cy + ry);
    path.quadraticBezierTo(cx - rx * 0.6, cy + ry * 0.8, cx - rx, cy + ry * 0.3);
    path.quadraticBezierTo(cx - rx * 0.8, cy - ry * 0.4, cx - rx * 0.2, cy - ry);
    path.close();
    return path;
  }

  Path _roseCutPath(double cx, double cy, double w, double h) {
    final r = math.min(w, h) / 2 * 0.85;
    final path = Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    return path;
  }

  Path _taperedBaguettePath(double cx, double cy, double w, double h) {
    final topW = w * 0.26;
    final botW = w * 0.14;
    final rh = h * 0.44;
    return Path()
      ..moveTo(cx - topW, cy - rh)
      ..lineTo(cx + topW, cy - rh)
      ..lineTo(cx + botW, cy + rh)
      ..lineTo(cx - botW, cy + rh)
      ..close();
  }

  Path _trapezoidPath(double cx, double cy, double w, double h) {
    final topW = w * 0.36;
    final botW = w * 0.18;
    final rh = h * 0.40;
    return Path()
      ..moveTo(cx - topW, cy - rh)
      ..lineTo(cx + topW, cy - rh)
      ..lineTo(cx + botW, cy + rh)
      ..lineTo(cx - botW, cy + rh)
      ..close();
  }

  Path _halfMoonPath(double cx, double cy, double w, double h) {
    final r = math.min(w, h) / 2 * 0.85;
    return Path()
      ..addArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -math.pi,
        math.pi,
      )
      ..lineTo(cx - r, cy)
      ..close();
  }

  Path _bulletPath(double cx, double cy, double w, double h) {
    final rw = w * 0.20;
    final rh = h * 0.44;
    return Path()
      ..moveTo(cx - rw, cy - rh)
      ..lineTo(cx + rw, cy - rh)
      ..lineTo(cx + rw, cy + rh * 0.3)
      ..quadraticBezierTo(cx + rw * 0.5, cy + rh, cx, cy + rh)
      ..quadraticBezierTo(cx - rw * 0.5, cy + rh, cx - rw, cy + rh * 0.3)
      ..close();
  }

  Path _lozengePath(double cx, double cy, double w, double h) {
    final rw = w * 0.38;
    final rh = h * 0.44;
    return Path()
      ..moveTo(cx, cy - rh)
      ..lineTo(cx + rw, cy)
      ..lineTo(cx, cy + rh)
      ..lineTo(cx - rw, cy)
      ..close();
  }

  void _drawInternalFacets(Canvas canvas, Size size, Paint paint) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final facetPaint = Paint()
      ..color = paint.color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    switch (shape) {
      case DiamondShapeType.round:
        _drawRoundFacets(canvas, cx, cy, size, facetPaint);
        break;
      case DiamondShapeType.emerald:
      case DiamondShapeType.asscher:
        _drawStepFacets(canvas, cx, cy, size, facetPaint);
        break;
      case DiamondShapeType.princess:
      case DiamondShapeType.lozenge:
        _drawCrossFacets(canvas, cx, cy, size, facetPaint);
        break;
      case DiamondShapeType.roseCut:
        _drawRoseCutFacets(canvas, cx, cy, size, facetPaint);
        break;
      default:
        break;
    }
  }

  void _drawRoundFacets(Canvas canvas, double cx, double cy, Size size, Paint paint) {
    final r = math.min(size.width, size.height) / 2 * 0.85;
    final innerR = r * 0.45;
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final innerPoint = Offset(cx + innerR * math.cos(angle), cy + innerR * math.sin(angle));
      final outerPoint = Offset(cx + r * math.cos(angle), cy + r * math.sin(angle));
      canvas.drawLine(innerPoint, outerPoint, paint);
    }
  }

  void _drawStepFacets(Canvas canvas, double cx, double cy, Size size, Paint paint) {
    final s = math.min(size.width, size.height) / 2 * 0.85;
    for (double f = 0.3; f < 0.8; f += 0.25) {
      final half = s * f;
      canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: half * 2, height: half * 2), paint);
    }
  }

  void _drawCrossFacets(Canvas canvas, double cx, double cy, Size size, Paint paint) {
    final s = math.min(size.width, size.height) / 2 * 0.85;
    canvas.drawLine(Offset(cx, cy - s), Offset(cx, cy + s), paint);
    canvas.drawLine(Offset(cx - s, cy), Offset(cx + s, cy), paint);
  }

  void _drawRoseCutFacets(Canvas canvas, double cx, double cy, Size size, Paint paint) {
    final r = math.min(size.width, size.height) / 2 * 0.85;
    final midR = r * 0.6;
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final midPoint = Offset(cx + midR * math.cos(angle), cy + midR * math.sin(angle));
      final outerPoint = Offset(cx + r * math.cos(angle), cy + r * math.sin(angle));
      canvas.drawLine(midPoint, outerPoint, paint);
    }
    canvas.drawOval(Rect.fromCircle(center: Offset(cx, cy), radius: midR * 0.6), paint);
  }

  @override
  bool shouldRepaint(covariant DiamondShapePainter oldDelegate) =>
      oldDelegate.shape != shape ||
      oldDelegate.strokeColor != strokeColor ||
      oldDelegate.fillColor != fillColor ||
      oldDelegate.strokeWidth != strokeWidth;
}

/// A premium capsule-shaped card that displays a diamond shape drawing and label.
/// Can be selected and toggled by the user.
class DiamondShapeCard extends StatelessWidget {
  const DiamondShapeCard({
    required this.name,
    required this.shapeType,
    required this.isSelected,
    required this.onTap,
    this.imagePath,
    super.key,
  });

  final String name;
  final DiamondShapeType shapeType;
  final bool isSelected;
  final VoidCallback onTap;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    const activeColor = AppColors.bronze;
    final inactiveBorderColor = AppColors.warmBorder;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? (AppColors.creamBg)
              : (AppColors.warmWhite),
          borderRadius: const BorderRadius.all(Radius.circular(60.0)),
          border: Border.all(
            color: isSelected ? activeColor : inactiveBorderColor,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected ? AppShadows.cardLight : AppShadows.none,
        ),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.s24,
          horizontal: AppSpacing.s12,
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: imagePath != null
                      ? Image.asset(
                          imagePath!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => renderShapeSvg(
                            name,
                            size: 48,
                            color: isSelected
                                ? activeColor
                                : AppColors.bronzeLight,
                          ),
                        )
                      : renderShapeSvg(
                          name,
                          size: 48,
                          color: isSelected
                              ? activeColor
                              : AppColors.bronzeLight,
                        ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.label.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? activeColor
                    : (AppColors.textPrimaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Maps shape name strings to DiamondShapeType enums.
DiamondShapeType getShapeType(String name) {
  return switch (name) {
    'Round' => DiamondShapeType.round,
    'Cushion' => DiamondShapeType.cushion,
    'Emerald' => DiamondShapeType.emerald,
    'Pear' => DiamondShapeType.pear,
    'Oval' => DiamondShapeType.oval,
    'Princess' => DiamondShapeType.princess,
    'Marquise' => DiamondShapeType.marquise,
    'Heart' => DiamondShapeType.heart,
    'Radiant' => DiamondShapeType.radiant,
    'Asscher' => DiamondShapeType.asscher,
    'Trilliant' => DiamondShapeType.trilliant,
    'Baguette' => DiamondShapeType.baguette,
    'Flanders' => DiamondShapeType.flanders,
    'Shield' => DiamondShapeType.shield,
    'Polki' => DiamondShapeType.polki,
    'Rose Cut' => DiamondShapeType.roseCut,
    'Tapered Baguette' => DiamondShapeType.taperedBaguette,
    'Trapezoid' => DiamondShapeType.trapezoid,
    'Half Moon' => DiamondShapeType.halfMoon,
    'Bullet' => DiamondShapeType.bullet,
    'Lozenge' => DiamondShapeType.lozenge,
    _ => DiamondShapeType.round,
  };
}
