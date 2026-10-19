import 'dart:math' as math;
import 'dart:typed_data';

import '../domain/jewelry_design.dart';
import '../domain/jewelry_metal.dart';
import '../geometry/jewelry_stone.dart';
import '../geometry/jmath.dart';
import '../geometry/jmesh.dart';
import '../physics/jewelry_physics.dart';

/// A mesh drawn wherever its [node] is.
class JPart {
  JPart(this.mesh, this.node);

  final JMesh mesh;
  final JNode node;
}

/// A centre stone traced by the diamond simulator's own renderer, held
/// at [local] (stone frame → node frame) on [node].
class JTracedStone {
  JTracedStone(this.stone, this.node, this.local);

  final JewelryStone stone;
  final JNode node;
  final Xf local;

  /// Stone frame → world, from the node's current transform.
  void worldTransform(Float64List out) {
    final l = Float64List(12);
    local.writeTo(l);
    M34.mul(node.xf, l, out);
  }
}

/// How the camera first frames a piece and how far it may orbit.
class JFraming {
  const JFraming({
    required this.focus,
    required this.radius,
    this.yaw = 0.5,
    this.pitch = 0.3,
    this.yawLimit,
    this.minPitch = -1.2,
    this.maxPitch = 1.35,
  });

  final V3 focus;

  /// Radius of the sphere that should fill the view at zoom 1.
  final double radius;
  final double yaw, pitch;

  /// Furthest the camera may swing either side, or null to circle freely.
  final double? yawLimit;
  final double minPitch, maxPitch;
}

/// What the piece weighs: shown beside it.
class JFacts {
  const JFacts({
    required this.metalGrams,
    required this.centreCarats,
    required this.accentCarats,
    required this.accentCount,
  });

  final double metalGrams;
  final double centreCarats, accentCarats;
  final int accentCount;
}

/// Everything the viewport shows and simulates for one design.
class JScene {
  JScene({
    required this.design,
    required this.parts,
    required this.stones,
    required this.physics,
    required this.framing,
    required this.facts,
  });

  final JewelryDesign design;
  final List<JPart> parts;
  final List<JTracedStone> stones;
  final JPhysics physics;
  final JFraming framing;
  final JFacts facts;

  /// The same geometry and motion in another metal, purity or finish:
  /// only the look and the weight change.
  JScene restyled(JewelryDesign next) {
    final ratio =
        next.metal.density(next.purity) / design.metal.density(design.purity);
    return JScene(
      design: next,
      parts: parts,
      stones: stones,
      physics: physics,
      framing: framing,
      facts: JFacts(
        metalGrams: facts.metalGrams * ratio,
        centreCarats: facts.centreCarats,
        accentCarats: facts.accentCarats,
        accentCount: facts.accentCount,
      ),
    );
  }
}

/// Running totals while a piece is built.
class JTally {
  double metalVolume = 0;
  double accentCarats = 0;
  int accentCount = 0;

  void accent(double diameterMm, [int count = 1]) {
    accentCount += count;
    accentCarats += JewelryStone.roundCarat(diameterMm) * count;
  }
}

/// Closed rounded rectangle profile, (u, v) points.
List<(double, double)> roundedRect(
  double u0,
  double u1,
  double v0,
  double v1,
  double r, {
  int steps = 3,
}) {
  r = math.min(r, math.min((u1 - u0) / 2, (v1 - v0) / 2));
  final out = <(double, double)>[];
  void corner(double cu, double cv, double a0) {
    for (var k = 0; k <= steps; k++) {
      final a = a0 + math.pi / 2 * k / steps;
      out.add((cu + r * math.cos(a), cv + r * math.sin(a)));
    }
  }

  corner(u1 - r, v0 + r, -math.pi / 2);
  corner(u1 - r, v1 - r, 0);
  corner(u0 + r, v1 - r, math.pi / 2);
  corner(u0 + r, v0 + r, math.pi);
  return out;
}

/// A ring band's cross-section: [t] thick (radially, u) and [w] wide
/// (along the finger, v), centred on (0, 0). Outer side is +u.
List<(double, double)> bandProfile(
  BandProfile p,
  double t,
  double w, {
  int steps = 28,
}) {
  // Superellipse exponents for the outside and inside halves: higher is
  // squarer. A comfort fit is domed outside and gently rounded inside.
  final (outer, inner, side) = switch (p) {
    BandProfile.comfort => (2.4, 2.6, 5.0),
    BandProfile.flat => (8.0, 8.0, 8.0),
    BandProfile.knifeEdge => (1.15, 6.0, 5.0),
    BandProfile.dShape => (2.0, 9.0, 6.0),
  };
  double sp(double v, double e) => v.sign * math.pow(v.abs(), 2 / e).toDouble();
  final out = <(double, double)>[];
  for (var k = 0; k < steps; k++) {
    final a = 2 * math.pi * k / steps;
    final c = math.cos(a), s = math.sin(a);
    final e = c >= 0 ? outer : inner;
    out.add((t / 2 * sp(c, e), w / 2 * sp(s, side)));
  }
  return out;
}
