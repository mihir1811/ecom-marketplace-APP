import 'dart:math' as math;
import 'package:flutter/widgets.dart';

import '../../../diamonds/presentation/widgets/diamond_svg_data.dart';
import '../../domain/models/product_detail.dart';

/// Outline of a dock frame.
///
/// Diamonds and gemstones are framed in the silhouette of their own cut (a
/// pear stone sits in a pear), every other segment keeps the gem-cut
/// octagon.
class ProductFrameShape {
  const ProductFrameShape._(this.key);

  /// Resolved SVG shape key, or null for the gem-cut octagon.
  final String? key;

  static const octagon = ProductFrameShape._(null);

  static ProductFrameShape of(ProductDetail detail) {
    switch (detail.segment) {
      case ProductSegment.naturalDiamond:
      case ProductSegment.labGrownDiamond:
      case ProductSegment.gemstone:
        final raw = detail.shapeKey ?? detail.media.shapeKey;
        return ProductFrameShape._(resolveShapeSvgKey(raw));
      case ProductSegment.jewelry:
      case ProductSegment.watch:
      case ProductSegment.bullion:
        return octagon;
    }
  }

  /// Width / height of the silhouette, so tall cuts are not squashed.
  double get aspect => switch (key) {
    null => 1.0,
    'Oval' => 0.78,
    'Pear' => 0.72,
    'Marquise' => 0.58,
    'Emerald' => 0.8,
    'Radiant' => 0.86,
    'Baguette' => 0.5,
    'Tapered_Baguette' => 0.56,
    'Trapezoid' => 0.9,
    'Bullet' => 0.66,
    'Shield' => 0.88,
    'Half_Moon' => 1.0,
    'Flanders' => 0.84,
    'Lozenge' => 0.72,
    'Trilliant' => 1.0,
    'Heart' => 1.0,
    _ => 1.0,
  };

  /// Outline fitted into the square [box], centred.
  Path pathIn(Rect box) {
    final a = aspect;
    final w = a >= 1 ? box.width : box.height * a;
    final h = a >= 1 ? box.width / a : box.height;
    final r = Rect.fromCenter(center: box.center, width: w, height: h);
    final m = Matrix4.identity()
      ..translateByDouble(r.left, r.top, 0, 1)
      ..scaleByDouble(r.width, r.height, 1, 1);
    return _unit(key).transform(m.storage);
  }
}

Path _unit(String? key) {
  switch (key) {
    case null:
      return _polygon(const [
        Offset(0.28, 0),
        Offset(0.72, 0),
        Offset(1, 0.28),
        Offset(1, 0.72),
        Offset(0.72, 1),
        Offset(0.28, 1),
        Offset(0, 0.72),
        Offset(0, 0.28),
      ], 0.03);
    case 'Round':
    case 'Polki':
    case 'Rose_Cut':
      return Path()..addOval(const Rect.fromLTWH(0, 0, 1, 1));
    case 'Oval':
      return Path()..addOval(const Rect.fromLTWH(0, 0, 1, 1));
    case 'Pear':
      return Path()
        ..moveTo(0.5, 0)
        ..cubicTo(0.58, 0.2, 1, 0.42, 1, 0.68)
        ..cubicTo(1, 0.88, 0.78, 1, 0.5, 1)
        ..cubicTo(0.22, 1, 0, 0.88, 0, 0.68)
        ..cubicTo(0, 0.42, 0.42, 0.2, 0.5, 0)
        ..close();
    case 'Marquise':
      return Path()
        ..moveTo(0.5, 0)
        ..cubicTo(1.04, 0.3, 1.04, 0.7, 0.5, 1)
        ..cubicTo(-0.04, 0.7, -0.04, 0.3, 0.5, 0)
        ..close();
    case 'Heart':
      return Path()
        ..moveTo(0.5, 1)
        ..cubicTo(0.1, 0.66, 0, 0.44, 0, 0.3)
        ..cubicTo(0, 0.12, 0.13, 0, 0.29, 0)
        ..cubicTo(0.4, 0, 0.47, 0.07, 0.5, 0.17)
        ..cubicTo(0.53, 0.07, 0.6, 0, 0.71, 0)
        ..cubicTo(0.87, 0, 1, 0.12, 1, 0.3)
        ..cubicTo(1, 0.44, 0.9, 0.66, 0.5, 1)
        ..close();
    case 'Emerald':
      return _cut(0.2);
    case 'Asscher':
      return _cut(0.27);
    case 'Radiant':
      return _cut(0.13);
    case 'Princess':
      return _rounded(0.08);
    case 'Cushion':
      return _rounded(0.3);
    case 'Baguette':
      return _rounded(0.05);
    case 'Tapered_Baguette':
    case 'Trapezoid':
      return _polygon(const [
        Offset(0.16, 0),
        Offset(0.84, 0),
        Offset(1, 1),
        Offset(0, 1),
      ], 0.05);
    case 'Trilliant':
      return _polygon(const [
        Offset(0.5, 0.02),
        Offset(1, 0.94),
        Offset(0, 0.94),
      ], 0.07);
    case 'Shield':
      return Path()
        ..moveTo(0.06, 0)
        ..lineTo(0.94, 0)
        ..quadraticBezierTo(1, 0, 1, 0.08)
        ..lineTo(1, 0.52)
        ..cubicTo(1, 0.78, 0.74, 0.92, 0.5, 1)
        ..cubicTo(0.26, 0.92, 0, 0.78, 0, 0.52)
        ..lineTo(0, 0.08)
        ..quadraticBezierTo(0, 0, 0.06, 0)
        ..close();
    case 'Half_Moon':
      return Path()
        ..moveTo(0, 0.3)
        ..arcToPoint(
          const Offset(1, 0.3),
          radius: const Radius.elliptical(0.5, 0.7),
          clockwise: false,
        )
        ..close();
    case 'Bullet':
      return Path()
        ..moveTo(0, 1)
        ..lineTo(0, 0.4)
        ..cubicTo(0, 0.1, 0.25, 0, 0.5, 0)
        ..cubicTo(0.75, 0, 1, 0.1, 1, 0.4)
        ..lineTo(1, 1)
        ..close();
    case 'Lozenge':
      return _polygon(const [
        Offset(0.5, 0),
        Offset(1, 0.5),
        Offset(0.5, 1),
        Offset(0, 0.5),
      ], 0.08);
    case 'Flanders':
      return _polygon(const [
        Offset(0.22, 0),
        Offset(0.78, 0),
        Offset(1, 0.5),
        Offset(0.78, 1),
        Offset(0.22, 1),
        Offset(0, 0.5),
      ], 0.05);
    default:
      return Path()..addOval(const Rect.fromLTWH(0, 0, 1, 1));
  }
}

/// Rectangle with cut (stepped) corners.
Path _cut(double c) => _polygon([
  Offset(c, 0),
  Offset(1 - c, 0),
  Offset(1, c),
  Offset(1, 1 - c),
  Offset(1 - c, 1),
  Offset(c, 1),
  Offset(0, 1 - c),
  Offset(0, c),
], 0.02);

Path _rounded(double r) =>
    Path()..addRRect(RRect.fromRectXY(const Rect.fromLTWH(0, 0, 1, 1), r, r));

/// Polygon whose corners are softened by [radius] (unit-box fraction).
Path _polygon(List<Offset> points, double radius) {
  final path = Path();
  final n = points.length;
  for (var i = 0; i < n; i++) {
    final prev = points[(i + n - 1) % n];
    final cur = points[i];
    final next = points[(i + 1) % n];
    final toPrev = prev - cur;
    final toNext = next - cur;
    final rp = math.min(radius, toPrev.distance / 2);
    final rn = math.min(radius, toNext.distance / 2);
    final a = cur + toPrev / toPrev.distance * rp;
    final b = cur + toNext / toNext.distance * rn;
    if (i == 0) {
      path.moveTo(a.dx, a.dy);
    } else {
      path.lineTo(a.dx, a.dy);
    }
    path.quadraticBezierTo(cur.dx, cur.dy, b.dx, b.dy);
  }
  return path..close();
}
