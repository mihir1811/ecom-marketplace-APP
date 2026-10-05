import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Dial designs drawn after each featured house's flagship model.
enum WatchDialStyle {
  submariner,
  nautilus,
  royalOak,
  santos,
  speedmaster,
  bigBang,
  rm011,
  monaco,
  overseas,
  navitimer,
  snowflake,
}

/// Flagship model shown for a featured brand.
class WatchFlagship {
  const WatchFlagship(this.model, this.style, this.glow);

  final String model;
  final WatchDialStyle style;

  /// Tint for the stage light behind the dial.
  final Color glow;

  static WatchFlagship? of(String brand) => switch (brand) {
    'Rolex' => const WatchFlagship(
      'Submariner',
      WatchDialStyle.submariner,
      Color(0xFF2E6B4F),
    ),
    'Patek Philippe' => const WatchFlagship(
      'Nautilus',
      WatchDialStyle.nautilus,
      Color(0xFF2B4F86),
    ),
    'Audemars Piguet' => const WatchFlagship(
      'Royal Oak',
      WatchDialStyle.royalOak,
      Color(0xFF2B4F86),
    ),
    'Cartier' => const WatchFlagship(
      'Santos de Cartier',
      WatchDialStyle.santos,
      Color(0xFF9C7A45),
    ),
    'Omega' => const WatchFlagship(
      'Speedmaster Professional',
      WatchDialStyle.speedmaster,
      Color(0xFF5A6068),
    ),
    'Hublot' => const WatchFlagship(
      'Big Bang Unico',
      WatchDialStyle.bigBang,
      Color(0xFF8A2A27),
    ),
    'Richard Mille' => const WatchFlagship(
      'RM 011',
      WatchDialStyle.rm011,
      Color(0xFF8A2A27),
    ),
    'TAG Heuer' => const WatchFlagship(
      'Monaco',
      WatchDialStyle.monaco,
      Color(0xFF1F4E9E),
    ),
    'Vacheron Constantin' => const WatchFlagship(
      'Overseas',
      WatchDialStyle.overseas,
      Color(0xFF24508F),
    ),
    'Breitling' => const WatchFlagship(
      'Navitimer',
      WatchDialStyle.navitimer,
      Color(0xFF5A6068),
    ),
    'Grand Seiko' => const WatchFlagship(
      'Snowflake',
      WatchDialStyle.snowflake,
      Color(0xFF8FA6C2),
    ),
    _ => null,
  };
}

/// A watch head (case, bezel and dial — no bracelet) on a transparent
/// background. The face is static and cached; the hands show the live
/// time and repaint from [clock].
class WatchDial extends StatelessWidget {
  const WatchDial({
    required this.style,
    required this.clock,
    super.key,
    this.size = 100,
  });

  final WatchDialStyle style;
  final Listenable clock;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: CustomPaint(
              painter: _FacePainter(style, DateTime.now().day),
            ),
          ),
          RepaintBoundary(
            child: CustomPaint(painter: _HandsPainter(style, clock)),
          ),
        ],
      ),
    );
  }
}

// ── Palette ────────────────────────────────────────────────────────────────

const _steel = [
  Color(0xFFF4F5F6),
  Color(0xFF8E949A),
  Color(0xFFE3E6E9),
  Color(0xFF666C72),
  Color(0xFFD5D9DC),
  Color(0xFF858B91),
  Color(0xFFF4F5F6),
];
const _gold = [
  Color(0xFFFBEBC0),
  Color(0xFFB4862F),
  Color(0xFFF1D58A),
  Color(0xFF8A611E),
  Color(0xFFE6C473),
  Color(0xFFA47829),
  Color(0xFFFBEBC0),
];
const _titanium = [
  Color(0xFF9A9EA4),
  Color(0xFF3A3D42),
  Color(0xFF7D8187),
  Color(0xFF26282C),
  Color(0xFF6F7379),
  Color(0xFF3A3D42),
  Color(0xFF9A9EA4),
];
const _lume = Color(0xFFF1EEDF);
const _whiteGold = Color(0xFFE9ECEF);
const _red = Color(0xFFD7322B);

Paint _metal(List<Color> colors, double r, {double turn = -0.6}) => Paint()
  ..shader = SweepGradient(
    colors: colors,
    transform: GradientRotation(turn),
  ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));

Offset _at(double angle, double radius) =>
    Offset(math.sin(angle) * radius, -math.cos(angle) * radius);

const _tau = math.pi * 2;

void _label(
  Canvas canvas,
  String text,
  Offset at,
  double size,
  Color color, {
  double angle = 0,
  FontWeight weight = FontWeight.w600,
  double spacing = 0,
  String? family,
}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontSize: size,
        color: color,
        fontWeight: weight,
        letterSpacing: spacing,
        fontFamily: family,
        height: 1,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  canvas
    ..save()
    ..translate(at.dx, at.dy)
    ..rotate(angle);
  tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
  canvas.restore();
  tp.dispose();
}

/// Rotated rounded bar from radius [from] to [to] at [angle].
void _bar(
  Canvas canvas,
  double angle,
  double from,
  double to,
  double width,
  Paint paint, {
  double radius = 0,
}) {
  canvas
    ..save()
    ..rotate(angle)
    ..drawRRect(
      RRect.fromLTRBR(
        -width / 2,
        -to,
        width / 2,
        -from,
        Radius.circular(radius),
      ),
      paint,
    )
    ..restore();
}

void _ticks(
  Canvas canvas,
  double r1,
  double r2,
  int count,
  Paint paint, {
  int skipEvery = 0,
}) {
  for (var i = 0; i < count; i++) {
    if (skipEvery > 0 && i % skipEvery == 0) continue;
    final a = i / count * _tau;
    canvas.drawLine(_at(a, r1), _at(a, r2), paint);
  }
}

void _dateWindow(
  Canvas canvas,
  Offset centre,
  double w,
  double h,
  int day,
  Color bg,
  Color fg, {
  Color? frame,
}) {
  final rect = Rect.fromCenter(center: centre, width: w, height: h);
  canvas.drawRRect(
    RRect.fromRectAndRadius(rect, Radius.circular(h * 0.12)),
    Paint()..color = bg,
  );
  if (frame != null) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(h * 0.12)),
      Paint()
        ..color = frame
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * 0.1,
    );
  }
  _label(canvas, '$day', centre, h * 0.72, fg, weight: FontWeight.w700);
}

/// Path through [points] with each corner rounded by [round].
Path _roundedPolygon(List<Offset> points, double round) {
  final path = Path();
  final n = points.length;
  for (var i = 0; i < n; i++) {
    final prev = points[(i - 1 + n) % n];
    final cur = points[i];
    final next = points[(i + 1) % n];
    final a = cur + (prev - cur) / (prev - cur).distance * round;
    final b = cur + (next - cur) / (next - cur).distance * round;
    if (i == 0) {
      path.moveTo(a.dx, a.dy);
    } else {
      path.lineTo(a.dx, a.dy);
    }
    path.quadraticBezierTo(cur.dx, cur.dy, b.dx, b.dy);
  }
  return path..close();
}

List<Offset> _octagonPoints(double w, double h, double cut) => [
  Offset(-w + cut, -h),
  Offset(w - cut, -h),
  Offset(w, -h + cut),
  Offset(w, h - cut),
  Offset(w - cut, h),
  Offset(-w + cut, h),
  Offset(-w, h - cut),
  Offset(-w, -h + cut),
];

/// Point on a square of half side [h] in direction [angle] from 12.
Offset _onSquare(double angle, double h) {
  final s = math.sin(angle), c = -math.cos(angle);
  final k = h / math.max(s.abs(), c.abs());
  return Offset(s * k, c * k);
}

void _screw(Canvas canvas, Offset at, double r, List<Color> metal, double a) {
  canvas.drawCircle(at, r, Paint()..color = const Color(0x55000000));
  canvas
    ..save()
    ..translate(at.dx, at.dy);
  canvas.drawCircle(Offset.zero, r * 0.92, _metal(metal, r, turn: a));
  canvas.drawLine(
    _at(a, r * 0.7),
    _at(a + math.pi, r * 0.7),
    Paint()
      ..color = const Color(0x99000000)
      ..strokeWidth = r * 0.28
      ..strokeCap = StrokeCap.round,
  );
  canvas.restore();
}

void _hexScrew(Canvas canvas, Offset at, double r, double a) {
  final pts = [for (var i = 0; i < 6; i++) at + _at(a + i * _tau / 6, r)];
  canvas.drawPath(
    Path()..addPolygon(pts, true),
    Paint()..color = const Color(0xFFCDD1D5),
  );
  canvas.drawLine(
    at + _at(a + 0.5, r * 0.75),
    at + _at(a + 0.5 + math.pi, r * 0.75),
    Paint()
      ..color = const Color(0xFF6E747A)
      ..strokeWidth = r * 0.3,
  );
}

// ── Faces ──────────────────────────────────────────────────────────────────

class _FacePainter extends CustomPainter {
  _FacePainter(this.style, this.day);

  final WatchDialStyle style;
  final int day;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    canvas.translate(size.width / 2, size.height / 2);
    // Soft contact shadow so the head sits on the stage.
    canvas.drawCircle(
      Offset(0, r * 0.06),
      r * 0.94,
      Paint()
        ..color = const Color(0x8C000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.08),
    );
    switch (style) {
      case WatchDialStyle.submariner:
        _submariner(canvas, r);
      case WatchDialStyle.nautilus:
        _nautilus(canvas, r);
      case WatchDialStyle.royalOak:
        _royalOak(canvas, r);
      case WatchDialStyle.santos:
        _santos(canvas, r);
      case WatchDialStyle.speedmaster:
        _speedmaster(canvas, r);
      case WatchDialStyle.bigBang:
        _bigBang(canvas, r);
      case WatchDialStyle.rm011:
        _rm011(canvas, r);
      case WatchDialStyle.monaco:
        _monaco(canvas, r);
      case WatchDialStyle.overseas:
        _overseas(canvas, r);
      case WatchDialStyle.navitimer:
        _navitimer(canvas, r);
      case WatchDialStyle.snowflake:
        _snowflake(canvas, r);
    }
    // Sapphire highlight across the whole head.
    canvas.drawCircle(
      Offset.zero,
      r * 0.78,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x22FFFFFF),
            Color(0x00FFFFFF),
            Color(0x00FFFFFF),
            Color(0x0DFFFFFF),
          ],
          stops: [0, 0.38, 0.7, 1],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: r)),
    );
  }

  void _roundCase(Canvas canvas, double r, List<Color> metal) {
    canvas.drawCircle(Offset.zero, r, _metal(metal, r));
    canvas.drawCircle(
      Offset.zero,
      r * 0.995,
      Paint()
        ..color = const Color(0x33000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.01,
    );
  }

  void _batonIndices(
    Canvas canvas,
    double r,
    double from,
    double to,
    double width, {
    Color metal = _whiteGold,
    Color fill = _lume,
    bool double12 = true,
    Set<int> skip = const {},
  }) {
    final frame = Paint()..color = metal;
    final lume = Paint()..color = fill;
    for (var i = 0; i < 12; i++) {
      if (skip.contains(i)) continue;
      final a = i / 12 * _tau;
      if (i == 0 && double12) {
        for (final o in [-0.055, 0.055]) {
          _bar(
            canvas,
            a + o,
            from * r,
            to * r,
            width * r,
            frame,
            radius: width * r * 0.3,
          );
          _bar(
            canvas,
            a + o,
            (from + 0.02) * r,
            (to - 0.02) * r,
            width * r * 0.45,
            lume,
          );
        }
        continue;
      }
      _bar(
        canvas,
        a,
        from * r,
        to * r,
        width * r,
        frame,
        radius: width * r * 0.3,
      );
      _bar(
        canvas,
        a,
        (from + 0.02) * r,
        (to - 0.02) * r,
        width * r * 0.45,
        lume,
      );
    }
  }

  void _submariner(Canvas canvas, double r) {
    _roundCase(canvas, r, _steel);
    // Coin-edge bezel grip.
    _ticks(
      canvas,
      r * 0.955,
      r * 0.995,
      120,
      Paint()
        ..color = const Color(0x55000000)
        ..strokeWidth = r * 0.012,
    );
    // Black ceramic bezel.
    canvas.drawCircle(
      Offset.zero,
      r * 0.94,
      Paint()..color = const Color(0xFF0D0E10),
    );
    canvas.drawCircle(
      Offset.zero,
      r * 0.94,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x00FFFFFF), Color(0x14FFFFFF)],
          stops: [0.85, 1],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: r)),
    );
    final platinum = Paint()
      ..color = const Color(0xFFD7DADF)
      ..strokeWidth = r * 0.014;
    for (var i = 1; i < 15; i++) {
      final a = i / 60 * _tau;
      canvas.drawLine(_at(a, r * 0.86), _at(a, r * 0.92), platinum);
    }
    for (var n = 10; n <= 50; n += 10) {
      final a = n / 60 * _tau;
      _label(
        canvas,
        '$n',
        _at(a, r * 0.865),
        r * 0.1,
        const Color(0xFFD7DADF),
        angle: a,
        weight: FontWeight.w700,
      );
    }
    for (final m in [15, 25, 35, 45, 55]) {
      _bar(canvas, m / 60 * _tau, r * 0.83, r * 0.91, r * 0.035, platinum);
    }
    // Triangle pip with lume dot.
    final tri = Path()
      ..moveTo(0, -r * 0.82)
      ..lineTo(-r * 0.07, -r * 0.925)
      ..lineTo(r * 0.07, -r * 0.925)
      ..close();
    canvas.drawPath(tri, Paint()..color = const Color(0xFFD7DADF));
    canvas.drawCircle(Offset(0, -r * 0.885), r * 0.022, Paint()..color = _lume);
    // Dial.
    canvas.drawCircle(
      Offset.zero,
      r * 0.78,
      Paint()..color = const Color(0xFF0A0B0D),
    );
    canvas.drawCircle(
      Offset.zero,
      r * 0.78,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.4),
          colors: [Color(0x1FFFFFFF), Color(0x00FFFFFF)],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: r * 0.78)),
    );
    _ticks(
      canvas,
      r * 0.74,
      r * 0.77,
      60,
      Paint()
        ..color = const Color(0xCCFFFFFF)
        ..strokeWidth = r * 0.008,
    );
    final frame = Paint()..color = _whiteGold;
    final lume = Paint()..color = _lume;
    for (var i = 1; i < 12; i++) {
      final a = i / 12 * _tau;
      if (i == 3) continue;
      if (i == 6 || i == 9) {
        _bar(canvas, a, r * 0.5, r * 0.7, r * 0.085, frame);
        _bar(canvas, a, r * 0.515, r * 0.685, r * 0.06, lume);
      } else {
        canvas.drawCircle(_at(a, r * 0.62), r * 0.068, frame);
        canvas.drawCircle(_at(a, r * 0.62), r * 0.055, lume);
      }
    }
    final top = Path()
      ..moveTo(0, -r * 0.5)
      ..lineTo(-r * 0.09, -r * 0.71)
      ..lineTo(r * 0.09, -r * 0.71)
      ..close();
    canvas.drawPath(top, frame);
    canvas.drawPath(
      top.shift(Offset.zero),
      lume..color = _lume.withValues(alpha: 0.95),
    );
    // Date with cyclops magnifier.
    _dateWindow(
      canvas,
      Offset(r * 0.6, 0),
      r * 0.22,
      r * 0.17,
      day,
      Colors.white,
      Colors.black,
      frame: _whiteGold,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(r * 0.6, 0),
          width: r * 0.3,
          height: r * 0.24,
        ),
        Radius.circular(r * 0.05),
      ),
      Paint()..color = const Color(0x22FFFFFF),
    );
  }

  void _nautilus(Canvas canvas, double r) {
    final outer = _roundedPolygon(
      _octagonPoints(r * 0.99, r * 0.9, r * 0.36),
      r * 0.22,
    );
    canvas.drawPath(outer, _metal(_steel, r));
    final inner = _roundedPolygon(
      _octagonPoints(r * 0.86, r * 0.79, r * 0.3),
      r * 0.2,
    );
    canvas.drawPath(inner, _metal(_steel, r, turn: 1.1));
    canvas.drawPath(
      inner,
      Paint()
        ..color = const Color(0x40000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.012,
    );
    final dial = Rect.fromCircle(center: Offset.zero, radius: r * 0.74);
    canvas.drawCircle(
      Offset.zero,
      r * 0.74,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.2, -0.3),
          colors: [Color(0xFF34598F), Color(0xFF16305A), Color(0xFF0B1A33)],
          stops: [0, 0.6, 1],
        ).createShader(dial),
    );
    // Horizontal embossed stripes.
    canvas
      ..save()
      ..clipPath(Path()..addOval(dial));
    final light = Paint()
      ..color = const Color(0x24FFFFFF)
      ..strokeWidth = r * 0.012;
    final dark = Paint()
      ..color = const Color(0x40000000)
      ..strokeWidth = r * 0.012;
    for (var y = -0.74; y <= 0.74; y += 0.052) {
      canvas
        ..drawLine(Offset(-r, y * r), Offset(r, y * r), dark)
        ..drawLine(
          Offset(-r, (y + 0.013) * r),
          Offset(r, (y + 0.013) * r),
          light,
        );
    }
    canvas.restore();
    _ticks(
      canvas,
      r * 0.7,
      r * 0.735,
      60,
      Paint()
        ..color = const Color(0x99FFFFFF)
        ..strokeWidth = r * 0.007,
    );
    _batonIndices(canvas, r, 0.5, 0.68, 0.06, skip: {3});
    _dateWindow(
      canvas,
      Offset(r * 0.58, 0),
      r * 0.16,
      r * 0.14,
      day,
      Colors.white,
      Colors.black,
    );
  }

  void _royalOak(Canvas canvas, double r) {
    _roundCase(canvas, r, _steel);
    final octa = [
      for (var i = 0; i < 8; i++) _at(_tau / 16 + i * _tau / 8, r * 0.93),
    ];
    canvas.drawPath(
      _roundedPolygon(octa, r * 0.06),
      _metal(_steel, r, turn: 0.9),
    );
    for (var i = 0; i < 8; i++) {
      _hexScrew(
        canvas,
        _at(_tau / 16 + i * _tau / 8, r * 0.82),
        r * 0.055,
        i * 0.4,
      );
    }
    final dial = Rect.fromCircle(center: Offset.zero, radius: r * 0.7);
    canvas.drawCircle(
      Offset.zero,
      r * 0.71,
      Paint()..color = const Color(0xFFB9BEC3),
    );
    canvas.drawCircle(
      Offset.zero,
      r * 0.69,
      Paint()..color = const Color(0xFF1C365C),
    );
    // Grande Tapisserie: raised squares with lit tops.
    canvas
      ..save()
      ..clipPath(Path()..addOval(dial));
    const cell = 0.072;
    final top = Paint()..color = const Color(0xFF2B4E7F);
    final hi = Paint()
      ..color = const Color(0x3DFFFFFF)
      ..strokeWidth = r * 0.006;
    for (var y = -0.72; y < 0.72; y += cell) {
      for (var x = -0.72; x < 0.72; x += cell) {
        final rect = Rect.fromLTWH(
          (x + 0.012) * r,
          (y + 0.012) * r,
          (cell - 0.024) * r,
          (cell - 0.024) * r,
        );
        canvas
          ..drawRect(rect, top)
          ..drawLine(rect.topLeft, rect.topRight, hi)
          ..drawLine(rect.topLeft, rect.bottomLeft, hi);
      }
    }
    canvas.restore();
    canvas.drawCircle(
      Offset.zero,
      r * 0.69,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x00000000), Color(0x59000000)],
          stops: [0.7, 1],
        ).createShader(dial),
    );
    _batonIndices(canvas, r, 0.46, 0.64, 0.065, skip: {3});
    _dateWindow(
      canvas,
      Offset(r * 0.54, 0),
      r * 0.16,
      r * 0.14,
      day,
      Colors.white,
      Colors.black,
      frame: _whiteGold,
    );
  }

  void _santos(Canvas canvas, double r) {
    final outer = RRect.fromRectAndRadius(
      Rect.fromCircle(center: Offset.zero, radius: r * 0.95),
      Radius.circular(r * 0.3),
    );
    canvas.drawRRect(outer, _metal(_gold, r));
    for (final p in [
      for (var i = 0; i < 8; i++) _onSquare(_tau / 8 * i + _tau / 16, r * 0.82),
    ]) {
      _screw(canvas, p, r * 0.07, _gold, p.direction);
    }
    final dialRect = RRect.fromRectAndRadius(
      Rect.fromCircle(center: Offset.zero, radius: r * 0.7),
      Radius.circular(r * 0.16),
    );
    canvas.drawRRect(
      dialRect.inflate(r * 0.025),
      Paint()..color = const Color(0xFF9E7A33),
    );
    canvas.drawRRect(
      dialRect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.2, -0.3),
          colors: [Color(0xFFF8F6F0), Color(0xFFE4DFD3)],
        ).createShader(dialRect.outerRect),
    );
    // Railway track.
    final ink = Paint()
      ..color = const Color(0xFF1C1C1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.008;
    canvas.drawRRect(dialRect.deflate(r * 0.05), ink);
    canvas.drawRRect(dialRect.deflate(r * 0.1), ink);
    for (var i = 0; i < 60; i++) {
      final a = i / 60 * _tau;
      canvas.drawLine(
        _onSquare(a, r * 0.6),
        _onSquare(a, r * 0.65),
        ink..strokeWidth = r * (i % 5 == 0 ? 0.012 : 0.006),
      );
    }
    const numerals = [
      'XII', 'I', 'II', 'III', 'IIII', 'V', //
      'VI', 'VII', 'VIII', 'IX', 'X', 'XI',
    ];
    for (var i = 0; i < 12; i++) {
      final a = i / 12 * _tau;
      _label(
        canvas,
        numerals[i],
        _onSquare(a, r * 0.47),
        r * 0.1,
        const Color(0xFF1C1C1C),
        angle: a,
        weight: FontWeight.w500,
        family: 'serif',
      );
    }
  }

  void _subdial(
    Canvas canvas,
    Offset at,
    double radius,
    Color face,
    Color ink, {
    int ticks = 30,
  }) {
    canvas.drawCircle(at, radius, Paint()..color = face);
    canvas.drawCircle(
      at,
      radius,
      Paint()
        ..color = ink.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.05,
    );
    canvas
      ..save()
      ..translate(at.dx, at.dy);
    _ticks(
      canvas,
      radius * 0.78,
      radius * 0.95,
      ticks,
      Paint()
        ..color = ink.withValues(alpha: 0.8)
        ..strokeWidth = radius * 0.035,
    );
    canvas.restore();
  }

  void _speedmaster(Canvas canvas, double r) {
    _roundCase(canvas, r, _steel);
    canvas.drawCircle(
      Offset.zero,
      r * 0.94,
      Paint()..color = const Color(0xFF0E0F11),
    );
    // Tachymeter scale.
    const values = [
      500,
      400,
      300,
      250,
      200,
      170,
      150,
      130,
      110,
      100,
      90,
      80,
      70,
      60,
    ];
    final ink = Paint()
      ..color = const Color(0xFFE8E8E8)
      ..strokeWidth = r * 0.01;
    for (final v in values) {
      final a = 3600 / v / 60 * _tau;
      canvas.drawLine(_at(a, r * 0.91), _at(a, r * 0.94), ink);
      _label(
        canvas,
        '$v',
        _at(a, r * 0.855),
        r * 0.075,
        const Color(0xFFE8E8E8),
        angle: a,
        weight: FontWeight.w600,
      );
    }
    canvas.drawCircle(
      Offset.zero,
      r * 0.8,
      Paint()..color = const Color(0xFF1A1B1E),
    );
    canvas.drawCircle(
      Offset.zero,
      r * 0.78,
      Paint()..color = const Color(0xFF0B0B0D),
    );
    _ticks(
      canvas,
      r * 0.72,
      r * 0.775,
      300,
      Paint()
        ..color = const Color(0x99FFFFFF)
        ..strokeWidth = r * 0.004,
      skipEvery: 5,
    );
    _ticks(
      canvas,
      r * 0.7,
      r * 0.775,
      60,
      Paint()
        ..color = Colors.white
        ..strokeWidth = r * 0.008,
    );
    for (final at in [
      Offset(-r * 0.38, 0),
      Offset(r * 0.38, 0),
      Offset(0, r * 0.38),
    ]) {
      _subdial(canvas, at, r * 0.2, const Color(0xFF151619), Colors.white);
    }
    final white = Paint()..color = Colors.white;
    for (var i = 0; i < 12; i++) {
      _bar(canvas, i / 12 * _tau, r * 0.6, r * 0.69, r * 0.035, white);
    }
  }

  void _gear(Canvas canvas, Offset at, double radius, int teeth, Color c) {
    final path = Path();
    for (var i = 0; i < teeth * 2; i++) {
      final a = i / (teeth * 2) * _tau;
      final p = at + _at(a, i.isEven ? radius : radius * 0.86);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = c);
    canvas.drawCircle(
      at,
      radius * 0.62,
      Paint()..color = const Color(0xFF111214),
    );
    final spoke = Paint()
      ..color = c
      ..strokeWidth = radius * 0.14;
    for (var i = 0; i < 4; i++) {
      final a = i / 4 * _tau + 0.3;
      canvas.drawLine(at, at + _at(a, radius * 0.62), spoke);
    }
    canvas.drawCircle(
      at,
      radius * 0.16,
      Paint()..color = const Color(0xFFB9BEC3),
    );
  }

  void _bigBang(Canvas canvas, double r) {
    _roundCase(canvas, r, _titanium);
    canvas.drawCircle(Offset.zero, r * 0.92, _metal(_titanium, r, turn: 1.4));
    for (var i = 0; i < 6; i++) {
      final at = _at(i / 6 * _tau, r * 0.86);
      canvas
        ..save()
        ..translate(at.dx, at.dy)
        ..rotate(i / 6 * _tau);
      final h = Paint()
        ..color = const Color(0xFFD9DCDF)
        ..strokeWidth = r * 0.016;
      canvas
        ..drawCircle(
          Offset.zero,
          r * 0.045,
          Paint()..color = const Color(0xFF3A3D42),
        )
        ..drawLine(
          Offset(-r * 0.022, -r * 0.025),
          Offset(-r * 0.022, r * 0.025),
          h,
        )
        ..drawLine(
          Offset(r * 0.022, -r * 0.025),
          Offset(r * 0.022, r * 0.025),
          h,
        )
        ..drawLine(Offset(-r * 0.022, 0), Offset(r * 0.022, 0), h)
        ..restore();
    }
    // Openworked dial with visible wheels.
    canvas.drawCircle(
      Offset.zero,
      r * 0.78,
      Paint()..color = const Color(0xFF0E0F11),
    );
    _gear(
      canvas,
      Offset(-r * 0.28, -r * 0.2),
      r * 0.24,
      22,
      const Color(0xFF6E737A),
    );
    _gear(
      canvas,
      Offset(r * 0.26, r * 0.24),
      r * 0.2,
      18,
      const Color(0xFF6E737A),
    );
    _gear(canvas, Offset(-r * 0.12, r * 0.36), r * 0.12, 12, _red);
    final bridge = Paint()
      ..color = const Color(0xFF2C2F34)
      ..strokeWidth = r * 0.07
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(Offset(-r * 0.6, r * 0.2), Offset(r * 0.5, -r * 0.45), bridge)
      ..drawLine(
        Offset(-r * 0.4, -r * 0.55),
        Offset(r * 0.2, r * 0.62),
        bridge,
      );
    // Flange.
    canvas.drawCircle(
      Offset.zero,
      r * 0.74,
      Paint()
        ..color = const Color(0xFF1B1C1F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.08,
    );
    _ticks(
      canvas,
      r * 0.71,
      r * 0.77,
      60,
      Paint()
        ..color = const Color(0xCCFFFFFF)
        ..strokeWidth = r * 0.007,
    );
    _batonIndices(
      canvas,
      r,
      0.56,
      0.68,
      0.05,
      metal: const Color(0xFFD9DCDF),
      fill: _lume,
      double12: false,
    );
  }

  Path _tonneau(double w, double h) {
    return Path()
      ..moveTo(-w * 0.82, -h)
      ..quadraticBezierTo(0, -h * 1.06, w * 0.82, -h)
      ..cubicTo(w * 1.08, -h * 0.55, w * 1.08, h * 0.55, w * 0.82, h)
      ..quadraticBezierTo(0, h * 1.06, -w * 0.82, h)
      ..cubicTo(-w * 1.08, h * 0.55, -w * 1.08, -h * 0.55, -w * 0.82, -h)
      ..close();
  }

  void _rm011(Canvas canvas, double r) {
    final outer = _tonneau(r * 0.8, r * 0.95);
    canvas.drawPath(outer, Paint()..color = const Color(0xFF16171A));
    // Carbon TPT layering.
    canvas
      ..save()
      ..clipPath(outer);
    final layer = Paint()
      ..color = const Color(0x1AFFFFFF)
      ..strokeWidth = r * 0.012
      ..style = PaintingStyle.stroke;
    for (var y = -1.1; y < 1.1; y += 0.07) {
      final path = Path()..moveTo(-r, y * r);
      for (var x = -1.0; x <= 1.0; x += 0.1) {
        path.lineTo(x * r, (y + math.sin(x * 7 + y * 9) * 0.02) * r);
      }
      canvas.drawPath(path, layer);
    }
    canvas.restore();
    canvas.drawPath(
      outer,
      Paint()
        ..color = const Color(0x55FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.012,
    );
    for (final p in [
      Offset(-r * 0.66, -r * 0.8),
      Offset(0, -r * 0.88),
      Offset(r * 0.66, -r * 0.8),
      Offset(r * 0.8, 0),
      Offset(r * 0.66, r * 0.8),
      Offset(0, r * 0.88),
      Offset(-r * 0.66, r * 0.8),
      Offset(-r * 0.8, 0),
    ]) {
      canvas.drawCircle(p, r * 0.045, _metal(_titanium, r * 0.05));
      _ticks(
        canvas
          ..save()
          ..translate(p.dx, p.dy),
        0,
        r * 0.03,
        5,
        Paint()
          ..color = const Color(0xFF1A1B1E)
          ..strokeWidth = r * 0.01,
      );
      canvas.restore();
    }
    final dial = _tonneau(r * 0.62, r * 0.76);
    canvas.drawPath(dial, Paint()..color = const Color(0xFF0C0D0F));
    canvas
      ..save()
      ..clipPath(dial);
    final bridge = Paint()
      ..color = const Color(0xFF4A4E55)
      ..strokeWidth = r * 0.09;
    canvas
      ..drawLine(Offset(-r, r * 0.35), Offset(r, -r * 0.2), bridge)
      ..drawLine(Offset(-r, -r * 0.35), Offset(r, r * 0.5), bridge);
    _gear(
      canvas,
      Offset(-r * 0.2, r * 0.3),
      r * 0.18,
      16,
      const Color(0xFF80858C),
    );
    _gear(
      canvas,
      Offset(r * 0.25, -r * 0.3),
      r * 0.15,
      14,
      const Color(0xFF80858C),
    );
    canvas.restore();
    // Big date at 12 and red accents.
    for (final dx in [-0.07, 0.07]) {
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(dx * r, -r * 0.48),
          width: r * 0.12,
          height: r * 0.15,
        ),
        Paint()..color = Colors.white,
      );
    }
    _label(
      canvas,
      day.toString().padLeft(2, '0').split('').join(' '),
      Offset(0, -r * 0.48),
      r * 0.11,
      Colors.black,
      weight: FontWeight.w800,
    );
    final redTick = Paint()
      ..color = _red
      ..strokeWidth = r * 0.03
      ..strokeCap = StrokeCap.round;
    for (final a in [_tau / 4, _tau / 2, _tau * 3 / 4]) {
      canvas.drawLine(_at(a, r * 0.5), _at(a, r * 0.6), redTick);
    }
  }

  void _monaco(Canvas canvas, double r) {
    final outer = RRect.fromRectAndRadius(
      Rect.fromCircle(center: Offset.zero, radius: r * 0.95),
      Radius.circular(r * 0.26),
    );
    canvas.drawRRect(outer, _metal(_steel, r));
    final dialRect = RRect.fromRectAndRadius(
      Rect.fromCircle(center: Offset.zero, radius: r * 0.76),
      Radius.circular(r * 0.14),
    );
    canvas.drawRRect(
      dialRect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.1, -0.2),
          colors: [Color(0xFF2E66C2), Color(0xFF173B7E), Color(0xFF0D2556)],
          stops: [0, 0.6, 1],
        ).createShader(dialRect.outerRect),
    );
    // Sunray.
    canvas
      ..save()
      ..clipRRect(dialRect);
    final ray = Paint()
      ..color = const Color(0x12FFFFFF)
      ..strokeWidth = r * 0.006;
    for (var i = 0; i < 90; i++) {
      final a = i / 90 * _tau;
      canvas.drawLine(Offset.zero, _at(a, r * 1.2), ray);
    }
    canvas.restore();
    for (var i = 0; i < 60; i++) {
      final a = i / 60 * _tau;
      canvas.drawLine(
        _onSquare(a, r * 0.66),
        _onSquare(a, r * 0.72),
        Paint()
          ..color = const Color(0xCCFFFFFF)
          ..strokeWidth = r * (i % 5 == 0 ? 0.014 : 0.006),
      );
    }
    for (final dx in [-0.34, 0.34]) {
      final sq = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(dx * r, r * 0.04),
          width: r * 0.32,
          height: r * 0.32,
        ),
        Radius.circular(r * 0.05),
      );
      canvas.drawRRect(sq, Paint()..color = const Color(0xFFE9ECEF));
      canvas
        ..save()
        ..translate(dx * r, r * 0.04);
      _ticks(
        canvas,
        r * 0.1,
        r * 0.14,
        12,
        Paint()
          ..color = const Color(0xFF1A1B1E)
          ..strokeWidth = r * 0.008,
      );
      canvas.restore();
    }
    // Horizontal applied indices.
    final bar = Paint()..color = const Color(0xFFE9ECEF);
    final line = Paint()..color = const Color(0xFF111111);
    for (final i in [0, 1, 2, 4, 5, 6, 7, 8, 10, 11]) {
      final a = i / 12 * _tau;
      final p = _onSquare(a, r * 0.56);
      final rect = Rect.fromCenter(
        center: p,
        width: r * 0.12,
        height: r * 0.045,
      );
      canvas
        ..drawRect(rect, bar)
        ..drawRect(
          Rect.fromCenter(center: p, width: r * 0.1, height: r * 0.01),
          line,
        );
    }
  }

  void _overseas(Canvas canvas, double r) {
    // Bezel with six Maltese-cross notches.
    final bezel = Path();
    for (var i = 0; i <= 360; i++) {
      final a = i / 360 * _tau;
      final notch = math.pow(math.cos(3 * a).abs(), 60).toDouble();
      final rr = r * (0.97 - 0.045 * notch);
      final p = _at(a, rr);
      if (i == 0) {
        bezel.moveTo(p.dx, p.dy);
      } else {
        bezel.lineTo(p.dx, p.dy);
      }
    }
    bezel.close();
    canvas.drawPath(bezel, _metal(_steel, r));
    canvas.drawCircle(Offset.zero, r * 0.79, _metal(_steel, r, turn: 1.3));
    final dial = Rect.fromCircle(center: Offset.zero, radius: r * 0.74);
    canvas.drawCircle(
      Offset.zero,
      r * 0.74,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF3466B0), Color(0xFF1A3E78), Color(0xFF0C2346)],
          stops: [0, 0.65, 1],
        ).createShader(dial),
    );
    canvas
      ..save()
      ..clipPath(Path()..addOval(dial));
    final ray = Paint()
      ..color = const Color(0x14FFFFFF)
      ..strokeWidth = r * 0.005;
    for (var i = 0; i < 120; i++) {
      canvas.drawLine(Offset.zero, _at(i / 120 * _tau, r), ray);
    }
    canvas.restore();
    // Translucent outer minute ring.
    canvas.drawCircle(
      Offset.zero,
      r * 0.69,
      Paint()
        ..color = const Color(0x22FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.09,
    );
    _ticks(
      canvas,
      r * 0.66,
      r * 0.72,
      60,
      Paint()
        ..color = const Color(0xCCFFFFFF)
        ..strokeWidth = r * 0.006,
    );
    _batonIndices(
      canvas,
      r,
      0.44,
      0.6,
      0.055,
      metal: const Color(0xFFF1E2B8),
      skip: {3},
    );
    _dateWindow(
      canvas,
      Offset(r * 0.5, 0),
      r * 0.15,
      r * 0.13,
      day,
      Colors.white,
      Colors.black,
    );
  }

  void _navitimer(Canvas canvas, double r) {
    _roundCase(canvas, r, _steel);
    // Beaded rotating bezel.
    for (var i = 0; i < 64; i++) {
      canvas.drawCircle(
        _at(i / 64 * _tau, r * 0.96),
        r * 0.04,
        Paint()..color = const Color(0xFFD5D9DC),
      );
    }
    canvas.drawCircle(
      Offset.zero,
      r * 0.93,
      Paint()..color = const Color(0xFF0E0F11),
    );
    // Slide-rule scales (logarithmic).
    const scale = [10, 12, 15, 20, 25, 30, 35, 40, 50, 60, 70, 80, 90];
    final ink = Paint()
      ..color = const Color(0xFFE6E6E6)
      ..strokeWidth = r * 0.008;
    for (final v in scale) {
      final a = (math.log(v / 10) / math.ln10) * _tau;
      canvas
        ..drawLine(_at(a, r * 0.9), _at(a, r * 0.93), ink)
        ..drawLine(_at(a, r * 0.74), _at(a, r * 0.77), ink);
      _label(
        canvas,
        '$v',
        _at(a, r * 0.86),
        r * 0.06,
        const Color(0xFFE6E6E6),
        angle: a,
      );
      _label(
        canvas,
        '$v',
        _at(a, r * 0.8),
        r * 0.05,
        const Color(0xFFBFC4C9),
        angle: a,
      );
    }
    canvas.drawCircle(
      Offset.zero,
      r * 0.73,
      Paint()..color = const Color(0xFF0A0A0C),
    );
    _ticks(
      canvas,
      r * 0.68,
      r * 0.725,
      60,
      Paint()
        ..color = Colors.white
        ..strokeWidth = r * 0.006,
    );
    for (final at in [
      Offset(-r * 0.34, 0),
      Offset(r * 0.34, 0),
      Offset(0, r * 0.34),
    ]) {
      _subdial(
        canvas,
        at,
        r * 0.17,
        const Color(0xFFC9CDD1),
        const Color(0xFF1A1B1E),
      );
    }
    final white = Paint()..color = _lume;
    for (var i = 0; i < 12; i++) {
      if (i == 3 || i == 6 || i == 9) continue;
      _bar(canvas, i / 12 * _tau, r * 0.55, r * 0.66, r * 0.035, white);
    }
  }

  void _snowflake(Canvas canvas, double r) {
    _roundCase(canvas, r, _steel);
    canvas.drawCircle(
      Offset.zero,
      r * 0.86,
      Paint()
        ..shader = const SweepGradient(
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFF7D8590),
            Color(0xFFF6F7F8),
            Color(0xFF5F6670),
            Color(0xFFFFFFFF),
          ],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: r)),
    );
    final dial = Rect.fromCircle(center: Offset.zero, radius: r * 0.78);
    canvas.drawCircle(
      Offset.zero,
      r * 0.78,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.35),
          colors: [Color(0xFFFFFFFF), Color(0xFFE7EAEE)],
        ).createShader(dial),
    );
    // Snow texture.
    canvas
      ..save()
      ..clipPath(Path()..addOval(dial));
    final rng = math.Random(4);
    final flake = Paint()
      ..strokeWidth = r * 0.006
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 420; i++) {
      final p = Offset(
        (rng.nextDouble() * 2 - 1) * r * 0.8,
        (rng.nextDouble() * 2 - 1) * r * 0.8,
      );
      final a = rng.nextDouble() * math.pi;
      final l = r * (0.02 + rng.nextDouble() * 0.05);
      flake.color = rng.nextBool()
          ? const Color(0x1A5A6470)
          : const Color(0x55FFFFFF);
      canvas.drawLine(p, p + Offset(math.cos(a) * l, math.sin(a) * l), flake);
    }
    canvas.restore();
    _ticks(
      canvas,
      r * 0.73,
      r * 0.77,
      60,
      Paint()
        ..color = const Color(0xFF6B7380)
        ..strokeWidth = r * 0.006,
    );
    // Power reserve at 7–8 o'clock.
    final pr = Offset(-r * 0.32, r * 0.24);
    final arc = Paint()
      ..color = const Color(0xFF6B7380)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.008;
    canvas.drawArc(
      Rect.fromCircle(center: pr, radius: r * 0.16),
      math.pi * 0.95,
      math.pi * 0.9,
      false,
      arc,
    );
    canvas
      ..save()
      ..translate(pr.dx, pr.dy);
    for (var i = 0; i <= 6; i++) {
      final a = -math.pi * 0.55 + i * math.pi * 0.15 - math.pi / 2;
      canvas.drawLine(
        _at(a + math.pi / 2, r * 0.13),
        _at(a + math.pi / 2, r * 0.16),
        arc,
      );
    }
    canvas.restore();
    _batonIndices(
      canvas,
      r,
      0.52,
      0.7,
      0.06,
      metal: const Color(0xFFD7DCE2),
      fill: const Color(0xFFF7F8FA),
      skip: {3},
    );
    _dateWindow(
      canvas,
      Offset(r * 0.58, 0),
      r * 0.15,
      r * 0.13,
      day,
      Colors.white,
      const Color(0xFF222222),
      frame: const Color(0xFFB9C0C8),
    );
  }

  @override
  bool shouldRepaint(covariant _FacePainter old) =>
      old.style != style || old.day != day;
}

// ── Hands ──────────────────────────────────────────────────────────────────

enum _Hand { baton, mercedes, sword, dauphine, skeleton }

class _HandsPainter extends CustomPainter {
  _HandsPainter(this.style, this.clock) : super(repaint: clock);

  final WatchDialStyle style;
  final Listenable clock;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    canvas.translate(size.width / 2, size.height / 2);
    final now = DateTime.now();
    final secs = now.second + now.millisecond / 1000;
    final mins = now.minute + secs / 60;
    final hrs = now.hour % 12 + mins / 60;
    final ha = hrs / 12 * _tau, ma = mins / 60 * _tau, sa = secs / 60 * _tau;

    // Running seconds on chronograph sub-dials; central hand is the
    // chronograph, resting at 12.
    switch (style) {
      case WatchDialStyle.speedmaster:
        _subHand(canvas, Offset(-r * 0.38, 0), r * 0.16, sa, Colors.white);
        _subHand(canvas, Offset(r * 0.38, 0), r * 0.16, 0, Colors.white);
        _subHand(canvas, Offset(0, r * 0.38), r * 0.16, 0, Colors.white);
      case WatchDialStyle.navitimer:
        _subHand(canvas, Offset(-r * 0.34, 0), r * 0.14, sa, Colors.black);
        _subHand(canvas, Offset(r * 0.34, 0), r * 0.14, 0, Colors.black);
        _subHand(canvas, Offset(0, r * 0.34), r * 0.14, 0, Colors.black);
      case WatchDialStyle.monaco:
        _subHand(canvas, Offset(-r * 0.34, r * 0.04), r * 0.13, sa, _red);
        _subHand(canvas, Offset(r * 0.34, r * 0.04), r * 0.13, 0, _red);
      case WatchDialStyle.snowflake:
        _subHand(
          canvas,
          Offset(-r * 0.32, r * 0.24),
          r * 0.15,
          -math.pi * 0.2,
          const Color(0xFF2B5DB6),
        );
      default:
        break;
    }

    final (kind, color, lume, length) = switch (style) {
      WatchDialStyle.submariner => (_Hand.mercedes, _whiteGold, true, 0.7),
      WatchDialStyle.santos => (
        _Hand.sword,
        const Color(0xFF1F3C8A),
        false,
        0.62,
      ),
      WatchDialStyle.overseas => (
        _Hand.dauphine,
        const Color(0xFFE3E6EA),
        true,
        0.68,
      ),
      // Polished steel reads darker against the white snowflake dial.
      WatchDialStyle.snowflake => (
        _Hand.dauphine,
        const Color(0xFF8C96A2),
        false,
        0.7,
      ),
      WatchDialStyle.bigBang || WatchDialStyle.rm011 => (
        _Hand.skeleton,
        const Color(0xFFD9DCDF),
        true,
        0.62,
      ),
      _ => (_Hand.baton, _whiteGold, true, 0.68),
    };

    _withShadow(canvas, r, () {
      _hand(canvas, kind, ha, r * length * 0.68, r * 0.07, color, lume);
      _hand(canvas, kind, ma, r * length, r * 0.05, color, lume);
    });

    final secondsColor = switch (style) {
      WatchDialStyle.snowflake => const Color(0xFF2B5DB6),
      WatchDialStyle.santos => const Color(0xFF1F3C8A),
      WatchDialStyle.bigBang ||
      WatchDialStyle.rm011 ||
      WatchDialStyle.monaco => _red,
      _ => _whiteGold,
    };
    final chrono =
        style == WatchDialStyle.speedmaster ||
        style == WatchDialStyle.navitimer ||
        style == WatchDialStyle.monaco ||
        style == WatchDialStyle.bigBang;
    final centralSeconds = chrono ? 0.0 : sa;
    final p = Paint()
      ..color = secondsColor
      ..strokeWidth = r * 0.016
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      _at(centralSeconds + math.pi, r * 0.16),
      _at(centralSeconds, r * 0.74),
      p,
    );
    if (style == WatchDialStyle.submariner) {
      canvas.drawCircle(_at(centralSeconds, r * 0.56), r * 0.035, p);
      canvas.drawCircle(
        _at(centralSeconds, r * 0.56),
        r * 0.024,
        Paint()..color = _lume,
      );
    }
    canvas.drawCircle(Offset.zero, r * 0.035, Paint()..color = secondsColor);
    canvas.drawCircle(
      Offset.zero,
      r * 0.014,
      Paint()..color = const Color(0xFF222222),
    );
  }

  void _withShadow(Canvas canvas, double r, VoidCallback draw) {
    canvas
      ..saveLayer(
        null,
        Paint()
          ..colorFilter = const ColorFilter.mode(
            Color(0x66000000),
            BlendMode.srcIn,
          )
          ..imageFilter = _shadowBlur(r),
      )
      ..translate(r * 0.02, r * 0.035);
    draw();
    canvas.restore();
    draw();
  }

  static ImageFilter _shadowBlur(double r) =>
      ImageFilter.blur(sigmaX: r * 0.02, sigmaY: r * 0.02);

  void _subHand(Canvas canvas, Offset at, double length, double a, Color c) {
    canvas.drawLine(
      at,
      at + _at(a, length),
      Paint()
        ..color = c
        ..strokeWidth = length * 0.08
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(at, length * 0.1, Paint()..color = c);
  }

  void _hand(
    Canvas canvas,
    _Hand kind,
    double angle,
    double length,
    double width,
    Color color,
    bool lume,
  ) {
    canvas
      ..save()
      ..rotate(angle);
    final metal = Paint()..color = color;
    final glow = Paint()..color = _lume;
    switch (kind) {
      case _Hand.baton:
        canvas.drawRRect(
          RRect.fromLTRBR(
            -width / 2,
            -length,
            width / 2,
            width * 0.8,
            Radius.circular(width * 0.3),
          ),
          metal,
        );
        if (lume) {
          canvas.drawRect(
            Rect.fromLTRB(
              -width * 0.25,
              -length * 0.94,
              width * 0.25,
              -length * 0.3,
            ),
            glow,
          );
        }
      case _Hand.mercedes:
        canvas.drawRRect(
          RRect.fromLTRBR(
            -width / 2,
            -length,
            width / 2,
            width,
            Radius.circular(width * 0.2),
          ),
          metal,
        );
        canvas.drawRect(
          Rect.fromLTRB(
            -width * 0.28,
            -length * 0.95,
            width * 0.28,
            -length * 0.25,
          ),
          glow,
        );
        if (width > length * 0.09) {
          // Hour hand: the Mercedes circle near the tip.
          canvas.drawCircle(Offset(0, -length * 0.72), width * 0.95, metal);
          canvas.drawCircle(Offset(0, -length * 0.72), width * 0.68, glow);
        }
      case _Hand.sword:
        final path = Path()
          ..moveTo(0, -length)
          ..lineTo(width * 0.55, -length * 0.25)
          ..lineTo(width * 0.3, width)
          ..lineTo(-width * 0.3, width)
          ..lineTo(-width * 0.55, -length * 0.25)
          ..close();
        canvas.drawPath(path, metal);
      case _Hand.dauphine:
        final left = Path()
          ..moveTo(0, -length)
          ..lineTo(-width * 0.6, -length * 0.2)
          ..lineTo(0, width)
          ..close();
        final right = Path()
          ..moveTo(0, -length)
          ..lineTo(width * 0.6, -length * 0.2)
          ..lineTo(0, width)
          ..close();
        canvas
          ..drawPath(left, metal)
          ..drawPath(
            right,
            Paint()..color = Color.lerp(color, Colors.black, 0.35)!,
          );
        if (lume) {
          canvas.drawRect(
            Rect.fromLTRB(
              -width * 0.12,
              -length * 0.85,
              width * 0.12,
              -length * 0.35,
            ),
            glow,
          );
        }
      case _Hand.skeleton:
        final outline = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = width * 0.28;
        canvas.drawRRect(
          RRect.fromLTRBR(
            -width / 2,
            -length,
            width / 2,
            width * 0.6,
            Radius.circular(width * 0.3),
          ),
          outline,
        );
        canvas.drawRect(
          Rect.fromLTRB(
            -width * 0.3,
            -length * 0.98,
            width * 0.3,
            -length * 0.78,
          ),
          glow,
        );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HandsPainter old) =>
      old.style != style || old.clock != clock;
}
