import 'dart:math' as math;
import 'dart:typed_data';

import '../domain/diamond_grades.dart';
import 'sim_mesh.dart';
import 'sim_optics.dart';

/// Physically based light path through a cut stone, traced backward from
/// the eye: Fresnel reflection off the surface, refraction in (Snell),
/// total internal reflection off facets past the critical angle (24.4°
/// for diamond), partial escape everywhere else, Beer–Lambert body colour
/// along every segment and fluorescent glow picked up on the way.
///
/// Dispersion splits each escape into red, green and blue with their own
/// refractive index: near the critical angle one colour leaks out while
/// another is still trapped, which is exactly what makes diamond fire.
/// One geometric path is followed (green), so fire costs a few extra
/// environment lookups, not three traces.
///
/// Works in model space against the stone's facet planes: the stone is
/// convex, so a ray leaves through the nearest plane ahead of it.
class SimTracer {
  // Diamond's refractive index at red (687 nm), green (589 nm, the D
  // line) and blue (431 nm); B–G spread is its 0.044 dispersion. Must match
  // `shaders/diamond_trace.frag`.
  static const _iorR = 2.407, _iorG = 2.418, _iorB = 2.451;

  SimMesh? _mesh;
  late Float64List _solid; // non-girdle planes, packed nx ny nz d
  late Int32List _solidIndex;
  late Float64List _girdle;
  late Int32List _girdleIndex;
  late Float64List _inner;
  double _innerMin = 0;

  SimOptics optics = const SimOptics(
    absorbR: 0,
    absorbG: 0,
    absorbB: 0,
    emitR: 0,
    emitG: 0,
    emitB: 0,
    haze: 0,
    milk: 0,
    lighting: SimLighting.daylight,
  );
  SimStudio studio = SimStudio(SimLighting.daylight);

  /// Bounces followed inside the stone.
  int maxBounces = 8;

  /// Model → world rotation, row major.
  double r00 = 1, r01 = 0, r02 = 0;
  double r10 = 0, r11 = 1, r12 = 0;
  double r20 = 0, r21 = 0, r22 = 1;

  /// HDR result of the last [trace].
  double outR = 0, outG = 0, outB = 0;

  /// Length of the last path inside the stone, model units.
  double pathLength = 0;

  set mesh(SimMesh mesh) {
    if (identical(mesh, _mesh)) return;
    _mesh = mesh;
    final planes = mesh.planes;
    final girdle = mesh.girdleFacets.toSet();
    final solid = <int>[], ring = <int>[];
    for (var f = 0; f < mesh.facetCount; f++) {
      (girdle.contains(f) ? ring : solid).add(f);
    }
    Float64List pack(List<int> ids) {
      final out = Float64List(ids.length * 4);
      for (var i = 0; i < ids.length; i++) {
        out.setRange(i * 4, i * 4 + 4, planes, ids[i] * 4);
      }
      return out;
    }

    _solid = pack(solid);
    _solidIndex = Int32List.fromList(solid);
    _girdle = pack(ring);
    _girdleIndex = Int32List.fromList(ring);
    _inner = mesh.innerRadius;
    _innerMin = _inner.reduce(math.min);
  }

  /// Sets the model → world rotation.
  void rotation(Float64List m) {
    r00 = m[0];
    r01 = m[1];
    r02 = m[2];
    r10 = m[3];
    r11 = m[4];
    r12 = m[5];
    r20 = m[6];
    r21 = m[7];
    r22 = m[8];
  }

  void _env(double x, double y, double z) => studio.sample(
    r00 * x + r01 * y + r02 * z,
    r10 * x + r11 * y + r12 * z,
    r20 * x + r21 * y + r22 * z,
  );

  /// Unpolarised Fresnel reflectance between media [n1] → [n2].
  static double _fresnel(double cosI, double cosT, double n1, double n2) {
    final s = (n1 * cosI - n2 * cosT) / (n1 * cosI + n2 * cosT);
    final p = (n2 * cosI - n1 * cosT) / (n2 * cosI + n1 * cosT);
    return (s * s + p * p) / 2;
  }

  /// Traces the view ray hitting facet [facet] at (px, py, pz) along unit
  /// direction (dx, dy, dz), all in model space. Result in [outR],
  /// [outG], [outB].
  void trace(
    int facet,
    double px,
    double py,
    double pz,
    double dx,
    double dy,
    double dz,
  ) {
    final planes = _mesh!.planes;
    final env = studio;
    var nx = planes[facet * 4], ny = planes[facet * 4 + 1];
    var nz = planes[facet * 4 + 2];

    // Surface mirror.
    var cosI = -(dx * nx + dy * ny + dz * nz);
    if (cosI < 1e-4) cosI = 1e-4;
    final sin2 = (1 - cosI * cosI) / (_iorG * _iorG);
    final cosT = math.sqrt(1 - sin2);
    final f0 = _fresnel(cosI, cosT, 1, _iorG);
    _env(dx + 2 * cosI * nx, dy + 2 * cosI * ny, dz + 2 * cosI * nz);
    var accR = f0 * env.r, accG = f0 * env.g, accB = f0 * env.b;

    // Refract in.
    const eta = 1 / _iorG;
    final k = eta * cosI - cosT;
    var tx = eta * dx + k * nx, ty = eta * dy + k * ny, tz = eta * dz + k * nz;
    var thrR = 1 - f0, thrG = thrR, thrB = thrR;

    final o = optics;
    final aR = o.absorbR + o.haze, aG = o.absorbG + o.haze;
    final aB = o.absorbB + o.haze;
    final scatter = o.haze * 0.35 + o.milk;
    final glow = o.emitR + o.emitG + o.emitB > 0;
    var length = 0.0;

    final solid = _solid, solidIndex = _solidIndex;
    final girdle = _girdle, girdleIndex = _girdleIndex;
    final solidCount = solidIndex.length, girdleCount = girdleIndex.length;
    final inner = _inner;
    const bins = SimMesh.radialBins;

    for (var bounce = 0; bounce < maxBounces; bounce++) {
      // Nearest facet plane ahead.
      var tMin = double.infinity;
      var hit = -1;
      for (var j = 0, q = 0; j < solidCount; j++, q += 4) {
        final den = tx * solid[q] + ty * solid[q + 1] + tz * solid[q + 2];
        if (den <= 1e-9) continue;
        final t =
            (solid[q + 3] -
                (px * solid[q] + py * solid[q + 1] + pz * solid[q + 2])) /
            den;
        if (t < tMin) {
          tMin = t;
          hit = solidIndex[j];
        }
      }
      // The girdle only matters if that point lies outside its edge.
      var ring = hit < 0;
      if (!ring) {
        final hx = px + tx * tMin, hz = pz + tz * tMin;
        final r2 = hx * hx + hz * hz;
        if (r2 >= _innerMin * _innerMin) {
          final bin =
              (math.atan2(hz, hx) / (2 * math.pi) * bins).floor() % bins;
          final ri = inner[bin];
          ring = r2 >= ri * ri;
        }
      }
      if (ring) {
        for (var j = 0, q = 0; j < girdleCount; j++, q += 4) {
          final den = tx * girdle[q] + ty * girdle[q + 1] + tz * girdle[q + 2];
          if (den <= 1e-9) continue;
          final t =
              (girdle[q + 3] -
                  (px * girdle[q] + py * girdle[q + 1] + pz * girdle[q + 2])) /
              den;
          if (t < tMin) {
            tMin = t;
            hit = girdleIndex[j];
          }
        }
      }
      if (hit < 0 || !tMin.isFinite) break;
      if (tMin < 0) tMin = 0;

      px += tx * tMin;
      py += ty * tMin;
      pz += tz * tMin;
      length += tMin;

      // Colour soaks in along the segment; fluorescence and clouds add
      // their own light.
      if (aR + aG + aB > 0) {
        thrR *= math.exp(-aR * tMin);
        thrG *= math.exp(-aG * tMin);
        thrB *= math.exp(-aB * tMin);
      }
      if (glow) {
        final w = (thrR + thrG + thrB) / 3 * tMin;
        accR += o.emitR * w;
        accG += o.emitG * w;
        accB += o.emitB * w;
      }
      if (scatter > 0) {
        final w = scatter * tMin * (thrG + 0.2);
        accR += w * 0.5;
        accG += w * 0.5;
        accB += w * 0.52;
      }

      nx = planes[hit * 4];
      ny = planes[hit * 4 + 1];
      nz = planes[hit * 4 + 2];
      final c = tx * nx + ty * ny + tz * nz;
      final s1 = 1 - c * c;

      // Escape, per colour. Higher index traps blue first.
      final s2G = _iorG * _iorG * s1;
      if (s2G < 0.5) {
        // Steep exit: the three colours leave almost together.
        final cG = math.sqrt(1 - s2G);
        final ex = _iorG * tx - (_iorG * c - cG) * nx;
        final ey = _iorG * ty - (_iorG * c - cG) * ny;
        final ez = _iorG * tz - (_iorG * c - cG) * nz;
        _env(ex, ey, ez);
        final fR = _exitFresnel(c, s1, _iorR);
        final fG = _fresnel(c, cG, _iorG, 1);
        final fB = _exitFresnel(c, s1, _iorB);
        accR += thrR * (1 - fR) * env.r;
        accG += thrG * (1 - fG) * env.g;
        accB += thrB * (1 - fB) * env.b;
        thrR *= fR;
        thrG *= fG;
        thrB *= fB;
      } else {
        thrR = _escape(0, _iorR, tx, ty, tz, nx, ny, nz, c, s1, thrR);
        accR += _gain;
        thrG = _escape(1, _iorG, tx, ty, tz, nx, ny, nz, c, s1, thrG);
        accG += _gain;
        thrB = _escape(2, _iorB, tx, ty, tz, nx, ny, nz, c, s1, thrB);
        accB += _gain;
      }

      // Follow the reflected part.
      tx -= 2 * c * nx;
      ty -= 2 * c * ny;
      tz -= 2 * c * nz;
      if (thrR < 0.012 && thrG < 0.012 && thrB < 0.012) break;
    }

    // Whatever is still trapped returns as a faint average of the room.
    outR = accR + thrR * 0.02;
    outG = accG + thrG * 0.02;
    outB = accB + thrB * 0.02;
    pathLength = length;
  }

  double _gain = 0;

  /// Escapes channel [ch] at index [ior] through the facet: adds its
  /// transmitted light to [_gain] and returns the throughput it keeps.
  double _escape(
    int ch,
    double ior,
    double tx,
    double ty,
    double tz,
    double nx,
    double ny,
    double nz,
    double c,
    double s1,
    double thr,
  ) {
    final s2 = ior * ior * s1;
    if (s2 >= 1) {
      _gain = 0;
      return thr;
    }
    final cT = math.sqrt(1 - s2);
    final f = _fresnel(c, cT, ior, 1);
    final k = ior * c - cT;
    _env(ior * tx - k * nx, ior * ty - k * ny, ior * tz - k * nz);
    final e = ch == 0
        ? studio.r
        : ch == 1
        ? studio.g
        : studio.b;
    _gain = thr * (1 - f) * e;
    return thr * f;
  }

  static double _exitFresnel(double c, double s1, double ior) {
    final s2 = ior * ior * s1;
    if (s2 >= 1) return 1;
    return _fresnel(c, math.sqrt(1 - s2), ior, 1);
  }
}
