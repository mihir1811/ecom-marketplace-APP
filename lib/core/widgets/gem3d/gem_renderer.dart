import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'gem_mesh.dart';

/// Optical look of a stone: body tone, light tint and dispersion strength.
@immutable
class GemLook {
  const GemLook({
    required this.body,
    required this.light,
    this.fire = 0.55,
    this.brilliance = 1,
  });

  /// Colourless diamond under warm studio light.
  static const white = GemLook(
    body: Color(0xFF1A1C22),
    light: Color(0xFFFFF4E2),
  );

  /// Champagne / fancy-yellow stone.
  static const champagne = GemLook(
    body: Color(0xFF2A1F12),
    light: Color(0xFFF6D59A),
    fire: 0.35,
  );

  /// Cool ice-blue stone.
  static const ice = GemLook(
    body: Color(0xFF141C26),
    light: Color(0xFFDDEBFF),
    fire: 0.6,
  );

  final Color body;
  final Color light;
  final double fire;
  final double brilliance;
}

/// Pose of one stone in world space (x right, y up, z toward the viewer).
class GemPose {
  GemPose({
    this.x = 0,
    this.y = 0,
    this.z = 0,
    this.scale = 1,
    this.rx = 0,
    this.ry = 0,
    this.rz = 0,
  });

  double x, y, z, scale, rx, ry, rz;

  /// Optional row-major 3×3 rotation that replaces [rx]/[ry]/[rz] where
  /// supported (the diamond batch), for poses driven by quaternions.
  List<double>? basis;
}

/// Perspective camera. [unit] is pixels per world unit at z = 0; the eye
/// sits at ([eyeX], [eyeY], [distance]) looking down −z.
class GemCamera {
  const GemCamera({
    required this.center,
    required this.unit,
    this.distance = 9,
    this.eyeX = 0,
    this.eyeY = 0,
  });

  final Offset center;
  final double unit;
  final double distance;
  final double eyeX;
  final double eyeY;

  /// Perspective factor at depth [z].
  double depthScale(double z) => distance / math.max(0.5, distance - z);

  Offset project(double x, double y, double z) {
    final k = depthScale(z) * unit;
    return Offset(center.dx + (x - eyeX) * k, center.dy - (y - eyeY) * k);
  }
}

/// A star glint to draw over a facet that catches the key light.
class GemGlint {
  const GemGlint(this.position, this.intensity, this.size);

  final Offset position;
  final double intensity;
  final double size;
}

/// Accumulates flat-shaded triangles from many stones into one
/// [ui.Vertices] draw, plus their glints. Reuse one batch per painter.
class GemBatch {
  Float32List _pos = Float32List(0);
  Int32List _col = Int32List(0);
  int _tris = 0;
  final List<GemGlint> glints = [];

  void reset() {
    _tris = 0;
    glints.clear();
  }

  void _ensure(int extraTris) {
    final need = (_tris + extraTris) * 3;
    if (_col.length >= need) return;
    final cap = math.max(need, _col.length * 2);
    final pos = Float32List(cap * 2)..setRange(0, _tris * 6, _pos);
    final col = Int32List(cap)..setRange(0, _tris * 3, _col);
    _pos = pos;
    _col = col;
  }

  /// Draws the batch, then additive glints from [glintSprite] (if loaded).
  void paint(Canvas canvas, {ui.Image? glintSprite, double glintScale = 1}) {
    if (_tris > 0) {
      final vertices = ui.Vertices.raw(
        ui.VertexMode.triangles,
        Float32List.sublistView(_pos, 0, _tris * 6),
        colors: Int32List.sublistView(_col, 0, _tris * 3),
      );
      canvas.drawVertices(vertices, BlendMode.dst, Paint());
      vertices.dispose();
    }
    final sprite = glintSprite;
    if (sprite == null || glints.isEmpty) return;
    final src = Rect.fromLTWH(
      0,
      0,
      sprite.width.toDouble(),
      sprite.height.toDouble(),
    );
    final paint = Paint()..blendMode = BlendMode.plus;
    for (final g in glints) {
      final s = g.size * glintScale;
      paint.color = Color.fromRGBO(255, 255, 255, g.intensity.clamp(0, 1));
      canvas.drawImageRect(
        sprite,
        src,
        Rect.fromCenter(center: g.position, width: s, height: s),
        paint,
      );
    }
  }

  // Light directions (unit vectors, world space).
  static const _kx = -0.42, _ky = 0.74, _kz = 0.53; // key: top-left front
  static const _fx = 0.76, _fy = 0.18, _fz = 0.62; // fill: right
  static const _bx = 0.18, _by = 0.55, _bz = -0.81; // rim: behind

  /// Appends one stone. [fog] (0..1) fades it toward [fogColor] for depth.
  /// [time] animates dispersion; [flash] (0..1) brightens the whole stone.
  void addGem({
    required GemMesh mesh,
    required GemPose pose,
    required GemCamera camera,
    required GemLook look,
    double time = 0,
    double fog = 0,
    Color fogColor = const Color(0xFF070709),
    double flash = 0,
    bool glint = true,
    double light = 0,
    Offset lightFrom = Offset.zero,
    Color lightColor = const Color(0xFFFFD39A),
    double phase = 0,
    bool flat = false,
  }) {
    _ensure(mesh.triangleCount);

    // Rotation R = Ry · Rx · Rz.
    final cx = math.cos(pose.rx), sx = math.sin(pose.rx);
    final cy = math.cos(pose.ry), sy = math.sin(pose.ry);
    final cz = math.cos(pose.rz), sz = math.sin(pose.rz);
    final m00 = cy * cz + sy * sx * sz;
    final m01 = -cy * sz + sy * sx * cz;
    final m02 = sy * cx;
    final m10 = cx * sz;
    final m11 = cx * cz;
    final m12 = -sx;
    final m20 = -sy * cz + cy * sx * sz;
    final m21 = sy * sz + cy * sx * cz;
    final m22 = cy * cx;

    final eyeX = camera.eyeX, eyeY = camera.eyeY, eyeZ = camera.distance;
    final v = mesh.vertices, n = mesh.normals, seeds = mesh.seeds;
    final s = pose.scale;

    final bodyR = look.body.r, bodyG = look.body.g, bodyB = look.body.b;
    final lightR = look.light.r, lightG = look.light.g, lightB = look.light.b;
    final fogR = fogColor.r, fogG = fogColor.g, fogB = fogColor.b;
    final keep = 1 - fog.clamp(0.0, 1.0);
    final lit = light.clamp(0.0, 1.0);
    // A touch "lights" the stone: brighter returns and stronger fire.
    final brilliance = look.brilliance * (1 + flash * 0.9 + lit * 1.5);
    final fireGain = look.fire * (0.75 + lit * 0.9);
    final ambient = 0.05 + lit * 0.06;
    // Point light at the touch: [lightFrom] is the screen-space direction
    // from the stone toward it, so facets turned to the finger glow warm.
    var plx = lightFrom.dx, ply = -lightFrom.dy, plz = 0.55;
    final pl = math.sqrt(plx * plx + ply * ply + plz * plz);
    plx /= pl;
    ply /= pl;
    plz /= pl;
    final warmR = lightColor.r * lit, warmG = lightColor.g * lit;
    final warmB = lightColor.b * lit;

    var bestSpark = 0.0;
    var bestX = 0.0, bestY = 0.0, bestZ = 0.0;

    for (var t = 0; t < mesh.triangleCount; t++) {
      final ox = n[t * 3], oy = n[t * 3 + 1], oz = n[t * 3 + 2];
      final nx = m00 * ox + m01 * oy + m02 * oz;
      final ny = m10 * ox + m11 * oy + m12 * oz;
      final nz = m20 * ox + m21 * oy + m22 * oz;

      // Transform corners; cull against the view vector at corner 0.
      final b = t * 9;
      final wx0 = (m00 * v[b] + m01 * v[b + 1] + m02 * v[b + 2]) * s + pose.x;
      final wy0 = (m10 * v[b] + m11 * v[b + 1] + m12 * v[b + 2]) * s + pose.y;
      final wz0 = (m20 * v[b] + m21 * v[b + 1] + m22 * v[b + 2]) * s + pose.z;
      if (nx * (eyeX - wx0) + ny * (eyeY - wy0) + nz * (eyeZ - wz0) <= 0) {
        continue;
      }

      final kind = mesh.kinds[t];
      final seed = seeds[t];
      final base = _tris * 3;
      var cxSum = 0.0, cySum = 0.0, czSum = 0.0;
      var triSpark = 0.0;
      var color = 0;

      for (var c = 0; c < 3; c++) {
        final i = b + c * 3;
        final double wx, wy, wz;
        if (c == 0) {
          wx = wx0;
          wy = wy0;
          wz = wz0;
        } else {
          wx = (m00 * v[i] + m01 * v[i + 1] + m02 * v[i + 2]) * s + pose.x;
          wy = (m10 * v[i] + m11 * v[i + 1] + m12 * v[i + 2]) * s + pose.y;
          wz = (m20 * v[i] + m21 * v[i + 1] + m22 * v[i + 2]) * s + pose.z;
        }
        cxSum += wx;
        cySum += wy;
        czSum += wz;

        // Project.
        final k = camera.unit * eyeZ / math.max(0.5, eyeZ - wz);
        _pos[(base + c) * 2] = camera.center.dx + (wx - eyeX) * k;
        _pos[(base + c) * 2 + 1] = camera.center.dy - (wy - eyeY) * k;

        // Flat-shaded stones (far, defocused) reuse the first corner.
        if (flat && c > 0) {
          _col[base + c] = color;
          continue;
        }

        // View vector toward the eye, then mirror reflection.
        var vx = eyeX - wx, vy = eyeY - wy, vz = eyeZ - wz;
        final vl = math.sqrt(vx * vx + vy * vy + vz * vz);
        vx /= vl;
        vy /= vl;
        vz /= vl;
        final ndv = nx * vx + ny * vy + nz * vz;
        final rx = 2 * ndv * nx - vx;
        final ry = 2 * ndv * ny - vy;
        final rz = 2 * ndv * nz - vz;

        final key = math.max(0.0, rx * _kx + ry * _ky + rz * _kz);
        final fill = math.max(0.0, rx * _fx + ry * _fy + rz * _fz);
        final rim = math.max(0.0, rx * _bx + ry * _by + rz * _bz);
        final key2 = key * key;
        final key8 = key2 * key2 * key2 * key2;
        final key32 = key8 * key8 * key8 * key8;
        final fill4 = fill * fill * fill * fill;
        final rim2 = rim * rim;
        final rim8 = rim2 * rim2 * rim2 * rim2;

        // Pavilion facets return light through the table (total internal
        // reflection), so they read brighter and shift with rotation.
        final internal = kind == GemFacetKind.pavilion
            ? 0.55 + 0.45 * math.sin(seed * 12 + time * 0.8 + ry * 3)
            : 1.0;
        final env =
            (key32 * 2.2 + key8 * 0.35) * internal +
            fill4 * 0.4 +
            rim8 * 0.9 +
            ambient +
            0.07 * math.max(0.0, ry);
        final edge = 1 - ndv.abs();
        final fresnel = 0.35 + 0.65 * edge * edge * edge;
        final tableBoost = kind == GemFacetKind.table ? 0.85 : 1.0;
        final lum = env * (0.55 + 0.45 * fresnel) * tableBoost * brilliance;

        final shade = 0.55 + 0.45 * math.max(0.0, ny);
        var r = bodyR * shade + lightR * lum;
        var g = bodyG * shade + lightG * lum;
        var bl = bodyB * shade + lightB * lum;
        if (lit > 0) {
          final face = math.max(0.0, nx * plx + ny * ply + nz * plz);
          final hit = math.max(0.0, rx * plx + ry * ply + rz * plz);
          final hit4 = hit * hit * hit * hit;
          final warm = 0.12 + face * 0.5 + hit4 * hit4 * 1.4;
          r += warmR * warm;
          g += warmG * warm;
          bl += warmB * warm;
        }

        // Dispersion: a hue that drifts with the reflection direction.
        final fireAmt = fireGain * math.min(1.0, key8 * 1.6);
        if (fireAmt > 0.004) {
          final hue = seed * 6.283 + rx * 5 + ry * 3 + time * 0.6;
          r += (0.5 + 0.5 * math.cos(hue)) * fireAmt;
          g += (0.5 + 0.5 * math.cos(hue - 2.094)) * fireAmt;
          bl += (0.5 + 0.5 * math.cos(hue + 2.094)) * fireAmt;
        }

        r = r * keep + fogR * (1 - keep);
        g = g * keep + fogG * (1 - keep);
        bl = bl * keep + fogB * (1 - keep);

        color =
            0xFF000000 |
            ((r.clamp(0.0, 1.0) * 255).round() << 16) |
            ((g.clamp(0.0, 1.0) * 255).round() << 8) |
            (bl.clamp(0.0, 1.0) * 255).round();
        _col[base + c] = color;

        if (c == 0 && glint && kind != GemFacetKind.girdle) {
          triSpark = key32 * (0.6 + 0.4 * seed) + key8 * lit * 0.5;
        }
      }
      if (triSpark > bestSpark) {
        bestSpark = triSpark;
        bestX = cxSum / 3;
        bestY = cySum / 3;
        bestZ = czSum / 3;
      }
      _tris++;
    }

    // Lit stones glint far more readily, and twinkle while lit.
    final threshold = 0.55 * (1 - 0.8 * lit);
    if (glint && bestSpark > threshold) {
      final at = camera.project(bestX, bestY, bestZ);
      final px = pose.scale * camera.unit * camera.depthScale(pose.z);
      final twinkle = lit > 0
          ? 1 - lit * 0.45 * (0.5 + 0.5 * math.sin(time * 9 + phase * 6.283))
          : 1.0;
      glints.add(
        GemGlint(
          at,
          ((bestSpark - threshold) / (1 - threshold)).clamp(0.0, 1.0) *
              keep *
              (1 + flash + lit * 0.8) *
              twinkle,
          px * (1.6 + lit * 1.6),
        ),
      );
    }
  }
}

/// Lazily rendered four-point star used for facet glints.
abstract final class GemGlintSprite {
  static ui.Image? _image;

  static ui.Image get image => _image ??= _render();

  static ui.Image _render() {
    const size = 128.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const c = Offset(size / 2, size / 2);
    final core = Paint()
      ..shader = ui.Gradient.radial(c, size * 0.16, const [
        Color(0xFFFFFFFF),
        Color(0x00FFF4E2),
      ]);
    canvas.drawCircle(c, size * 0.16, core);
    final ray = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6);
    for (final vertical in [false, true]) {
      ray.shader = ui.Gradient.linear(
        vertical ? const Offset(size / 2, 0) : const Offset(0, size / 2),
        vertical ? const Offset(size / 2, size) : const Offset(size, size / 2),
        const [Color(0x00FFFFFF), Color(0xFFFFFFFF), Color(0x00FFFFFF)],
        const [0, 0.5, 1],
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: c,
          width: vertical ? 3.2 : size,
          height: vertical ? size : 3.2,
        ),
        ray,
      );
    }
    final picture = recorder.endRecording();
    final image = picture.toImageSync(size.toInt(), size.toInt());
    picture.dispose();
    return image;
  }
}
