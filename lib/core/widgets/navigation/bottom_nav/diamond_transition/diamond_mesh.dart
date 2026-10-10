import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'diamond_cut.dart';

/// A captured page: the GPU image plus the shader that maps it in logical
/// pixels.
class DiamondSnapshot {
  DiamondSnapshot(this.image, this.ratio, this.size)
    : shader = ui.ImageShader(
        image,
        TileMode.clamp,
        TileMode.clamp,
        Float64List.fromList([
          1 / ratio, 0, 0, 0, //
          0, 1 / ratio, 0, 0, //
          0, 0, 1, 0, //
          0, 0, 0, 1, //
        ]),
        filterQuality: FilterQuality.low,
      );

  final ui.Image image;
  final double ratio;

  /// Logical size of the captured page.
  final Size size;
  final ui.ImageShader shader;

  void dispose() {
    shader.dispose();
    image.dispose();
  }
}

/// Everything [DiamondMesh] needs for one frame.
abstract interface class DiamondFrameSource {
  /// 0 = flat page, 1 = fully formed gem.
  double get wrap;

  /// Turn about the vertical axis (radians, + = front moves right).
  double get angle;

  DiamondCut get cutFrom;
  DiamondCut get cutTo;

  /// 0 = [cutFrom], 1 = [cutTo].
  double get cutBlend;

  /// Page carried by each sheet triangle (a snapshot id).
  Uint8List get faceTextures;

  /// Snapshot id that triangles facing away may switch to, or -1.
  int get swapTo;

  DiamondSnapshot? snapshot(int id);
}

/// Colours the gem is shaded with.
@immutable
class DiamondStyle {
  const DiamondStyle({
    required this.backdrop,
    required this.sheetBack,
    required this.accent,
    required this.isDark,
  });

  final Color backdrop;

  /// Reverse side of the sheet, seen on the corner flaps as they fold.
  final Color sheetBack;
  final Color accent;
  final bool isDark;

  @override
  bool operator ==(Object other) =>
      other is DiamondStyle &&
      other.backdrop == backdrop &&
      other.sheetBack == sheetBack &&
      other.accent == accent &&
      other.isDark == isDark;

  @override
  int get hashCode => Object.hash(backdrop, sheetBack, accent, isDark);
}

/// Folds page snapshots into a gem and paints it with flat facet shading,
/// glints and crease hairlines: a 3D-looking stone made of textured 2D
/// triangles.
///
/// Three overlapping movements, all on one sheet of [DiamondGrid]:
///
/// 1. **Fold** — the four corner flaps turn about the diagonal creases
///    joining the edge midpoints and swing in behind the page, like an
///    envelope folded from four sides.
/// 2. **Close** — the centre rises into a pyramid while the flaps meet
///    behind it: the sheet becomes an octahedron and draws in to gem size.
/// 3. **Cut** — the octahedron is pressed onto the cut's facet planes.
///
/// Every piece stays flat until it is pressed, so the creases are sharp at
/// every stage. The surface is convex, so back-facing triangles are drawn
/// first and front-facing ones over them in rough depth order; no depth
/// buffer is needed. All buffers are allocated once and reused.
class DiamondMesh {
  static const _n = DiamondGrid.size;
  static const _stride = DiamondGrid.stride;
  static const _verts = DiamondGrid.vertexCount;
  static const _tris = DiamondGrid.triangleCount;
  static const _buckets = 24;

  /// Pale spectral tints for the occasional glint.
  static const _fire = <Color>[
    Color(0xFFFFE3C4),
    Color(0xFFDDF3FF),
    Color(0xFFF2E1FF),
    Color(0xFFE4FFE9),
    Color(0xFFFFF7D6),
  ];

  // Light from the upper left, slightly in front.
  static const _lx = -0.35, _ly = -0.6, _lz = 0.72;
  // Blinn half-vector of the light and a viewer straight ahead.
  static const _hx = -0.189, _hy = -0.323, _hz = 0.927;

  /// Octahedron position of every sheet vertex (static).
  static final Float64List _octa = () {
    final out = Float64List(_verts * 3);
    for (var j = 0; j <= _n; j++) {
      for (var i = 0; i <= _n; i++) {
        DiamondGrid.octahedron(
          DiamondGrid.q(i),
          DiamondGrid.q(j),
          out,
          (j * _stride + i) * 3,
        );
      }
    }
    return out;
  }();

  /// Every sheet edge: vertex a, vertex b, the triangle on each side
  /// (-1 on the outer border). Creases are found per frame where the two
  /// sides bend apart, so fold lines, the octahedron's ridges and the cut's
  /// facet edges all come from the same flat pieces.
  static final Int32List _edges = _buildEdges();

  // Per vertex: view-space position and projected position.
  final _vx = Float64List(_verts);
  final _vy = Float64List(_verts);
  final _vz = Float64List(_verts);
  final _px = Float32List(_verts);
  final _py = Float32List(_verts);

  // Per triangle.
  final _front = Uint8List(_tris);
  final _nx = Float32List(_tris);
  final _ny = Float32List(_tris);
  final _nz = Float32List(_tris);
  final _depth = Float32List(_tris);
  final _shade = Int32List(_tris);
  final _order = Int32List(_tris);
  final _bucketStart = Int32List(_buckets + 1);
  final _bucketOf = Uint8List(_tris);

  // Draw buffers.
  final _pos = Float32List(_tris * 6);
  final _tex = Float32List(_tris * 6);
  final _col = Int32List(_tris * 3);
  final _lines = Float32List(_tris * 6);
  final _rim = Float32List(_tris * 6);

  // Frame transform (see [_transform]).
  double _cp = 1, _sp = 0, _cr = 1, _sr = 0, _ct = 1, _st = 0;
  double _lift = 0, _focal = 1, _cx = 0, _cy = 0;
  double _ox = 0, _oy = 0, _oz = 0;
  double _sx = 0, _sy = 0;

  /// Lowest projected point of the last frame (for the cast shadow).
  double _floor = 0;

  /// Corner fold: flaps turn behind about the diagonal creases.
  static double foldOf(double w) => _sine(w / 0.55);

  /// Sheet closes into an octahedron and draws in to gem size.
  static double closeOf(double w) => _sine((w - 0.25) / 0.5);

  /// Octahedron pressed onto the cut's facets.
  static double cutOf(double w) => _sine((w - 0.5) / 0.5);

  /// Girdle radius of the formed gem on a page of [size].
  static double girdleOf(Size size) =>
      0.28 * math.min(size.width, 0.6 * size.height);

  static double _sine(double t) =>
      0.5 - 0.5 * math.cos(math.pi * t.clamp(0.0, 1.0));

  void paint(
    Canvas canvas,
    Size size,
    DiamondFrameSource src,
    DiamondStyle style,
  ) {
    final w = src.wrap.clamp(0.0, 1.0);
    final width = size.width, height = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = style.backdrop);
    if (width <= 0 || height <= 0) return;

    final fold = foldOf(w), close = closeOf(w), cut = cutOf(w);
    final girdle = girdleOf(size);

    _project(size, src, fold, close, cut, girdle);
    _paintStage(canvas, size, style, close, girdle);
    final fronts = _triangles(src, style, fold, close, cut);
    _paintBack(canvas, fronts);
    _paintFront(canvas, src);
    _paintLines(canvas, style, fold, close, cut);
  }

  void _project(
    Size size,
    DiamondFrameSource src,
    double fold,
    double close,
    double cut,
    double girdle,
  ) {
    final width = size.width, height = size.height;
    final ga = src.cutFrom.gem.positions, gb = src.cutTo.gem.positions;
    final blend = src.cutBlend.clamp(0.0, 1.0);
    final phi = src.angle;

    // Spin character, blended with the cut.
    double weight(DiamondSpin spin) =>
        (src.cutFrom.spin == spin ? 1 - blend : 0) +
        (src.cutTo.spin == spin ? blend : 0);
    final detent = weight(DiamondSpin.detent);
    final precess = weight(DiamondSpin.precess);
    final shown = 0.45 * close + 0.55 * cut;
    final tilt =
        (src.cutFrom.tilt +
            (src.cutTo.tilt - src.cutFrom.tilt) * blend +
            0.07 * detent * math.sin(2 * phi) +
            0.05 * precess * math.cos(phi)) *
        shown;
    final roll = 0.09 * precess * math.sin(phi) * cut;
    _cp = math.cos(phi);
    _sp = math.sin(phi);
    _cr = math.cos(roll);
    _sr = math.sin(roll);
    _ct = math.cos(tilt);
    _st = math.sin(tilt);
    _lift = -0.04 * height * close;
    _focal = 1.4 * math.max(width, height);
    _cx = width / 2;
    _cy = height / 2;

    // Sheet extents shrink from the page to the octahedron as it closes.
    final a = width / 2, b = height / 2;
    final ex = a + (girdle * 1.02 - a) * close;
    final ey = b + (girdle * 1.12 - b) * close;
    final ez = math.min(a, b) + (girdle * 1.02 - math.min(a, b)) * close;

    // Corner flaps turn up to nearly flat behind the page.
    final beta = math.pi * 0.985 * fold;
    final cb = math.cos(beta), sb = math.sin(beta);
    const root = 0.7071067811865476;
    final octa = _octa;

    var floor = -double.infinity;
    for (var j = 0; j <= _n; j++) {
      final qy = DiamondGrid.q(j);
      for (var i = 0; i <= _n; i++) {
        final qx = DiamondGrid.q(i);
        final vi = j * _stride + i;
        final o = vi * 3;

        // 1. Fold: rigid flap turn about the crease through (±1, 0) and
        //    (0, ±1) (Rodrigues), towards the back.
        var fx = qx, fy = qy, fz = 0.0;
        if (qx.abs() + qy.abs() > 1 && fold > 0) {
          final sx = qx < 0 ? -1.0 : 1.0, sy = qy < 0 ? -1.0 : 1.0;
          final kx = -sy * root, ky = sx * root;
          final vx = qx - sx, vy = qy;
          final kv = kx * vx + ky * vy;
          final cz = kx * vy - ky * vx; // (k × v).z
          fx = vx * cb + kx * kv * (1 - cb) + sx;
          fy = vy * cb + ky * kv * (1 - cb);
          fz = cz * sb;
        }

        // 2. Close onto the octahedron.
        final x = (fx + (octa[o] - fx) * close) * ex;
        final y = (fy + (octa[o + 1] - fy) * close) * ey;
        final z = (fz + (octa[o + 2] - fz) * close) * ez;

        // 3. Press onto the cut.
        final gx = (ga[o] + (gb[o] - ga[o]) * blend) * girdle;
        final gy = (ga[o + 1] + (gb[o + 1] - ga[o + 1]) * blend) * girdle;
        final gz = (ga[o + 2] + (gb[o + 2] - ga[o + 2]) * blend) * girdle;

        _transform(x + (gx - x) * cut, y + (gy - y) * cut, z + (gz - z) * cut);
        _vx[vi] = _ox;
        _vy[vi] = _oy;
        _vz[vi] = _oz;
        _px[vi] = _sx;
        _py[vi] = _sy;
        if (_sy > floor) floor = _sy;
      }
    }
    _floor = floor;
  }

  /// Turn, lean and tilt a point, then project it; results in _o*, _s*.
  void _transform(double x, double y, double z) {
    final x1 = x * _cp + z * _sp;
    final z1 = -x * _sp + z * _cp;
    final x2 = x1 * _cr - y * _sr;
    final y2 = x1 * _sr + y * _cr;
    _oy = y2 * _ct + z1 * _st + _lift;
    _oz = -y2 * _st + z1 * _ct;
    _ox = x2;
    final k = _focal / (_focal - _oz);
    _sx = _cx + _ox * k;
    _sy = _cy + _oy * k;
  }

  /// Display backdrop: a faint pool of light and the gem's cast shadow.
  void _paintStage(
    Canvas canvas,
    Size size,
    DiamondStyle style,
    double close,
    double girdle,
  ) {
    if (close <= 0.01) return;
    final centre = Offset(size.width / 2, size.height / 2 - 0.04 * size.height);
    final glow = girdle * 2.6;
    canvas.drawCircle(
      centre,
      glow,
      Paint()
        ..shader = RadialGradient(
          colors: [
            style.accent.withValues(
              alpha: (style.isDark ? 0.10 : 0.08) * close,
            ),
            style.accent.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: centre, radius: glow)),
    );
    // Soft elliptical contact shadow: a radial pool squashed flat.
    final radius = girdle * 0.95;
    final shadow = Rect.fromCircle(center: Offset.zero, radius: radius);
    canvas.save();
    canvas.translate(size.width / 2, _floor + girdle * 0.2);
    canvas.scale(1, 0.16);
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(
              0xFF000000,
            ).withValues(alpha: (style.isDark ? 0.6 : 0.22) * close),
            const Color(0x00000000),
          ],
        ).createShader(shadow),
    );
    canvas.restore();
  }

  /// Facing, depth, texture swap and shade of every triangle. Returns the
  /// number of front-facing ones.
  int _triangles(
    DiamondFrameSource src,
    DiamondStyle style,
    double fold,
    double close,
    double cut,
  ) {
    final highlight = Color.lerp(
      const Color(0xFFFFFFFF),
      style.accent,
      style.isDark ? 0.18 : 0.28,
    )!;
    final na = src.cutFrom.gem.normals, nb = src.cutTo.gem.normals;
    final blend = src.cutBlend.clamp(0.0, 1.0);
    final faces = src.faceTextures;
    final swapTo = src.swapTo;
    final amount = 0.75 * math.max(fold, close) * (1 - cut) + cut;
    var zMin = double.infinity, zMax = -double.infinity;
    var fronts = 0;

    for (var t = 0; t < _tris; t++) {
      final i0 = DiamondGrid.vertex(t, 0);
      final i1 = DiamondGrid.vertex(t, 1);
      final i2 = DiamondGrid.vertex(t, 2);

      final cross =
          (_px[i1] - _px[i0]) * (_py[i2] - _py[i0]) -
          (_py[i1] - _py[i0]) * (_px[i2] - _px[i0]);
      final ex = _vx[i1] - _vx[i0], ey = _vy[i1] - _vy[i0];
      final ez = _vz[i1] - _vz[i0];
      final fx = _vx[i2] - _vx[i0], fy = _vy[i2] - _vy[i0];
      final fz = _vz[i2] - _vz[i0];
      var nx = ey * fz - ez * fy;
      var ny = ez * fx - ex * fz;
      var nz = ex * fy - ey * fx;
      var len = math.sqrt(nx * nx + ny * ny + nz * nz);
      if (len > 1e-9) {
        nx /= len;
        ny /= len;
        nz /= len;
      } else {
        nx = ny = 0;
        nz = 1;
      }

      _nx[t] = nx;
      _ny[t] = ny;
      _nz[t] = nz;
      // Pavilion facets sit below the girdle on the cut.
      final o = t * 3;
      final pavilion =
          cut > 0 && na[o + 1] + (nb[o + 1] - na[o + 1]) * blend > 0.05;

      final depth = (_vz[i0] + _vz[i1] + _vz[i2]) / 3;
      _depth[t] = depth;
      final lit = nx * _lx + ny * _ly + nz * _lz;
      if (cross > 0) {
        _front[t] = 1;
        fronts++;
        if (depth < zMin) zMin = depth;
        if (depth > zMax) zMax = depth;
        var facet = (0.5 + 0.7 * lit).clamp(0.22, 1.2);
        if (cut > 0) {
          // Crown facets take the light directly; pavilion facets return
          // it reflected inside the stone (normal mirrored up).
          final base = pavilion
              ? 0.2 + 0.95 * (nx * _lx - ny * _ly + nz * _lz)
              : 0.36 + 0.95 * lit;
          // Brilliance keyed to each facet's facing, so light and dark
          // facets trade places as the stone turns.
          final facing = math.atan2(nx, nz);
          final sparkle =
              0.3 * math.cos(8 * facing + 1.3 * ny) +
              0.12 * math.cos(3 * facing - 2 * ny);
          facet += (base * (1 + sparkle) - facet) * cut;
        }
        final m = 1 + (facet.clamp(0.14, 1.3) - 1) * amount;
        final h = nx * _hx + ny * _hy + nz * _hz;
        final glint = math.max(close * 0.5, cut);
        final spec = h > 0 ? math.pow(h, 36) * 0.55 * glint : 0.0;
        final light = math.max(0.0, m - 1) + spec;
        final dark = math.max(0.0, 1 - m);
        if (light > dark) {
          // A whisper of fire on the brightest glints.
          final tone = spec > 0.18
              ? Color.lerp(
                  highlight,
                  _fire[((math.atan2(nx, nz) + math.pi) * 1.9).floor() %
                      _fire.length],
                  0.6,
                )!
              : highlight;
          _shade[t] = tone.withValues(alpha: math.min(light, 0.6)).toARGB32();
        } else {
          _shade[t] = const Color(
            0xFF000000,
          ).withValues(alpha: math.min(dark, 0.8)).toARGB32();
        }
      } else {
        _front[t] = 0;
        // Facing away: the page it carries can change unseen.
        if (swapTo >= 0) faces[t] = swapTo;
        // Reverse of the sheet, lit from its own side.
        final inner = (0.38 + 0.4 * math.max(0.0, -lit)).clamp(0.0, 1.0);
        _shade[t] = Color.lerp(
          const Color(0xFF000000),
          style.sheetBack,
          inner,
        )!.toARGB32();
      }
    }

    // Far-to-near bucket order of the front faces.
    final range = zMax - zMin;
    _bucketStart.fillRange(0, _bucketStart.length, 0);
    for (var t = 0; t < _tris; t++) {
      if (_front[t] == 0) continue;
      final k = range < 1e-6
          ? 0
          : ((_depth[t] - zMin) / range * (_buckets - 1)).round();
      _bucketOf[t] = k;
      _bucketStart[k + 1]++;
    }
    for (var k = 0; k < _buckets; k++) {
      _bucketStart[k + 1] += _bucketStart[k];
    }
    final fill = Int32List.fromList(_bucketStart);
    for (var t = 0; t < _tris; t++) {
      if (_front[t] == 0) continue;
      _order[fill[_bucketOf[t]]++] = t;
    }
    return fronts;
  }

  /// Appends triangle [t] with a flat [colour] at vertex slot [n].
  int _emitColoured(int t, int colour, int n) {
    for (var k = 0; k < 3; k++) {
      final i = DiamondGrid.vertex(t, k);
      _pos[n * 2] = _px[i];
      _pos[n * 2 + 1] = _py[i];
      _col[n] = colour;
      n++;
    }
    return n;
  }

  /// Appends triangle [t] textured from a page of [sw] × [sh] at slot [n].
  int _emitTextured(int t, double sw, double sh, int n) {
    for (var k = 0; k < 3; k++) {
      final i = DiamondGrid.vertex(t, k);
      _pos[n * 2] = _px[i];
      _pos[n * 2 + 1] = _py[i];
      _tex[n * 2] = (i % _stride) / _n * sw;
      _tex[n * 2 + 1] = (i ~/ _stride) / _n * sh;
      n++;
    }
    return n;
  }

  void _drawColoured(Canvas canvas, int n) {
    if (n == 0) return;
    final vertices = ui.Vertices.raw(
      ui.VertexMode.triangles,
      Float32List.sublistView(_pos, 0, n * 2),
      colors: Int32List.sublistView(_col, 0, n),
    );
    canvas.drawVertices(vertices, BlendMode.dst, Paint());
    vertices.dispose();
  }

  void _paintBack(Canvas canvas, int fronts) {
    if (fronts == _tris) return;
    var n = 0;
    for (var t = 0; t < _tris; t++) {
      if (_front[t] == 0) n = _emitColoured(t, _shade[t], n);
    }
    _drawColoured(canvas, n);
  }

  void _paintFront(Canvas canvas, DiamondFrameSource src) {
    final count = _bucketStart[_buckets];
    if (count == 0) return;
    final faces = src.faceTextures;

    // One textured batch per carried page.
    final ids = <int>{for (var o = 0; o < count; o++) faces[_order[o]]};
    for (final id in ids) {
      final snap = src.snapshot(id);
      if (snap == null) continue;
      final sw = snap.size.width, sh = snap.size.height;
      var n = 0;
      for (var o = 0; o < count; o++) {
        final t = _order[o];
        if (faces[t] == id) n = _emitTextured(t, sw, sh, n);
      }
      if (n == 0) continue;
      final vertices = ui.Vertices.raw(
        ui.VertexMode.triangles,
        Float32List.sublistView(_pos, 0, n * 2),
        textureCoordinates: Float32List.sublistView(_tex, 0, n * 2),
      );
      canvas.drawVertices(
        vertices,
        BlendMode.srcOver,
        Paint()..shader = snap.shader,
      );
      vertices.dispose();
    }

    // Facet shading and glints over the page.
    var n = 0;
    for (var o = 0; o < count; o++) {
      final t = _order[o];
      final colour = _shade[t];
      if ((colour >>> 24) != 0) n = _emitColoured(t, colour, n);
    }
    _drawColoured(canvas, n);
  }

  /// Creases where neighbouring pieces bend apart, the silhouette, and the
  /// sheet's outer edge — all from this frame's flat pieces.
  void _paintLines(
    Canvas canvas,
    DiamondStyle style,
    double fold,
    double close,
    double cut,
  ) {
    final strength = math.min(1.0, 2.5 * math.max(fold, close));
    if (strength <= 0.02) return;
    final e = _edges;
    var creases = 0, rims = 0, borders = _lines.length;
    for (var k = 0; k < e.length; k += 4) {
      final a = e[k], b = e[k + 1], t0 = e[k + 2], t1 = e[k + 3];
      if (t1 < 0) {
        if (_front[t0] == 0) continue;
        _lines[--borders] = _py[b];
        _lines[--borders] = _px[b];
        _lines[--borders] = _py[a];
        _lines[--borders] = _px[a];
        continue;
      }
      final f0 = _front[t0] == 1, f1 = _front[t1] == 1;
      if (!f0 && !f1) continue;
      if (f0 != f1) {
        _rim[rims++] = _px[a];
        _rim[rims++] = _py[a];
        _rim[rims++] = _px[b];
        _rim[rims++] = _py[b];
        continue;
      }
      final dot = _nx[t0] * _nx[t1] + _ny[t0] * _ny[t1] + _nz[t0] * _nz[t1];
      if (dot > 0.995) continue;
      if (creases + 4 > borders) break;
      _lines[creases++] = _px[a];
      _lines[creases++] = _py[a];
      _lines[creases++] = _px[b];
      _lines[creases++] = _py[b];
    }

    final glint = Color.lerp(const Color(0xFFFFFFFF), style.accent, 0.15)!;
    if (creases > 0) {
      _strokeCrease(
        canvas,
        Float32List.sublistView(_lines, 0, creases),
        style,
        strength,
        glint,
      );
    }
    if (rims > 0) {
      _strokeCrease(
        canvas,
        Float32List.sublistView(_rim, 0, rims),
        style,
        strength * math.max(close, cut),
        glint,
      );
    }
    if (borders < _lines.length) {
      canvas.drawRawPoints(
        ui.PointMode.lines,
        Float32List.sublistView(_lines, borders),
        Paint()
          ..strokeWidth = 0.8
          ..strokeCap = StrokeCap.round
          ..color = const Color(
            0xFF000000,
          ).withValues(alpha: (style.isDark ? 0.4 : 0.12) * strength),
      );
    }
  }

  /// A dark cut line with a bright bevel over it reads on any page.
  void _strokeCrease(
    Canvas canvas,
    Float32List points,
    DiamondStyle style,
    double strength,
    Color glint,
  ) {
    canvas.drawRawPoints(
      ui.PointMode.lines,
      points,
      Paint()
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round
        ..color = const Color(
          0xFF000000,
        ).withValues(alpha: (style.isDark ? 0.35 : 0.2) * strength),
    );
    canvas.drawRawPoints(
      ui.PointMode.lines,
      points,
      Paint()
        ..strokeWidth = 0.5
        ..strokeCap = StrokeCap.round
        ..color = glint.withValues(
          alpha: (style.isDark ? 0.45 : 0.6) * strength,
        ),
    );
  }

  static Int32List _buildEdges() {
    final out = <int>[];
    final seen = <int, int>{};
    for (var t = 0; t < _tris; t++) {
      for (var k = 0; k < 3; k++) {
        final a = DiamondGrid.vertex(t, k);
        final b = DiamondGrid.vertex(t, (k + 1) % 3);
        final key = a < b ? a * _verts + b : b * _verts + a;
        final at = seen[key];
        if (at == null) {
          seen[key] = out.length;
          out.addAll([a, b, t, -1]);
        } else {
          out[at + 3] = t;
        }
      }
    }
    return Int32List.fromList(out);
  }
}
