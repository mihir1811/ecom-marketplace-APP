import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'stardust_field.dart';

/// Pre-rendered star sprites shared by every frame.
class StardustSprites {
  const StardustSprites({required this.dot, required this.flare});

  /// Soft round glow; drawn for every star.
  final ui.Image dot;

  /// Four-point diffraction flare; drawn on the brightest stars only.
  final ui.Image flare;

  static const dotSize = 64.0;
  static const flareSize = 128.0;

  static Future<StardustSprites>? _cache;

  static Future<StardustSprites> load() => _cache ??= _build();

  static Future<StardustSprites> _build() async {
    final dotRecorder = ui.PictureRecorder();
    const c = Offset(dotSize / 2, dotSize / 2);
    Canvas(dotRecorder).drawCircle(
      c,
      dotSize / 2,
      Paint()
        ..shader = ui.Gradient.radial(
          c,
          dotSize / 2,
          const [
            Color(0xFFFFFFFF),
            Color(0xCCFFFFFF),
            Color(0x26FFFFFF),
            Color(0x00FFFFFF),
          ],
          const [0, 0.14, 0.4, 1],
        ),
    );
    final dot = await dotRecorder.endRecording().toImage(
      dotSize.toInt(),
      dotSize.toInt(),
    );

    final flareRecorder = ui.PictureRecorder();
    final canvas = Canvas(flareRecorder);
    const f = Offset(flareSize / 2, flareSize / 2);
    for (final horizontal in const [true, false]) {
      final a = horizontal ? Offset(0, f.dy) : Offset(f.dx, 0);
      final b = horizontal ? Offset(flareSize, f.dy) : Offset(f.dx, flareSize);
      canvas.drawLine(
        a,
        b,
        Paint()
          ..strokeWidth = 1.6
          ..shader = ui.Gradient.linear(
            a,
            b,
            const [Color(0x00FFFFFF), Color(0xFFFFFFFF), Color(0x00FFFFFF)],
            const [0, 0.5, 1],
          ),
      );
    }
    final flare = await flareRecorder.endRecording().toImage(
      flareSize.toInt(),
      flareSize.toInt(),
    );
    return StardustSprites(dot: dot, flare: flare);
  }
}

/// Rasterises [char] and returns its stroke pixels as a normalised cloud.
Future<GlyphCloud> sampleGlyph(String char) async {
  final style = GoogleFonts.cormorantGaramond(
    fontSize: 300,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1,
  );
  try {
    await GoogleFonts.pendingFonts([style]);
  } catch (_) {
    // Offline or fonts unavailable: the fallback serif still reads as a G.
  }
  final painter = TextPainter(
    text: TextSpan(text: char, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  final w = painter.width.ceil() + 8;
  final h = painter.height.ceil() + 8;
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), const Offset(4, 4));
  final image = await recorder.endRecording().toImage(w, h);
  final data = await image.toByteData();
  image.dispose();
  painter.dispose();
  if (data == null) return const GlyphCloud(fill: [], edge: []);

  bool solid(int x, int y) =>
      x >= 0 &&
      y >= 0 &&
      x < w &&
      y < h &&
      data.getUint8((y * w + x) * 4 + 3) > 140;

  var minX = w, minY = h, maxX = 0, maxY = 0;
  final fill = <Offset>[];
  final edge = <Offset>[];
  const stride = 2;
  for (var y = 0; y < h; y += stride) {
    for (var x = 0; x < w; x += stride) {
      if (!solid(x, y)) continue;
      minX = math.min(minX, x);
      maxX = math.max(maxX, x);
      minY = math.min(minY, y);
      maxY = math.max(maxY, y);
      final p = Offset(x.toDouble(), y.toDouble());
      fill.add(p);
      if (!solid(x - 3, y) ||
          !solid(x + 3, y) ||
          !solid(x, y - 3) ||
          !solid(x, y + 3)) {
        edge.add(p);
      }
    }
  }
  if (fill.isEmpty) return const GlyphCloud(fill: [], edge: []);
  final cx = (minX + maxX) / 2, cy = (minY + maxY) / 2;
  final half = math.max(maxX - minX, maxY - minY) / 2;
  Offset norm(Offset p) => Offset((p.dx - cx) / half, (p.dy - cy) / half);
  return GlyphCloud(
    fill: fill.map(norm).toList(growable: false),
    edge: edge.map(norm).toList(growable: false),
  );
}

/// Paints the stardust in two atlas draw calls with additive blending, so
/// dense formations bloom naturally.
class StardustPainter extends CustomPainter {
  StardustPainter({
    required this.field,
    required this.sprites,
    required this.progress,
    required this.center,
    required this.scale,
  }) : _rst = Float32List(field.count * 4),
       _rects = Float32List(field.count * 4),
       _colors = Int32List(field.count),
       super(repaint: Listenable.merge([field, progress])) {
    for (var i = 0; i < field.count; i++) {
      _rects[i * 4 + 2] = StardustSprites.dotSize;
      _rects[i * 4 + 3] = StardustSprites.dotSize;
    }
    for (var i = 0; i < field.count; i++) {
      if (field.size[i] > 3.2) _bright.add(i);
    }
    _flareRst = Float32List(_bright.length * 4);
    _flareRects = Float32List(_bright.length * 4);
    _flareColors = Int32List(_bright.length);
    for (var j = 0; j < _bright.length; j++) {
      _flareRects[j * 4 + 2] = StardustSprites.flareSize;
      _flareRects[j * 4 + 3] = StardustSprites.flareSize;
    }
  }

  final StardustField field;
  final StardustSprites sprites;
  final ValueListenable<double> progress;
  final Offset center;
  final double scale;

  final Float32List _rst;
  final Float32List _rects;
  final Int32List _colors;
  final List<int> _bright = [];
  late final Float32List _flareRst;
  late final Float32List _flareRects;
  late final Int32List _flareColors;

  static final _additive = Paint()
    ..blendMode = BlendMode.plus
    ..filterQuality = FilterQuality.low;

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress.value.clamp(0.0, 1.0);
    final fade = (1 - p * 1.35).clamp(0.0, 1.0);
    if (fade == 0) return;

    canvas.save();
    // Scroll-away: the cosmos zooms toward the viewer as it fades.
    final zoom = 1 + p * 0.45;
    canvas.translate(center.dx, center.dy - p * size.height * 0.12);
    canvas.scale(zoom);
    canvas.translate(-center.dx, -center.dy);

    final glow = field.coreGlow;
    final t = field.time;
    final pulse = 0.88 + 0.12 * math.sin(t * 0.9);
    canvas.drawCircle(
      center,
      scale * 1.1,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = ui.Gradient.radial(
          center,
          scale * 1.1,
          [
            Color.fromRGBO(255, 214, 160, 0.16 * glow * pulse * fade),
            Color.fromRGBO(255, 190, 120, 0.05 * glow * fade),
            const Color.fromRGBO(255, 190, 120, 0),
          ],
          const [0, 0.35, 1],
        ),
    );

    const half = StardustSprites.dotSize / 2;
    final px = field.px, py = field.py;
    for (var i = 0; i < field.count; i++) {
      final s = field.size[i] * 2.6 / StardustSprites.dotSize;
      _rst[i * 4] = s;
      _rst[i * 4 + 1] = 0;
      _rst[i * 4 + 2] = px[i] - s * half;
      _rst[i * 4 + 3] = py[i] - s * half;
      final tw =
          0.6 +
          0.4 * math.sin(t * field.twinkleSpeed[i] + field.twinklePhase[i]);
      final a = (255 * tw * fade).round().clamp(0, 255);
      _colors[i] = ((a << 24) | field.rgb[i]).toSigned(32);
    }
    canvas.drawRawAtlas(
      sprites.dot,
      _rst,
      _rects,
      _colors,
      BlendMode.modulate,
      null,
      _additive,
    );

    const fh = StardustSprites.flareSize / 2;
    for (var j = 0; j < _bright.length; j++) {
      final i = _bright[j];
      final tw =
          0.5 +
          0.5 *
              math.sin(t * field.twinkleSpeed[i] * 0.6 + field.twinklePhase[i]);
      final s =
          field.size[i] * 5.5 * (0.6 + tw * 0.4) / StardustSprites.flareSize;
      _flareRst[j * 4] = s;
      _flareRst[j * 4 + 1] = 0;
      _flareRst[j * 4 + 2] = px[i] - s * fh;
      _flareRst[j * 4 + 3] = py[i] - s * fh;
      final a = (200 * tw * fade).round().clamp(0, 255);
      _flareColors[j] = ((a << 24) | field.rgb[i]).toSigned(32);
    }
    if (_bright.isNotEmpty) {
      canvas.drawRawAtlas(
        sprites.flare,
        _flareRst,
        _flareRects,
        _flareColors,
        BlendMode.modulate,
        null,
        _additive,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(StardustPainter old) =>
      old.field != field ||
      old.sprites != sprites ||
      old.center != center ||
      old.scale != scale;
}
