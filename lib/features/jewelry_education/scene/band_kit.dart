import 'dart:math' as math;

import '../domain/jewelry_design.dart';
import '../geometry/jmath.dart';
import '../geometry/jmesh.dart';
import 'jewelry_scene.dart';

/// A band swept round a loop: a ring's shank, a hoop, a bangle.
///
/// The band's centre line is an ellipse ([a] by [b]) in the plane of
/// [ex] and [ey] about [centre]; [ez] runs across the band (along the
/// finger for a ring). A ring's head sits at the top, angle π/2 (+[ey]),
/// where a cathedral raises the shoulders and split, bypass and tapered
/// shanks change shape. A cuff leaves out [gapHalf] radians either side
/// of angle [gapAt].
class Shank {
  Shank({
    required this.style,
    required this.profile,
    required double rMid,
    required this.thickness,
    required this.width,
    this.cathedral = 0,
    this.headHalf = 0,
    double? b,
    this.centre = V3.zero,
    this.ex = V3.unitX,
    this.ey = V3.unitY,
    this.ez = V3.unitZ,
    this.hasHead = true,
    this.gapAt = -math.pi / 2,
    this.gapHalf = 0,
    this.metal = JTag.metal,
  }) : a = rMid,
       b = b ?? rMid;

  final ShankStyle style;
  final BandProfile profile;
  final double a, b, thickness, width, cathedral, headHalf;
  final V3 centre, ex, ey, ez;
  final bool hasHead;
  final double gapAt, gapHalf;
  final double Function(double ao) metal;

  static const top = math.pi / 2;

  /// How far a split shank's strands reach from the head, radians.
  static const splitReach = 1.05;

  /// Angle from the top, 0..π.
  double fromTop(double th) {
    if (!hasHead) return math.pi;
    var d = (th - top).abs() % (2 * math.pi);
    if (d > math.pi) d = 2 * math.pi - d;
    return d;
  }

  double shoulder(double th) => smoothstep(0.8, 0.0, fromTop(th));

  V3 outward(double th) =>
      (ex * (b * math.cos(th)) + ey * (a * math.sin(th))).normalized;

  V3 tangent(double th) =>
      (ex * (-a * math.sin(th)) + ey * (b * math.cos(th))).normalized;

  /// The centre line at [th], a cathedral raising the shoulders.
  V3 point(double th) =>
      centre +
      ex * (a * math.cos(th)) +
      ey * (b * math.sin(th)) +
      outward(th) * (cathedral * shoulder(th));

  /// Width at [th] (before splitting).
  double widthAt(double th) {
    final d = fromTop(th);
    final w = switch (style) {
      ShankStyle.tapered => 1 - 0.38 * smoothstep(math.pi * 0.9, 0.25, d),
      ShankStyle.reverseTapered =>
        1 + 0.5 * smoothstep(math.pi * 0.85, 0.25, d),
      // The ends thin as they tuck under the head.
      ShankStyle.bypass => 1 - 0.45 * smoothstep(0.4, 0.0, d),
      _ => 1 - (cathedral > 0 ? 0.18 : 0.06) * shoulder(th),
    };
    return width * w;
  }

  /// The strands at [th]: each one's offset across the band and width.
  List<(double, double)> strands(double th) {
    final w = widthAt(th);
    final d = fromTop(th);
    switch (style) {
      case ShankStyle.split:
        if (d >= splitReach) return [(0, w)];
        final open = smoothstep(splitReach, 0.3, d) * (headHalf * 0.55);
        return [(-(w / 4 + open), w / 2), (w / 4 + open, w / 2)];
      case ShankStyle.bypass:
        // Each arm swings out past the head, then curls back in under it.
        final side = _sideOf(th);
        final out =
            smoothstep(1.3, 0.35, d) * (0.55 + 0.45 * smoothstep(0, 0.35, d));
        return [(side * headHalf * 0.42 * out, w)];
      default:
        return [(0, w)];
    }
  }

  double _sideOf(double th) {
    final rel = ((th - top) % (2 * math.pi) + 2 * math.pi) % (2 * math.pi);
    return rel < math.pi ? 1 : -1;
  }

  bool inGap(double th) {
    if (gapHalf <= 0) return false;
    var d = (th - gapAt).abs() % (2 * math.pi);
    if (d > math.pi) d = 2 * math.pi - d;
    return d < gapHalf;
  }

  /// Outer surface point on a strand at [th], offset [z] across.
  V3 surface(double th, double z) =>
      point(th) + outward(th) * (thickness / 2) + ez * z;

  void build(MeshBuilder mb, {bool milgrain = false}) {
    switch (style) {
      case ShankStyle.twisted:
        _twisted(mb);
        return;
      case ShankStyle.split:
        // One band round the bottom, two strands round the head; at the
        // fork the strands lie side by side, as wide as the band.
        _sweep(
          mb,
          top + splitReach,
          top + 2 * math.pi - splitReach,
          closed: false,
          milgrain: milgrain,
        );
        _sweep(
          mb,
          top - splitReach,
          top + splitReach,
          closed: false,
          milgrain: milgrain,
          strand: 0,
        );
        _sweep(
          mb,
          top - splitReach,
          top + splitReach,
          closed: false,
          milgrain: milgrain,
          strand: 1,
        );
      case ShankStyle.bypass:
        // The two ends pass beside the head, hidden under it.
        _sweep(
          mb,
          top + 0.03,
          top + 2 * math.pi - 0.03,
          closed: false,
          milgrain: milgrain,
          roundEnds: true,
        );
      default:
        if (gapHalf > 0) {
          _sweep(
            mb,
            gapAt + gapHalf,
            gapAt + 2 * math.pi - gapHalf,
            closed: false,
            milgrain: milgrain,
            roundEnds: true,
          );
        } else {
          _sweep(mb, 0, 2 * math.pi, closed: true, milgrain: milgrain);
        }
    }
  }

  void _sweep(
    MeshBuilder mb,
    double from,
    double to, {
    required bool closed,
    bool milgrain = false,
    int strand = 0,
    bool roundEnds = false,
  }) {
    final span = to - from;
    final steps = math.max(12, (144 * span / (2 * math.pi)).round());
    final origins = <V3>[], us = <V3>[], vs = <V3>[];
    final edgeA = <V3>[], edgeB = <V3>[];
    final prof = bandProfile(profile, thickness, 1);
    for (var i = 0; i < (closed ? steps : steps + 1); i++) {
      final th = from + span * i / steps;
      final ss = strands(th);
      final (z, w) = ss[math.min(strand, ss.length - 1)];
      final out = outward(th);
      origins.add(point(th) + ez * z);
      us.add(out);
      vs.add(ez * w);
      if (milgrain) {
        final rim = point(th) + out * (thickness * 0.36);
        edgeA.add(rim + ez * (z - w * 0.46));
        edgeB.add(rim + ez * (z + w * 0.46));
      }
    }
    final before = mb.solidVolume;
    mb.sweep(
      origins: origins,
      us: us,
      vs: vs,
      profile: prof,
      closedPath: closed,
      // The inside of the band is shaded.
      tagAt: (_, j) => metal(prof[j].$1 < 0 ? 0.68 : 1.0),
    );
    // The profile is a unit wide; the band is as wide as its strands.
    var mean = 0.0;
    for (final v in vs) {
      mean += v.length;
    }
    mean /= vs.length;
    mb.solidVolume = before + (mb.solidVolume - before) * mean;
    if (roundEnds && !closed) {
      for (final i in [0, origins.length - 1]) {
        mb.sphere(
          origins[i],
          thickness * 0.5,
          metal(1),
          segments: 8,
          rings: 5,
          count: false,
        );
      }
    }
    if (milgrain) {
      final r = math.min(0.15, thickness * 0.09);
      mb.beads(edgeA, r, metal(1), closed: closed);
      mb.beads(edgeB, r, metal(1), closed: closed);
    }
  }

  /// Two strands wound round each other along the loop.
  void _twisted(MeshBuilder mb) {
    final r = math.min(thickness, width) * 0.34;
    final wind = math.min(thickness, width) * 0.24;
    final turns = ((2 * math.pi * a) / (width * 2.6)).round().clamp(6, 40);
    const steps = 288;
    for (final phase in const [0.0, math.pi]) {
      final pts = <V3>[];
      for (var i = 0; i < steps; i++) {
        final th = 2 * math.pi * i / steps;
        final ph = phase + turns * th;
        pts.add(
          point(th) +
              outward(th) * (wind * math.cos(ph)) +
              ez * (wind * 1.6 * math.sin(ph) * widthAt(th) / width),
        );
      }
      mb.tube(pts, r, metal(1), sides: 7, closed: true);
    }
  }
}

/// Small stones set along a [Shank]: half, three-quarter or full
/// eternity, in pavé, a channel, shared prongs or bezels.
abstract final class BandStones {
  /// Stone size on a strand [w] mm wide.
  static double sizeFor(double w) => (w * 0.5).clamp(0.9, 1.8);

  /// Places stones out from angle [centreAt] both ways, starting
  /// [clear] radians away (clear of a ring's head).
  static void place(
    MeshBuilder mb,
    JTally tally,
    Shank shank, {
    required BandAccent coverage,
    required AccentSetting setting,
    double clear = 0,
    double centreAt = Shank.top,
    double seed = 13.7,
  }) {
    final perSide = switch (coverage) {
      BandAccent.plain => 0.0,
      BandAccent.half => 1.45,
      BandAccent.threeQuarter => 2.36,
      BandAccent.eternity => math.pi,
    };
    final span = math.min(perSide, math.pi - clear);
    if (span <= 0) return;
    final rOut = math.max(shank.a, shank.b) + shank.thickness / 2;
    for (final side in const [-1.0, 1.0]) {
      // Each strand's run of stones: positions, sizes.
      final runs = <int, List<(V3, V3, V3, double, double)>>{};
      var d = clear;
      var first = true;
      while (true) {
        final th0 = centreAt + side * d;
        final ss = shank.strands(th0);
        final hs = sizeFor(ss.map((s) => s.$2).reduce(math.min));
        final step = hs * 1.12 / rOut;
        if (first) {
          d += step / 2;
          first = false;
          continue;
        }
        if (d > clear + span - step * 0.4) break;
        final th = centreAt + side * d;
        if (!shank.inGap(th)) {
          final n = shank.outward(th), t = shank.tangent(th);
          final here = shank.strands(th);
          for (var k = 0; k < here.length; k++) {
            final (z, w) = here[k];
            final s = sizeFor(w);
            final p = shank.surface(th, z);
            (runs[k] ??= []).add((p, n, t, s, z));
          }
        }
        d += step;
      }
      for (final run in runs.values) {
        _setRun(mb, tally, shank, run, setting, seed * side);
      }
    }
  }

  static void _setRun(
    MeshBuilder mb,
    JTally tally,
    Shank shank,
    List<(V3, V3, V3, double, double)> run,
    AccentSetting setting,
    double seed,
  ) {
    final ez = shank.ez;
    final tag = shank.metal(1);
    for (var i = 0; i < run.length; i++) {
      final (p, n, t, hs, _) = run[i];
      final sink = switch (setting) {
        AccentSetting.channel => hs * 0.14,
        _ => hs * 0.05,
      };
      mb.brilliant(p - n * sink, n, hs, seed + i * 0.618, around: t);
      tally.accent(hs);
      if (setting == AccentSetting.bezel) {
        final c = p + n * (hs * 0.02);
        final ring = [
          for (var k = 0; k < 14; k++)
            c +
                t * ((hs * 0.6) * math.cos(2 * math.pi * k / 14)) +
                ez * ((hs * 0.6) * math.sin(2 * math.pi * k / 14)),
        ];
        mb.tube(ring, hs * 0.12, tag, sides: 5, closed: true);
      }
      if (i == run.length - 1) continue;
      final (q, m, _, hq, _) = run[i + 1];
      final mid = (p + q) * 0.5, mn = (n + m).normalized;
      final h = (hs + hq) / 2;
      switch (setting) {
        case AccentSetting.pave:
          for (final z in const [-1.0, 1.0]) {
            mb.sphere(
              mid + mn * 0.08 + ez * (z * h * 0.42),
              h * 0.17,
              tag,
              segments: 5,
              rings: 3,
            );
          }
        case AccentSetting.sharedProng:
          for (final z in const [-1.0, 1.0]) {
            final foot = mid - mn * (h * 0.25) + ez * (z * h * 0.47);
            final tip = mid + mn * (h * 0.2) + ez * (z * h * 0.42);
            mb
              ..tube([foot, tip], h * 0.12, tag, sides: 5, roundEnds: false)
              ..sphere(tip, h * 0.13, tag, segments: 5, rings: 3);
          }
        case AccentSetting.channel:
        case AccentSetting.bezel:
          break;
      }
    }
    if (setting == AccentSetting.channel && run.length > 1) {
      // Two walls along the run hold the stones by their girdles.
      for (final zs in const [-1.0, 1.0]) {
        final origins = <V3>[], us = <V3>[], vs = <V3>[];
        for (final (p, n, _, hs, _) in run) {
          origins.add(p + ez * (zs * hs * 0.6));
          us.add(n);
          vs.add(ez);
        }
        final h = run.first.$4;
        final profile = roundedRect(
          -h * 0.35,
          h * 0.16,
          -h * 0.1,
          h * 0.1,
          h * 0.05,
        );
        mb.sweep(
          origins: origins,
          us: us,
          vs: vs,
          profile: profile,
          tagAt: (_, _) => tag,
        );
      }
    }
  }
}
