import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../../domain/diamond_grades.dart';
import '../../../simulation/sim_inclusion_plot.dart';
import '../../../simulation/sim_inclusions.dart';
import '../../../simulation/sim_mesh.dart';

/// Localized text for the inclusion labels, built where a context is at
/// hand and handed to the painter.
class SimCalloutText {
  const SimCalloutText({
    required this.names,
    required this.internal,
    required this.external,
    required this.places,
  });

  final Map<InclusionType, String> names;

  /// What GIA's key calls each side: internal, external.
  final String internal, external;
  final Map<SimFacetKind, String> places;
}

/// Labels for the inclusions in the line drawing, set outside the stone
/// in a column either side, each with an arrow to every inclusion of its
/// kind. The arrows follow the inclusions in 3D as the stone turns;
/// labels glide to stay level with them and never overlap, and keep
/// their side until an inclusion clearly crosses to the other.
///
/// Keyed as GIA plots them: internal characteristics red, external ones
/// green, matching the picker and the symbols.
class SimInclusionCallouts {
  final Map<InclusionType, _Label> _labels = {};
  SimCalloutText? _text;
  final Map<SimInclusion, SimFacetKind> _places = Map.identity();
  SimMesh? _placesFor;

  /// Hit areas of the labels drawn last, for taps.
  final Map<InclusionType, Rect> rects = {};

  final Paint _line = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final Paint _fill = Paint()..isAntiAlias = true;

  set text(SimCalloutText value) {
    if (identical(value, _text)) return;
    _text = value;
    for (final l in _labels.values) {
      l.dispose();
    }
    _labels.clear();
  }

  void clear() {
    for (final l in _labels.values) {
      l.dispose();
    }
    _labels.clear();
    rects.clear();
  }

  /// Lays out and paints labels for [anchors] round [stone] (the stone's
  /// outline on screen), within [stage]. [dt] is seconds since the last
  /// frame (0 to snap into place); [focus] is drawn highlighted.
  void paint(
    Canvas canvas, {
    required List<SimInclusionAnchor> anchors,
    required SimMesh mesh,
    required Rect stone,
    required Rect stage,
    required double dt,
    double opacity = 1,
    InclusionType? focus,
  }) {
    rects.clear();
    final text = _text;
    if (text == null || opacity <= 0.01 || stone.isEmpty) return;
    if (!identical(mesh, _placesFor)) {
      _placesFor = mesh;
      _places.clear();
    }

    // Anchors by kind, nearest first.
    final groups = <InclusionType, List<SimInclusionAnchor>>{};
    for (final a in anchors) {
      if (!a.inclusion.kind.labelled) continue;
      (groups[a.inclusion.kind.type] ??= []).add(a);
    }
    for (final g in groups.values) {
      g.sort((a, b) => b.depth.compareTo(a.depth));
    }
    _labels.removeWhere((type, l) {
      if (groups.containsKey(type)) return false;
      l.dispose();
      return true;
    });

    final cx = stone.center.dx;
    const gap = 16.0, margin = 6.0, spacing = 6.0;
    final leftRoom = stone.left - gap - stage.left - margin;
    final rightRoom = stage.right - margin - (stone.right + gap);
    final snap = dt <= 0;
    final ease = snap ? 1.0 : 1 - math.exp(-dt * 13);

    final sides = <bool, List<(InclusionType, _Label, double)>>{
      true: [],
      false: [],
    };
    for (final MapEntry(key: type, value: group) in groups.entries) {
      var mx = 0.0, my = 0.0;
      for (final a in group) {
        mx += a.at.dx;
        my += a.at.dy;
      }
      mx /= group.length;
      my /= group.length;
      final first = group.first.inclusion;
      final place = _places[first] ??= SimInclusions.nearestFacet(mesh, first);
      final label = _labels[type] ??= _Label(
        name: '${text.names[type] ?? type.name} (${type.giaCode})',
        tags: type.isExternal ? text.external : text.internal,
        color: SimInclusionPlot.colorOf(type),
        left: mx < cx,
      );
      label.place(text.places[place] ?? '');
      // Keep the side until the inclusions clearly cross over.
      final hysteresis = stone.width * 0.12;
      if (label.left && mx > cx + hysteresis) label.left = false;
      if (!label.left && mx < cx - hysteresis) label.left = true;
      // Too little room on a side: the other one.
      final room = label.left ? leftRoom : rightRoom;
      final other = label.left ? rightRoom : leftRoom;
      if (room < 72 && other > room + 30) label.left = !label.left;
      final maxWidth = math.max(
        72.0,
        math.min(150.0, label.left ? leftRoom : rightRoom),
      );
      label.layout(maxWidth);
      sides[label.left]!.add((type, label, my - label.height / 2));
    }

    // Stack each column without overlaps, close to where each wants to be.
    for (final MapEntry(key: left, value: column) in sides.entries) {
      column.sort((a, b) => a.$3.compareTo(b.$3));
      final ys = [for (final c in column) c.$3];
      for (var i = 0; i < column.length; i++) {
        final lo = i == 0
            ? stage.top
            : ys[i - 1] + column[i - 1].$2.height + spacing;
        ys[i] = math.max(ys[i], lo);
      }
      for (var i = column.length - 1; i >= 0; i--) {
        final hi = i == column.length - 1
            ? stage.bottom - column[i].$2.height
            : ys[i + 1] - column[i].$2.height - spacing;
        ys[i] = math.max(stage.top, math.min(ys[i], hi));
      }
      for (var i = 0; i < column.length; i++) {
        final (_, label, _) = column[i];
        final x = left
            ? math.max(stage.left + margin, stone.left - gap - label.width)
            : math.min(stage.right - margin - label.width, stone.right + gap);
        if (label.fresh || snap) {
          label
            ..x = x
            ..y = ys[i];
        } else {
          label
            ..x += (x - label.x) * ease
            ..y += (ys[i] - label.y) * ease;
        }
        label.fresh = false;
        label.alpha = snap ? 1 : math.min(1, label.alpha + dt / 0.25);
      }
      // Gliding labels never overlap either.
      final shown = [for (final c in column) c.$2]
        ..sort((a, b) => a.y.compareTo(b.y));
      for (var i = 1; i < shown.length; i++) {
        final prev = shown[i - 1];
        shown[i].y = math.max(shown[i].y, prev.y + prev.height + spacing);
      }
    }

    // Arrows under the labels, then the labels.
    for (final MapEntry(key: type, value: group) in groups.entries) {
      final label = _labels[type]!;
      final a = opacity * label.alpha;
      final focused = focus == type;
      final color = label.color;
      final from = Offset(
        label.left ? label.x + label.width : label.x,
        label.y + label.height / 2,
      );
      final elbow = from.translate(label.left ? 10 : -10, 0);
      for (final anchor in group.take(3)) {
        final front = anchor.depth >= 0;
        final toward = anchor.at - elbow;
        final dist = toward.distance;
        if (dist < 1) continue;
        final dir = toward / dist;
        final stop = math.min(anchor.radius * 0.55, 14.0) + 4;
        final tip = anchor.at - dir * stop;
        final alpha = a * (front ? 0.9 : 0.55) * (focused ? 1 : 0.85);
        _line
          ..color = const Color(0xFFFFFFFF).withValues(alpha: alpha)
          ..strokeWidth = focused ? 1.5 : 1.1;
        canvas.drawPath(
          Path()
            ..moveTo(from.dx, from.dy)
            ..lineTo(elbow.dx, elbow.dy)
            ..lineTo(tip.dx, tip.dy),
          _line,
        );
        // Arrowhead at the inclusion.
        final side = Offset(-dir.dy, dir.dx);
        const len = 7.0, half = 3.2;
        canvas.drawPath(
          Path()
            ..moveTo(tip.dx + dir.dx * 1.5, tip.dy + dir.dy * 1.5)
            ..lineTo(
              tip.dx - dir.dx * len + side.dx * half,
              tip.dy - dir.dy * len + side.dy * half,
            )
            ..lineTo(
              tip.dx - dir.dx * len - side.dx * half,
              tip.dy - dir.dy * len - side.dy * half,
            )
            ..close(),
          _fill..color = const Color(0xFFFFFFFF).withValues(alpha: alpha),
        );
      }
      canvas.drawCircle(from, 2.4, _fill..color = color.withValues(alpha: a));

      final rect = Rect.fromLTWH(label.x, label.y, label.width, label.height);
      rects[type] = rect;
      final rr = RRect.fromRectAndRadius(rect, const Radius.circular(9));
      canvas.drawRRect(
        rr,
        _fill..color = const Color(0xE00B0D10).withValues(alpha: 0.88 * a),
      );
      _line
        ..color = (focused ? color : const Color(0x40FFFFFF)).withValues(
          alpha: (focused ? 0.95 : 0.25) * a,
        )
        ..strokeWidth = focused ? 1.4 : 1;
      canvas.drawRRect(rr, _line);
      label.paint(canvas, a, color);
    }
  }
}

/// One kind's label: its name over its class and where it sits.
class _Label {
  _Label({
    required this.name,
    required this.tags,
    required this.color,
    required this.left,
  });

  final String name, tags;
  final Color color;
  bool left;
  bool fresh = true;
  double x = 0, y = 0, alpha = 0;

  String _place = '';
  double _laidFor = -1;
  TextPainter? _name, _tags;

  static const _padX = 9.0, _padY = 6.0, _dot = 7.0;

  double get width =>
      _padX * 2 + _dot + 5 + math.max(_name?.width ?? 0, _tags?.width ?? 0);

  double get height =>
      _padY * 2 + (_name?.height ?? 0) + 1 + (_tags?.height ?? 0);

  void place(String value) {
    if (value == _place) return;
    _place = value;
    _laidFor = -1;
  }

  void layout(double maxWidth) {
    if (maxWidth == _laidFor) return;
    _laidFor = maxWidth;
    _name?.dispose();
    _tags?.dispose();
    final inner = math.max(20.0, maxWidth - _padX * 2 - _dot - 5);
    _name = TextPainter(
      text: TextSpan(
        text: name,
        style: const TextStyle(
          color: Color(0xFFF4F5F7),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.15,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: inner);
    _tags = TextPainter(
      text: TextSpan(
        text: _place.isEmpty ? tags : '$tags · $_place',
        style: TextStyle(
          color: color.withValues(alpha: 0.92),
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          height: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: inner);
  }

  void paint(Canvas canvas, double alpha, Color color) {
    final n = _name, t = _tags;
    if (n == null || t == null) return;
    final textX = x + _padX + _dot + 5;
    canvas.drawCircle(
      Offset(x + _padX + _dot / 2, y + _padY + n.height / 2),
      _dot / 2,
      Paint()..color = color.withValues(alpha: alpha),
    );
    if (alpha < 0.99) {
      canvas.saveLayer(
        Rect.fromLTWH(x, y, width, height),
        Paint()..color = Color.fromRGBO(0, 0, 0, alpha),
      );
    }
    n.paint(canvas, Offset(textX, y + _padY));
    t.paint(canvas, Offset(textX, y + _padY + n.height + 1));
    if (alpha < 0.99) canvas.restore();
  }

  void dispose() {
    _name?.dispose();
    _tags?.dispose();
  }
}
