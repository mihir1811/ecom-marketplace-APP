import 'dart:math' as math;

import '../../diamond_education/domain/diamond_shape.dart';
import '../domain/jewelry_design.dart';
import '../geometry/jewelry_stone.dart';
import '../geometry/jmath.dart';
import '../geometry/jmesh.dart';

/// Shared pieces for building scenes: stone orientations, chain links,
/// display velvet and the samples physics needs.
abstract final class SceneKit {
  /// Stone frame → a ring's top, table up, length along the finger
  /// (north–south). A heart's outline already runs along z.
  static Xf ringSeat(SimShape shape, V3 at) => shape == SimShape.heart
      ? Xf.axes(V3.unitX, V3.unitY, V3.unitZ, at)
      : Xf.axes(V3.unitZ, V3.unitY, const V3(-1, 0, 0), at);

  /// Stone frame → facing the viewer (+z), length upright: studs,
  /// drops and pendants. A pear points up to its bail, a heart down.
  static Xf facingFront(SimShape shape, V3 at) => shape == SimShape.heart
      ? Xf.axes(V3.unitX, V3.unitZ, const V3(0, -1, 0), at)
      : Xf.axes(V3.unitY, V3.unitZ, V3.unitX, at);

  /// How far a stone faced by [xf] reaches above its centre.
  static double reachUp(JewelryStone s, Xf xf) {
    var top = 0.0;
    for (var i = 0; i < 64; i++) {
      final p = xf.rotate(s.outline(i / 64));
      top = math.max(top, p.y);
    }
    return top;
  }

  /// Point masses for a rigid body: [grams] of metal spread over [mesh]
  /// (a sample of its vertices).
  static List<(V3, double)> massOf(
    JMesh mesh,
    double grams, {
    int samples = 300,
  }) {
    final n = mesh.vertexCount;
    if (n == 0 || grams <= 0) return const [];
    final step = math.max(1, n ~/ samples);
    final pts = <V3>[];
    for (var i = 0; i < n; i += step) {
      pts.add(V3(mesh.pos[i * 3], mesh.pos[i * 3 + 1], mesh.pos[i * 3 + 2]));
    }
    final w = grams / pts.length;
    return [for (final p in pts) (p, w)];
  }

  /// Points on [mesh] a finger can find.
  static List<V3> touchOf(JMesh mesh, {int samples = 90}) {
    final n = mesh.vertexCount;
    final step = math.max(1, n ~/ samples);
    return [
      for (var i = 0; i < n; i += step)
        V3(mesh.pos[i * 3], mesh.pos[i * 3 + 1], mesh.pos[i * 3 + 2]),
    ];
  }

  /// Diamond weighs 0.2 g per carat.
  static double stoneGrams(double carat) => carat * 0.2;

  // ---- Chain links -----------------------------------------------------

  /// Centre-to-centre spacing of links in a chain [width] mm wide.
  static double linkPitch(ChainStyle style, double width) => switch (style) {
    ChainStyle.cable => width * 1.0,
    ChainStyle.curb => width * 0.86,
    ChainStyle.box => width * 0.92,
    ChainStyle.rope => width * 0.9,
  };

  /// One link (or, for rope, one twist of the cord) centred on the
  /// origin, running along x; the link's loop lies in the x–y plane.
  static JMesh link(ChainStyle style, double width) {
    final mb = MeshBuilder();
    final tag = JTag.metal(0.92);
    switch (style) {
      case ChainStyle.cable:
      case ChainStyle.curb:
        final wire = width * (style == ChainStyle.curb ? 0.3 : 0.27);
        final a = (width * 1.55 - wire) / 2, b = (width - wire) / 2;
        final pts = <V3>[];
        // Links are a few pixels across: a light mesh is plenty, and a
        // long fine chain has hundreds of them.
        for (var i = 0; i < 12; i++) {
          final t = 2 * math.pi * i / 12;
          // A stadium: straight sides, round ends.
          final c = math.cos(t), s = math.sin(t);
          final x = a * c.sign * math.pow(c.abs(), 0.7).toDouble();
          var z = 0.0;
          if (style == ChainStyle.curb) {
            // Curb links are twisted so they lie flat when linked.
            z = 0.22 * width * s * c;
          }
          pts.add(V3(x, b * s, z));
        }
        mb.tube(pts, wire / 2, tag, sides: width < 1.4 ? 4 : 5, closed: true);
      case ChainStyle.box:
        final wall = width * 0.13;
        final h = width / 2 - wall / 2;
        final pts = <V3>[];
        for (var i = 0; i < 12; i++) {
          final t = 2 * math.pi * (i + 0.5) / 12;
          final c = math.cos(t), s = math.sin(t);
          pts.add(
            V3(
              h * c.sign * math.pow(c.abs(), 0.25).toDouble(),
              h * s.sign * math.pow(s.abs(), 0.25).toDouble(),
              0,
            ),
          );
        }
        final origins = pts, us = <V3>[], vs = <V3>[];
        for (final p in pts) {
          us.add(V3(p.x, p.y, 0).normalized);
          vs.add(V3.unitZ);
        }
        mb.sweep(
          origins: origins,
          us: us,
          vs: vs,
          profile: [
            (-wall / 2, -width * 0.42),
            (wall / 2, -width * 0.42),
            (wall / 2, width * 0.42),
            (-wall / 2, width * 0.42),
          ],
          closedPath: true,
          tagAt: (_, _) => tag,
        );
      case ChainStyle.rope:
        // Three strands, a third of a turn per segment: segments laid end
        // to end continue the twist seamlessly.
        final len = linkPitch(style, width);
        final r = width * 0.24, helix = width * 0.27;
        for (var k = 0; k < 3; k++) {
          final pts = <V3>[];
          for (var i = 0; i <= 6; i++) {
            final f = i / 6;
            final a = 2 * math.pi * (k / 3 + f / 3);
            pts.add(
              V3(
                -len * 0.55 + len * 1.1 * f,
                helix * math.cos(a),
                helix * math.sin(a),
              ),
            );
          }
          mb.tube(pts, r, tag, sides: 4, roundEnds: false);
        }
    }
    return mb.build();
  }

  // ---- Display velvet --------------------------------------------------

  /// A cylinder along z, rounded at both ends.
  static void rod(MeshBuilder mb, double radius, double halfLength) {
    final tag = JTag.velvet(1);
    mb.surface(
      40,
      16,
      (u, v) {
        final a = 2 * math.pi * u;
        return V3(
          radius * math.cos(a),
          radius * math.sin(a),
          -halfLength + 2 * halfLength * v,
        );
      },
      (_, _) => tag,
      closedU: true,
      outward: (p) => V3(p.x, p.y, 0),
    );
    for (final s in const [-1.0, 1.0]) {
      mb.surface(
        40,
        6,
        (u, v) {
          final a = 2 * math.pi * u, b = math.pi / 2 * v;
          final r = radius * math.cos(b);
          return V3(
            r * math.cos(a),
            r * math.sin(a),
            s * (halfLength + radius * 0.35 * math.sin(b)),
          );
        },
        (_, _) => tag,
        closedU: true,
        outward: (p) => V3(p.x * 0.2, p.y * 0.2, s),
      );
    }
  }
}
