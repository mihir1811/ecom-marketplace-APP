import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gemstone/core/theme/app_fonts.dart';

import 'stardust_field.dart';

/// Pre-rendered star sprites shared by every frame.
class StardustSprites {
  const StardustSprites({required this.dot});

  /// Soft round glow; drawn for every star.
  final ui.Image dot;

  static const dotSize = 64.0;

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
    return StardustSprites(dot: dot);
  }
}

/// Rasterises [char] and returns its stroke pixels as a normalised cloud.
Future<GlyphCloud> sampleGlyph(String char) async {
  final style = AppFonts.display(
    fontSize: 300,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1,
  );
  try {
    await GoogleFonts.pendingFonts([style]);
  } catch (_) {
    // Offline or fonts unavailable: the fallback font still reads as a G.
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

/// Paints the stardust in one atlas draw call with additive blending, so
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
  }

  final StardustField field;
  final StardustSprites sprites;
  final ValueListenable<double> progress;
  final Offset center;
  final double scale;

  final Float32List _rst;
  final Float32List _rects;
  final Int32List _colors;

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
    final px = field.sx, py = field.sy, depth = field.depth;
    for (var i = 0; i < field.count; i++) {
      // Perspective: nearer stars are larger and brighter.
      final f = depth[i];
      final near = ((f - 0.78) / 0.55).clamp(0.0, 1.0);
      final s = field.size[i] * 2.6 * f * f / StardustSprites.dotSize;
      _rst[i * 4] = s;
      _rst[i * 4 + 1] = 0;
      _rst[i * 4 + 2] = px[i] - s * half;
      _rst[i * 4 + 3] = py[i] - s * half;
      final tw =
          0.6 +
          0.4 * math.sin(t * field.twinkleSpeed[i] + field.twinklePhase[i]);
      final a = (255 * tw * fade * (0.35 + 0.65 * near)).round().clamp(0, 255);
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
    canvas.restore();
  }

  @override
  bool shouldRepaint(StardustPainter old) =>
      old.field != field ||
      old.sprites != sprites ||
      old.center != center ||
      old.scale != scale;
}
