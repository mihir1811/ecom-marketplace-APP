import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'sim_inclusions.dart';
import 'sim_renderer.dart';

/// Where an inclusion landed on screen in the last frame, for its label.
class SimInclusionAnchor {
  SimInclusionAnchor(this.inclusion, this.at, this.radius, this.depth);

  final SimInclusion inclusion;

  /// Its centre, logical pixels.
  final Offset at;

  /// Its bounding radius on screen, logical pixels.
  final double radius;

  /// World depth toward the viewer: positive on the near half.
  final double depth;
}

/// Draws clarity characteristics as solid, lit objects for the line
/// drawing (`shaders/inclusion_vector.frag`), in the same perspective as
/// [SimRenderer] and [SimWireRenderer]. One draw covers every inclusion;
/// they are sorted far to near each frame so the nearer ones lie over.
class SimInclusionShader {
  static Future<ui.FragmentProgram>? _program;

  static Future<ui.FragmentProgram> loadProgram() => _program ??=
      ui.FragmentProgram.fromAsset('shaders/inclusion_vector.frag');

  static Future<void>? _warmUp;

  /// Loads the program and draws it once offscreen so the GPU driver
  /// compiles it before the first stone that needs it. Never throws.
  static Future<void> warmUp() => _warmUp ??= _runWarmUp();

  static Future<void> _runWarmUp() async {
    try {
      final sh = (await loadProgram()).fragmentShader();
      sh
        ..setFloat(2, 100)
        ..setFloat(3, SimRenderer.eyeDistance)
        ..setFloat(4, 1)
        ..setFloat(9, 1)
        ..setFloat(14, 1)
        ..setFloat(18, 1)
        ..setFloat(19, 0.01);
      final recorder = ui.PictureRecorder();
      Canvas(
        recorder,
      ).drawRect(const Rect.fromLTWH(0, 0, 4, 4), Paint()..shader = sh);
      final picture = recorder.endRecording();
      final image = await picture.toImage(4, 4);
      picture.dispose();
      image.dispose();
      sh.dispose();
    } catch (_) {
      // Inclusions are left out of the line drawing; nothing to warm.
    }
  }

  ui.FragmentShader? shader;

  /// Anchors from the last [paint], in the order inclusions were given.
  final List<SimInclusionAnchor> anchors = [];

  final Paint _paint = Paint();
  final List<int> _order = [];
  final List<double> _depth = [];

  static const _d0 = SimRenderer.eyeDistance;
  static const _uIncl = 20;

  /// Paints [inclusions] for model → world rotation [rot] (row major, as
  /// [SimView.rotationInto] fills it), [scale] logical pixels per model
  /// unit at the stone's centre, centred at [centre]. Records [anchors]
  /// even without a shader, so labels still find their inclusions.
  void paint(
    Canvas canvas,
    List<SimInclusion> inclusions, {
    required Float64List rot,
    required double scale,
    required Offset centre,
    double opacity = 1,
    double time = 0,
  }) {
    anchors.clear();
    if (inclusions.isEmpty || scale <= 0) return;
    final n = math.min(inclusions.length, SimInclusions.maxVectorCount);
    _order.clear();
    _depth.clear();
    var left = double.infinity, top = double.infinity;
    var right = -double.infinity, bottom = -double.infinity;
    for (var i = 0; i < n; i++) {
      final c = inclusions[i];
      final wx = rot[0] * c.x + rot[1] * c.y + rot[2] * c.z;
      final wy = rot[3] * c.x + rot[4] * c.y + rot[5] * c.z;
      final wz = rot[6] * c.x + rot[7] * c.y + rot[8] * c.z;
      final k = scale * _d0 / (_d0 - wz);
      final at = Offset(centre.dx + wx * k, centre.dy - wy * k);
      var reach = c.size * c.kind.reach;
      if (c.kind == SimInclusionKind.laserDrillHole) reach += 0.02;
      final r = math.max(reach * k, 4.0) + 3;
      anchors.add(SimInclusionAnchor(c, at, c.size * k, wz));
      _order.add(i);
      _depth.add(wz);
      left = math.min(left, at.dx - r);
      top = math.min(top, at.dy - r);
      right = math.max(right, at.dx + r);
      bottom = math.max(bottom, at.dy + r);
    }
    final sh = shader;
    if (sh == null || opacity <= 0.001) return;
    // Far first: the shader lays each nearer one over those behind.
    _order.sort((a, b) => _depth[a].compareTo(_depth[b]));

    sh
      ..setFloat(0, centre.dx)
      ..setFloat(1, centre.dy)
      ..setFloat(2, scale)
      ..setFloat(3, _d0);
    for (var row = 0; row < 3; row++) {
      for (var k = 0; k < 3; k++) {
        sh.setFloat(4 + row * 4 + k, rot[row * 3 + k]);
      }
      sh.setFloat(4 + row * 4 + 3, 0);
    }
    sh
      ..setFloat(16, n.toDouble())
      ..setFloat(17, time)
      ..setFloat(18, opacity.clamp(0.0, 1.0))
      ..setFloat(19, 1 / scale);
    for (var j = 0; j < n; j++) {
      final c = inclusions[_order[j]];
      final o = _uIncl + j * 12;
      sh
        ..setFloat(o, c.x)
        ..setFloat(o + 1, c.y)
        ..setFloat(o + 2, c.z)
        ..setFloat(o + 3, c.size)
        ..setFloat(o + 4, c.ax)
        ..setFloat(o + 5, c.ay)
        ..setFloat(o + 6, c.az)
        ..setFloat(o + 7, c.kind.vectorCode + c.seed.clamp(0.0, 0.999))
        ..setFloat(o + 8, c.sx)
        ..setFloat(o + 9, c.sy)
        ..setFloat(o + 10, c.sz)
        ..setFloat(o + 11, c.sd);
    }
    canvas.drawRect(
      Rect.fromLTRB(left, top, right, bottom),
      _paint..shader = sh,
    );
  }

  void dispose() {
    shader?.dispose();
    shader = null;
  }
}
