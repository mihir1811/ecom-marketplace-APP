import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../../core/widgets/gem3d/diamond_renderer.dart';
import '../domain/diamond_grades.dart';
import 'sim_inclusions.dart';
import 'sim_mesh.dart';
import 'sim_optics.dart';
import 'sim_tracer.dart';

/// Orientation and zoom of the simulated stone. [spin] turns it about its
/// own table axis, [tilt] tips that axis toward the viewer: 0 is a side
/// view with the table up, π/2 face up, −π/2 culet up.
class SimView {
  const SimView({required this.tilt, required this.spin, this.zoom = 1});

  final double tilt, spin, zoom;
}

/// Light performance measured on the last frame, 0..1: [brightness] is
/// white light returned, [fire] its colour, [sparkle] the share of crown
/// facets flashing.
class SimFrameStats {
  double brightness = 0, fire = 0, sparkle = 0;
  int samples = 0;
}

/// Draws a [SimMesh] by tracing light through it.
///
/// With a [shader] (`shaders/diamond_trace.frag`) every pixel traces its
/// own path on the GPU: facet patterns come out exact and crisp, with
/// anti-aliased edges. The CPU tracer then runs only at a coarse sample
/// spacing, every few frames, to measure light performance ([stats]).
///
/// Without one (while it loads, or where fragment programs are missing)
/// the CPU tracer samples every visible facet and fills between samples
/// (Gouraud); the spacing is set in screen pixels so cost follows the
/// stone's size on screen, and callers can coarsen it to hold frame rate.
///
/// The GPU trace can run at fewer pixels than the screen has
/// ([renderScale]) and is then scaled up smoothly: the cost of a moving
/// stone drops by half or more for a barely visible softening.
///
/// Buffers are reused frame to frame, so steady painting allocates only
/// the [ui.Vertices] (CPU) or one offscreen image (GPU, reduced scale)
/// handed to the canvas.
class SimRenderer {
  final SimTracer _tracer = SimTracer();
  final SimFrameStats stats = SimFrameStats();

  SimMesh? _mesh;
  List<SimInclusion> _inclusions = const [];
  SimLighting? _lighting;

  /// Camera distance in model units; enough perspective to feel solid.
  static const _eye = 9.0;

  /// Most samples in one stone, whatever its size on screen.
  static const _sampleBudget = 2600;

  /// Linear light to display; matches the shader.
  static const _exposure = 0.95;

  /// HDR luminance above which a facet counts as flashing.
  static const _sparkThreshold = 6.0;

  /// Facet plane slots in the shader.
  static const _maxPlanes = 140;

  /// Per-pixel GPU tracer; null falls back to the CPU renderer.
  ui.FragmentShader? shader;

  /// Whether the GPU path measures [stats]; off when nothing shows them.
  bool measureStats = true;

  /// Most bounces the light-performance measurement follows; the meters
  /// settle well before the picture does.
  static const _measureBounces = 6;

  /// Shortest gap between measurements while the stone moves.
  static const _measureGap = Duration(milliseconds: 220);

  final Stopwatch _clock = Stopwatch()..start();
  Duration _measuredAt = -_measureGap;
  bool _statsDirty = true;

  /// Asks for fresh [stats] on the next paint, e.g. once a stone settles.
  void requestStats() => _statsDirty = true;

  ui.Image? _frameImage;

  /// Releases GPU resources; the renderer must not paint afterwards.
  void dispose() {
    _frameImage?.dispose();
    _frameImage = null;
    shader?.dispose();
    shader = null;
  }

  static Future<ui.FragmentProgram>? _program;

  /// The per-pixel tracer program, loaded once per run.
  static Future<ui.FragmentProgram> loadProgram() =>
      _program ??= ui.FragmentProgram.fromAsset('shaders/diamond_trace.frag');

  /// Whether [shader] can draw [mesh] (its plane slots are bounded).
  static bool fitsShader(SimMesh mesh) => mesh.facetCount <= _maxPlanes;

  void setStone(SimMesh mesh, List<SimInclusion> inclusions) {
    _mesh = mesh;
    _inclusions = inclusions;
    _tracer.mesh = mesh;
    _statsDirty = true;
  }

  void setOptics(SimOptics optics) {
    _tracer.optics = optics;
    _statsDirty = true;
    if (_lighting != optics.lighting) {
      _lighting = optics.lighting;
      _tracer.studio = SimStudio(optics.lighting);
    }
  }

  set maxBounces(int value) => _tracer.maxBounces = value;

  // ---- Sample layout -------------------------------------------------

  SimMesh? _layoutFor;
  double _layoutUnits = -1;
  Float64List _sp = Float64List(0);
  Int32List _fs = Int32List(1), _ft = Int32List(1);
  Int32List _tri = Int32List(0);

  /// Lays samples on every facet about [units] apart (model units).
  void _layout(SimMesh mesh, double units) {
    final starts = mesh.facetStart, fv = mesh.facetVerts;
    final pos = mesh.positions;
    for (var pass = 0; pass < 4; pass++) {
      final rings = Int32List(mesh.facetCount);
      var samples = 0, tris = 0;
      for (var f = 0; f < mesh.facetCount; f++) {
        final k = starts[f + 1] - starts[f];
        var cx = 0.0, cy = 0.0, cz = 0.0;
        for (var j = starts[f]; j < starts[f + 1]; j++) {
          cx += pos[fv[j] * 3];
          cy += pos[fv[j] * 3 + 1];
          cz += pos[fv[j] * 3 + 2];
        }
        cx /= k;
        cy /= k;
        cz /= k;
        var reach = 0.0;
        for (var j = starts[f]; j < starts[f + 1]; j++) {
          final dx = pos[fv[j] * 3] - cx, dy = pos[fv[j] * 3 + 1] - cy;
          final dz = pos[fv[j] * 3 + 2] - cz;
          reach = math.max(reach, dx * dx + dy * dy + dz * dz);
        }
        // Girdle facets are thin bands: one ring is plenty.
        final n = mesh.kinds[f] == SimFacetKind.girdle.index
            ? 1
            : (math.sqrt(reach) / units).ceil().clamp(1, 12);
        rings[f] = n;
        samples += 1 + k * n * (n + 1) ~/ 2;
        tris += k * n * n;
      }
      if (samples > _sampleBudget && pass < 3) {
        units *= math.sqrt(samples / _sampleBudget) * 1.05;
        continue;
      }

      _sp = Float64List(samples * 3);
      _fs = Int32List(mesh.facetCount + 1);
      _ft = Int32List(mesh.facetCount + 1);
      _tri = Int32List(tris * 3);
      var s = 0, t = 0;
      for (var f = 0; f < mesh.facetCount; f++) {
        final k = starts[f + 1] - starts[f];
        final tpl = _Template.of(k, rings[f]);
        var cx = 0.0, cy = 0.0, cz = 0.0;
        for (var j = starts[f]; j < starts[f + 1]; j++) {
          cx += pos[fv[j] * 3];
          cy += pos[fv[j] * 3 + 1];
          cz += pos[fv[j] * 3 + 2];
        }
        cx /= k;
        cy /= k;
        cz /= k;
        _fs[f] = s;
        _ft[f] = t;
        for (var q = 0; q < tpl.count; q++) {
          final a = fv[starts[f] + tpl.sector[q]] * 3;
          final b = fv[starts[f] + (tpl.sector[q] + 1) % k] * 3;
          final wa = tpl.wa[q], wb = tpl.wb[q], wc = tpl.wc[q];
          _sp[s * 3] = wc * cx + wa * pos[a] + wb * pos[b];
          _sp[s * 3 + 1] = wc * cy + wa * pos[a + 1] + wb * pos[b + 1];
          _sp[s * 3 + 2] = wc * cz + wa * pos[a + 2] + wb * pos[b + 2];
          s++;
        }
        for (var q = 0; q < tpl.tris.length; q++) {
          _tri[t * 3 + q] = tpl.tris[q];
        }
        t += tpl.tris.length ~/ 3;
      }
      _fs[mesh.facetCount] = s;
      _ft[mesh.facetCount] = t;
      break;
    }
    _layoutFor = mesh;
    _layoutUnits = units;
  }

  // ---- Frame buffers -------------------------------------------------

  Float32List _vp = Float32List(0);
  Int32List _vc = Int32List(0);
  Uint16List _vi = Uint16List(0);
  Float32List _bp = Float32List(0);
  Int32List _bc = Int32List(0);
  Uint16List _bi = Uint16List(0);
  Float32List _px = Float32List(0), _py = Float32List(0);

  // Best sample per facet for sparkles: luminance, screen xy, rgb.
  Float64List _spark = Float64List(0);

  final Paint _vertexPaint = Paint();
  final Paint _dot = Paint()..isAntiAlias = true;
  final Paint _line = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  static double _tone(double x) {
    if (x <= 0) return 0;
    // ACES filmic fit, display gamma and a little S-curve: the same
    // curve as the shader.
    x *= _exposure;
    final y = (x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14);
    if (y >= 1) return 1;
    final g = math.pow(y, 1 / 2.2).toDouble();
    return g + 0.3 * (g * g * (3 - 2 * g) - g);
  }

  final Float64List _rot = Float64List(9);
  final List<int> _hullIds = [];

  /// Paints the stone centred in [size]. [pxPerUnit] maps model units to
  /// logical pixels at zoom 1; CPU samples land about [samplePx] pixels
  /// apart. The GPU traces [renderScale] pixels per logical pixel, capped
  /// at [devicePixelRatio], which also sizes its edge anti-aliasing.
  void paint(
    Canvas canvas,
    Size size, {
    required SimView view,
    required double pxPerUnit,
    required double samplePx,
    double devicePixelRatio = 1,
    double? renderScale,
    double time = 0,
    bool twinkle = false,
  }) {
    final mesh = _mesh;
    if (mesh == null || size.isEmpty) return;
    final scale = pxPerUnit * view.zoom;
    final gpu = shader != null && fitsShader(mesh);
    // On the GPU path the CPU trace only measures light, so a coarse,
    // fixed spacing is plenty, and only a few times a second.
    final units = gpu ? 0.2 : samplePx / scale;
    var measure = !gpu;
    if (gpu && measureStats) {
      final now = _clock.elapsed;
      if (_statsDirty || now - _measuredAt >= _measureGap) {
        measure = true;
        _statsDirty = false;
        _measuredAt = now;
      }
    }
    if ((measure || !gpu) &&
        (!identical(_layoutFor, mesh) ||
            (units - _layoutUnits).abs() > _layoutUnits * 0.12)) {
      _layout(mesh, units);
    }

    // Model → world: spin about the table axis, then tilt toward viewer.
    final cs = math.cos(view.spin), ss = math.sin(view.spin);
    final ct = math.cos(view.tilt), st = math.sin(view.tilt);
    final r00 = cs, r01 = 0.0, r02 = ss;
    final r10 = st * ss, r11 = ct, r12 = -st * cs;
    final r20 = -ct * ss, r21 = st, r22 = ct * cs;
    final rot = _rot
      ..[0] = r00
      ..[1] = r01
      ..[2] = r02
      ..[3] = r10
      ..[4] = r11
      ..[5] = r12
      ..[6] = r20
      ..[7] = r21
      ..[8] = r22;
    final tracer = _tracer..rotation(rot);
    const d0 = _eye;
    final ex = d0 * r20, ey = d0 * r21, ez = d0 * r22;
    final cx = size.width / 2, cy = size.height / 2;

    // Project every mesh vertex once (facet outlines for the base layer).
    final vcount = mesh.vertexCount;
    if (_px.length < vcount) {
      _px = Float32List(vcount);
      _py = Float32List(vcount);
    }
    final pos = mesh.positions;
    for (var i = 0; i < vcount; i++) {
      final x = pos[i * 3], y = pos[i * 3 + 1], z = pos[i * 3 + 2];
      final wx = r00 * x + r01 * y + r02 * z;
      final wy = r10 * x + r11 * y + r12 * z;
      final wz = r20 * x + r21 * y + r22 * z;
      final k = scale * d0 / (d0 - wz);
      _px[i] = cx + wx * k;
      _py[i] = cy - wy * k;
    }

    if (gpu) {
      final s = math.min(renderScale ?? devicePixelRatio, devicePixelRatio);
      _paintGpu(canvas, mesh, scale, cx, cy, devicePixelRatio, s, rot);
      if (measure) {
        final bounces = tracer.maxBounces;
        tracer.maxBounces = math.min(bounces, _measureBounces);
        _measure(mesh, ex, ey, ez);
        tracer.maxBounces = bounces;
      }
    } else {
      _paintCpu(canvas, mesh, scale, cx, cy, ex, ey, ez, rot, time, twinkle);
    }

    if (_inclusions.isNotEmpty) {
      // Inclusions and their mirror images stay inside the silhouette.
      canvas
        ..save()
        ..clipPath(_hull(vcount));
      _paintInclusions(
        canvas,
        scale,
        cx,
        cy,
        rot,
        // Pavilion mirrors show when looking in through the crown.
        mirror: st.clamp(0.0, 1.0),
      );
      canvas.restore();
    }

    final optics = tracer.optics;
    if (optics.lighting == SimLighting.ultraviolet) {
      final glow = (optics.emitR + optics.emitG + optics.emitB) / 1.5;
      if (glow > 0.01) {
        final radius = mesh.radius * scale * 1.5;
        final c = Offset(cx, cy);
        final m = math.max(optics.emitR, math.max(optics.emitG, optics.emitB));
        Color tint(double a) => Color.fromRGBO(
          (optics.emitR / m * 255).round(),
          (optics.emitG / m * 255).round(),
          (optics.emitB / m * 255).round(),
          a,
        );
        canvas.drawCircle(
          c,
          radius,
          _glowPaint
            ..shader = ui.Gradient.radial(c, radius, [
              tint((0.16 * glow).clamp(0.0, 0.3)),
              tint(0),
            ]),
        );
      }
    }
  }

  // ---- GPU path ------------------------------------------------------

  final Paint _gpuPaint = Paint();
  final Paint _glowPaint = Paint()..blendMode = BlendMode.plus;
  final Paint _blitPaint = Paint()..filterQuality = FilterQuality.medium;
  ui.FragmentShader? _uniformShader;
  SimMesh? _uniformMesh;
  SimStudio? _uniformStudio;

  // Uniform float offsets in shaders/diamond_trace.frag.
  static const _uPlanes = 36;
  static const _uBoxes = _uPlanes + _maxPlanes * 4;
  static const _uSpots = _uBoxes + SimStudio.maxBoxes * 12;

  void _paintGpu(
    Canvas canvas,
    SimMesh mesh,
    double scale,
    double cx,
    double cy,
    double dpr,
    double renderScale,
    Float64List r,
  ) {
    final sh = shader!;
    if (!identical(sh, _uniformShader)) {
      _uniformShader = sh;
      _uniformMesh = null;
      _uniformStudio = null;
    }
    if (!identical(mesh, _uniformMesh)) {
      _uniformMesh = mesh;
      _setPlanes(sh, mesh);
    }
    final studio = _tracer.studio;
    if (!identical(studio, _uniformStudio)) {
      _uniformStudio = studio;
      final boxes = studio.packedBoxes, spots = studio.packedSpots;
      for (var i = 0; i < boxes.length; i++) {
        sh.setFloat(_uBoxes + i, boxes[i]);
      }
      for (var i = 0; i < spots.length; i++) {
        sh.setFloat(_uSpots + i, spots[i]);
      }
      sh.setFloat(23, studio.ambient);
    }
    final o = _tracer.optics;
    sh
      ..setFloat(0, cx)
      ..setFloat(1, cy)
      ..setFloat(2, scale)
      ..setFloat(3, _eye);
    for (var row = 0; row < 3; row++) {
      for (var k = 0; k < 3; k++) {
        sh.setFloat(4 + row * 4 + k, r[row * 3 + k]);
      }
    }
    // Pixels actually traced per logical pixel.
    final s = renderScale.clamp(0.5, dpr);
    sh
      ..setFloat(18, _tracer.maxBounces.toDouble())
      ..setFloat(19, _exposure)
      ..setFloat(24, o.absorbR + o.haze)
      ..setFloat(25, o.absorbG + o.haze)
      ..setFloat(26, o.absorbB + o.haze)
      ..setFloat(27, o.haze * 0.35 + o.milk)
      ..setFloat(28, o.emitR)
      ..setFloat(29, o.emitG)
      ..setFloat(30, o.emitB)
      ..setFloat(31, o.lighting == SimLighting.ultraviolet ? 1 : 0)
      ..setFloat(32, mesh.radius)
      ..setFloat(33, 1 / (scale * s))
      ..setFloat(34, 1 / s)
      ..setFloat(35, studio.lowestLight);

    // Trace only the silhouette's bounds: the projected corners plus a
    // pixel for the anti-aliased edge.
    var l = double.infinity, t = double.infinity;
    var rt = -double.infinity, b = -double.infinity;
    for (var i = 0; i < mesh.vertexCount; i++) {
      l = math.min(l, _px[i]);
      rt = math.max(rt, _px[i]);
      t = math.min(t, _py[i]);
      b = math.max(b, _py[i]);
    }
    final bounds = Rect.fromLTRB(l - 2, t - 2, rt + 2, b + 2);
    _gpuPaint.shader = sh;

    if (s >= dpr - 0.05) {
      canvas.drawRect(bounds, _gpuPaint);
      return;
    }
    // Trace at reduced density offscreen, then scale up with filtering.
    final w = (bounds.width * s).ceil(), h = (bounds.height * s).ceil();
    if (w <= 0 || h <= 0) return;
    final recorder = ui.PictureRecorder();
    Canvas(recorder)
      ..scale(s)
      ..translate(-bounds.left, -bounds.top)
      ..drawRect(bounds, _gpuPaint);
    final picture = recorder.endRecording();
    final image = picture.toImageSync(w, h);
    picture.dispose();
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      Rect.fromLTWH(bounds.left, bounds.top, w / s, h / s),
      _blitPaint,
    );
    // The canvas keeps its own reference until the frame is drawn.
    _frameImage?.dispose();
    _frameImage = image;
  }

  /// Facet planes, solid ones first, and the band beyond which a ray has
  /// to test the girdle (see [SimMesh.innerRadius]).
  static void _setPlanes(ui.FragmentShader sh, SimMesh mesh) {
    final planes = mesh.planes, pos = mesh.positions;
    final girdle = mesh.girdleFacets.toSet();
    final order = [
      for (var f = 0; f < mesh.facetCount; f++)
        if (!girdle.contains(f)) f,
      ...mesh.girdleFacets,
    ];
    for (var i = 0; i < order.length; i++) {
      for (var k = 0; k < 4; k++) {
        sh.setFloat(_uPlanes + i * 4 + k, planes[order[i] * 4 + k]);
      }
    }
    var a = 0.0, b = 0.0;
    for (var i = 0; i < mesh.vertexCount; i++) {
      a = math.max(a, pos[i * 3].abs());
      b = math.max(b, pos[i * 3 + 2].abs());
    }
    final ia = 1 / (a * a), ib = 1 / (b * b);
    // Inner reach of the girdle, in units of that ellipse: its corners
    // and the midpoints of the chords between them.
    var rim = double.infinity;
    final starts = mesh.facetStart, fv = mesh.facetVerts;
    for (final f in mesh.girdleFacets) {
      final k = starts[f + 1] - starts[f];
      for (var j = 0; j < k; j++) {
        final p = fv[starts[f] + j] * 3;
        final q = fv[starts[f] + (j + 1) % k] * 3;
        for (final w in const [0.0, 0.5]) {
          final x = pos[p] + (pos[q] - pos[p]) * w;
          final z = pos[p + 2] + (pos[q + 2] - pos[p + 2]) * w;
          rim = math.min(rim, x * x * ia + z * z * ib);
        }
      }
    }
    if (!rim.isFinite) rim = 0;
    sh
      ..setFloat(16, (mesh.facetCount - girdle.length).toDouble())
      ..setFloat(17, mesh.facetCount.toDouble())
      ..setFloat(20, ia)
      ..setFloat(21, ib)
      ..setFloat(22, rim * 0.95);
  }

  /// Traces the crown's layout samples for [stats], without drawing.
  void _measure(SimMesh mesh, double ex, double ey, double ez) {
    final tracer = _tracer;
    final planes = mesh.planes, kinds = mesh.kinds;
    final tableKind = SimFacetKind.table.index;
    final crownKind = SimFacetKind.crown.index;
    var lumSum = 0.0, fireSum = 0.0, crownSamples = 0;
    var crownFacets = 0, flashing = 0;
    for (var f = 0; f < mesh.facetCount; f++) {
      if (kinds[f] != tableKind && kinds[f] != crownKind) continue;
      final o = f * 4;
      final facing =
          planes[o] * ex +
          planes[o + 1] * ey +
          planes[o + 2] * ez -
          planes[o + 3];
      if (facing <= 1e-6) continue;
      crownFacets++;
      var best = 0.0;
      for (var s = _fs[f]; s < _fs[f + 1]; s++) {
        final px = _sp[s * 3], py = _sp[s * 3 + 1], pz = _sp[s * 3 + 2];
        final dx = px - ex, dy = py - ey, dz = pz - ez;
        final l = 1 / math.sqrt(dx * dx + dy * dy + dz * dz);
        tracer.trace(f, px, py, pz, dx * l, dy * l, dz * l);
        final hr = tracer.outR, hg = tracer.outG, hb = tracer.outB;
        final r = _tone(hr), g = _tone(hg), b = _tone(hb);
        final tl = 0.2126 * r + 0.7152 * g + 0.0722 * b;
        lumSum += tl;
        fireSum +=
            (math.max(r, math.max(g, b)) - math.min(r, math.min(g, b))) * tl;
        crownSamples++;
        best = math.max(best, 0.2126 * hr + 0.7152 * hg + 0.0722 * hb);
      }
      if (best > _sparkThreshold) flashing++;
    }
    _setStats(lumSum, fireSum, crownSamples, crownFacets, flashing);
  }

  void _setStats(
    double lumSum,
    double fireSum,
    int crownSamples,
    int crownFacets,
    int flashing,
  ) {
    stats
      ..samples = crownSamples
      ..brightness = crownSamples == 0 ? 0 : lumSum / crownSamples
      ..fire = crownSamples == 0
          ? 0
          : (fireSum / crownSamples * 4).clamp(0.0, 1.0)
      ..sparkle = crownFacets == 0 ? 0 : flashing / crownFacets;
  }

  // ---- CPU path ------------------------------------------------------

  void _paintCpu(
    Canvas canvas,
    SimMesh mesh,
    double scale,
    double cx,
    double cy,
    double ex,
    double ey,
    double ez,
    Float64List rot,
    double time,
    bool twinkle,
  ) {
    const d0 = _eye;
    final tracer = _tracer;
    final r00 = rot[0], r01 = rot[1], r02 = rot[2];
    final r10 = rot[3], r11 = rot[4], r12 = rot[5];
    final r20 = rot[6], r21 = rot[7], r22 = rot[8];
    final vcount = mesh.vertexCount;
    final planes = mesh.planes, kinds = mesh.kinds;
    final starts = mesh.facetStart, fv = mesh.facetVerts;
    final facets = mesh.facetCount;
    final totalSamples = _fs[facets];
    if (_vc.length < totalSamples) {
      _vp = Float32List(totalSamples * 2);
      _vc = Int32List(totalSamples);
    }
    if (_vi.length < _tri.length) _vi = Uint16List(_tri.length);
    final baseTris = (fv.length - 2 * facets).clamp(0, 1 << 20);
    if (_bi.length < baseTris * 3) {
      _bi = Uint16List(baseTris * 3);
    }
    if (_bp.length < vcount * 2) {
      _bp = Float32List(vcount * 2);
      _bc = Int32List(vcount);
    }
    if (_spark.length < facets * 6) _spark = Float64List(facets * 6);

    // Base layer: every visible facet as a dark silhouette, so seams
    // between independently sampled facets never show the background.
    for (var i = 0; i < vcount; i++) {
      _bp[i * 2] = _px[i];
      _bp[i * 2 + 1] = _py[i];
      _bc[i] = 0xFF060608;
    }
    var bi = 0;

    var vn = 0, in_ = 0;
    var lumSum = 0.0, fireSum = 0.0, crownSamples = 0;
    var crownFacets = 0, flashing = 0;
    const sparkThreshold = _sparkThreshold;
    final tableKind = SimFacetKind.table.index;
    final crownKind = SimFacetKind.crown.index;

    for (var f = 0; f < facets; f++) {
      final o = f * 4;
      final facing =
          planes[o] * ex +
          planes[o + 1] * ey +
          planes[o + 2] * ez -
          planes[o + 3];
      _spark[f * 6] = 0;
      if (facing <= 1e-6) continue;

      final a = fv[starts[f]];
      for (var j = starts[f] + 1; j < starts[f + 1] - 1; j++) {
        _bi[bi++] = a;
        _bi[bi++] = fv[j];
        _bi[bi++] = fv[j + 1];
      }

      final faceUp = kinds[f] == tableKind || kinds[f] == crownKind;
      if (faceUp) crownFacets++;
      final base = vn;
      var best = 0.0;
      for (var s = _fs[f]; s < _fs[f + 1]; s++) {
        final px = _sp[s * 3], py = _sp[s * 3 + 1], pz = _sp[s * 3 + 2];
        var dx = px - ex, dy = py - ey, dz = pz - ez;
        final l = 1 / math.sqrt(dx * dx + dy * dy + dz * dz);
        dx *= l;
        dy *= l;
        dz *= l;
        tracer.trace(f, px, py, pz, dx, dy, dz);
        final hr = tracer.outR, hg = tracer.outG, hb = tracer.outB;
        final r = _tone(hr), g = _tone(hg), b = _tone(hb);

        final wx = r00 * px + r01 * py + r02 * pz;
        final wy = r10 * px + r11 * py + r12 * pz;
        final wz = r20 * px + r21 * py + r22 * pz;
        final k = scale * d0 / (d0 - wz);
        final sx = cx + wx * k, sy = cy - wy * k;
        _vp[vn * 2] = sx;
        _vp[vn * 2 + 1] = sy;
        _vc[vn] =
            0xFF000000 |
            (r * 255).round() << 16 |
            (g * 255).round() << 8 |
            (b * 255).round();
        vn++;

        final lum = 0.2126 * hr + 0.7152 * hg + 0.0722 * hb;
        if (faceUp) {
          final tl = 0.2126 * r + 0.7152 * g + 0.0722 * b;
          lumSum += tl;
          fireSum +=
              (math.max(r, math.max(g, b)) - math.min(r, math.min(g, b))) * tl;
          crownSamples++;
        }
        if (lum > best) {
          best = lum;
          _spark
            ..[f * 6] = lum
            ..[f * 6 + 1] = sx
            ..[f * 6 + 2] = sy
            ..[f * 6 + 3] = hr
            ..[f * 6 + 4] = hg
            ..[f * 6 + 5] = hb;
        }
      }
      if (faceUp && best > sparkThreshold) flashing++;
      for (var t = _ft[f] * 3; t < _ft[f + 1] * 3; t++) {
        _vi[in_++] = base + _tri[t];
      }
    }

    _setStats(lumSum, fireSum, crownSamples, crownFacets, flashing);

    if (bi > 0) {
      final base = ui.Vertices.raw(
        ui.VertexMode.triangles,
        Float32List.sublistView(_bp, 0, vcount * 2),
        colors: Int32List.sublistView(_bc, 0, vcount),
        indices: Uint16List.sublistView(_bi, 0, bi),
      );
      canvas.drawVertices(base, BlendMode.dst, _vertexPaint);
      base.dispose();
    }
    if (in_ > 0) {
      final body = ui.Vertices.raw(
        ui.VertexMode.triangles,
        Float32List.sublistView(_vp, 0, vn * 2),
        colors: Int32List.sublistView(_vc, 0, vn),
        indices: Uint16List.sublistView(_vi, 0, in_),
      );
      canvas.drawVertices(body, BlendMode.dst, _vertexPaint);
      body.dispose();
    }

    _paintSparkles(canvas, facets, scale, time, twinkle, sparkThreshold);
  }

  void _paintSparkles(
    Canvas canvas,
    int facets,
    double scale,
    double time,
    bool twinkle,
    double threshold,
  ) {
    final sprite = DiamondSparkle.image;
    final spriteW = sprite.width.toDouble();
    // Brightest facets only; a real stone shows a handful of flashes.
    final picks = <int>[];
    for (var f = 0; f < facets; f++) {
      if (_spark[f * 6] > threshold) picks.add(f);
    }
    if (picks.isEmpty) return;
    picks.sort((a, b) => _spark[b * 6].compareTo(_spark[a * 6]));
    final count = math.min(picks.length, 26);
    final xform = Float32List(count * 4);
    final rects = Float32List(count * 4);
    final colors = Int32List(count);
    for (var i = 0; i < count; i++) {
      final f = picks[i];
      final lum = _spark[f * 6];
      final over = ((lum - threshold) / threshold).clamp(0.0, 2.2);
      var flick = 1.0;
      if (twinkle) flick = 0.72 + 0.28 * math.sin(time * 9 + f * 2.17);
      final px = scale * (0.09 + 0.11 * math.sqrt(over)) * flick;
      final s = px / spriteW;
      xform
        ..[i * 4] = s
        ..[i * 4 + 1] = 0
        ..[i * 4 + 2] = _spark[f * 6 + 1] - spriteW / 2 * s
        ..[i * 4 + 3] = _spark[f * 6 + 2] - spriteW / 2 * s;
      rects
        ..[i * 4 + 2] = spriteW
        ..[i * 4 + 3] = sprite.height.toDouble();
      // Sparkles keep the colour of the light that made them: fire
      // flashes red, blue or green, white flashes stay white.
      final r = _spark[f * 6 + 3], g = _spark[f * 6 + 4], b = _spark[f * 6 + 5];
      final m = math.max(r, math.max(g, b));
      int ch(double v) => (math.pow(v / m, 1.6) * 255).round().clamp(0, 255);
      final alpha = ((0.45 + 0.35 * over) * flick).clamp(0.0, 1.0);
      colors[i] =
          (alpha * 255).round() << 24 | ch(r) << 16 | ch(g) << 8 | ch(b);
    }
    canvas.drawRawAtlas(
      sprite,
      xform,
      rects,
      colors,
      BlendMode.modulate,
      null,
      Paint()..blendMode = BlendMode.plus,
    );
  }

  void _paintInclusions(
    Canvas canvas,
    double scale,
    double cx,
    double cy,
    Float64List r, {
    required double mirror,
  }) {
    Offset project(double x, double y, double z) {
      final wx = r[0] * x + r[1] * y + r[2] * z;
      final wy = r[3] * x + r[4] * y + r[5] * z;
      final wz = r[6] * x + r[7] * y + r[8] * z;
      final k = scale * _eye / (_eye - wz);
      return Offset(cx + wx * k, cy - wy * k);
    }

    for (final inc in _inclusions) {
      final at = project(inc.x, inc.y, inc.z);
      final size = inc.size * scale;
      switch (inc.kind) {
        case SimInclusionKind.pinpoint:
          _dot.color = const Color(0xB3FFFFFF);
          canvas.drawCircle(at, math.max(0.6, size), _dot);
        case SimInclusionKind.crystal:
          void crystal(Offset p, double alpha) {
            _dot.color = Color.fromRGBO(4, 4, 6, 0.82 * alpha);
            canvas.drawCircle(p, math.max(0.8, size), _dot);
            _dot.color = Color.fromRGBO(255, 255, 255, 0.22 * alpha);
            canvas.drawCircle(
              p.translate(-size * 0.3, -size * 0.3),
              math.max(0.4, size * 0.35),
              _dot,
            );
          }

          crystal(at, 1);
          final m = inc.mirrors;
          for (var i = 0; i + 2 < m.length; i += 3) {
            crystal(project(m[i], m[i + 1], m[i + 2]), 0.4 * mirror);
          }
        case SimInclusionKind.feather:
          void feather(Offset a, Offset b, double alpha) {
            _line
              ..color = Color.fromRGBO(235, 240, 255, 0.12 * alpha)
              ..strokeWidth = math.max(1.4, inc.size * scale * 0.16);
            canvas.drawLine(a, b, _line);
            _line
              ..color = Color.fromRGBO(245, 248, 255, 0.42 * alpha)
              ..strokeWidth = math.max(0.6, inc.size * scale * 0.05);
            canvas.drawLine(a, b, _line);
          }

          feather(at, project(inc.ex, inc.ey, inc.ez), 1);
          final m = inc.mirrors;
          for (var i = 0; i + 5 < m.length; i += 6) {
            feather(
              project(m[i], m[i + 1], m[i + 2]),
              project(m[i + 3], m[i + 4], m[i + 5]),
              0.35 * mirror,
            );
          }
        case SimInclusionKind.cloud:
          final rng = math.Random((inc.seed * 1e6).round());
          _dot.color = const Color(0x40FFFFFF);
          for (var i = 0; i < 10; i++) {
            final a = rng.nextDouble() * math.pi * 2;
            final d = math.sqrt(rng.nextDouble()) * size;
            canvas.drawCircle(
              at.translate(math.cos(a) * d, math.sin(a) * d),
              0.5 + rng.nextDouble() * 0.6,
              _dot,
            );
          }
      }
    }
  }
}

extension on SimRenderer {
  /// Convex hull of the first [count] projected vertices (monotone chain).
  Path _hull(int count) {
    final ids = _hullIds..clear();
    for (var i = 0; i < count; i++) {
      ids.add(i);
    }
    ids.sort((a, b) {
      final c = _px[a].compareTo(_px[b]);
      return c != 0 ? c : _py[a].compareTo(_py[b]);
    });
    double cross(int o, int a, int b) =>
        (_px[a] - _px[o]) * (_py[b] - _py[o]) -
        (_py[a] - _py[o]) * (_px[b] - _px[o]);
    final hull = <int>[];
    for (final pass in [ids, ids.reversed.toList()]) {
      final start = hull.length;
      for (final i in pass) {
        while (hull.length >= start + 2 &&
            cross(hull[hull.length - 2], hull.last, i) <= 0) {
          hull.removeLast();
        }
        hull.add(i);
      }
      hull.removeLast();
    }
    final path = Path();
    for (var k = 0; k < hull.length; k++) {
      final i = hull[k];
      k == 0 ? path.moveTo(_px[i], _py[i]) : path.lineTo(_px[i], _py[i]);
    }
    return path..close();
  }
}

/// Sample grid over a k-sided facet fanned from its centroid: ring r of
/// n holds k·r points, and each fan sector is a triangular grid between
/// rings. Point q is `wc·centroid + wa·v[sector] + wb·v[sector + 1]`.
class _Template {
  _Template._(this.count, this.sector, this.wa, this.wb, this.wc, this.tris);

  final int count;
  final Int32List sector;
  final Float64List wa, wb, wc;
  final Int32List tris;

  static final Map<int, _Template> _cache = {};

  static _Template of(int k, int n) =>
      _cache.putIfAbsent(k * 16 + n, () => _build(k, n));

  static _Template _build(int k, int n) {
    final count = 1 + k * n * (n + 1) ~/ 2;
    final sector = Int32List(count);
    final wa = Float64List(count), wb = Float64List(count);
    final wc = Float64List(count)..[0] = 1;
    var q = 1;
    for (var r = 1; r <= n; r++) {
      for (var i = 0; i < k; i++) {
        for (var j = 0; j < r; j++) {
          sector[q] = i;
          wc[q] = (n - r) / n;
          wa[q] = (r - j) / n;
          wb[q] = j / n;
          q++;
        }
      }
    }
    int id(int r, int i, int j) {
      if (r == 0) return 0;
      if (j == r) {
        i = (i + 1) % k;
        j = 0;
      }
      return 1 + k * (r - 1) * r ~/ 2 + i * r + j;
    }

    final tris = <int>[];
    for (var i = 0; i < k; i++) {
      for (var r = 1; r <= n; r++) {
        for (var j = 0; j < r; j++) {
          tris.addAll([id(r, i, j), id(r, i, j + 1), id(r - 1, i, j)]);
        }
        for (var j = 0; j < r - 1; j++) {
          tris.addAll([id(r - 1, i, j), id(r, i, j + 1), id(r - 1, i, j + 1)]);
        }
      }
    }
    return _Template._(count, sector, wa, wb, wc, Int32List.fromList(tris));
  }
}
