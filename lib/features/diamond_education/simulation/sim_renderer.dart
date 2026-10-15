import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

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

/// Draws a [SimMesh] by tracing light through it at sample points spread
/// over every visible facet, then filling the facet between them
/// (Gouraud). Facets are sampled densely enough that the patterns inside
/// each one, the reflections of other facets, read clearly; the spacing
/// is set in screen pixels so cost follows the stone's size on screen,
/// and callers can coarsen it to hold frame rate.
///
/// Buffers are reused frame to frame, so steady painting allocates only
/// the [ui.Vertices] handed to the canvas.
class SimRenderer {
  final SimTracer _tracer = SimTracer();
  final SimFrameStats stats = SimFrameStats();

  SimMesh? _mesh;
  List<SimInclusion> _inclusions = const [];
  SimLighting? _lighting;

  /// Camera distance in model units; enough perspective to feel solid.
  static const _eye = 9.0;

  /// Most samples in one stone, whatever its size on screen.
  static const _sampleBudget = 6400;

  void setStone(SimMesh mesh, List<SimInclusion> inclusions) {
    _mesh = mesh;
    _inclusions = inclusions;
    _tracer.mesh = mesh;
  }

  void setOptics(SimOptics optics) {
    _tracer.optics = optics;
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
        final n = mesh.kinds[f] == SimFacetKind.girdle.index
            ? 2
            : (math.sqrt(reach) / units).ceil().clamp(2, 16);
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
  Float32List _ipx = Float32List(0), _ipy = Float32List(0);

  // Best sample per facet for sparkles: luminance, screen xy, rgb.
  Float64List _spark = Float64List(0);

  final Paint _vertexPaint = Paint();
  final Paint _fill = Paint()..isAntiAlias = true;
  final Paint _line = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static double _tone(double x) {
    if (x <= 0) return 0;
    // Crisp crystal/glass filmic tone curve: keeps dark internal contrast
    // facets translucent smoky-silver (never dead black) while driving
    // studio window reflections to brilliant pure crystal white.
    final y = (x * (2.45 * x + 0.08)) / (x * (2.32 * x + 0.62) + 0.14);
    return y >= 1 ? 1.0 : math.pow(y, 0.48).toDouble();
  }

  /// Paints the stone centred in [size]. [pxPerUnit] maps model units to
  /// logical pixels at zoom 1; samples land about [samplePx] pixels apart.
  void paint(
    Canvas canvas,
    Size size, {
    required SimView view,
    required double pxPerUnit,
    required double samplePx,
    double time = 0,
    bool twinkle = false,
  }) {
    final mesh = _mesh;
    if (mesh == null || size.isEmpty) return;
    final scale = pxPerUnit * view.zoom;
    final units = samplePx / scale;
    if (!identical(_layoutFor, mesh) ||
        (units - _layoutUnits).abs() > _layoutUnits * 0.12) {
      _layout(mesh, units);
    }

    // Model → world: spin about the table axis, then tilt toward viewer.
    final cs = math.cos(view.spin), ss = math.sin(view.spin);
    final ct = math.cos(view.tilt), st = math.sin(view.tilt);
    final r00 = cs, r01 = 0.0, r02 = ss;
    final r10 = st * ss, r11 = ct, r12 = -st * cs;
    final r20 = -ct * ss, r21 = st, r22 = ct * cs;
    final tracer = _tracer
      ..rotation([r00, r01, r02, r10, r11, r12, r20, r21, r22]);
    const d0 = _eye;
    final ex = d0 * r20, ey = d0 * r21, ez = d0 * r22;
    final cx = size.width / 2, cy = size.height / 2;
    final optics = tracer.optics;
    final isUv = optics.lighting == SimLighting.ultraviolet;

    // Project every mesh vertex once (facet outlines & refracted inner web).
    final vcount = mesh.vertexCount;
    if (_px.length < vcount) {
      _px = Float32List(vcount);
      _py = Float32List(vcount);
      _ipx = Float32List(vcount);
      _ipy = Float32List(vcount);
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
      // Refracted internal projection: pavilion vertices seen through the
      // high-IOR crown appear magnified/pulled slightly toward the axis.
      final pull = 0.90 + 0.06 * (wz / mesh.radius).clamp(-1.0, 1.0);
      _ipx[i] = cx + wx * k * pull;
      _ipy[i] = cy - wy * k * pull;
    }

    final hullPath = _hull(vcount);

    // Subtle crystal caustic halo on the soft dark studio stage.
    if (!isUv) {
      final haloR = mesh.radius * scale * 1.28;
      final haloCenter = Offset(cx, cy + mesh.radius * scale * 0.04);
      canvas.drawCircle(
        haloCenter,
        haloR,
        Paint()
          ..shader = ui.Gradient.radial(
            haloCenter,
            haloR,
            const [
              Color(0x18D8E4FF),
              Color(0x0AD8E4FF),
              Color(0x00D8E4FF),
            ],
            const [0.0, 0.55, 1.0],
          ),
      );
    }

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

    // Base silhouette layer: cool smoky crystal slate so seams between
    // independently sampled facets never bleed background.
    final baseColor = isUv ? 0xFF0A0C18 : 0xFF282E3C;
    for (var i = 0; i < vcount; i++) {
      _bp[i * 2] = _px[i];
      _bp[i * 2 + 1] = _py[i];
      _bc[i] = baseColor;
    }
    var bi = 0;

    var vn = 0, in_ = 0;
    var lumSum = 0.0, fireSum = 0.0, crownSamples = 0;
    var crownFacets = 0, flashing = 0;
    const sparkThreshold = 1.65;
    final tableKind = SimFacetKind.table.index;
    final crownKind = SimFacetKind.crown.index;
    final girdleKind = SimFacetKind.girdle.index;

    for (var f = 0; f < facets; f++) {
      final o = f * 4;
      final fnx = planes[o], fny = planes[o + 1], fnz = planes[o + 2];
      final facing = fnx * ex + fny * ey + fnz * ez - planes[o + 3];
      _spark[f * 6] = 0;
      if (facing <= 1e-6) continue;

      final a = fv[starts[f]];
      for (var j = starts[f] + 1; j < starts[f + 1] - 1; j++) {
        _bi[bi++] = a;
        _bi[bi++] = fv[j];
        _bi[bi++] = fv[j + 1];
      }

      // Per-facet planar normal orientation in world space: gives each flat
      // facet a distinct planar glass reflection step so adjacent facets
      // articulate as crisp flat crystal planes.
      final wnx = r00 * fnx + r01 * fny + r02 * fnz;
      final wny = r10 * fnx + r11 * fny + r12 * fnz;
      final wnz = r20 * fnx + r21 * fny + r22 * fnz;
      final keyDot = (-0.28 * wnx + 0.68 * wny + 0.67 * wnz).clamp(0.0, 1.0);
      final rimDot = (0.35 * wnx - 0.45 * wny + 0.82 * wnz).clamp(0.0, 1.0);
      final facetPlanarStep = isUv
          ? 0.0
          : (0.075 * math.pow(keyDot, 3) - 0.025 * (1 - rimDot));

      final faceUp = kinds[f] == tableKind || kinds[f] == crownKind;
      final isGirdle = kinds[f] == girdleKind;
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
        var hr = tracer.outR, hg = tracer.outG, hb = tracer.outB;
        if (isGirdle && !isUv) {
          // Bruted/frosted girdle band: translucent satin glass edge.
          final avg = (hr + hg + hb) / 3;
          hr = 0.28 + 0.46 * avg;
          hg = 0.30 + 0.46 * avg;
          hb = 0.34 + 0.48 * avg;
        }
        final r = (_tone(hr) + facetPlanarStep).clamp(0.0, 1.0);
        final g = (_tone(hg) + facetPlanarStep).clamp(0.0, 1.0);
        final b = (_tone(hb) + facetPlanarStep).clamp(0.0, 1.0);

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

    stats
      ..samples = vn
      ..brightness = crownSamples == 0 ? 0 : lumSum / crownSamples
      ..fire = crownSamples == 0
          ? 0
          : (fireSum / crownSamples * 4).clamp(0.0, 1.0)
      ..sparkle = crownFacets == 0 ? 0 : flashing / crownFacets;

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

    // Internal refracted pavilion facet web, planar glass sheet reflections,
    // and external crystal ridge bevels.
    canvas
      ..save()
      ..clipPath(hullPath);
    _paintFacetArchitecture(
      canvas,
      mesh,
      ex,
      ey,
      ez,
      [r00, r01, r02, r10, r11, r12, r20, r21, r22],
      isUv: isUv,
    );
    if (_inclusions.isNotEmpty) {
      _paintInclusions(
        canvas,
        scale,
        cx,
        cy,
        [r00, r01, r02, r10, r11, r12, r20, r21, r22],
        mirror: st.clamp(0.0, 1.0),
      );
    }
    canvas.restore();

    // Crisp outer glass rim definition against the soft dark studio.
    _line
      ..color = isUv ? const Color(0x406088E0) : const Color(0x66DCE6F8)
      ..strokeWidth = 0.85;
    canvas.drawPath(hullPath, _line);

    if (isUv) {
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
          Paint()
            ..blendMode = BlendMode.plus
            ..shader = ui.Gradient.radial(c, radius, [
              tint((0.16 * glow).clamp(0.0, 0.3)),
              tint(0),
            ]),
        );
      }
    }

    _paintGlassSparkles(
      canvas,
      mesh,
      facets,
      scale,
      time,
      twinkle,
      sparkThreshold,
      isUv: isUv,
    );
  }

  /// Draws the internal refracted pavilion facet lines seen through the
  /// transparent crystal, planar glass-sheet surface sheen on each flat
  /// facet, and crisp specular bevel ridges where facets meet.
  void _paintFacetArchitecture(
    Canvas canvas,
    SimMesh mesh,
    double ex,
    double ey,
    double ez,
    List<double> r, {
    required bool isUv,
  }) {
    final planes = mesh.planes, kinds = mesh.kinds;
    final starts = mesh.facetStart, fv = mesh.facetVerts;
    final facets = mesh.facetCount;
    final pavilionKind = SimFacetKind.pavilion.index;
    final girdleKind = SimFacetKind.girdle.index;
    final tableKind = SimFacetKind.table.index;

    // 1. Back-facing facets (pavilion seen through the crown): subtle
    // refracted internal facet lines that give the crystalline kaleidoscope
    // depth of real optical glass/diamond.
    _line.strokeWidth = 0.65;
    for (var f = 0; f < facets; f++) {
      final o = f * 4;
      final facing =
          planes[o] * ex +
          planes[o + 1] * ey +
          planes[o + 2] * ez -
          planes[o + 3];
      if (facing > 1e-6) continue;
      if (kinds[f] == girdleKind) continue;

      final wnz =
          r[6] * planes[o] + r[7] * planes[o + 1] + r[8] * planes[o + 2];
      final vis = (-wnz).clamp(0.0, 1.0);
      if (vis < 0.08) continue;

      final s0 = starts[f], s1 = starts[f + 1];
      _line.color = isUv
          ? Color.fromRGBO(140, 175, 255, 0.12 * vis)
          : Color.fromRGBO(210, 225, 250, 0.16 * vis);
      for (var j = s0; j < s1; j++) {
        final a = fv[j], b = fv[s0 + (j - s0 + 1) % (s1 - s0)];
        if (a < b) {
          canvas.drawLine(
            Offset(_ipx[a], _ipy[a]),
            Offset(_ipx[b], _ipy[b]),
            _line,
          );
        }
      }
    }

    // 2. Front-facing facets: planar glass-sheet surface sheen + razor-sharp
    // crystal ridge bevels.
    final sheenPaint = Paint()..isAntiAlias = true;
    for (var f = 0; f < facets; f++) {
      final o = f * 4;
      final fnx = planes[o], fny = planes[o + 1], fnz = planes[o + 2];
      final facing = fnx * ex + fny * ey + fnz * ez - planes[o + 3];
      if (facing <= 1e-6) continue;

      final kind = kinds[f];
      final wnx = r[0] * fnx + r[1] * fny + r[2] * fnz;
      final wny = r[3] * fnx + r[4] * fny + r[5] * fnz;
      final wnz = r[6] * fnx + r[7] * fny + r[8] * fnz;
      final s0 = starts[f], s1 = starts[f + 1];

      if (kind == girdleKind) {
        _line
          ..color = isUv
              ? const Color(0x2890B0FF)
              : const Color(0x42B8C6DC)
          ..strokeWidth = 0.55;
        for (var j = s0; j < s1; j++) {
          final a = fv[j], b = fv[s0 + (j - s0 + 1) % (s1 - s0)];
          if (a < b) {
            canvas.drawLine(
              Offset(_px[a], _py[a]),
              Offset(_px[b], _py[b]),
              _line,
            );
          }
        }
        continue;
      }

      // Surface glass reflection sheen across the flat facet polygon:
      // Fresnel grazing reflection + overhead studio window alignment.
      final ndv = wnz.clamp(0.0, 1.0);
      final fresnel = 0.17 + 0.83 * math.pow(1 - ndv, 3);
      final rx = -2 * ndv * wnx;
      final ry = -2 * ndv * wny;
      final rz = 2 * ndv * wnz - 1.0;
      final winAlign =
          (-0.22 * rx + 0.72 * ry + 0.66 * rz).clamp(0.0, 1.0);
      final sideAlign =
          (0.75 * rx.abs() + 0.35 * ry + 0.56 * rz).clamp(0.0, 1.0);
      final glassIntensity = isUv
          ? 0.08 * winAlign
          : (0.28 * math.pow(winAlign, 2) + 0.18 * fresnel * sideAlign)
                .clamp(0.0, 0.36);

      if (glassIntensity > 0.03) {
        final poly = Path();
        var minX = double.infinity, maxX = -double.infinity;
        var minY = double.infinity, maxY = -double.infinity;
        for (var j = s0; j < s1; j++) {
          final v = fv[j];
          final vx = _px[v], vy = _py[v];
          if (j == s0) {
            poly.moveTo(vx, vy);
          } else {
            poly.lineTo(vx, vy);
          }
          if (vx < minX) minX = vx;
          if (vx > maxX) maxX = vx;
          if (vy < minY) minY = vy;
          if (vy > maxY) maxY = vy;
        }
        poly.close();

        // Linear glass reflection sweeping across the flat facet plane at
        // the facet's projected reflection angle (never a round bubble).
        final cxF = (minX + maxX) * 0.5, cyF = (minY + maxY) * 0.5;
        final dxF = maxX - minX, dyF = maxY - minY;
        final span = math.max(8.0, math.sqrt(dxF * dxF + dyF * dyF) * 0.5);
        final gx = wnx * 0.85 - 0.32, gy = -wny * 0.85 - 0.55;
        final gl = math.max(1e-4, math.sqrt(gx * gx + gy * gy));
        final ux = gx / gl * span, uy = gy / gl * span;
        final p0 = Offset(cxF - ux, cyF - uy);
        final p1 = Offset(cxF + ux, cyF + uy);
        sheenPaint.shader = ui.Gradient.linear(
          p0,
          p1,
          [
            Color.fromRGBO(255, 255, 255, glassIntensity),
            Color.fromRGBO(230, 240, 255, glassIntensity * 0.35),
            const Color(0x00FFFFFF),
            Color.fromRGBO(210, 228, 255, glassIntensity * 0.22),
          ],
          const [0.0, 0.36, 0.72, 1.0],
        );
        canvas.drawPath(poly, sheenPaint);
      }

      // Specular glint on facet ridges catching the overhead/key lights,
      // paired with a crisp bevel contrast line.
      final spec = (-0.25 * wnx + 0.65 * wny + 0.71 * wnz).clamp(0.0, 1.0);
      final isTable = kind == tableKind;
      final isPav = kind == pavilionKind;
      final ridgeAlpha = isTable
          ? 0.62
          : isPav
          ? 0.40
          : 0.52;

      for (var j = s0; j < s1; j++) {
        final a = fv[j], b = fv[s0 + (j - s0 + 1) % (s1 - s0)];
        if (!isTable && a > b) continue;
        final pa = Offset(_px[a], _py[a]);
        final pb = Offset(_px[b], _py[b]);

        if (!isUv) {
          _line
            ..color = Color.fromRGBO(
              18,
              22,
              32,
              (isTable ? 0.28 : 0.20) * (1 - 0.3 * spec),
            )
            ..strokeWidth = isTable ? 1.0 : 0.75;
          canvas.drawLine(pa, pb, _line);
        }

        // Crisp linear glass-bevel highlight along the straight facet edge.
        _line
          ..color = isUv
              ? Color.fromRGBO(180, 205, 255, 0.26 * ridgeAlpha)
              : Color.fromRGBO(
                  255,
                  255,
                  255,
                  (0.32 + 0.62 * spec * spec) * ridgeAlpha,
                )
          ..strokeWidth = isTable ? 0.85 : 0.6;
        canvas.drawLine(pa, pb, _line);
      }
    }
  }

  /// Renders glass-reflection facet flashes and razor-thin optical edge
  /// glints without any circular/bubble sprites:
  /// 1. Flashing facets light up across their exact polygonal crystal plane
  ///    with a linear glass-sheet reflection gradient.
  /// 2. The brightest facet ridges emit crisp linear bevel gleams and
  ///    ultra-thin tapered optical needle rays (zero circular halo).
  void _paintGlassSparkles(
    Canvas canvas,
    SimMesh mesh,
    int facets,
    double scale,
    double time,
    bool twinkle,
    double threshold, {
    required bool isUv,
  }) {
    final picks = <int>[];
    for (var f = 0; f < facets; f++) {
      if (_spark[f * 6] > threshold) picks.add(f);
    }
    if (picks.isEmpty) return;
    picks.sort((a, b) => _spark[b * 6].compareTo(_spark[a * 6]));

    final starts = mesh.facetStart, fv = mesh.facetVerts;
    final flashCount = math.min(picks.length, 14);
    final flashPaint = Paint()
      ..isAntiAlias = true
      ..blendMode = BlendMode.plus;

    for (var i = 0; i < flashCount; i++) {
      final f = picks[i];
      final lum = _spark[f * 6];
      final over = ((lum - threshold) / threshold).clamp(0.0, 2.2);
      var flick = 1.0;
      if (twinkle) flick = 0.78 + 0.22 * math.sin(time * 7.5 + f * 2.17);

      final r = _spark[f * 6 + 3], g = _spark[f * 6 + 4], b = _spark[f * 6 + 5];
      final m = math.max(1e-4, math.max(r, math.max(g, b)));
      int ch(double v) => (math.pow(v / m, 1.4) * 255).round().clamp(0, 255);
      final cr = ch(r), cg = ch(g), cb = ch(b);

      // 1. Polygonal glass-sheet flash across the facet's own straight edges.
      final s0 = starts[f], s1 = starts[f + 1];
      if (s1 - s0 >= 3) {
        final poly = Path();
        var minX = double.infinity, maxX = -double.infinity;
        var minY = double.infinity, maxY = -double.infinity;
        for (var j = s0; j < s1; j++) {
          final v = fv[j];
          final vx = _px[v], vy = _py[v];
          if (j == s0) {
            poly.moveTo(vx, vy);
          } else {
            poly.lineTo(vx, vy);
          }
          if (vx < minX) minX = vx;
          if (vx > maxX) maxX = vx;
          if (vy < minY) minY = vy;
          if (vy > maxY) maxY = vy;
        }
        poly.close();

        final sheetAlpha = ((0.16 + 0.18 * over) * flick).clamp(0.0, 0.42);
        final pStart = Offset(minX, minY);
        final pEnd = Offset(
          maxX == minX ? minX + 1 : maxX,
          maxY == minY ? minY + 1 : maxY,
        );
        flashPaint.shader = ui.Gradient.linear(
          pStart,
          pEnd,
          [
            Color.fromRGBO(cr, cg, cb, sheetAlpha),
            Color.fromRGBO(255, 255, 255, sheetAlpha * 0.75),
            Color.fromRGBO(cr, cg, cb, sheetAlpha * 0.12),
          ],
          const [0.0, 0.45, 1.0],
        );
        canvas.drawPath(poly, flashPaint);

        // Crisp specular glass edge gleam on the facet's longest ridge.
        var bestLen = 0.0;
        Offset ea = pStart, eb = pEnd;
        for (var j = s0; j < s1; j++) {
          final va = fv[j], vb = fv[s0 + (j - s0 + 1) % (s1 - s0)];
          final pa = Offset(_px[va], _py[va]);
          final pb = Offset(_px[vb], _py[vb]);
          final d = (pb - pa).distance;
          if (d > bestLen) {
            bestLen = d;
            ea = pa;
            eb = pb;
          }
        }
        if (bestLen > 2.0) {
          final edgeAlpha = ((0.35 + 0.35 * over) * flick).clamp(0.0, 0.85);
          _line
            ..color = Color.fromRGBO(255, 255, 255, edgeAlpha)
            ..strokeWidth = 1.05;
          canvas.drawLine(ea, eb, _line);
        }
      }

      // 2. Top 6 brightest facets emit a razor-thin optical needle glint
      //    anchored at the facet's brightest reflection point (no circular
      //    bubble or round halo).
      if (i < 6 && over > 0.18) {
        final sx = _spark[f * 6 + 1], sy = _spark[f * 6 + 2];
        final rayLen = scale * (0.045 + 0.055 * math.sqrt(over)) * flick;
        final glintAlpha = ((0.48 + 0.38 * over) * flick).clamp(0.0, 0.92);
        final tiltAngle = (f % 4) * (math.pi / 16);

        void drawNeedleRay(double angle, double len, double halfW, double a) {
          final ca = math.cos(angle), sa = math.sin(angle);
          final nx = -sa * halfW, ny = ca * halfW;
          final t1 = Offset(sx + ca * len, sy + sa * len);
          final t2 = Offset(sx - ca * len, sy - sa * len);
          final rayPath = Path()
            ..moveTo(t1.dx, t1.dy)
            ..lineTo(sx + nx, sy + ny)
            ..lineTo(t2.dx, t2.dy)
            ..lineTo(sx - nx, sy - ny)
            ..close();
          flashPaint.shader = ui.Gradient.linear(
            t1,
            t2,
            [
              Color.fromRGBO(cr, cg, cb, 0),
              Color.fromRGBO(cr, cg, cb, a * 0.75),
              Color.fromRGBO(255, 255, 255, a),
              Color.fromRGBO(cr, cg, cb, a * 0.75),
              Color.fromRGBO(cr, cg, cb, 0),
            ],
            const [0.0, 0.38, 0.5, 0.62, 1.0],
          );
          canvas.drawPath(rayPath, flashPaint);
        }

        drawNeedleRay(tiltAngle, rayLen, 0.85, glintAlpha);
        drawNeedleRay(tiltAngle + math.pi / 2, rayLen, 0.85, glintAlpha);
        drawNeedleRay(
          tiltAngle + math.pi / 4,
          rayLen * 0.48,
          0.55,
          glintAlpha * 0.65,
        );
        drawNeedleRay(
          tiltAngle - math.pi / 4,
          rayLen * 0.48,
          0.55,
          glintAlpha * 0.65,
        );
      }
    }
  }

  void _paintInclusions(
    Canvas canvas,
    double scale,
    double cx,
    double cy,
    List<double> r, {
    required double mirror,
  }) {
    Offset project(double x, double y, double z) {
      final wx = r[0] * x + r[1] * y + r[2] * z;
      final wy = r[3] * x + r[4] * y + r[5] * z;
      final wz = r[6] * x + r[7] * y + r[8] * z;
      final k = scale * _eye / (_eye - wz);
      return Offset(cx + wx * k, cy - wy * k);
    }

    // View-dependent rotation angle so internal crystal facets turn naturally
    // with the stone in 3D space.
    final spinAngle = math.atan2(r[2], r[0]);

    for (final inc in _inclusions) {
      final at = project(inc.x, inc.y, inc.z);
      final size = inc.size * scale;
      final rng = math.Random((inc.seed * 1e6).round());
      final baseRot = inc.seed * math.pi * 2 + spinAngle * 0.65;

      switch (inc.kind) {
        case SimInclusionKind.pinpoint:
          // Tiny sharp crystalline micro-speck (angular 4-point diamond glint,
          // never a round bubble).
          final rad = math.max(0.55, size * 0.85);
          final path = Path()
            ..moveTo(at.dx, at.dy - rad)
            ..lineTo(at.dx + rad * 0.75, at.dy)
            ..lineTo(at.dx, at.dy + rad)
            ..lineTo(at.dx - rad * 0.75, at.dy)
            ..close();
          _fill.color = const Color(0x52364052);
          canvas.drawPath(path, _fill);
          _line
            ..color = const Color(0x66FFFFFF)
            ..strokeWidth = 0.45;
          canvas.drawLine(
            Offset(at.dx - rad * 0.6, at.dy - rad * 0.2),
            Offset(at.dx + rad * 0.6, at.dy + rad * 0.2),
            _line,
          );

        case SimInclusionKind.crystal:
          // Angular mineral crystal inclusion or slender crystalline needle:
          // faceted irregular polygon with subtle internal cleavage planes and
          // dark-field relief edges (never a round cartoon bubble).
          final isNeedle = inc.seed > 0.58;
          final corners = isNeedle ? 4 : (5 + (inc.seed * 10).floor() % 2);
          final angles = <double>[];
          final radii = <double>[];
          for (var k = 0; k < corners; k++) {
            final a =
                baseRot +
                (k / corners) * math.pi * 2 +
                (rng.nextDouble() - 0.5) * 0.35;
            final aspect = isNeedle ? (k.isEven ? 2.15 : 0.36) : (0.68 + rng.nextDouble() * 0.52);
            angles.add(a);
            radii.add(math.max(0.9, size * 0.92) * aspect);
          }

          void drawCrystal(Offset p, double alpha, double scaleMod) {
            if (alpha < 0.04) return;
            final poly = Path();
            final pts = <Offset>[];
            for (var k = 0; k < corners; k++) {
              final rk = radii[k] * scaleMod;
              final pt = Offset(
                p.dx + math.cos(angles[k]) * rk,
                p.dy + math.sin(angles[k]) * rk,
              );
              pts.add(pt);
              k == 0 ? poly.moveTo(pt.dx, pt.dy) : poly.lineTo(pt.dx, pt.dy);
            }
            poly.close();

            // Subtle semi-translucent mineral crystal relief fill.
            _fill
              ..shader = null
              ..color = Color.fromRGBO(52, 60, 74, (0.22 * alpha).clamp(0.0, 1.0));
            canvas.drawPath(poly, _fill);

            // Crisp dark-relief crystal cleavage outline.
            _line
              ..color = Color.fromRGBO(34, 40, 52, (0.42 * alpha).clamp(0.0, 1.0))
              ..strokeWidth = 0.6;
            canvas.drawPath(poly, _line);

            // Internal crystal facet ridge & bright refracted edge glint.
            _line
              ..color = Color.fromRGBO(
                255,
                255,
                255,
                (0.48 * alpha).clamp(0.0, 1.0),
              )
              ..strokeWidth = 0.5;
            canvas.drawLine(pts[0], pts[1], _line);
            if (pts.length >= 4) {
              _line.color = Color.fromRGBO(
                235,
                242,
                255,
                (0.28 * alpha).clamp(0.0, 1.0),
              );
              canvas.drawLine(pts[0], pts[pts.length ~/ 2], _line);
            }
          }

          drawCrystal(at, 1.0, 1.0);
          final m = inc.mirrors;
          for (var i = 0; i + 2 < m.length; i += 3) {
            drawCrystal(
              project(m[i], m[i + 1], m[i + 2]),
              0.34 * mirror,
              0.82,
            );
          }

        case SimInclusionKind.feather:
          // Delicate feathery cleavage fracture plane: tapering translucent
          // veil with fine angled micro-barbs along the fracture spine.
          void drawFeather(Offset a, Offset b, double alpha) {
            if (alpha < 0.04) return;
            final dx = b.dx - a.dx, dy = b.dy - a.dy;
            final len = math.sqrt(dx * dx + dy * dy);
            if (len < 0.8) return;
            final ux = dx / len, uy = dy / len;
            final nx = -uy, ny = ux;
            final bend = (inc.seed - 0.5) * len * 0.16;
            final mid = Offset(
              (a.dx + b.dx) * 0.5 + nx * bend,
              (a.dy + b.dy) * 0.5 + ny * bend,
            );
            final wingW = math.max(1.2, len * 0.16);
            final wing = Path()
              ..moveTo(a.dx, a.dy)
              ..quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy)
              ..quadraticBezierTo(
                mid.dx + nx * wingW,
                mid.dy + ny * wingW,
                a.dx,
                a.dy,
              )
              ..close();
            _fill
              ..shader = null
              ..color = Color.fromRGBO(
                225,
                232,
                245,
                (0.16 * alpha).clamp(0.0, 1.0),
              );
            canvas.drawPath(wing, _fill);

            // Fine feathery micro-barbs radiating from the cleavage spine.
            const barbs = 5;
            _line
              ..color = Color.fromRGBO(
                62,
                70,
                86,
                (0.24 * alpha).clamp(0.0, 1.0),
              )
              ..strokeWidth = 0.45;
            for (var k = 1; k <= barbs; k++) {
              final t = k / (barbs + 1);
              final omt = 1 - t;
              final sx = omt * omt * a.dx + 2 * omt * t * mid.dx + t * t * b.dx;
              final sy = omt * omt * a.dy + 2 * omt * t * mid.dy + t * t * b.dy;
              final barbLen = wingW * (1 - (t - 0.5).abs() * 1.4);
              canvas.drawLine(
                Offset(sx, sy),
                Offset(
                  sx + (nx * 0.82 + ux * 0.55) * barbLen,
                  sy + (ny * 0.82 + uy * 0.55) * barbLen,
                ),
                _line,
              );
            }

            // Razor-thin fracture spine with subtle bright/dark relief.
            final spine = Path()
              ..moveTo(a.dx, a.dy)
              ..quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy);
            _line
              ..color = Color.fromRGBO(
                48,
                56,
                70,
                (0.32 * alpha).clamp(0.0, 1.0),
              )
              ..strokeWidth = 0.7;
            canvas.drawPath(spine, _line);
            _line
              ..color = Color.fromRGBO(
                255,
                255,
                255,
                (0.46 * alpha).clamp(0.0, 1.0),
              )
              ..strokeWidth = 0.45;
            canvas.drawPath(spine, _line);
          }

          drawFeather(at, project(inc.ex, inc.ey, inc.ez), 1.0);
          final m = inc.mirrors;
          for (var i = 0; i + 5 < m.length; i += 6) {
            drawFeather(
              project(m[i], m[i + 1], m[i + 2]),
              project(m[i + 3], m[i + 4], m[i + 5]),
              0.32 * mirror,
            );
          }

        case SimInclusionKind.cloud:
          // Soft diffused nebula of sub-microscopic pinpoints: radial haze
          // veil plus fine crystalline micro-grain ticks (never bubbles).
          final rCloud = math.max(2.0, size * 1.15);
          final rect = Rect.fromCenter(
            center: at,
            width: rCloud * 2.2,
            height: rCloud * 1.65,
          );
          _fill.shader = ui.Gradient.radial(
            at,
            rCloud,
            const [
              Color(0x2458647A),
              Color(0x1278849A),
              Color(0x0078849A),
            ],
            const [0.0, 0.55, 1.0],
          );
          canvas.drawOval(rect, _fill);
          _fill.shader = null;

          _line
            ..color = const Color(0x36485266)
            ..strokeWidth = 0.45;
          for (var i = 0; i < 9; i++) {
            final a = rng.nextDouble() * math.pi * 2;
            final d = math.sqrt(rng.nextDouble()) * rCloud * 0.78;
            final px = at.dx + math.cos(a) * d;
            final py = at.dy + math.sin(a) * d * 0.75;
            final ca = rng.nextDouble() * math.pi;
            canvas.drawLine(
              Offset(px - math.cos(ca) * 0.55, py - math.sin(ca) * 0.55),
              Offset(px + math.cos(ca) * 0.55, py + math.sin(ca) * 0.55),
              _line,
            );
          }
      }
    }
  }
}

extension on SimRenderer {
  /// Convex hull of the first [count] projected vertices (monotone chain).
  Path _hull(int count) {
    final ids = List<int>.generate(count, (i) => i)
      ..sort((a, b) {
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
