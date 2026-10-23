import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../domain/hand_model.dart';
import '../domain/hand_ring.dart';
import 'hand_ring_mesh.dart';
import 'sim_renderer.dart';

/// How the 3D hand is seen: turned [yaw] about the vertical, tipped by
/// [pitch], rolled by [roll] about the line of sight, around
/// [HandModel.pivot], which lands at [centre] on screen with [pxPerMm]
/// logical pixels per millimetre. A gentle perspective from [distance] mm,
/// as a product photographer's longer lens gives.
class HandCamera {
  HandCamera({
    required this.yaw,
    required this.pitch,
    this.roll = 0,
    required this.centre,
    required this.pxPerMm,
    this.distance = 700,
  }) {
    final cy = math.cos(yaw), sy = math.sin(yaw);
    final cp = math.cos(pitch), sp = math.sin(pitch);
    final cr = math.cos(roll), sr = math.sin(roll);
    // Rz(roll) · Rx(pitch) · Ry(yaw), row major.
    final m = [
      cy, 0.0, sy, //
      sp * sy, cp, -sp * cy,
      -cp * sy, sp, cp * cy,
    ];
    for (var c = 0; c < 3; c++) {
      r[c] = cr * m[c] - sr * m[3 + c];
      r[3 + c] = sr * m[c] + cr * m[3 + c];
      r[6 + c] = m[6 + c];
    }
  }

  final double yaw, pitch, roll, pxPerMm, distance;
  final Offset centre;

  /// Hand → camera rotation, row major. Camera space: x right, y up, z
  /// toward the viewer.
  final Float64List r = Float64List(9);

  /// Direction [v] (hand space) in camera space.
  HandVec turn(HandVec v) => HandVec(
    r[0] * v.x + r[1] * v.y + r[2] * v.z,
    r[3] * v.x + r[4] * v.y + r[5] * v.z,
    r[6] * v.x + r[7] * v.y + r[8] * v.z,
  );

  /// Point [p] (hand space) in camera space, the pivot at the origin.
  HandVec toCamera(HandVec p) => turn(p - HandModel.pivot);

  /// The eye, in hand space.
  HandVec get eye => HandModel.pivot + HandVec(r[6], r[7], r[8]) * distance;

  /// Where [p] lands on screen and the scale there (px per mm).
  ({Offset at, double pxPerMm, double depth}) project(HandVec p) {
    final c = toCamera(p);
    final k = distance / (distance - c.z);
    return (
      at: centre + Offset(c.x, -c.y) * (pxPerMm * k),
      pxPerMm: pxPerMm * k,
      depth: c.z,
    );
  }

  /// The view that shows a stone sitting on [normal] (its table facing
  /// that way, its length along [along]), turned [spin] about its table:
  /// what [SimView] needs to draw it as this camera sees it.
  SimView stoneView(HandVec normal, HandVec along, double spin) {
    final y = turn(normal).unit;
    var x = turn(along);
    x = (x - y * x.dot(y)).unit;
    final z = x.cross(y);
    // Turn the stone about its table: model x → x·cos − z·sin… as SimView
    // applies spin before tilting.
    final cs = math.cos(spin), ss = math.sin(spin);
    final x2 = x * cs - z * ss;
    // Decompose M = Rz(roll) · Rtilt · Rspin, column 1 being the table.
    final roll = math.atan2(-y.x, y.y);
    final tilt = math.atan2(y.z, math.sqrt(y.x * y.x + y.y * y.y));
    final cr = math.cos(-roll), sr = math.sin(-roll);
    final c0x = cr * x2.x - sr * x2.y;
    final c0y = sr * x2.x + cr * x2.y;
    final c0z = x2.z;
    final st = math.sin(tilt), ct = math.cos(tilt);
    final s = math.atan2(c0y * st - c0z * ct, c0x);
    return SimView(tilt: tilt, spin: s, roll: roll);
  }
}

/// The scanned hand's mesh, as the hand bake writes `assets/models/hand.bin`:
/// "HND1", vertex and triangle counts, then hand-space positions (mm),
/// texture coordinates (0..1), triangle indices and per-vertex ambient
/// occlusion (0..255).
class HandMesh {
  HandMesh._(this.positions, this.uvs, this.indices, this.occlusion);

  factory HandMesh.parse(ByteData data) {
    final magic = String.fromCharCodes([
      for (var i = 0; i < 4; i++) data.getUint8(i),
    ]);
    if (magic != 'HND1') throw const FormatException('Not a hand mesh');
    final nv = data.getUint32(4, Endian.little);
    final nt = data.getUint32(8, Endian.little);
    var at = 12;
    Float32List floats(int n) {
      final out = Float32List(n);
      for (var i = 0; i < n; i++, at += 4) {
        out[i] = data.getFloat32(at, Endian.little);
      }
      return out;
    }

    final positions = floats(nv * 3);
    final uvs = floats(nv * 2);
    final indices = Uint16List(nt * 3);
    for (var i = 0; i < indices.length; i++, at += 2) {
      indices[i] = data.getUint16(at, Endian.little);
    }
    final occlusion = Uint8List(nv);
    for (var i = 0; i < nv; i++, at++) {
      occlusion[i] = data.getUint8(at);
    }
    return HandMesh._(positions, uvs, indices, occlusion);
  }

  final Float32List positions, uvs;
  final Uint16List indices;
  final Uint8List occlusion;

  int get vertexCount => occlusion.length;
  int get triangleCount => indices.length ~/ 3;
}

/// Everything the hand needs from the bundle, loaded once.
class HandAssets {
  HandAssets._(this.program, this.mesh, this.skin, this.normals);

  final ui.FragmentProgram program;
  final HandMesh mesh;

  /// The scan's photographed skin, and its hand-space normal map with the
  /// pores and creases of the photograph pressed into it.
  final ui.Image skin, normals;
}

/// A ring on the hand: its triangles, and the seat it hugs (for the soft
/// contact shadow it casts on the skin).
typedef HandRing = ({HandSeat seat, RingMesh mesh, double bandWidth});

/// Draws the scanned hand (LibHand, CC BY 3.0) and the rings on it: all
/// triangles are sorted back to front together and rasterised with the
/// skin photograph and the normal map into a G-buffer, then
/// `shaders/hand_skin.frag` lights skin as skin and rings as metal. Some
/// 24k triangles and one cheap pass instead of a ray march, redrawn only
/// when the view changes and kept as an image in between.
///
/// Stones are drawn over the hand by their own widgets; [paintFront] then
/// redraws, over each stone, whatever lies in front of it (another
/// finger, the near claws), so stones are hidden only where the hand
/// really covers them.
class HandRenderer {
  static Future<HandAssets>? _assets;

  static Future<HandAssets> load() => _assets ??= _load();

  static Future<HandAssets> _load() async {
    Future<ui.Image> image(String path) async {
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      codec.dispose();
      return frame.image;
    }

    final results = await Future.wait<Object>([
      ui.FragmentProgram.fromAsset('shaders/hand_skin.frag'),
      () async {
        return rootBundle.load('assets/models/hand.bin');
      }(),
      image('assets/models/hand_albedo.jpg'),
      image('assets/models/hand_normal.png'),
    ]);
    return HandAssets._(
      results[0] as ui.FragmentProgram,
      HandMesh.parse(results[1] as ByteData),
      results[2] as ui.Image,
      results[3] as ui.Image,
    );
  }

  static Future<void>? _warmUp;

  /// Loads the hand and draws it once offscreen, so the files are decoded
  /// and the GPU driver has compiled its pipelines before it first shows.
  static Future<void> warmUp() => _warmUp ??= _runWarmUp();

  static Future<void> _runWarmUp() async {
    try {
      final r = HandRenderer()..attach(await load());
      final recorder = ui.PictureRecorder();
      r.paint(
        Canvas(recorder),
        const Size(48, 48),
        HandCamera(
          yaw: 0,
          pitch: 0,
          centre: const Offset(24, 24),
          pxPerMm: 0.2,
        ),
        devicePixelRatio: 1,
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(48, 48);
      picture.dispose();
      image.dispose();
      r.dispose();
    } catch (_) {
      // The stage shows no hand rather than fail.
    }
  }

  HandAssets? _a;
  ui.FragmentShader? _shader;
  final Paint _skinPaint = Paint(), _normalPaint = Paint();
  final Paint _shade = Paint();
  final Paint _copy = Paint()..filterQuality = FilterQuality.none;

  /// Scales up an image traced below the device's resolution.
  final Paint _blit = Paint()..filterQuality = FilterQuality.medium;

  /// Pixels per logical pixel the hand is drawn at now, and whether that
  /// is the device's full resolution.
  double _scale = 1;
  bool _full = true;

  // The bare hand, filled once.
  late Float32List _handRel; // positions about the pivot
  late Float32List _handTex; // texture coordinates, skin texels
  late Int32List _handColors; // occlusion grey, forearm fade alpha

  // Hand and rings together, refilled when the rings change.
  Float32List _rel = Float32List(0), _tex = Float32List(0);
  Int32List _colors = Int32List(0), _normalColors = Int32List(0);
  Uint16List _indices = Uint16List(0);
  Uint8List _faded = Uint8List(0);

  /// Whether the bare hand changed since the arrays were filled, and the
  /// bands whose contact shadows they hold.
  bool _handDirty = true;
  List<(HandSeat, double)> _shadows = const [];

  // Per view.
  late Float32List _screen, _depth;
  late Uint16List _sorted;
  late Int32List _keys;
  final Int32List _counts = Int32List(_buckets + 1);
  int _drawn = 0;
  Rect _rect = Rect.zero;

  List<HandRing> _rings = const [];
  RingMetal _metalKind = RingMetal.yellowGold;
  int _version = 0;

  ui.Image? _image, _gbuffer;
  final Float64List _key = Float64List(18), _cachedKey = Float64List(18);
  final Map<int, _FrontLayer> _fronts = {};

  /// Gap between the two halves of the G-buffer, device px.
  static const _gap = 4;
  static const _buckets = 4096;

  /// How far toward the eye a ring's triangles sort, mm: the band hugs
  /// the skin closer than one skin triangle is wide.
  static const _ringBias = 1.5;

  /// What the albedo pass writes for metal: no skin is this magenta.
  static const _metalMarker = 0xFFFF00FF;

  bool get ready => _a != null;

  /// Changes whenever the rings do.
  int get version => _version;

  void attach(HandAssets a) {
    _a = a;
    _shader?.dispose();
    _shader = a.program.fragmentShader();
    final m = a.mesh, nv = m.vertexCount;
    final pivot = HandModel.pivot;
    _handRel = Float32List(nv * 3);
    _handTex = Float32List(nv * 2);
    _handColors = Int32List(nv);
    final tw = a.skin.width.toDouble(), th = a.skin.height.toDouble();
    const fadeStart = HandModel.fadeStart, fadeEnd = HandModel.fadeEnd;
    for (var i = 0; i < nv; i++) {
      final x = m.positions[i * 3], y = m.positions[i * 3 + 1];
      final z = m.positions[i * 3 + 2];
      _handRel[i * 3] = x - pivot.x;
      _handRel[i * 3 + 1] = y - pivot.y;
      _handRel[i * 3 + 2] = z - pivot.z;
      _handTex[i * 2] = m.uvs[i * 2] * tw;
      _handTex[i * 2 + 1] = m.uvs[i * 2 + 1] * th;
      // Baked occlusion, eased: the photograph already darkens the deepest
      // folds.
      final o = m.occlusion[i] / 255;
      final g = (255 * (0.3 + 0.7 * math.pow(o, 0.85))).round().clamp(0, 255);
      var f = ((y - fadeEnd) / (fadeStart - fadeEnd)).clamp(0.0, 1.0);
      f = f * f * (3 - 2 * f);
      final alpha = (255 * f).round();
      _handColors[i] = alpha << 24 | g << 16 | g << 8 | g;
    }
    _skinPaint.shader = ui.ImageShader(
      a.skin,
      TileMode.clamp,
      TileMode.clamp,
      Matrix4.identity().storage,
      filterQuality: FilterQuality.medium,
    );
    final s = a.skin.width / a.normals.width;
    _handDirty = true;
    _normalPaint.shader = ui.ImageShader(
      a.normals,
      TileMode.clamp,
      TileMode.clamp,
      Matrix4.diagonal3Values(s, s, 1).storage,
      filterQuality: FilterQuality.low,
    );
    _combine();
  }

  /// Puts [rings] in [metal] on the hand (none by default).
  void setRings(List<HandRing> rings, RingMetal metal) {
    var same = metal == _metalKind && rings.length == _rings.length;
    for (var i = 0; i < rings.length && same; i++) {
      same =
          identical(rings[i].mesh, _rings[i].mesh) &&
          identical(rings[i].seat, _rings[i].seat);
    }
    if (same) return;
    _rings = List.of(rings);
    _metalKind = metal;
    if (_a != null) _combine();
  }

  /// Fills the hand and rings arrays. Spinning a stone on the hand
  /// rebuilds its ring's claws every frame with the same vertex and
  /// triangle counts, so the arrays are kept and only what changed is
  /// written again: the rings always, the hand only when it or the bands'
  /// contact shadows on it change.
  void _combine() {
    final a = _a!, m = a.mesh;
    final nvH = m.vertexCount, ntH = m.triangleCount;
    var nv = nvH, nt = ntH;
    for (final r in _rings) {
      nv += r.mesh.vertexCount;
      nt += r.mesh.triangleCount;
    }
    var refill = _handDirty;
    _handDirty = false;
    if (refill || _rel.length != nv * 3) {
      refill = true;
      _rel = Float32List(nv * 3)..setAll(0, _handRel);
      _tex = Float32List(nv * 2)..setAll(0, _handTex);
      _colors = Int32List(nv);
      _normalColors = Int32List(nv)..fillRange(0, nvH, 0xFFFFFFFF);
      _screen = Float32List(nv * 2);
      _depth = Float32List(nv);
    }
    if (refill || _indices.length != nt * 3) {
      refill = true;
      _indices = Uint16List(nt * 3)..setAll(0, m.indices);
      _sorted = Uint16List(nt * 3);
      _keys = Int32List(nt);
      _faded = Uint8List(nt);
    }

    // Each band's soft contact shadow on the skin beside it.
    final shadows = [for (final r in _rings) (r.seat, r.bandWidth)];
    if (refill || !listEquals(shadows, _shadows)) {
      _shadows = shadows;
      _colors.setRange(0, nvH, _handColors);
      for (final r in _rings) {
        final s = r.seat, half = r.bandWidth / 2;
        final reach = s.radii.reduce(math.max) + 3;
        for (var i = 0; i < nvH; i++) {
          final p = HandVec(
            m.positions[i * 3],
            m.positions[i * 3 + 1],
            m.positions[i * 3 + 2],
          );
          final q = p - s.centre;
          final ax = q.dot(s.along).abs();
          if (ax > half + 3) continue;
          if ((q - s.along * q.dot(s.along)).length > reach) continue;
          var k = ((ax - half + 0.3) / 2.8).clamp(0.0, 1.0);
          k = 0.55 + 0.45 * k * k * (3 - 2 * k);
          final c = _colors[i];
          final g = ((c & 0xFF) * k).round();
          _colors[i] = (c & 0xFF000000) | g << 16 | g << 8 | g;
        }
      }
    }

    final pivot = HandModel.pivot;
    final pu = HandModel.patchU * a.skin.width;
    final pv = HandModel.patchV * a.skin.height;
    int enc(double n) => ((n * 0.5 + 0.5) * 255).round().clamp(0, 255);
    var v = nvH, t = ntH;
    for (final r in _rings) {
      final rm = r.mesh;
      for (var i = 0; i < rm.vertexCount; i++, v++) {
        _rel[v * 3] = rm.positions[i * 3] - pivot.x;
        _rel[v * 3 + 1] = rm.positions[i * 3 + 1] - pivot.y;
        _rel[v * 3 + 2] = rm.positions[i * 3 + 2] - pivot.z;
        _tex[v * 2] = pu;
        _tex[v * 2 + 1] = pv;
        _colors[v] = _metalMarker;
        _normalColors[v] =
            0xFF000000 |
            enc(rm.normals[i * 3]) << 16 |
            enc(rm.normals[i * 3 + 1]) << 8 |
            enc(rm.normals[i * 3 + 2]);
      }
      final base = v - rm.vertexCount;
      for (var i = 0; i < rm.indices.length; i++) {
        _indices[t * 3 + i] = base + rm.indices[i];
      }
      t += rm.triangleCount;
    }

    if (refill) {
      // Only the bare hand fades out up the forearm; shadows keep alpha
      // and metal is opaque, so this holds until the arrays change.
      for (var i = 0; i < nt; i++) {
        var all = true;
        for (var k = 0; k < 3 && all; k++) {
          all = (_colors[_indices[i * 3 + k]] >>> 24) == 0;
        }
        _faded[i] = all ? 1 : 0;
      }
    }
    _version++;
  }

  void dispose() {
    _image?.dispose();
    _image = null;
    _gbuffer?.dispose();
    _gbuffer = null;
    for (final f in _fronts.values) {
      f.dispose();
    }
    _fronts.clear();
    _shader?.dispose();
    _shader = null;
  }

  /// Screen rectangle the hand can cover under [cam].
  static Rect bounds(HandCamera cam) {
    final b = HandModel.bounds;
    final c = cam.project(b.c);
    final k = cam.distance / (cam.distance - c.depth - b.r);
    final r = b.r * cam.pxPerMm * k;
    return Rect.fromCircle(center: c.at, radius: r);
  }

  Float64List _keyFor(Size size, HandCamera cam, double dpr, bool uv) {
    final key = _key
      ..[0] = cam.centre.dx
      ..[1] = cam.centre.dy
      ..[2] = cam.pxPerMm
      ..[3] = cam.distance
      ..[4] = dpr
      ..[5] = uv ? 1 : 0
      ..[6] = size.width
      ..[7] = size.height
      ..[8] = _version.toDouble();
    for (var k = 0; k < 9; k++) {
      key[9 + k] = cam.r[k];
    }
    return key;
  }

  /// Brings the hand image and the sorted triangles up to date for this
  /// view, drawn at [scale] pixels per logical pixel (at most [dpr]) and
  /// within [pixelBudget]; false when the hand is off screen.
  bool _update(
    Size size,
    HandCamera cam,
    double dpr,
    bool uv,
    double? scale,
    int? pixelBudget,
  ) {
    if (_a == null || _shader == null || size.isEmpty) return false;
    final area = bounds(cam).intersect(Offset.zero & size);
    if (area.isEmpty) return false;
    var s = math.min(scale ?? dpr, dpr);
    if (pixelBudget != null) {
      // The G-buffer is two images wide, and the shaded one a third.
      final need = area.width * area.height * 3;
      if (need * s * s > pixelBudget) {
        s = math.max(0.5, math.sqrt(pixelBudget / need));
      }
    }
    _full = s >= dpr - 0.05;
    final key = _keyFor(size, cam, s, uv);
    var same = _image != null;
    for (var k = 0; k < key.length && same; k++) {
      same = key[k] == _cachedKey[k];
    }
    if (same) return true;
    _image?.dispose();
    _image = null;
    _scale = dpr = s;
    // Whole device pixels, so the copy lands one to one.
    final x0 = (area.left * dpr).floor(), y0 = (area.top * dpr).floor();
    final x1 = (area.right * dpr).ceil(), y1 = (area.bottom * dpr).ceil();
    final w = x1 - x0, h = y1 - y0;
    if (w <= 0 || h <= 0) return false;
    _rect = Rect.fromLTRB(x0 / dpr, y0 / dpr, x1 / dpr, y1 / dpr);
    _drawn = _project(cam, _rect, dpr);
    if (_drawn == 0) return false;
    final shaded = _shadeRegion(
      Uint16List.sublistView(_sorted, 0, _drawn * 3),
      0,
      0,
      w,
      h,
      cam,
      uv,
    );
    _gbuffer?.dispose();
    _gbuffer = shaded.gbuffer;
    _image = shaded.image;
    _cachedKey.setAll(0, key);
    return true;
  }

  /// Draws the hand at [renderScale] pixels per logical pixel (the
  /// device's own by default; lower while it moves on a device that
  /// cannot keep up), within [pixelBudget] pixels of images.
  void paint(
    Canvas canvas,
    Size size,
    HandCamera cam, {
    required double devicePixelRatio,
    double? renderScale,
    int? pixelBudget,
    bool ultraviolet = false,
  }) {
    if (!_update(
      size,
      cam,
      devicePixelRatio,
      ultraviolet,
      renderScale,
      pixelBudget,
    )) {
      return;
    }
    final image = _image!;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      _rect,
      _full ? _copy : _blit,
    );
  }

  /// Over a stone at [centre] (hand space) of [radius] mm drawn within
  /// [clip], draws the parts of the hand and rings that stand in front of
  /// it: skin wholly nearer than the stone's front, and metal with the
  /// stone behind it on its line of sight, never in front (judged against
  /// [hull]; without a hull, metal nearer than the centre). [slot] keeps one cached layer
  /// per stone. [renderScale] and [pixelBudget] as for [paint], and the
  /// same, or the hand is drawn again.
  void paintFront(
    Canvas canvas,
    Size size,
    HandCamera cam, {
    required double devicePixelRatio,
    double? renderScale,
    int? pixelBudget,
    bool ultraviolet = false,
    required int slot,
    required HandVec centre,
    required double radius,
    required Rect clip,
    StoneHull? hull,
  }) {
    if (!_update(
      size,
      cam,
      devicePixelRatio,
      ultraviolet,
      renderScale,
      pixelBudget,
    )) {
      return;
    }
    final dpr = _scale;
    final layer = _fronts[slot] ??= _FrontLayer();
    final key = layer.key
      ..setAll(0, _cachedKey)
      ..[18] = centre.x
      ..[19] = centre.y
      ..[20] = centre.z
      ..[21] = radius
      ..[22] = clip.left
      ..[23] = clip.top
      ..[24] = clip.right
      ..[25] = clip.bottom;
    var same = layer.valid && identical(layer.hull, hull);
    for (var k = 0; k < key.length && same; k++) {
      same = key[k] == layer.cachedKey[k];
    }
    if (!same) {
      layer.clear();
      layer.valid = true;
      layer.hull = hull;
      layer.cachedKey.setAll(0, key);
      final area = clip.intersect(_rect);
      if (!area.isEmpty) {
        _renderFront(layer, cam, dpr, ultraviolet, centre, radius, area, hull);
      }
    }
    final image = layer.image;
    if (image == null) return;
    canvas.save();
    canvas.clipRect(clip);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      layer.rect,
      _full ? _copy : _blit,
    );
    canvas.restore();
  }

  void _renderFront(
    _FrontLayer layer,
    HandCamera cam,
    double dpr,
    bool uv,
    HandVec centre,
    double radius,
    Rect area,
    StoneHull? hull,
  ) {
    final c = cam.toCamera(centre);
    final eye = cam.eye, pivot = HandModel.pivot, rel = _rel;
    // Per vertex, once asked (bit 0): the stone between it and the eye
    // (bit 1), the stone behind it on the same line of sight (bit 2).
    final sight = Uint8List(hull == null ? 0 : _depth.length);
    int sightOf(int v) {
      if (sight[v] == 0) {
        final p = HandVec(
          rel[v * 3] + pivot.x,
          rel[v * 3 + 1] + pivot.y,
          rel[v * 3 + 2] + pivot.z,
        );
        final away = p + (p - eye).unit * 100;
        sight[v] =
            1 |
            (hull!.blocks(p, eye) ? 2 : 0) |
            // A little wider, so a claw along the girdle counts as over it.
            (hull.blocks(p, away, inset: -0.3) ? 4 : 0);
      }
      return sight[v];
    }

    final zs = c.z;
    final ox = _rect.left * dpr, oy = _rect.top * dpr;
    final x0 = (area.left * dpr - ox).floor(),
        y0 = (area.top * dpr - oy).floor();
    final x1 = (area.right * dpr - ox).ceil(),
        y1 = (area.bottom * dpr - oy).ceil();
    final w = x1 - x0, h = y1 - y0;
    if (w <= 0 || h <= 0) return;
    final screen = _screen, depth = _depth, sorted = _sorted;
    final picked = Uint16List(_drawn * 3);
    var n = 0;
    for (var t = 0; t < _drawn; t++) {
      final a = sorted[t * 3], b = sorted[t * 3 + 1], d = sorted[t * 3 + 2];
      final za = depth[a], zb = depth[b], zc = depth[d];
      final metal = _isMetal(a);
      final bool front;
      if (!metal) {
        front = math.min(za, math.min(zb, zc)) > zs + radius;
      } else if (hull != null) {
        // Only metal with the stone behind it: anything else (the far
        // half of the band behind the finger, claws beside the stone) the
        // hand image already shows sorted against the skin. And no corner
        // hidden: a triangle behind the stone that pokes out past its
        // outline must not paint over it.
        final sa = sightOf(a), sb = sightOf(b), sd = sightOf(d);
        front = (sa | sb | sd) & 2 == 0 && (sa | sb | sd) & 4 != 0;
      } else {
        front = (za + zb + zc) / 3 > zs;
      }
      if (!front) continue;
      final ax = screen[a * 2], bx = screen[b * 2], cx = screen[d * 2];
      final ay = screen[a * 2 + 1], by = screen[b * 2 + 1];
      final cy = screen[d * 2 + 1];
      if (math.max(ax, math.max(bx, cx)) < x0 ||
          math.min(ax, math.min(bx, cx)) > x1 ||
          math.max(ay, math.max(by, cy)) < y0 ||
          math.min(ay, math.min(by, cy)) > y1) {
        continue;
      }
      picked[n * 3] = a;
      picked[n * 3 + 1] = b;
      picked[n * 3 + 2] = d;
      n++;
    }
    if (n == 0) return;
    final shaded = _shadeRegion(
      Uint16List.sublistView(picked, 0, n * 3),
      x0,
      y0,
      w,
      h,
      cam,
      uv,
    );
    layer
      ..gbuffer = shaded.gbuffer
      ..image = shaded.image
      ..rect = Rect.fromLTWH(
        (ox + x0) / dpr,
        (oy + y0) / dpr,
        w / dpr,
        h / dpr,
      );
  }

  /// Ring vertices follow the hand's in the combined arrays.
  bool _isMetal(int vertex) => vertex >= _a!.mesh.vertexCount;

  /// Rasterises [indices] (device px of the hand's rect, offset by [x0],
  /// [y0]) into a [w]×[h] G-buffer and shades it.
  ({ui.Image gbuffer, ui.Image image}) _shadeRegion(
    Uint16List indices,
    int x0,
    int y0,
    int w,
    int h,
    HandCamera cam,
    bool uv,
  ) {
    final sh = _shader!;
    final skin = ui.Vertices.raw(
      VertexMode.triangles,
      _screen,
      textureCoordinates: _tex,
      colors: _colors,
      indices: indices,
    );
    final normals = ui.Vertices.raw(
      VertexMode.triangles,
      _screen,
      textureCoordinates: _tex,
      colors: _normalColors,
      indices: indices,
    );
    var recorder = ui.PictureRecorder();
    final half = Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble());
    // Each half clipped, so triangles past the edge never spill into the
    // other half.
    Canvas(recorder)
      ..save()
      ..clipRect(half)
      ..translate(-x0.toDouble(), -y0.toDouble())
      ..drawVertices(skin, BlendMode.modulate, _skinPaint)
      ..restore()
      ..translate((w + _gap).toDouble(), 0)
      ..clipRect(half)
      ..translate(-x0.toDouble(), -y0.toDouble())
      ..drawVertices(normals, BlendMode.modulate, _normalPaint);
    var picture = recorder.endRecording();
    final gbuffer = picture.toImageSync(w * 2 + _gap, h);
    picture.dispose();
    skin.dispose();
    normals.dispose();

    sh
      ..setFloat(0, w.toDouble())
      ..setFloat(1, h.toDouble())
      ..setFloat(2, _gap.toDouble())
      ..setFloat(3, 0.9);
    for (var row = 0; row < 3; row++) {
      for (var k = 0; k < 3; k++) {
        sh.setFloat(4 + row * 4 + k, cam.r[row * 3 + k]);
      }
      sh.setFloat(4 + row * 4 + 3, 0);
    }
    sh
      ..setFloat(16, uv ? 1 : 0)
      ..setFloat(17, _metalKind.r)
      ..setFloat(18, _metalKind.g)
      ..setFloat(19, _metalKind.b)
      ..setImageSampler(0, gbuffer);
    _shade.shader = sh;
    recorder = ui.PictureRecorder();
    Canvas(
      recorder,
    ).drawRect(Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), _shade);
    picture = recorder.endRecording();
    final image = picture.toImageSync(w, h);
    picture.dispose();
    return (gbuffer: gbuffer, image: image);
  }

  /// Projects every vertex into device px of [rect] and fills [_sorted]
  /// with the triangles that face the camera, farthest first. Returns how
  /// many.
  int _project(HandCamera cam, Rect rect, double dpr) {
    final nv = _rel.length ~/ 3, nt = _indices.length ~/ 3;
    final ntHand = _a!.mesh.triangleCount;
    final r = cam.r;
    final r0 = r[0], r1 = r[1], r2 = r[2], r3 = r[3], r4 = r[4], r5 = r[5];
    final r6 = r[6], r7 = r[7], r8 = r[8];
    final dist = cam.distance, ppm = cam.pxPerMm * dpr;
    final ox = (cam.centre.dx - rect.left) * dpr;
    final oy = (cam.centre.dy - rect.top) * dpr;
    final rel = _rel, screen = _screen, depth = _depth;
    var zMin = double.infinity, zMax = -double.infinity;
    for (var i = 0; i < nv; i++) {
      final x = rel[i * 3], y = rel[i * 3 + 1], z = rel[i * 3 + 2];
      final cx = r0 * x + r1 * y + r2 * z;
      final cy = r3 * x + r4 * y + r5 * z;
      final cz = r6 * x + r7 * y + r8 * z;
      final k = ppm * dist / (dist - cz);
      screen[i * 2] = ox + cx * k;
      screen[i * 2 + 1] = oy - cy * k;
      depth[i] = cz;
      if (cz < zMin) zMin = cz;
      if (cz > zMax) zMax = cz;
    }
    // Facing triangles keyed by depth: a counting sort, back to front.
    final idx = _indices, keys = _keys, counts = _counts;
    counts.fillRange(0, _buckets + 1, 0);
    final scale = (_buckets - 1) / math.max(3 * (zMax - zMin), 1e-6);
    final base = 3 * zMin;
    var n = 0;
    for (var t = 0; t < nt; t++) {
      if (_faded[t] == 1) {
        keys[t] = -1;
        continue;
      }
      final a = idx[t * 3], b = idx[t * 3 + 1], c = idx[t * 3 + 2];
      final ax = screen[a * 2], ay = screen[a * 2 + 1];
      final area =
          (screen[b * 2] - ax) * (screen[c * 2 + 1] - ay) -
          (screen[c * 2] - ax) * (screen[b * 2 + 1] - ay);
      if (area >= 0) {
        keys[t] = -1;
        continue;
      }
      var z = depth[a] + depth[b] + depth[c] - base;
      if (t >= ntHand) z += 3 * _ringBias;
      final k = (z * scale).toInt().clamp(0, _buckets - 1);
      keys[t] = k;
      counts[k + 1]++;
      n++;
    }
    for (var k = 1; k <= _buckets; k++) {
      counts[k] += counts[k - 1];
    }
    final out = _sorted;
    for (var t = 0; t < nt; t++) {
      final k = keys[t];
      if (k < 0) continue;
      final o = counts[k]++ * 3;
      out[o] = idx[t * 3];
      out[o + 1] = idx[t * 3 + 1];
      out[o + 2] = idx[t * 3 + 2];
    }
    return n;
  }
}

class _FrontLayer {
  final Float64List key = Float64List(26), cachedKey = Float64List(26);
  bool valid = false;
  StoneHull? hull;
  ui.Image? image, gbuffer;
  Rect rect = Rect.zero;

  void clear() {
    image?.dispose();
    image = null;
    gbuffer?.dispose();
    gbuffer = null;
  }

  void dispose() => clear();
}
