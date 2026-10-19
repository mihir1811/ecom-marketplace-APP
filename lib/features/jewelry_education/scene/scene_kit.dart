import 'dart:math' as math;

import '../../diamond_education/domain/diamond_shape.dart';
import '../domain/jewelry_design.dart';
import '../geometry/jewelry_stone.dart';
import '../geometry/jmath.dart';
import '../geometry/jmesh.dart';
import '../physics/jewelry_physics.dart';

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

  /// The surface's outward normal at each of [touchOf]'s points.
  static List<V3> touchNormalsOf(JMesh mesh, {int samples = 90}) {
    final n = mesh.vertexCount;
    final step = math.max(1, n ~/ samples);
    return [
      for (var i = 0; i < n; i += step)
        V3(mesh.nrm[i * 3], mesh.nrm[i * 3 + 1], mesh.nrm[i * 3 + 2]),
    ];
  }

  /// Diamond weighs 0.2 g per carat.
  static double stoneGrams(double carat) => carat * 0.2;

  // ---- Chain links -----------------------------------------------------

  /// Centre-to-centre spacing of links in a chain [width] mm wide.
  static double linkPitch(ChainStyle style, double width) => switch (style) {
    ChainStyle.cable => width * 1.0,
    ChainStyle.curb || ChainStyle.figaro => width * 0.86,
    ChainStyle.box => width * 0.92,
    ChainStyle.rope => width * 0.9,
    ChainStyle.paperclip => width * 2.3,
    ChainStyle.snake => width * 0.5,
    ChainStyle.bead => width * 1.3,
  };

  /// How each link turns from the last.
  static JLinkTwist twistOf(ChainStyle style) => switch (style) {
    ChainStyle.cable ||
    ChainStyle.box ||
    ChainStyle.paperclip => JLinkTwist.alternate,
    _ => JLinkTwist.none,
  };

  /// A chain [length] mm long: the mesh of each link in order, their
  /// positions along it (null when evenly spaced at [linkPitch]) and the
  /// metal's volume, mm³. A figaro runs three short curb links, then one
  /// twice as long.
  static (List<JMesh>, List<double>?, double) chain(
    ChainStyle style,
    double width,
    double length,
  ) {
    final pitch = linkPitch(style, width);
    if (style != ChainStyle.figaro) {
      final mesh = link(style, width);
      final n = JChainSkin.linksFor(length, pitch);
      return (List.filled(n, mesh), null, mesh.volume * n);
    }
    final short = link(ChainStyle.curb, width);
    final long = link(ChainStyle.figaro, width);
    final meshes = <JMesh>[], at = <double>[];
    var volume = 0.0, pos = 0.0, prev = 0.0;
    for (var i = 0; ; i++) {
      final isLong = i % 4 == 3;
      final p = isLong ? pitch * 1.95 : pitch;
      if (i > 0) pos += (prev + p) / 2;
      if (pos > length - p / 2) break;
      meshes.add(isLong ? long : short);
      at.add(pos);
      volume += (isLong ? long : short).volume;
      prev = p;
    }
    return (meshes, at, volume);
  }

  /// One link (or, for rope, one twist of the cord) centred on the
  /// origin, running along x; the link's loop lies in the x–y plane.
  static JMesh link(ChainStyle style, double width) {
    final mb = MeshBuilder();
    final tag = JTag.metal(0.92);
    switch (style) {
      case ChainStyle.cable:
      case ChainStyle.curb:
      case ChainStyle.figaro:
      case ChainStyle.paperclip:
        final curb = style == ChainStyle.curb || style == ChainStyle.figaro;
        final wire =
            width *
            switch (style) {
              ChainStyle.curb || ChainStyle.figaro => 0.3,
              ChainStyle.paperclip => 0.17,
              _ => 0.27,
            };
        final long = switch (style) {
          ChainStyle.figaro => 3.2,
          ChainStyle.paperclip => 3.3,
          _ => 1.55,
        };
        final a = (width * long - wire) / 2,
            b = (width * (style == ChainStyle.paperclip ? 0.8 : 1) - wire) / 2;
        final pts = <V3>[];
        // Links are a few pixels across: a light mesh is plenty, and a
        // long fine chain has hundreds of them.
        for (var i = 0; i < 12; i++) {
          final t = 2 * math.pi * i / 12;
          // A stadium: straight sides, round ends.
          final c = math.cos(t), s = math.sin(t);
          final x = a * c.sign * math.pow(c.abs(), 0.7).toDouble();
          var z = 0.0;
          if (curb) {
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
      case ChainStyle.snake:
        // Close-fitting plates: a short drum per segment, slightly
        // waisted, so the whole reads as a smooth, scaled tube.
        final len = linkPitch(style, width) * 1.08;
        mb.surface(
          8,
          3,
          (u, v) {
            final a = 2 * math.pi * u;
            final r = width * 0.5 * (1 - 0.08 * math.sin(math.pi * v));
            return V3(-len / 2 + len * v, r * math.cos(a), r * math.sin(a));
          },
          (_, v) => JTag.metal(1 - 0.25 * (v - 0.5).abs()),
          closedU: true,
          outward: (p) => V3(0, p.y, p.z),
        );
        mb.solidVolume += math.pi * width * width / 4 * len * 0.8;
      case ChainStyle.bead:
        final pitch = linkPitch(style, width);
        mb
          ..sphere(V3.zero, width * 0.5, tag, segments: 8, rings: 5)
          ..tube(
            [V3(-pitch / 2, 0, 0), V3(pitch / 2, 0, 0)],
            width * 0.1,
            JTag.metal(0.8),
            sides: 4,
            roundEnds: false,
          );
    }
    return mb.build();
  }

  // ---- Findings: clasps, stations, charms ------------------------------

  static List<V3> _circle(V3 c, V3 a, V3 b, double r, int n) => [
    for (var i = 0; i < n; i++)
      c +
          a * (r * math.cos(2 * math.pi * i / n)) +
          b * (r * math.sin(2 * math.pi * i / n)),
  ];

  /// A clasp for a chain [width] mm wide, along x like a link, and its
  /// metal's volume, mm³.
  static (JMesh, double) clasp(ClaspStyle style, double width) {
    final mb = MeshBuilder();
    final tag = JTag.metal(1);
    final wire = math.max(0.35, width * 0.32);
    switch (style) {
      case ClaspStyle.lobster:
        // A teardrop body with its spring trigger, and the ring it bites.
        final l = 4.5 * width + 3.5, h = l * 0.42;
        final body = <V3>[];
        for (var i = 0; i < 20; i++) {
          final t = 2 * math.pi * i / 20;
          final c = math.cos(t), s = math.sin(t);
          body.add(V3(l / 2 * c, h / 2 * s * (0.75 + 0.25 * c), 0));
        }
        mb
          ..tube(body, wire * 1.15, tag, sides: 7, closed: true)
          ..tube(
            [V3(-l * 0.1, h * 0.38, 0), V3(-l * 0.1, h * 0.62, 0)],
            wire * 0.7,
            tag,
            sides: 5,
          )
          ..tube(
            _circle(V3(-l / 2 - wire - 1.1, 0, 0), V3.unitX, V3.unitZ, 1.1, 12),
            wire * 0.6,
            tag,
            sides: 5,
            closed: true,
          );
      case ClaspStyle.springRing:
        final r = 1.6 + width * 0.8;
        mb
          ..tube(
            _circle(V3.zero, V3.unitX, V3.unitY, r, 18),
            wire,
            tag,
            sides: 6,
            closed: true,
          )
          ..tube(
            [V3(r * 0.2, r, 0), V3(r * 0.2, r + wire * 2.4, 0)],
            wire * 0.8,
            tag,
            sides: 5,
          );
      case ClaspStyle.toggle:
        // A ring and the bar that passes through it.
        final r = 3.0 + width * 1.2;
        mb
          ..tube(
            _circle(V3.zero, V3.unitX, V3.unitY, r, 20),
            wire * 1.2,
            tag,
            sides: 7,
            closed: true,
          )
          ..tube(
            [V3(-r * 1.3, 0, wire * 2), V3(r * 1.3, 0, wire * 2)],
            wire * 1.1,
            tag,
            sides: 7,
          );
      case ClaspStyle.box:
        final hx = 2.2 + width * 1.2, hy = 1.4 + width * 0.6;
        mb
          ..roundedBox(
            V3.zero,
            V3(hx, hy, hy * 0.75),
            tag,
            roundness: 0.3,
            res: 8,
          )
          ..roundedBox(
            V3(hx * 0.2, hy * 1.02, 0),
            V3(hx * 0.3, 0.25, hy * 0.4),
            JTag.metal(0.85),
            roundness: 0.4,
            res: 5,
          );
    }
    return (mb.build(), mb.solidVolume);
  }

  /// A bezel-set diamond station on a chain: local x along the chain,
  /// table toward +z. Returns the mesh and its metal mm³.
  static (JMesh, double) station(double diameter) {
    final mb = MeshBuilder();
    mb.brilliant(
      V3(0, 0, diameter * 0.18),
      V3.unitZ,
      diameter,
      0.41,
      around: V3.unitX,
    );
    final r = diameter / 2 + 0.25;
    mb
      ..tube(
        _circle(V3(0, 0, diameter * 0.12), V3.unitX, V3.unitY, r, 18),
        0.32,
        JTag.metal(1),
        sides: 6,
        closed: true,
      )
      ..roundedBox(
        V3(0, 0, -diameter * 0.1),
        V3(r, r, diameter * 0.22),
        JTag.metal(0.8),
        roundness: 0.8,
        res: 8,
      );
    for (final sx in const [-1.0, 1.0]) {
      mb.tube(
        _circle(V3(sx * (r + 0.55), 0, -0.2), V3.unitX, V3.unitZ, 0.5, 10),
        0.22,
        JTag.metal(1),
        sides: 5,
        closed: true,
      );
    }
    return (mb.build(), mb.solidVolume);
  }

  /// A heart charm about [size] mm tall on its jump ring, hanging from
  /// the origin down −y, face toward +z. Returns the mesh and metal mm³.
  static (JMesh, double) charm(double size) {
    final mb = MeshBuilder();
    final k = size / 34;
    const n = 48;
    final outline = <V3>[];
    for (var i = 0; i < n; i++) {
      final t = 2 * math.pi * i / n;
      final s = math.sin(t);
      outline.add(
        V3(
          16 * s * s * s * k,
          (13 * math.cos(t) -
                  5 * math.cos(2 * t) -
                  2 * math.cos(3 * t) -
                  math.cos(4 * t)) *
              k,
          0,
        ),
      );
    }
    // The cleft at the top hangs under the jump ring.
    final top = outline.map((p) => p.y).reduce(math.max);
    final drop = V3(0, -top - 2.2, 0);
    const half = 0.55;
    for (final face in const [-1.0, 1.0]) {
      final c = mb.vertex(
        drop + V3(0, 0, face * half * 1.2),
        V3(0, 0, face),
        JTag.metal(1),
      );
      final ring = [
        for (final p in outline)
          mb.vertex(
            drop + p + V3(0, 0, face * half),
            V3(0, 0, face),
            JTag.metal(1),
          ),
      ];
      for (var i = 0; i < n; i++) {
        mb.tri(c, ring[i], ring[(i + 1) % n]);
      }
    }
    final edge = <int>[];
    for (var i = 0; i < n; i++) {
      final a = outline[(i - 1 + n) % n], b = outline[(i + 1) % n];
      final t = b - a;
      var nn = V3(t.y, -t.x, 0).normalized;
      if (nn.dot(outline[i] - V3(0, 2 * k, 0)) < 0) nn = -nn;
      for (final z in const [-half, half]) {
        edge.add(
          mb.vertex(drop + outline[i] + V3(0, 0, z), nn, JTag.metal(0.9)),
        );
      }
    }
    for (var i = 0; i < n; i++) {
      final j = (i + 1) % n;
      mb.quad(edge[i * 2], edge[j * 2], edge[j * 2 + 1], edge[i * 2 + 1]);
    }
    var area = 0.0;
    for (var i = 0; i < n; i++) {
      final a = outline[i], b = outline[(i + 1) % n];
      area += a.x * b.y - b.x * a.y;
    }
    mb.solidVolume += area.abs() / 2 * half * 2;
    // The jump ring, at right angles to the face.
    mb.tube(
      _circle(const V3(0, -1.1, 0), V3.unitY, V3.unitZ, 1.1, 14),
      0.3,
      JTag.metal(1),
      sides: 5,
      closed: true,
    );
    return (mb.build(), mb.solidVolume);
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
