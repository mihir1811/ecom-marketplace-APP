import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/painting.dart';

import '../domain/diamond_grades.dart';
import 'sim_inclusions.dart';
import 'sim_mesh.dart';
import 'sim_optics.dart';
import 'sim_renderer.dart';

/// The facet edges of a [SimMesh], as a line drawing of the stone shows
/// them: every crease where two cut facets meet, taken from the very
/// polygons the tracer uses, so the drawing is the traced stone exactly.
///
/// - Sides are split wherever another facet's corner lies along them, so
///   each drawn edge is shared by exactly the facets on either side.
/// - Splits that are not facet edges never show: the triangles a slightly
///   bent kite is cut into ([SimMesh.facetGroup]), and the seam down a
///   heart's mirror plane where a facet continues flat across it.
/// - A curved girdle is one smooth band: the joins between its short
///   segments show only where they form the outline, while true corners
///   (a princess, an emerald's cut corners, a pear's point) always do.
class SimWireMesh {
  SimWireMesh._({
    required this.mesh,
    required this.edges,
    required this.adjStart,
    required this.adj,
    required this.smooth,
    required this.convex,
  });

  final SimMesh mesh;

  /// Edge `e` runs between vertices `edges[2e]` and `edges[2e + 1]`.
  final Int32List edges;

  /// Facets meeting along edge `e`: `adj[adjStart[e] .. adjStart[e + 1]]`.
  final Int32List adjStart, adj;

  /// Girdle seams, drawn only where they form the outline.
  final Uint8List smooth;

  /// Whether no facet hides another that faces the viewer (all but a
  /// heart, whose cleft can hide part of the far lobe).
  final bool convex;

  int get edgeCount => smooth.length;

  /// A girdle join turning less than this (degrees) is a smooth curve.
  static const smoothTurn = 15.0;

  static final _cache = Expando<SimWireMesh>();

  static SimWireMesh of(SimMesh mesh) => _cache[mesh] ??= _build(mesh);

  static SimWireMesh _build(SimMesh mesh) {
    final pos = mesh.positions;
    final n = mesh.vertexCount;
    // Weld corners computed separately at the same point.
    const weld = 2e-6;
    final canon = Int32List(n);
    for (var i = 0; i < n; i++) {
      canon[i] = i;
      for (var j = 0; j < i; j++) {
        if (canon[j] != j) continue;
        if ((pos[i * 3] - pos[j * 3]).abs() < weld &&
            (pos[i * 3 + 1] - pos[j * 3 + 1]).abs() < weld &&
            (pos[i * 3 + 2] - pos[j * 3 + 2]).abs() < weld) {
          canon[i] = j;
          break;
        }
      }
    }

    final starts = mesh.facetStart, fv = mesh.facetVerts;
    final facets = mesh.facetCount;
    final polys = <List<int>>[];
    final used = <int>{};
    for (var f = 0; f < facets; f++) {
      final poly = <int>[];
      for (var j = starts[f]; j < starts[f + 1]; j++) {
        final c = canon[fv[j]];
        if (poly.isEmpty || poly.last != c) poly.add(c);
      }
      while (poly.length > 1 && poly.first == poly.last) {
        poly.removeLast();
      }
      polys.add(poly);
      used.addAll(poly);
    }
    final corners = used.toList();

    final byEdge = <int, List<int>>{};
    void link(int p, int q, int f) {
      if (p == q) return;
      final key = p < q ? p * n + q : q * n + p;
      final list = byEdge.putIfAbsent(key, () => <int>[]);
      if (!list.contains(f)) list.add(f);
    }

    const onLine = 1e-6 * 1e-6;
    final cuts = <(double, int)>[];
    for (var f = 0; f < facets; f++) {
      final poly = polys[f];
      final k = poly.length;
      if (k < 2) continue;
      for (var i = 0; i < k; i++) {
        final a = poly[i], b = poly[(i + 1) % k];
        final ax = pos[a * 3], ay = pos[a * 3 + 1], az = pos[a * 3 + 2];
        final ex = pos[b * 3] - ax, ey = pos[b * 3 + 1] - ay;
        final ez = pos[b * 3 + 2] - az;
        final len2 = ex * ex + ey * ey + ez * ez;
        if (len2 < 1e-18) continue;
        cuts.clear();
        for (final v in corners) {
          if (v == a || v == b) continue;
          final vx = pos[v * 3] - ax, vy = pos[v * 3 + 1] - ay;
          final vz = pos[v * 3 + 2] - az;
          final t = (vx * ex + vy * ey + vz * ez) / len2;
          if (t <= 1e-6 || t >= 1 - 1e-6) continue;
          final dx = vx - ex * t, dy = vy - ey * t, dz = vz - ez * t;
          if (dx * dx + dy * dy + dz * dz < onLine) cuts.add((t, v));
        }
        if (cuts.isEmpty) {
          link(a, b, f);
          continue;
        }
        cuts.sort((p, q) => p.$1.compareTo(q.$1));
        var prev = a;
        for (final (_, v) in cuts) {
          link(prev, v, f);
          prev = v;
        }
        link(prev, b, f);
      }
    }

    final planes = mesh.planes, kinds = mesh.kinds;
    final group = mesh.facetGroup;
    final girdle = SimFacetKind.girdle.index;
    // Facets closer than this to parallel continue one flat face.
    const flat = 0.99999;
    final sharpGirdle = math.cos(smoothTurn * math.pi / 180);
    final edges = <int>[], adjStart = <int>[0], adj = <int>[];
    final smooth = <int>[];
    for (final MapEntry(:key, value: fl) in byEdge.entries) {
      var distinct = false, allGirdle = true;
      var minDot = 1.0;
      for (var i = 0; i < fl.length; i++) {
        if (kinds[fl[i]] != girdle) allGirdle = false;
        for (var j = i + 1; j < fl.length; j++) {
          if (group[fl[i]] == group[fl[j]]) continue;
          distinct = true;
          final p = fl[i] * 4, q = fl[j] * 4;
          final dot =
              planes[p] * planes[q] +
              planes[p + 1] * planes[q + 1] +
              planes[p + 2] * planes[q + 2];
          minDot = math.min(minDot, dot);
        }
      }
      // A lone side (an open seam) still draws; otherwise only creases.
      if (fl.length > 1 && (!distinct || minDot > flat)) continue;
      edges
        ..add(key ~/ n)
        ..add(key % n);
      adj.addAll(fl);
      adjStart.add(adj.length);
      smooth.add(allGirdle && fl.length > 1 && minDot > sharpGirdle ? 1 : 0);
    }

    var convex = true;
    outer:
    for (var f = 0; f < facets; f++) {
      final nx = planes[f * 4], ny = planes[f * 4 + 1];
      final nz = planes[f * 4 + 2], d = planes[f * 4 + 3];
      for (final v in corners) {
        if (nx * pos[v * 3] + ny * pos[v * 3 + 1] + nz * pos[v * 3 + 2] - d >
            1e-5) {
          convex = false;
          break outer;
        }
      }
    }

    return SimWireMesh._(
      mesh: mesh,
      edges: Int32List.fromList(edges),
      adjStart: Int32List.fromList(adjStart),
      adj: Int32List.fromList(adj),
      smooth: Uint8List.fromList(smooth),
      convex: convex,
    );
  }
}

/// Line colours for the drawing, from the same optics the tracer uses:
/// body colour tints the lines as it tints light through the stone,
/// milkiness and cloudy clarity veil them, fluorescence lights them
/// under ultraviolet.
@immutable
class SimWireStyle {
  const SimWireStyle({required this.line});

  factory SimWireStyle.of(SimOptics o) {
    double r, g, b;
    if (o.lighting == SimLighting.ultraviolet) {
      // Dark but for the glow.
      final glow = ((o.emitR + o.emitG + o.emitB) / 0.13).clamp(0.0, 1.0);
      final m = math.max(o.emitR, math.max(o.emitG, o.emitB));
      final (er, eg, eb) = m > 1e-9
          ? (o.emitR / m, o.emitG / m, o.emitB / m)
          : (0.0, 0.0, 0.0);
      r = 0.34 + (er - 0.34) * glow;
      g = 0.31 + (eg - 0.31) * glow;
      b = 0.46 + (eb - 0.46) * glow;
    } else {
      // Light through about a stone's depth and a half, as the swatches.
      const path = 3.0;
      final tr = math.exp(-o.absorbR * path);
      final tg = math.exp(-o.absorbG * path);
      final tb = math.exp(-o.absorbB * path);
      final m = math.max(tr, math.max(tg, tb));
      // Hue at full strength, darker only for a deep stone.
      final k = (0.45 + 0.55 * m) / m;
      r = tr * k;
      g = tg * k;
      b = tb * k;
    }
    final veil = ((o.milk + o.haze) * 3.5).clamp(0.0, 0.55);
    const grey = 0.7;
    r += (grey - r) * veil * 0.6;
    g += (grey - g) * veil * 0.6;
    b += (grey - b) * veil * 0.6;
    return SimWireStyle(
      line: Color.fromRGBO(
        (r.clamp(0.0, 1.0) * 255).round(),
        (g.clamp(0.0, 1.0) * 255).round(),
        (b.clamp(0.0, 1.0) * 255).round(),
        1 - veil * 0.6,
      ),
    );
  }

  /// Facet edges facing the viewer; hidden ones are drawn faintly in it.
  final Color line;

  /// Internal characteristics, red as on a grading report's plot.
  static const inclusion = Color(0xFFFF5A52);
  static const inclusionDark = Color(0xFF9E1C18);

  @override
  bool operator ==(Object other) => other is SimWireStyle && other.line == line;

  @override
  int get hashCode => line.hashCode;
}

/// Draws a [SimMesh] as a 3D line drawing: only its facet edges, in the
/// same perspective as [SimRenderer]. Edges on the side facing the viewer
/// are drawn crisp, those on the far side faintly (the stone is clear, so
/// they read as depth without cluttering the face), and inclusions are
/// plotted inside in red with a grading report's symbols.
///
/// Visibility is exact: an edge shows when a facet beside it faces the
/// viewer, and on a stone that is not convex (a heart) each edge is also
/// clipped where a nearer facet covers it.
class SimWireRenderer {
  final Float64List _rot = Float64List(9);
  Float64List _sx = Float64List(0), _sy = Float64List(0);
  Uint8List _front = Uint8List(0);
  final List<int> _frontIds = [];
  Float32List _vis = Float32List(256), _hid = Float32List(256);
  int _nv = 0, _nh = 0;
  final List<double> _occ = [];

  final Paint _visPaint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final Paint _hidPaint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final Paint _incPaint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final Paint _incFill = Paint()..isAntiAlias = true;

  /// Share of the line colour the far side's edges are drawn in.
  static const hiddenAlpha = 0.2;

  // Camera for the current frame.
  double _scale = 1, _cx = 0, _cy = 0;
  static const _d0 = SimRenderer.eyeDistance;

  void _project(double x, double y, double z, Float32List out, int at) {
    final r = _rot;
    final wx = r[0] * x + r[1] * y + r[2] * z;
    final wy = r[3] * x + r[4] * y + r[5] * z;
    final wz = r[6] * x + r[7] * y + r[8] * z;
    final k = _scale * _d0 / (_d0 - wz);
    out[at] = _cx + wx * k;
    out[at + 1] = _cy - wy * k;
  }

  Offset _offset(double x, double y, double z) {
    _project(x, y, z, _tmp, 0);
    return Offset(_tmp[0], _tmp[1]);
  }

  final Float32List _tmp = Float32List(2);

  /// Paints [mesh] centred in [size]; [pxPerUnit] maps model units to
  /// logical pixels at zoom 1, as for [SimRenderer.paint].
  void paint(
    Canvas canvas,
    Size size, {
    required SimMesh mesh,
    required SimView view,
    required double pxPerUnit,
    required SimWireStyle style,
    List<SimInclusion> inclusions = const [],
  }) {
    if (size.isEmpty) return;
    final wire = SimWireMesh.of(mesh);
    _scale = pxPerUnit * view.zoom;
    _cx = size.width / 2;
    _cy = size.height / 2;
    view.rotationInto(_rot);
    final ex = _d0 * _rot[6], ey = _d0 * _rot[7], ez = _d0 * _rot[8];

    final pos = mesh.positions;
    final vcount = mesh.vertexCount;
    if (_sx.length < vcount) {
      _sx = Float64List(vcount);
      _sy = Float64List(vcount);
    }
    final r = _rot;
    for (var i = 0; i < vcount; i++) {
      final x = pos[i * 3], y = pos[i * 3 + 1], z = pos[i * 3 + 2];
      final wx = r[0] * x + r[1] * y + r[2] * z;
      final wy = r[3] * x + r[4] * y + r[5] * z;
      final wz = r[6] * x + r[7] * y + r[8] * z;
      final k = _scale * _d0 / (_d0 - wz);
      _sx[i] = _cx + wx * k;
      _sy[i] = _cy - wy * k;
    }

    final facets = mesh.facetCount, planes = mesh.planes;
    if (_front.length < facets) _front = Uint8List(facets);
    _frontIds.clear();
    for (var f = 0; f < facets; f++) {
      final o = f * 4;
      final facing =
          planes[o] * ex +
          planes[o + 1] * ey +
          planes[o + 2] * ez -
          planes[o + 3];
      final front = facing > 1e-9;
      _front[f] = front ? 1 : 0;
      if (front) _frontIds.add(f);
    }

    _nv = 0;
    _nh = 0;
    final edges = wire.edges, adjStart = wire.adjStart, adj = wire.adj;
    for (var e = 0; e < wire.edgeCount; e++) {
      var anyFront = false, anyBack = false;
      for (var j = adjStart[e]; j < adjStart[e + 1]; j++) {
        if (_front[adj[j]] == 1) {
          anyFront = true;
        } else {
          anyBack = true;
        }
      }
      final a = edges[e * 2], b = edges[e * 2 + 1];
      if (wire.smooth[e] == 1) {
        // A girdle seam shows only as the girdle's outline.
        if (!(anyFront && anyBack)) continue;
      } else if (!anyFront) {
        _addHidden(_sx[a], _sy[a], _sx[b], _sy[b]);
        continue;
      }
      if (wire.convex) {
        _addVisible(_sx[a], _sy[a], _sx[b], _sy[b]);
      } else {
        _clipCovered(mesh, wire, e, a, b, ex, ey, ez);
      }
    }

    final width = (_scale * 0.0105).clamp(0.9, 1.7);
    final line = style.line;
    if (_nh > 0) {
      _hidPaint
        ..color = line.withValues(alpha: line.a * hiddenAlpha)
        ..strokeWidth = width * 0.8;
      canvas.drawRawPoints(
        ui.PointMode.lines,
        Float32List.sublistView(_hid, 0, _nh),
        _hidPaint,
      );
    }
    if (inclusions.isNotEmpty) _paintInclusions(canvas, inclusions, width);
    if (_nv > 0) {
      _visPaint
        ..color = line
        ..strokeWidth = width;
      canvas.drawRawPoints(
        ui.PointMode.lines,
        Float32List.sublistView(_vis, 0, _nv),
        _visPaint,
      );
    }
  }

  void _addVisible(double x0, double y0, double x1, double y1) {
    if (_nv + 4 > _vis.length) {
      _vis = Float32List(_vis.length * 2)..setAll(0, _vis);
    }
    _vis
      ..[_nv++] = x0
      ..[_nv++] = y0
      ..[_nv++] = x1
      ..[_nv++] = y1;
  }

  void _addHidden(double x0, double y0, double x1, double y1) {
    if (_nh + 4 > _hid.length) {
      _hid = Float32List(_hid.length * 2)..setAll(0, _hid);
    }
    _hid
      ..[_nh++] = x0
      ..[_nh++] = y0
      ..[_nh++] = x1
      ..[_nh++] = y1;
  }

  /// Draws edge [e] (vertices [a]–[b]) visible where no nearer facet
  /// facing the viewer covers it, faint where one does. Each test is
  /// exact in 3D: a point is covered when it lies behind a facet's plane
  /// and the line of sight to it passes inside the facet, all linear
  /// along the edge.
  void _clipCovered(
    SimMesh mesh,
    SimWireMesh wire,
    int e,
    int a,
    int b,
    double ex,
    double ey,
    double ez,
  ) {
    final pos = mesh.positions, planes = mesh.planes;
    final starts = mesh.facetStart, fv = mesh.facetVerts;
    final ax = pos[a * 3], ay = pos[a * 3 + 1], az = pos[a * 3 + 2];
    final dx = pos[b * 3] - ax, dy = pos[b * 3 + 1] - ay;
    final dz = pos[b * 3 + 2] - az;
    // From the eye to the edge's start.
    final qx = ax - ex, qy = ay - ey, qz = az - ez;
    _occ.clear();
    facets:
    for (final f in _frontIds) {
      for (var j = wire.adjStart[e]; j < wire.adjStart[e + 1]; j++) {
        if (wire.adj[j] == f) continue facets;
      }
      var t0 = 0.0, t1 = 1.0;
      // Clips [t0, t1] to where alpha + beta·t > 0.
      bool keep(double alpha, double beta) {
        if (beta.abs() < 1e-14) return alpha > 0;
        final t = -alpha / beta;
        if (beta > 0) {
          if (t > t0) t0 = t;
        } else if (t < t1) {
          t1 = t;
        }
        return t0 < t1;
      }

      final o = f * 4;
      final nx = planes[o], ny = planes[o + 1], nz = planes[o + 2];
      // Behind the facet's plane, seen from the eye.
      if (!keep(
        planes[o + 3] - (nx * ax + ny * ay + nz * az) - 1e-6,
        -(nx * dx + ny * dy + nz * dz),
      )) {
        continue;
      }
      final s0 = starts[f], k = starts[f + 1] - s0;
      var gx = 0.0, gy = 0.0, gz = 0.0;
      for (var j = 0; j < k; j++) {
        final v = fv[s0 + j] * 3;
        gx += pos[v];
        gy += pos[v + 1];
        gz += pos[v + 2];
      }
      gx = gx / k - ex;
      gy = gy / k - ey;
      gz = gz / k - ez;
      var inside = true;
      for (var j = 0; j < k && inside; j++) {
        final p = fv[s0 + j] * 3, q = fv[s0 + (j + 1) % k] * 3;
        final px = pos[p] - ex, py = pos[p + 1] - ey, pz = pos[p + 2] - ez;
        final rx = pos[q] - ex, ry = pos[q + 1] - ey, rz = pos[q + 2] - ez;
        // Plane through the eye and this side of the facet.
        var mx = py * rz - pz * ry;
        var my = pz * rx - px * rz;
        var mz = px * ry - py * rx;
        final ml = math.sqrt(mx * mx + my * my + mz * mz);
        if (ml < 1e-14) continue;
        if (mx * gx + my * gy + mz * gz < 0) {
          mx = -mx;
          my = -my;
          mz = -mz;
        }
        inside = keep(
          mx * qx + my * qy + mz * qz - 1e-6 * ml,
          mx * dx + my * dy + mz * dz,
        );
      }
      if (inside) _occ.addAll([t0, t1]);
    }

    final out = Float32List(4);
    void piece(double from, double to, bool visible) {
      if (to - from < 1e-6) return;
      _project(ax + dx * from, ay + dy * from, az + dz * from, out, 0);
      _project(ax + dx * to, ay + dy * to, az + dz * to, out, 2);
      visible
          ? _addVisible(out[0], out[1], out[2], out[3])
          : _addHidden(out[0], out[1], out[2], out[3]);
    }

    if (_occ.isEmpty) {
      piece(0, 1, true);
      return;
    }
    // Merge the covered spans, then draw the gaps between them.
    final spans = [
      for (var i = 0; i < _occ.length; i += 2) (_occ[i], _occ[i + 1]),
    ]..sort((p, q) => p.$1.compareTo(q.$1));
    var at = 0.0;
    var coverFrom = -1.0, coverTo = -1.0;
    for (final (lo, hi) in spans) {
      if (coverTo >= 0 && lo <= coverTo) {
        coverTo = math.max(coverTo, hi);
        continue;
      }
      if (coverTo >= 0) {
        piece(coverFrom, coverTo, false);
        at = coverTo;
      }
      piece(at, lo, true);
      coverFrom = lo;
      coverTo = hi;
    }
    piece(coverFrom, coverTo, false);
    piece(coverTo, 1, true);
  }

  /// Plots inclusions with a grading report's symbols, drawn in 3D where
  /// they sit: crystals as small octahedra (filled when dark), feathers as
  /// their crack's outline (dashed once glass filled), needles as lines,
  /// clouds as rings of dots, pinpoints as dots.
  void _paintInclusions(
    Canvas canvas,
    List<SimInclusion> inclusions,
    double width,
  ) {
    final strokes = Path(), dashes = Path();
    final fills = Path(), points = Path();
    var dark = false, pins = false;
    final dots = <double>[];
    final px = 1 / _scale;

    for (final inc in inclusions) {
      final cx = inc.x, cy = inc.y, cz = inc.z;
      // Axis and two directions across it.
      var ux = inc.ax, uy = inc.ay, uz = inc.az;
      var l = math.sqrt(ux * ux + uy * uy + uz * uz);
      if (l < 1e-9) {
        (ux, uy, uz, l) = (0.0, 1.0, 0.0, 1.0);
      }
      ux /= l;
      uy /= l;
      uz /= l;
      final (hx, hy, hz) = uy.abs() < 0.9 ? (0.0, 1.0, 0.0) : (1.0, 0.0, 0.0);
      var vx = uy * hz - uz * hy, vy = uz * hx - ux * hz;
      var vz = ux * hy - uy * hx;
      final vl = math.sqrt(vx * vx + vy * vy + vz * vz);
      vx /= vl;
      vy /= vl;
      vz /= vl;
      final wx = uy * vz - uz * vy, wy = uz * vx - ux * vz;
      final wz = ux * vy - uy * vx;

      Offset at(double a, double b, double c) => _offset(
        cx + ux * a + vx * b + wx * c,
        cy + uy * a + vy * b + wy * c,
        cz + uz * a + vz * b + wz * c,
      );

      /// Closed outline across the axis, radius [rad] varied by [wobble].
      List<Offset> ring(int n, double rad, double wobble) => [
        for (var i = 0; i < n; i++)
          () {
            final th = 2 * math.pi * i / n;
            final rr =
                rad *
                (1 +
                    wobble *
                        (0.6 * math.sin(3 * th + inc.seed * 6.3) +
                            0.4 * math.sin(5 * th + inc.seed * 11.7)));
            return at(0, rr * math.cos(th), rr * math.sin(th));
          }(),
      ];

      switch (inc.kind) {
        case SimInclusionKind.pinpoint:
          final o = _offset(cx, cy, cz);
          pins = true;
          points.addOval(
            Rect.fromCircle(
              center: o,
              radius: math.max(1.3, inc.size * _scale),
            ),
          );
        case SimInclusionKind.clearCrystal || SimInclusionKind.darkCrystal:
          final rad = math.max(inc.size, 2.6 * px);
          final long = rad * (1 + 0.5 * inc.seed);
          final tip = [at(long, 0, 0), at(-long, 0, 0)];
          final belt = [
            at(0, rad, 0),
            at(0, 0, rad),
            at(0, -rad, 0),
            at(0, 0, -rad),
          ];
          if (inc.kind == SimInclusionKind.darkCrystal) {
            dark = true;
            for (final t in tip) {
              for (var i = 0; i < 4; i++) {
                fills.addPolygon([t, belt[i], belt[(i + 1) % 4]], true);
              }
            }
          }
          strokes.addPolygon(belt, true);
          for (final t in tip) {
            for (final q in belt) {
              strokes
                ..moveTo(t.dx, t.dy)
                ..lineTo(q.dx, q.dy);
            }
          }
        case SimInclusionKind.feather:
          strokes.addPolygon(ring(18, math.max(inc.size, 3 * px), 0.18), true);
        case SimInclusionKind.filledFeather:
          final pts = ring(24, math.max(inc.size, 3 * px), 0.18);
          for (var i = 0; i < pts.length; i += 2) {
            final p = pts[i], q = pts[(i + 1) % pts.length];
            dashes
              ..moveTo(p.dx, p.dy)
              ..lineTo(q.dx, q.dy);
          }
        case SimInclusionKind.needle:
          final half = math.max(inc.size, 2.5 * px);
          final p = at(-half, 0, 0), q = at(half, 0, 0);
          strokes
            ..moveTo(p.dx, p.dy)
            ..lineTo(q.dx, q.dy);
        case SimInclusionKind.cloud:
          final rad = math.max(inc.size, 4 * px);
          for (final o in ring(14, rad, 0.12)) {
            dots
              ..add(o.dx)
              ..add(o.dy);
          }
          // A few within, placed by the seed.
          for (var i = 0; i < 6; i++) {
            final th = 2 * math.pi * ((inc.seed * 7.31 + i * 0.618) % 1);
            final rr = rad * (0.25 + 0.5 * ((inc.seed * 3.7 + i * 0.414) % 1));
            final o = at(0, rr * math.cos(th), rr * math.sin(th));
            dots
              ..add(o.dx)
              ..add(o.dy);
          }
      }
    }

    final w = width * 0.9;
    if (dark) {
      canvas.drawPath(
        fills,
        _incFill..color = SimWireStyle.inclusionDark.withValues(alpha: 0.9),
      );
    }
    if (pins) {
      canvas.drawPath(points, _incFill..color = SimWireStyle.inclusion);
    }
    _incPaint
      ..color = SimWireStyle.inclusion
      ..strokeWidth = w;
    canvas
      ..drawPath(strokes, _incPaint)
      ..drawPath(dashes, _incPaint);
    if (dots.isNotEmpty) {
      canvas.drawRawPoints(
        ui.PointMode.points,
        Float32List.fromList(dots),
        _incPaint..strokeWidth = w * 1.5,
      );
    }
  }
}
