import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'diamond_mesh.dart';
import 'gem_mesh.dart';
import 'gem_renderer.dart';

/// Facet colours of one stone kept between frames. A stone can then be
/// re-shaded only every few frames while its outline still moves every
/// frame: facet colours drift slowly as it turns, so the lag is invisible,
/// and shading is most of the per-stone cost.
class DiamondShade {
  DiamondMesh? _mesh;
  bool _clear = false;
  Int32List _color = Int32List(0);
  Float32List _lum = Float32List(0);

  /// Per facet: 0 not shaded yet, 1 shaded as a front facet, 2 as a back
  /// facet seen through the stone.
  Uint8List _side = Uint8List(0);

  /// Binds to [mesh]; false when the cache had to be cleared.
  bool _bind(DiamondMesh mesh, bool clear) {
    if (identical(mesh, _mesh) && clear == _clear) return true;
    _mesh = mesh;
    _clear = clear;
    final n = mesh.facetCount;
    if (_side.length < n) {
      _color = Int32List(n);
      _lum = Float32List(n);
      _side = Uint8List(n);
    } else {
      _side.fillRange(0, n, 0);
    }
    return false;
  }
}

/// Accumulates colourless diamonds into indexed [ui.Vertices] draws plus
/// one sparkle atlas draw. Reuse one batch per painter: its buffers grow
/// once and are recycled every frame, so steady-state painting allocates
/// almost nothing.
///
/// Shading: each facet is a flat mirror and gets one neutral grey, the
/// studio it reflects off its surface (weak, Fresnel) plus the light it
/// returns from inside, where the ray refracts in, bounces off the pavilion
/// and comes back out (strong, the "brilliance"). The studio is a dark room
/// with an overhead soft box, strip lights and a floor bounce, and the
/// viewer's own head blocks what lies straight behind the camera, so facets
/// snap between white and near black as the stone turns, as a real diamond
/// does. No dispersion colour is added.
///
/// Cost per stone: every shared vertex is transformed and projected once,
/// every facet is culled, shaded and coloured once; stones entirely off
/// the viewport are skipped before any of that.
class DiamondBatch {
  // Indexed draws use 16-bit indices, so a batch is cut into chunks.
  static const _chunkVertices = 65000;

  Float32List _pos = Float32List(0);
  Int32List _col = Int32List(0);
  Uint16List _idx = Uint16List(0);
  int _verts = 0, _indices = 0;
  final List<ui.Vertices> _chunks = [];

  // Per-stone scratch: world and screen position of each vertex.
  Float32List _wx = Float32List(0), _wy = Float32List(0);
  Float32List _wz = Float32List(0);
  Float32List _sx = Float32List(0), _sy = Float32List(0);

  // Sparkles, drawn in one atlas call.
  Float32List _sparkXform = Float32List(0);
  Float32List _sparkRects = Float32List(0);
  Int32List _sparkColor = Int32List(0);
  int _sparks = 0;

  void reset() {
    _verts = 0;
    _indices = 0;
    _sparks = 0;
    for (final c in _chunks) {
      c.dispose();
    }
    _chunks.clear();
  }

  void _flush() {
    if (_indices == 0) return;
    _chunks.add(
      ui.Vertices.raw(
        ui.VertexMode.triangles,
        Float32List.sublistView(_pos, 0, _verts * 2),
        colors: Int32List.sublistView(_col, 0, _verts),
        indices: Uint16List.sublistView(_idx, 0, _indices),
      ),
    );
    _verts = 0;
    _indices = 0;
  }

  void _reserve(DiamondMesh mesh, {bool twice = false}) {
    final passes = twice ? 2 : 1;
    if (_verts + mesh.verts.length * passes > _chunkVertices) _flush();
    final verts = _verts + mesh.verts.length * passes;
    if (_col.length < verts) {
      final cap = math.max(verts, _col.length * 2);
      _pos = Float32List(cap * 2)..setRange(0, _verts * 2, _pos);
      _col = Int32List(cap)..setRange(0, _verts, _col);
    }
    final indices = _indices + mesh.tris.length * passes;
    if (_idx.length < indices) {
      _idx = Uint16List(math.max(indices, _idx.length * 2))
        ..setRange(0, _indices, _idx);
    }
    _mesh = mesh;
    final n = mesh.vertexCount;
    if (_wx.length < n) {
      _wx = Float32List(n);
      _wy = Float32List(n);
      _wz = Float32List(n);
      _sx = Float32List(n);
      _sy = Float32List(n);
    }
  }

  DiamondMesh? _mesh;

  /// Appends facet [f] of the stone being added: its vertices (projected
  /// into the scratch arrays) in one [color], then its triangles.
  void _emit(int f, int color, int start, int end) {
    final mesh = _mesh!;
    final verts = mesh.verts, tris = mesh.tris;
    final base = _verts;
    for (var j = start; j < end; j++) {
      final v = verts[j];
      _pos[_verts * 2] = _sx[v];
      _pos[_verts * 2 + 1] = _sy[v];
      _col[_verts] = color;
      _verts++;
    }
    for (var j = mesh.triStart[f]; j < mesh.triStart[f + 1]; j++) {
      _idx[_indices++] = base + tris[j];
    }
  }

  /// Draws everything added since [reset], then the sparkles from
  /// [sparkle] additively.
  void paint(Canvas canvas, {ui.Image? sparkle}) {
    _flush();
    final paint = Paint();
    for (final c in _chunks) {
      canvas.drawVertices(c, BlendMode.dst, paint);
      c.dispose();
    }
    _chunks.clear();
    if (sparkle == null || _sparks == 0) return;
    final w = sparkle.width.toDouble(), h = sparkle.height.toDouble();
    if (_sparkRects.length < _sparks * 4) {
      _sparkRects = Float32List(_sparkXform.length);
    }
    final rects = _sparkRects;
    for (var i = 0; i < _sparks; i++) {
      rects
        ..[i * 4 + 2] = w
        ..[i * 4 + 3] = h;
    }
    canvas.drawRawAtlas(
      sparkle,
      Float32List.sublistView(_sparkXform, 0, _sparks * 4),
      Float32List.sublistView(rects, 0, _sparks * 4),
      Int32List.sublistView(_sparkColor, 0, _sparks),
      BlendMode.modulate,
      null,
      Paint()..blendMode = BlendMode.plus,
    );
  }

  void _addSparkle(Offset at, double size, double intensity, double spriteW) {
    if (_sparkColor.length <= _sparks) {
      final cap = math.max(32, _sparkColor.length * 2);
      _sparkXform = Float32List(cap * 4)..setRange(0, _sparks * 4, _sparkXform);
      _sparkColor = Int32List(cap)..setRange(0, _sparks, _sparkColor);
    }
    final scale = size / spriteW;
    final half = spriteW / 2 * scale;
    final c = (intensity.clamp(0.0, 1.0) * 255).round();
    _sparkXform
      ..[_sparks * 4] = scale
      ..[_sparks * 4 + 1] = 0
      ..[_sparks * 4 + 2] = at.dx - half
      ..[_sparks * 4 + 3] = at.dy - half;
    _sparkColor[_sparks] = c << 24 | c << 16 | c << 8 | c;
    _sparks++;
  }

  // Fluorescence of the stone being added: emitted colour and strength.
  double _glowR = 0, _glowG = 0, _glowB = 0, _glow = 0;

  /// ARGB of a facet: its [base] grey (before fog) plus the stone's
  /// fluorescence, which glows from the body and so shows most in dark
  /// facets and through the crystal ([inner]), then fogged.
  int _facetColor(
    double base,
    double tone,
    double seed,
    double keep,
    double fogGrey,
    int alpha, {
    bool inner = false,
  }) {
    if (_glow <= 0) {
      final c = ((base * keep + fogGrey * (1 - keep)).clamp(0.0, 1.0) * 255)
          .round();
      return alpha << 24 | c << 16 | c << 8 | c;
    }
    final e =
        _glow * (0.55 + 0.45 * seed) * (1 - 0.7 * tone) * (inner ? 1.3 : 1);
    int ch(double glow) =>
        (((base + e * glow) * keep + fogGrey * (1 - keep)).clamp(0.0, 1.0) *
                255)
            .round();
    return alpha << 24 | ch(_glowR) << 16 | ch(_glowG) << 8 | ch(_glowB);
  }

  static const _ior = 2.42;
  static const _eta = 1 / _ior;

  // Studio lights (unit directions, world space; +z toward the viewer).
  static const _boxX = -0.3, _boxY = 0.8, _boxZ = 0.52; // overhead box
  static const _rightX = 0.88, _rightY = 0.3, _rightZ = 0.36; // strip
  static const _leftX = -0.9, _leftY = 0.12, _leftZ = 0.42; // strip
  static const _lowX = 0.2, _lowY = -0.7, _lowZ = 0.68; // floor bounce

  static double _step(double e0, double e1, double x) {
    if (x <= e0) return 0;
    if (x >= e1) return 1;
    final t = (x - e0) / (e1 - e0);
    return t * t * (3 - 2 * t);
  }

  static double _studio(double x, double y, double z) {
    final box = _step(0.5, 0.8, x * _boxX + y * _boxY + z * _boxZ);
    final right = _step(0.78, 0.9, x * _rightX + y * _rightY + z * _rightZ);
    final left = _step(0.8, 0.9, x * _leftX + y * _leftY + z * _leftZ);
    final low = _step(0.75, 0.9, x * _lowX + y * _lowY + z * _lowZ);
    // Panels on the walls behind the stone, seen through it.
    final wall = z < 0
        ? _step(0.55, 0.85, (x * 3.1 + y * 1.7).abs() % 2 / 2 * -z * 1.6)
        : 0.0;
    final room = 0.04 + 0.07 * math.max(0.0, y);
    final head = 1 - _step(0.93, 0.985, z);
    return (box * 1.3 + right + left * 0.85 + low * 0.5 + wall * 0.6 + room) *
        head;
  }

  /// Appends one colourless diamond, flat shaded per facet. Stones wholly
  /// outside [viewport] cost a bounds check and nothing more.
  ///
  /// [fog] (0..1) fades it toward [fogColor]; [flash] (0..1) brightens the
  /// whole stone. [light] (0..1) is a white point light at the touch,
  /// [lightFrom] the screen-space direction from the stone toward it.
  /// [sparkleWidth] is the sparkle sprite's pixel width.
  ///
  /// With [seeThrough] the stone is drawn as clear crystal: first the back
  /// facets, seen through the stone and lit by the light they mirror
  /// inside it, then the front facets over them, part transparent. The
  /// crossing facet lines and the bright/dark mosaic inside are what read
  /// as a cut diamond on large flat facets (step cuts). It roughly doubles
  /// the facets drawn, so it is skipped on stones under [seeThroughMin] px.
  ///
  /// With a [shade] cache, facet colours are stored per stone; when
  /// [reshade] is false the stored colours are reused for every facet
  /// still facing the same way, so only the outline is recomputed.
  ///
  /// [glow] (0..1) is fluorescence: the body emits [glowColor], as a
  /// fluorescent diamond does under a UV-rich light.
  void add({
    required DiamondMesh mesh,
    required GemPose pose,
    required GemCamera camera,
    required Size viewport,
    double time = 0,
    double fog = 0,
    Color fogColor = const Color(0xFF070709),
    double flash = 0,
    bool sparkle = true,
    double sparkleWidth = 64,
    double light = 0,
    Offset lightFrom = Offset.zero,
    double phase = 0,
    bool seeThrough = false,
    double seeThroughMin = 12,
    DiamondShade? shade,
    bool reshade = true,
    Color glowColor = const Color(0xFF5B8CFF),
    double glow = 0,
  }) {
    _glow = glow.clamp(0.0, 1.0);
    _glowR = glowColor.r;
    _glowG = glowColor.g;
    _glowB = glowColor.b;
    final eyeX = camera.eyeX, eyeY = camera.eyeY, eyeZ = camera.distance;
    final unit = camera.unit;
    final ccx = camera.center.dx, ccy = camera.center.dy;

    // Whole-stone viewport cull, with a margin for perspective.
    final k0 = unit * eyeZ / math.max(0.5, eyeZ - pose.z);
    final reach = mesh.radius * pose.scale * k0 * 1.25;
    final px0 = ccx + (pose.x - eyeX) * k0, py0 = ccy - (pose.y - eyeY) * k0;
    if (px0 + reach < 0 ||
        py0 + reach < 0 ||
        px0 - reach > viewport.width ||
        py0 - reach > viewport.height) {
      return;
    }
    final clear = seeThrough && reach >= seeThroughMin;
    _reserve(mesh, twice: clear);
    final reuse = shade != null && shade._bind(mesh, clear) && !reshade;
    final colors = shade?._color, lums = shade?._lum, sides = shade?._side;

    // Rotation: the pose's own basis when set, else R = Ry · Rx · Rz.
    final double m00, m01, m02, m10, m11, m12, m20, m21, m22;
    final basis = pose.basis;
    if (basis != null) {
      m00 = basis[0];
      m01 = basis[1];
      m02 = basis[2];
      m10 = basis[3];
      m11 = basis[4];
      m12 = basis[5];
      m20 = basis[6];
      m21 = basis[7];
      m22 = basis[8];
    } else {
      final cx = math.cos(pose.rx), sx = math.sin(pose.rx);
      final cy = math.cos(pose.ry), sy = math.sin(pose.ry);
      final cz = math.cos(pose.rz), sz = math.sin(pose.rz);
      m00 = cy * cz + sy * sx * sz;
      m01 = -cy * sz + sy * sx * cz;
      m02 = sy * cx;
      m10 = cx * sz;
      m11 = cx * cz;
      m12 = -sx;
      m20 = -sy * cz + cy * sx * sz;
      m21 = sy * sz + cy * sx * cz;
      m22 = cy * cx;
    }
    // The stone's table axis; the pavilion mirrors light across it.
    final upX = m01, upY = m11, upZ = m21;

    // Transform and project every shared vertex once.
    final p = mesh.positions;
    final s = pose.scale;
    final wxs = _wx, wys = _wy, wzs = _wz, sxs = _sx, sys = _sy;
    for (var i = 0, j = 0; i < mesh.vertexCount; i++, j += 3) {
      final x = p[j], y = p[j + 1], z = p[j + 2];
      final wx = (m00 * x + m01 * y + m02 * z) * s + pose.x;
      final wy = (m10 * x + m11 * y + m12 * z) * s + pose.y;
      final wz = (m20 * x + m21 * y + m22 * z) * s + pose.z;
      wxs[i] = wx;
      wys[i] = wy;
      wzs[i] = wz;
      final k = unit * eyeZ / math.max(0.5, eyeZ - wz);
      sxs[i] = ccx + (wx - eyeX) * k;
      sys[i] = ccy - (wy - eyeY) * k;
    }

    // One view direction per stone: stones are small against the camera
    // distance, so per-facet view vectors would change nothing visible.
    var vx = eyeX - pose.x, vy = eyeY - pose.y, vz = eyeZ - pose.z;
    final vl = math.sqrt(vx * vx + vy * vy + vz * vz);
    vx /= vl;
    vy /= vl;
    vz /= vl;

    // Fog toward the background's brightness only: never a tint.
    final fogGrey =
        0.2126 * fogColor.r + 0.7152 * fogColor.g + 0.0722 * fogColor.b;
    final keep = 1 - fog.clamp(0.0, 1.0);
    final lit = light.clamp(0.0, 1.0);
    final exposure = 1 + flash * 0.9 + lit * 0.7;
    var plx = lightFrom.dx, ply = -lightFrom.dy, plz = 0.55;
    final pl = math.sqrt(plx * plx + ply * ply + plz * plz);
    plx /= pl;
    ply /= pl;
    plz /= pl;
    const body = 0.025;

    final n = mesh.normals, seeds = mesh.seeds, kinds = mesh.kinds;
    final vertStart = mesh.vertStart, verts = mesh.verts;
    final girdleKind = GemFacetKind.girdle.index;
    final tableKind = GemFacetKind.table.index;
    var bestSpark = 0.0;
    var bestFacet = -1;

    // Pass 0 draws the back facets seen through the stone (clear stones
    // only), pass 1 the front facets.
    for (var pass = clear ? 0 : 1; pass < 2; pass++) {
      final behind = pass == 0;
      for (var f = 0; f < mesh.facetCount; f++) {
        final ox = n[f * 3], oy = n[f * 3 + 1], oz = n[f * 3 + 2];
        final nx = m00 * ox + m01 * oy + m02 * oz;
        final ny = m10 * ox + m11 * oy + m12 * oz;
        final nz = m20 * ox + m21 * oy + m22 * oz;
        final start = vertStart[f], end = vertStart[f + 1];
        final r0 = verts[start];
        final facing =
            nx * (eyeX - wxs[r0]) +
                ny * (eyeY - wys[r0]) +
                nz * (eyeZ - wzs[r0]) >
            0;
        if (facing == behind) continue;
        final kind = kinds[f];
        final side = behind ? 2 : 1;

        // Cached colour from an earlier frame, while the facet still faces
        // the same way.
        if (reuse && sides![f] == side) {
          _emit(f, colors![f], start, end);
          final l = lums![f];
          if (sparkle && kind != girdleKind && l > bestSpark) {
            bestSpark = l;
            bestFacet = f;
          }
          continue;
        }

        if (behind) {
          // Inside face of a back facet: the view ray mirrors off it and
          // off the pavilion before leaving, so it shows a scattered patch
          // of the room, the kaleidoscope inside a diamond.
          final dn = -(nx * vx + ny * vy + nz * vz);
          var ix = -vx - 2 * dn * nx;
          var iy = -vy - 2 * dn * ny;
          var iz = -vz - 2 * dn * nz;
          final scatter = (seeds[f] - 0.5) * 2.2;
          ix += nx * scatter;
          iy += ny * scatter;
          iz += nz * scatter;
          var il = math.sqrt(ix * ix + iy * iy + iz * iz);
          ix /= il;
          iy /= il;
          iz /= il;
          final iu = 2 * (ix * upX + iy * upY + iz * upZ);
          var jx = ix - iu * upX, jy = iy - iu * upY, jz = iz - iu * upZ;
          il = math.sqrt(jx * jx + jy * jy + jz * jz);
          jx /= il;
          jy /= il;
          jz /= il;
          var lum =
              0.02 + 0.9 * _studio(ix, iy, iz) + 1.3 * _studio(jx, jy, jz);
          if (lit > 0) {
            final hit = math.max(0.0, jx * plx + jy * ply + jz * plz);
            final h2 = hit * hit;
            lum += lit * (0.08 + h2 * h2 * h2 * 1.2);
          }
          lum *= exposure;
          final tone = 1 - math.exp(-lum * 1.7);
          final color = _facetColor(
            0.04 + tone * tone * (1.6 - 0.6 * tone),
            tone,
            seeds[f],
            keep,
            fogGrey,
            0xFF,
            inner: true,
          );
          _emit(f, color, start, end);
          if (sides != null) {
            colors![f] = color;
            lums![f] = lum;
            sides[f] = side;
          }
          // Inner reflections sparkle too.
          if (sparkle && kind != girdleKind && lum > bestSpark) {
            bestSpark = lum;
            bestFacet = f;
          }
          continue;
        }

        final ndv = math.max(0.0, nx * vx + ny * vy + nz * vz);
        // Surface mirror.
        final rx = 2 * ndv * nx - vx;
        final ry = 2 * ndv * ny - vy;
        final rz = 2 * ndv * nz - vz;
        final grazing = 1 - ndv;
        final g2 = grazing * grazing;
        final fresnel = 0.17 + 0.83 * g2 * g2 * grazing;

        var lum = 0.0;
        var ex = rx, ey = ry, ez = rz;
        if (kind == girdleKind) {
          // Frosted girdle: a dim, soft band.
          lum = 0.04 + 0.25 * _studio(rx, ry, rz);
        } else {
          // Refract in, mirror off the pavilion across the table axis, and
          // let each facet's angle scatter the returning ray.
          final kk = 1 - _eta * _eta * (1 - ndv * ndv);
          final fr = _eta * ndv - math.sqrt(math.max(0.0, kk));
          var tx = -_eta * vx + fr * nx;
          var ty = -_eta * vy + fr * ny;
          var tz = -_eta * vz + fr * nz;
          final tu = 2 * (tx * upX + ty * upY + tz * upZ);
          tx -= tu * upX;
          ty -= tu * upY;
          tz -= tu * upZ;
          final scatter = (seeds[f] - 0.5) * 1.6;
          ex = tx + nx * scatter + vx * 0.15;
          ey = ty + ny * scatter + vy * 0.15;
          ez = tz + nz * scatter + vz * 0.15;
          final el = math.sqrt(ex * ex + ey * ey + ez * ez);
          ex /= el;
          ey /= el;
          ez /= el;
          var inside = _studio(ex, ey, ez);
          if (kind == tableKind) {
            // The table is one flat facet over many pavilion facets: it
            // returns a spread of the room, not a single mirror direction.
            double spread(double ax, double ay, double az) {
              final qx = ex + ax, qy = ey + ay, qz = ez + az;
              final ql = math.sqrt(qx * qx + qy * qy + qz * qz);
              return _studio(qx / ql, qy / ql, qz / ql);
            }

            inside =
                (inside +
                    spread(m00 * 0.8, m10 * 0.8, m20 * 0.8) +
                    spread(-m00 * 0.8, -m10 * 0.8, -m20 * 0.8) +
                    spread(m02 * 0.8, m12 * 0.8, m22 * 0.8) +
                    spread(-m02 * 0.8, -m12 * 0.8, -m22 * 0.8)) /
                5 *
                1.6;
          }
          lum = clear
              // The crystal behind already returns the inner light; the
              // front shows mostly its mirror and a share of the brilliance.
              ? fresnel * 2.2 * _studio(rx, ry, rz) +
                    (1 - fresnel) * 0.6 * inside
              : fresnel * _studio(rx, ry, rz) + (1 - fresnel) * 0.95 * inside;
        }

        if (lit > 0) {
          final face = math.max(0.0, nx * plx + ny * ply + nz * plz);
          final hit = math.max(
            math.max(0.0, rx * plx + ry * ply + rz * plz),
            math.max(0.0, ex * plx + ey * ply + ez * plz),
          );
          final h2 = hit * hit;
          final h8 = h2 * h2 * h2 * h2;
          lum += lit * (0.06 + face * 0.18 + h8 * h8 * 1.6);
        }
        lum *= exposure;

        // Soft shoulder so bright facets stay crisp white, never a flat blob,
        // and a toe that sinks mid greys toward black for diamond contrast.
        final tone = 1 - math.exp(-lum * 1.7);
        // Clear stones: front facets let the crystal behind show through,
        // less so at grazing angles where the surface mirrors more.
        final alpha = clear ? (0.38 + 0.8 * fresnel).clamp(0.38, 0.92) : 1.0;
        final color = _facetColor(
          body + tone * tone * (1.6 - 0.6 * tone),
          tone,
          seeds[f],
          keep,
          fogGrey,
          (alpha * 255).round(),
        );
        _emit(f, color, start, end);
        if (sides != null) {
          colors![f] = color;
          lums![f] = lum;
          sides[f] = side;
        }

        if (sparkle && kind != girdleKind && lum > bestSpark) {
          bestSpark = lum;
          bestFacet = f;
        }
      }
    }

    // The brightest facet throws a small, crisp sparkle.
    final threshold = 0.95 * (1 - 0.3 * lit);
    if (bestFacet < 0 || bestSpark <= threshold) return;
    var ax = 0.0, ay = 0.0;
    final start = vertStart[bestFacet], end = vertStart[bestFacet + 1];
    for (var j = start; j < end; j++) {
      ax += sxs[verts[j]];
      ay += sys[verts[j]];
    }
    final count = end - start;
    final twinkle = lit > 0
        ? 1 - lit * 0.4 * (0.5 + 0.5 * math.sin(time * 9 + phase * 6.283))
        : 1.0;
    _addSparkle(
      Offset(ax / count, ay / count),
      pose.scale * k0 * (0.9 + lit * 0.6),
      ((bestSpark - threshold) / threshold).clamp(0.0, 1.0) *
          keep *
          (1 + flash) *
          twinkle,
      sparkleWidth,
    );
  }
}

/// Lazily rendered small white sparkle: a bright point in a soft halo with
/// short, faint diffraction spikes, as a camera sees a diamond's sparkle.
abstract final class DiamondSparkle {
  static ui.Image? _image;

  static ui.Image get image => _image ??= _render();

  static ui.Image _render() {
    const size = 64.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const c = Offset(size / 2, size / 2);
    canvas
      ..drawCircle(
        c,
        size * 0.3,
        Paint()
          ..shader = ui.Gradient.radial(c, size * 0.3, const [
            Color(0x55FFFFFF),
            Color(0x00FFFFFF),
          ]),
      )
      ..drawCircle(
        c,
        size * 0.07,
        Paint()
          ..shader = ui.Gradient.radial(c, size * 0.07, const [
            Color(0xFFFFFFFF),
            Color(0x00FFFFFF),
          ]),
      );
    final ray = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8);
    for (final vertical in [false, true]) {
      ray.shader = ui.Gradient.linear(
        vertical ? const Offset(size / 2, 0) : const Offset(0, size / 2),
        vertical ? const Offset(size / 2, size) : const Offset(size, size / 2),
        const [Color(0x00FFFFFF), Color(0x88FFFFFF), Color(0x00FFFFFF)],
        const [0.15, 0.5, 0.85],
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: c,
          width: vertical ? 1.4 : size * 0.8,
          height: vertical ? size * 0.8 : 1.4,
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
