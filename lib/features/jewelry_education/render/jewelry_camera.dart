import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import '../geometry/jmath.dart';

/// An orbiting perspective camera, world in millimetres.
///
/// View space: x right, y up, the camera looking down −z from the
/// origin, so a point's depth is −z.
class JCamera {
  JCamera({
    required this.target,
    required this.yaw,
    required this.pitch,
    required this.distance,
  });

  V3 target;
  double yaw, pitch, distance;

  /// Vertical field of view: a moderate telephoto, as jewelry is shot,
  /// which keeps the piece in true proportion.
  static const fovY = 0.42;

  /// World → view, 3×4 row-major.
  final Float64List view = M34.identity();
  double focal = 1, cx = 0, cy = 0;
  V3 eye = V3.zero,
      right = V3.unitX,
      up = V3.unitY,
      forward = const V3(0, 0, -1);

  /// Distance at which a sphere of [radius] fills [size].
  static double fitDistance(double radius, Size size) {
    final aspect = size.width / math.max(1.0, size.height);
    final half = math.min(fovY / 2, math.atan(math.tan(fovY / 2) * aspect));
    return radius / math.sin(half);
  }

  void update(Size size) {
    final cp = math.cos(pitch), sp = math.sin(pitch);
    final offset = V3(math.sin(yaw) * cp, sp, math.cos(yaw) * cp) * distance;
    eye = target + offset;
    forward = (target - eye).normalized;
    right = forward.cross(V3.unitY).normalized;
    up = right.cross(forward);
    final back = -forward;
    view
      ..[0] = right.x
      ..[1] = right.y
      ..[2] = right.z
      ..[3] = -right.dot(eye)
      ..[4] = up.x
      ..[5] = up.y
      ..[6] = up.z
      ..[7] = -up.dot(eye)
      ..[8] = back.x
      ..[9] = back.y
      ..[10] = back.z
      ..[11] = -back.dot(eye);
    focal = size.height / 2 / math.tan(fovY / 2);
    cx = size.width / 2;
    cy = size.height / 2;
  }

  /// Screen position of world point [p], or null behind the camera.
  Offset? project(V3 p) {
    final v = M34.apply(view, p);
    final d = -v.z;
    if (d < 1) return null;
    return Offset(cx + focal * v.x / d, cy - focal * v.y / d);
  }

  /// Logical pixels per millimetre at world point [p].
  double pxPerMm(V3 p) => focal / math.max(1.0, -M34.apply(view, p).z);

  /// World direction through screen point [s].
  V3 ray(Offset s) {
    final x = (s.dx - cx) / focal, y = -(s.dy - cy) / focal;
    return (right * x + up * y + forward).normalized;
  }

  /// Where the ray through [s] meets the plane through [p] facing the
  /// camera: for dragging a point across the screen.
  V3 onPlane(Offset s, V3 p) {
    final d = ray(s);
    final t = (p - eye).dot(forward) / math.max(1e-6, d.dot(forward));
    return eye + d * t;
  }
}
