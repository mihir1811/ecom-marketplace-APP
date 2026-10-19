import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../diamond_education/simulation/sim_renderer.dart';
import '../domain/jewelry_metal.dart';
import '../geometry/jmath.dart';
import '../geometry/jmesh.dart';
import '../scene/jewelry_scene.dart';
import 'jewelry_camera.dart';

/// Draws a [JScene]: metal, velvet and melee by deferred shading, the
/// centre stones by the diamond simulator's own ray tracer.
///
/// Each frame the CPU moves every mesh to where physics put it, culls
/// back faces, sorts triangles far to near (a linear-time radix sort of
/// their depths) and rasterises them with [Canvas.drawVertices], their
/// colours carrying view-space normals and material tags, into a
/// G-buffer image. `shaders/jewelry_shade.frag` then shades each pixel:
/// metal mirrors a studio with physically based Fresnel, velvet glows at
/// grazing angles, melee facets flash. A traced stone is opaque, so it
/// is painted in depth order between the triangles behind and in front
/// of it: prongs on the near side grip over its crown, the halo behind
/// it is hidden by it.
///
/// Without the shading program (while it loads, or where fragment
/// programs are missing) vertices are shaded on the CPU instead.
class JewelryRenderer {
  ui.FragmentProgram? _program;
  final List<ui.FragmentShader> _shaders = [];
  ui.FragmentProgram? _diamondProgram;

  JScene? _scene;
  final List<SimRenderer> _traced = [];

  static Future<ui.FragmentProgram>? _load;

  /// The shading program, loaded once per run.
  static Future<ui.FragmentProgram> loadProgram() =>
      _load ??= ui.FragmentProgram.fromAsset('shaders/jewelry_shade.frag');

  set program(ui.FragmentProgram? p) {
    for (final s in _shaders) {
      s.dispose();
    }
    _shaders.clear();
    _program = p;
  }

  bool get hasProgram => _program != null;

  set diamondProgram(ui.FragmentProgram? p) {
    _diamondProgram = p;
    for (final r in _traced) {
      r.shader?.dispose();
      r.shader = p?.fragmentShader();
    }
  }

  /// Linear exposure before tone mapping.
  double exposure = 1.0;

  // Geometry of the current scene, flattened.
  int _triCount = 0;
  Int32List _tris = Int32List(0);
  final List<(JPart, int)> _bases = [];

  // Per-frame buffers.
  Float32List _vx = Float32List(0), _vy = Float32List(0), _vz = Float32List(0);
  Float32List _sx = Float32List(0), _sy = Float32List(0);
  Int32List _col = Int32List(0);
  Uint8List _ok = Uint8List(0);
  Float32List _key = Float32List(0);
  Int32List _order = Int32List(0), _tmp = Int32List(0), _pick = Int32List(0);
  Uint32List _q = Uint32List(0), _qTmp = Uint32List(0);
  Float32List _keyTmp = Float32List(0);
  Float32List _pos = Float32List(0);
  Int32List _vcol = Int32List(0);

  final List<ui.Image> _frameImages = [];

  void setScene(JScene scene) {
    if (identical(scene, _scene)) return;
    final restyle = _scene != null && identical(scene.parts, _scene!.parts);
    _scene = scene;
    // A new metal or finish on the same geometry: nothing to rebuild.
    if (restyle) return;
    for (final r in _traced) {
      r.dispose();
    }
    _traced.clear();
    for (final s in scene.stones) {
      final r = SimRenderer()
        ..maxBounces = SimRenderer.bounces
        ..measureStats = false
        ..setStone(s.stone.mesh, s.stone.inclusions)
        ..setOptics(s.stone.optics);
      r.shader = _diamondProgram?.fragmentShader();
      _traced.add(r);
    }
    _bases.clear();
    var v = 0, t = 0;
    for (final p in scene.parts) {
      _bases.add((p, v));
      v += p.mesh.vertexCount;
      t += p.mesh.triangleCount;
    }
    _triCount = t;
    _tris = Int32List(t * 3);
    var k = 0;
    for (final (p, base) in _bases) {
      for (final i in p.mesh.idx) {
        _tris[k++] = base + i;
      }
    }
    _vx = Float32List(v);
    _vy = Float32List(v);
    _vz = Float32List(v);
    _sx = Float32List(v);
    _sy = Float32List(v);
    _col = Int32List(v);
    _ok = Uint8List(v);
    _key = Float32List(t);
    _order = Int32List(t);
    _tmp = Int32List(t);
    _pick = Int32List(t);
    _q = Uint32List(t);
    _qTmp = Uint32List(t);
    _keyTmp = Float32List(t);
    _pos = Float32List(t * 6);
    _vcol = Int32List(t * 3);
  }

  void dispose() {
    _releaseFrame();
    program = null;
    for (final r in _traced) {
      r.dispose();
    }
    _traced.clear();
  }

  void _releaseFrame() {
    for (final i in _frameImages) {
      i.dispose();
    }
    _frameImages.clear();
  }

  final Float64List _m = Float64List(12);
  final Float64List _stoneXf = Float64List(12);
  final Float64List _stoneView = Float64List(12);

  /// Paints the scene for [cam] (already updated for [size]). The
  /// G-buffer has [renderScale] pixels per logical pixel, at most
  /// [devicePixelRatio].
  void paint(
    Canvas canvas,
    Size size,
    JCamera cam, {
    double devicePixelRatio = 1,
    double? renderScale,
  }) {
    final scene = _scene;
    if (scene == null || size.isEmpty) return;
    // The canvas holds its own references to last frame's images until
    // that frame is drawn; by now it has been.
    _releaseFrame();
    final view = cam.view;
    final shade = _program != null;
    final f = cam.focal, cx = cam.cx, cy = cam.cy;

    // 1. Move, project and colour every vertex.
    final f0 = scene.design.metal.f0(scene.design.purity);
    final f0b = scene.design.settingMetal.f0(scene.design.settingPurity);
    final rough = scene.design.finish.roughness;
    for (final (part, base) in _bases) {
      M34.mul(view, part.node.xf, _m);
      final m = _m, mesh = part.mesh;
      final pos = mesh.pos, nrm = mesh.nrm, tag = mesh.tag;
      for (var i = 0; i < mesh.vertexCount; i++) {
        final x = pos[i * 3], y = pos[i * 3 + 1], z = pos[i * 3 + 2];
        final vx = m[0] * x + m[1] * y + m[2] * z + m[3];
        final vy = m[4] * x + m[5] * y + m[6] * z + m[7];
        final vz = m[8] * x + m[9] * y + m[10] * z + m[11];
        final k = base + i;
        _vx[k] = vx;
        _vy[k] = vy;
        _vz[k] = vz;
        final d = -vz;
        if (d < 1) {
          _ok[k] = 0;
          continue;
        }
        _ok[k] = 1;
        _sx[k] = cx + f * vx / d;
        _sy[k] = cy - f * vy / d;
        final a = nrm[i * 3], b = nrm[i * 3 + 1], c = nrm[i * 3 + 2];
        final nx = m[0] * a + m[1] * b + m[2] * c;
        final ny = m[4] * a + m[5] * b + m[6] * c;
        final nz = m[8] * a + m[9] * b + m[10] * c;
        _col[k] = shade
            ? _encode(nx, ny, tag[i])
            : _cpuShade(nx, ny, nz, tag[i], f0, f0b, rough);
      }
    }

    // 2. Cull back faces and off-screen triangles; key the rest by depth.
    var visible = 0;
    var kmin = double.infinity, kmax = -double.infinity;
    final w = size.width, h = size.height;
    for (var t = 0; t < _triCount; t++) {
      final a = _tris[t * 3], b = _tris[t * 3 + 1], c = _tris[t * 3 + 2];
      if (_ok[a] == 0 || _ok[b] == 0 || _ok[c] == 0) continue;
      final ax = _sx[a], ay = _sy[a], bx = _sx[b], by = _sy[b];
      final qx = _sx[c], qy = _sy[c];
      // Counter-clockwise from outside reads clockwise on a y-down screen.
      if ((bx - ax) * (qy - ay) - (qx - ax) * (by - ay) >= 0) continue;
      if (math.max(ax, math.max(bx, qx)) < 0 ||
          math.min(ax, math.min(bx, qx)) > w ||
          math.max(ay, math.max(by, qy)) < 0 ||
          math.min(ay, math.min(by, qy)) > h) {
        continue;
      }
      final key = -(_vz[a] + _vz[b] + _vz[c]);
      _key[visible] = key;
      _order[visible] = t;
      if (key < kmin) kmin = key;
      if (key > kmax) kmax = key;
      visible++;
    }
    _sortFarToNear(visible, kmin, kmax);

    // 3. The whole piece in one G-buffer, then each stone, far to near,
    // with whatever lies in front of it drawn again over it. (Splitting
    // the G-buffer at a stone's depth instead would leave seams where
    // the two halves' smoothed edges meet.)
    final scale = math
        .min(renderScale ?? devicePixelRatio, devicePixelRatio)
        .clamp(0.75, 4.0);
    _drawTris(canvas, _order, visible, size, cam, scale, f0, f0b, rough);
    final stones = <(double, int)>[];
    for (var i = 0; i < scene.stones.length; i++) {
      scene.stones[i].worldTransform(_stoneXf);
      M34.mul(view, _stoneXf, _stoneView);
      stones.add((-_stoneView[11] * 3, i));
    }
    stones.sort((a, b) => b.$1.compareTo(a.$1));
    for (final (depth3, i) in stones) {
      final rect = _paintStone(canvas, i, cam, devicePixelRatio, scale);
      if (rect == null) continue;
      var start = 0;
      while (start < visible && _key[start] > depth3) {
        start++;
      }
      var n = 0;
      for (var k = start; k < visible; k++) {
        final tri = _order[k];
        final a = _tris[tri * 3],
            b = _tris[tri * 3 + 1],
            c = _tris[tri * 3 + 2];
        if (math.max(_sx[a], math.max(_sx[b], _sx[c])) < rect.left ||
            math.min(_sx[a], math.min(_sx[b], _sx[c])) > rect.right ||
            math.max(_sy[a], math.max(_sy[b], _sy[c])) < rect.top ||
            math.min(_sy[a], math.min(_sy[b], _sy[c])) > rect.bottom) {
          continue;
        }
        _pick[n++] = tri;
      }
      if (n == 0) continue;
      canvas
        ..save()
        ..clipRect(rect);
      _drawTris(
        canvas,
        _pick,
        n,
        size,
        cam,
        scale,
        f0,
        f0b,
        rough,
        limit: rect,
      );
      canvas.restore();
    }
  }

  static int _byte(double v) => (v * 255).round().clamp(0, 255);

  static int _encode(double nx, double ny, double tag) =>
      0xFF000000 |
      (_byte(nx * 0.5 + 0.5) << 16) |
      (_byte(ny * 0.5 + 0.5) << 8) |
      _byte(tag);

  /// Sorts `_order[0 .. n)` (with `_key`) by decreasing depth: two
  /// 8-bit radix passes over 16-bit quantised keys.
  void _sortFarToNear(int n, double kmin, double kmax) {
    if (n < 2) return;
    final span = math.max(1e-6, kmax - kmin);
    for (var i = 0; i < n; i++) {
      _q[i] = 65535 - ((_key[i] - kmin) / span * 65535).round().clamp(0, 65535);
    }
    final keys = _keyTmp, qtmp = _qTmp;
    for (var shift = 0; shift < 16; shift += 8) {
      final count = Int32List(257);
      for (var i = 0; i < n; i++) {
        count[((_q[i] >> shift) & 255) + 1]++;
      }
      for (var b = 0; b < 256; b++) {
        count[b + 1] += count[b];
      }
      for (var i = 0; i < n; i++) {
        final b = (_q[i] >> shift) & 255;
        final j = count[b]++;
        _tmp[j] = _order[i];
        keys[j] = _key[i];
        qtmp[j] = _q[i];
      }
      _order.setRange(0, n, _tmp);
      _key.setRange(0, n, keys);
      _q.setRange(0, n, qtmp);
    }
  }

  /// Rasterises triangles `tris[0 .. count)`, far to near, and shades
  /// them, within [limit] when given.
  void _drawTris(
    Canvas canvas,
    Int32List tris,
    int count,
    Size size,
    JCamera cam,
    double scale,
    JRgb f0,
    JRgb f0b,
    double rough, {
    Rect? limit,
  }) {
    if (count <= 0) return;
    var l = double.infinity, t = double.infinity;
    var r = -double.infinity, b = -double.infinity;
    for (var k = 0; k < count; k++) {
      final tri = tris[k];
      for (var j = 0; j < 3; j++) {
        final v = _tris[tri * 3 + j];
        final x = _sx[v], y = _sy[v];
        if (x < l) l = x;
        if (x > r) r = x;
        if (y < t) t = y;
        if (y > b) b = y;
      }
    }
    var bounds = Rect.fromLTRB(
      l - 1,
      t - 1,
      r + 1,
      b + 1,
    ).intersect(Offset.zero & size);
    if (limit != null) bounds = bounds.intersect(limit.inflate(1));
    if (bounds.width <= 0 || bounds.height <= 0) return;
    final program = _program;
    final ox = program == null ? 0.0 : bounds.left,
        oy = program == null ? 0.0 : bounds.top;
    final s = program == null ? 1.0 : scale;
    var p = 0, c = 0;
    for (var k = 0; k < count; k++) {
      final tri = tris[k];
      for (var j = 0; j < 3; j++) {
        final v = _tris[tri * 3 + j];
        _pos[p++] = (_sx[v] - ox) * s;
        _pos[p++] = (_sy[v] - oy) * s;
        _vcol[c++] = _col[v];
      }
    }
    final vertices = ui.Vertices.raw(
      ui.VertexMode.triangles,
      Float32List.sublistView(_pos, 0, p),
      colors: Int32List.sublistView(_vcol, 0, c),
    );
    if (program == null) {
      canvas.drawVertices(vertices, BlendMode.dst, _plain);
      vertices.dispose();
      return;
    }
    final gw = (bounds.width * s).ceil(), gh = (bounds.height * s).ceil();
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawVertices(vertices, BlendMode.dst, _plain);
    final picture = recorder.endRecording();
    final image = picture.toImageSync(gw, gh);
    picture.dispose();
    vertices.dispose();
    _frameImages.add(image);

    final index = _frameImages.length - 1;
    while (_shaders.length <= index) {
      _shaders.add(program.fragmentShader());
    }
    final sh = _shaders[index];
    final scene = _scene!;
    final tint = _gemTint(scene);
    // View → world is the transpose of the camera's rotation.
    final v = cam.view;
    sh
      ..setFloat(0, bounds.left)
      ..setFloat(1, bounds.top)
      ..setFloat(2, s / gw)
      ..setFloat(3, s / gh)
      ..setFloat(4, cam.cx)
      ..setFloat(5, cam.cy)
      ..setFloat(6, cam.focal)
      ..setFloat(7, exposure)
      ..setFloat(8, v[0])
      ..setFloat(9, v[4])
      ..setFloat(10, v[8])
      ..setFloat(11, 0)
      ..setFloat(12, v[1])
      ..setFloat(13, v[5])
      ..setFloat(14, v[9])
      ..setFloat(15, 0)
      ..setFloat(16, v[2])
      ..setFloat(17, v[6])
      ..setFloat(18, v[10])
      ..setFloat(19, 0)
      ..setFloat(20, f0.r)
      ..setFloat(21, f0.g)
      ..setFloat(22, f0.b)
      ..setFloat(23, rough)
      ..setFloat(24, tint.r)
      ..setFloat(25, tint.g)
      ..setFloat(26, tint.b)
      ..setFloat(27, 1.25)
      ..setFloat(28, velvet.r)
      ..setFloat(29, velvet.g)
      ..setFloat(30, velvet.b)
      ..setFloat(31, 0.8)
      ..setFloat(32, f0b.r)
      ..setFloat(33, f0b.g)
      ..setFloat(34, f0b.b)
      ..setFloat(35, rough)
      ..setImageSampler(0, image, filterQuality: FilterQuality.low);
    canvas.drawRect(bounds, Paint()..shader = sh);
  }

  // Unsmoothed edges: blended edge pixels would mix two surfaces'
  // normals and tags, and leave seams between neighbouring triangles.
  final Paint _plain = Paint()..isAntiAlias = false;

  /// Display velvet colour, linear: a deep blue-black.
  static const JRgb velvet = (r: 0.028, g: 0.030, b: 0.044);

  JRgb? _tint;
  Object? _tintFor;

  /// The melee's body colour from the centre stone's grade: white light
  /// after a few millimetres through the stone.
  JRgb _gemTint(JScene scene) {
    if (identical(_tintFor, scene.design.stone) && _tint != null) return _tint!;
    final a = scene.design.stone.absorption;
    double t(double v) => math.exp(-v * 1.2);
    _tintFor = scene.design.stone;
    return _tint = (r: t(a.r), g: t(a.g), b: t(a.b));
  }

  /// Paints traced stone [i] where its node holds it, turned to match.
  ///
  /// [SimRenderer] turns a stone by tilt and spin about its own axes and
  /// draws it centred; any orientation is that, then a roll in the
  /// picture plane, which the canvas applies.
  Rect? _paintStone(
    Canvas canvas,
    int i,
    JCamera cam,
    double dpr,
    double scale,
  ) {
    final scene = _scene!;
    final js = scene.stones[i];
    js.worldTransform(_stoneXf);
    M34.mul(cam.view, _stoneXf, _stoneView);
    final a = _stoneView;
    final depth = -a[11];
    if (depth < 1) return null;
    final sx = cam.cx + cam.focal * a[3] / depth;
    final sy = cam.cy - cam.focal * a[7] / depth;
    // Stone y (table axis) and x in view space.
    final ax = a[1], ay = a[5], az = a[9];
    final bx = a[0], by = a[4], bz = a[8];
    final tilt = math.asin(az.clamp(-1.0, 1.0));
    final ct = math.cos(tilt), st = math.sin(tilt);
    final roll = ct > 1e-4 ? math.atan2(-ax, ay) : 0.0;
    final cr = math.cos(roll), sr = math.sin(roll);
    final bpx = cr * bx + sr * by, bpy = -sr * bx + cr * by;
    final spin = math.atan2(st * bpy - ct * bz, bpx);
    final pxPerUnit = cam.focal / depth * js.stone.mmPerUnit;
    final r = js.stone.mesh.radius * pxPerUnit * 1.15;
    if (r < 0.5) return null;
    canvas
      ..save()
      ..translate(sx, sy)
      ..rotate(-roll)
      ..translate(-r, -r);
    _traced[i].paint(
      canvas,
      Size.square(r * 2),
      view: SimView(tilt: tilt, spin: spin),
      pxPerUnit: pxPerUnit,
      samplePx: 5,
      devicePixelRatio: dpr,
      renderScale: scale,
    );
    canvas.restore();
    return Rect.fromCircle(center: Offset(sx, sy), radius: r);
  }

  // ---- CPU fallback ----------------------------------------------------

  static double _tone(double x) {
    if (x <= 0) return 0;
    final y = (x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14);
    return math.pow(y.clamp(0.0, 1.0), 1 / 2.2).toDouble();
  }

  /// A simple per-vertex look: metal mirrors a bright overhead and a
  /// dim floor, velvet is matte, melee sparkles by facet.
  static int _cpuShade(
    double nx,
    double ny,
    double nz,
    double tag,
    JRgb metal,
    JRgb setting,
    double rough,
  ) {
    double r, g, b;
    if (JTag.isMetal(tag)) {
      final f0 = JTag.isHeadMetal(tag) ? setting : metal;
      final ao = 0.3 + 0.7 * JTag.metalAo(tag);
      final ry = 2 * nz * ny; // reflected view ray's height
      final env =
          0.05 +
          0.5 * smoothstep(-0.2, 0.8, ry) +
          2.2 * math.pow(math.max(0.0, ry), 8 / (1 + rough * 6));
      r = f0.r * env * ao;
      g = f0.g * env * ao;
      b = f0.b * env * ao;
    } else if (JTag.isGem(tag)) {
      final seed = (tag - 0.70) / 0.30;
      final flash = math
          .pow((math.sin(seed * 40 + nx * 9 + ny * 7) * 0.5 + 0.5), 6)
          .toDouble();
      r = g = b = 0.25 + 2.5 * flash;
    } else {
      final ao = 0.25 + 0.75 * ((tag - 0.45) / 0.20).clamp(0.0, 1.0);
      final lit =
          0.25 + 0.75 * math.max(0.0, -0.45 * nx + 0.75 * ny + 0.5 * nz);
      final sheen = math.pow(1 - nz.clamp(0.0, 1.0), 2.5) * 1.5;
      r = velvet.r * (lit + sheen) * ao;
      g = velvet.g * (lit + sheen) * ao;
      b = velvet.b * (lit + sheen) * ao;
    }
    return 0xFF000000 |
        (_byte(_tone(r)) << 16) |
        (_byte(_tone(g)) << 8) |
        _byte(_tone(b));
  }
}
