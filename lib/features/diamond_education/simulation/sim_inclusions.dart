import 'dart:math' as math;
import 'dart:typed_data';

import '../domain/diamond_grades.dart';
import '../domain/inclusion_catalog.dart';
import 'sim_mesh.dart';

export '../domain/inclusion_catalog.dart';

/// Kinds of clarity characteristics the simulator draws.
///
/// [code] is how `shaders/diamond_trace.frag` tells them apart: the
/// tracer knows eight looks, and every other kind is traced as the one
/// closest to it. The line drawing plots each with its GIA key symbol
/// instead (`SimInclusionPlot`).
enum SimInclusionKind {
  /// A speck too small to resolve: a single sparkling white point.
  pinpoint(1, InclusionType.pinpoint, 4),

  /// A dark included mineral (graphite, sulphide): absorbs light.
  darkCrystal(2, InclusionType.carbon, 2.5),

  /// A transparent included mineral (olivine, garnet, diamond): bends
  /// and mirrors light at its faces.
  clearCrystal(3, InclusionType.crystal, 1.8),

  /// A thin fracture: mirrors light past diamond's critical angle, frosty
  /// and broken at its edges.
  feather(4, InclusionType.feather, 1.25),

  /// A hazy drift of countless pinpoints.
  cloud(5, InclusionType.cloud, 1.05),

  /// A thin rod-like crystal, bright white; often several together.
  needle(6, InclusionType.needle, 1.15),

  /// A feather filled with lead glass: the crack all but vanishes, but
  /// flashes orange and blue as the stone moves.
  filledFeather(7, InclusionType.filledFeather, 1.25),

  /// A feather that breaks the surface.
  openFeather(4, InclusionType.openFeather, 1.25),

  /// A diamond crystal cut through at the surface.
  knot(3, InclusionType.knot, 1.8),

  /// An angular hole in the surface.
  cavity(4, InclusionType.cavity, 1.35),

  /// A shallow, shell-like break at the girdle edge.
  chip(4, InclusionType.chip, 1.35),

  /// A crushed point at a facet junction with root-like feathers.
  bruise(4, InclusionType.bruise, 1.6),

  /// Hair-fine feathers running in from the girdle.
  bearding(4, InclusionType.bearding, 1.5),

  /// The rough's skin dipping below the girdle.
  indentedNatural(4, InclusionType.indentedNatural, 1.35),

  /// Faint planes of irregular growth.
  graining(5, InclusionType.graining, 1.2),

  /// A twisted ribbon of pinpoints along a twin plane.
  twinningWisp(5, InclusionType.twinningWisp, 1.2),

  /// A hollow, kinked tunnel dissolved in from the surface.
  etchChannel(6, InclusionType.etchChannel, 1.25),

  /// A straight laser-bored tunnel from the surface to a crystal.
  laserDrillHole(6, InclusionType.laserDrillHole, 1.1),

  /// A dark crystal bleached through a drill hole; drawn as part of the
  /// hole, never labelled on its own.
  bleachedCrystal(3, InclusionType.laserDrillHole, 1.8),

  /// A feather along a cleavage plane.
  cleavage(4, InclusionType.cleavage, 1.25),

  /// A small knot of distorted growth: a faint haze.
  grainCenter(5, InclusionType.grainCenter, 1.05),

  /// A row of tiny nicks along a facet junction: a fuzzy white line.
  abrasion(6, InclusionType.abrasion, 1.15),

  /// The rough's skin left on the girdle.
  natural(4, InclusionType.natural, 1.35),

  /// A small notch at the girdle edge.
  nick(4, InclusionType.nick, 1.35),

  /// A tiny opening in a facet: a white speck.
  pit(1, InclusionType.pit, 4),

  /// Fine parallel lines left by polishing.
  polishLines(6, InclusionType.polishLines, 1.15),

  /// A hazy patch from heat while polishing.
  burnMark(5, InclusionType.burnMark, 1.05),

  /// A fine line scratched into a facet.
  scratch(6, InclusionType.scratch, 1.15),

  /// Growth lines where they cross the polished surface.
  surfaceGraining(6, InclusionType.surfaceGraining, 1.15),

  /// A small facet polished where none belongs: a flat mirror.
  extraFacet(8, InclusionType.extraFacet, 1.35);

  const SimInclusionKind(this.code, this.type, this.reach);

  final int code;

  /// The characteristic it shows, for its label.
  final InclusionType type;

  /// Bounding radius in units of [SimInclusion.size].
  final double reach;

  bool get labelled => this != SimInclusionKind.bleachedCrystal;
}

/// How many of each inclusion a grade holds, and their size scale.
typedef _Mix = ({
  int pin,
  int needle,
  int dark,
  int clear,
  int feather,
  int cloud,
  double s,
});

//// One clarity characteristic inside the stone, model space.
class SimInclusion {
  const SimInclusion({
    required this.kind,
    required this.x,
    required this.y,
    required this.z,
    required this.size,
    this.ax = 0,
    this.ay = 1,
    this.az = 0,
    this.seed = 0,
    this.sx = 0,
    this.sy = 0,
    this.sz = 0,
    this.sd = 0,
  });

  final SimInclusionKind kind;
  final double x, y, z;

  /// Radius (crystals, pinpoints, feathers, clouds, openings), half
  /// length (needles, tunnels, ribbons) or half span along the girdle
  /// (bearding, an indented natural), model units.
  final double size;

  /// Unit axis: a feather's plane normal, a crystal's or needle's long
  /// axis, the axis a cloud is flattened along, a tunnel's direction out
  /// toward its opening, the girdle's run for bearding.
  final double ax, ay, az;

  /// 0..1; varies outline, habit and tint between inclusions.
  final double seed;

  /// The facet an open characteristic breaks, `s · p = sd` with outward
  /// unit normal s; zero for one wholly inside the stone.
  final double sx, sy, sz, sd;

  bool get open => sx != 0 || sy != 0 || sz != 0;

  SimInclusion resized(double size) => copy(size: size);

  SimInclusion as(SimInclusionKind kind) => copy(kind: kind);

  SimInclusion copy({
    SimInclusionKind? kind,
    double? x,
    double? y,
    double? z,
    double? size,
    (double, double, double)? axis,
    (double, double, double, double)? surface,
  }) => SimInclusion(
    kind: kind ?? this.kind,
    x: x ?? this.x,
    y: y ?? this.y,
    z: z ?? this.z,
    size: size ?? this.size,
    ax: axis?.$1 ?? ax,
    ay: axis?.$2 ?? ay,
    az: axis?.$3 ?? az,
    seed: seed,
    sx: surface?.$1 ?? sx,
    sy: surface?.$2 ?? sy,
    sz: surface?.$3 ?? sz,
    sd: surface?.$4 ?? sd,
  );
}

typedef _V = (double, double, double);

/// Places inclusions for a clarity grade. Deterministic per grade, so
/// stepping between grades reads as the stone getting cleaner or more
/// included, and placement follows the stone through proportion changes.
///
/// Sizes follow how graders see them in a one carat stone (the stone is
/// two units wide, so a unit is about 3.2 mm): VVS points of a few
/// hundredths of a millimetre, VS crystals and feathers around a tenth,
/// SI ones up to half a millimetre, I grades millimetre-scale crystals
/// and fractures with clouds that dull the stone.
abstract final class SimInclusions {
  /// Inclusion slots in the tracer (`diamond_trace.frag`).
  static const maxCount = 12;

  /// Most inclusions a stone holds: enough for every kind at once. The
  /// line drawing plots them all; the tracer the first [maxCount].
  static const maxShown = 36;

  /// How much larger than true scale inclusions are drawn.
  static const visibility = 1.8;

  /// [only] limits the stone to those kinds, each placed where it is
  /// easy to tell apart and large enough to see (null keeps the grade's
  /// usual mix). Kinds that reach the surface are cut into it where they
  /// typically occur: feathers, chips and bearding at the girdle, knots,
  /// cavities and bruises on the crown. Flawless grades stay clean.
  /// [enhancement] applies treatments that work on inclusions, adding
  /// what each one treats if the stone lacks it: fracture filling fills
  /// feathers with glass (only an open crack can take it, so each is
  /// opened to the surface); laser drilling bleaches dark crystals and
  /// leaves a fine tunnel out to the nearest facet.
  ///
  /// Sizes are enlarged over true scale ([visibility]) so they read on a
  /// phone screen: at true scale a VS crystal is a pixel or less.
  static List<SimInclusion> generate(
    SimMesh mesh,
    ClarityGrade grade, {
    Set<InclusionType>? only,
    Enhancement enhancement = Enhancement.none,
  }) {
    final mix = _mix(grade);
    if (mix == null) return const [];
    final filling = enhancement == Enhancement.fractureFilling;
    final drilling = enhancement == Enhancement.laserDrilling;
    var out = <SimInclusion>[];
    if (only != null) {
      final s = math.max(mix.s, 3.4) * visibility;
      out = _specimens(mesh, only, s);
      final has = out.map((c) => c.kind).toSet();
      // A treatment needs something to treat.
      if (filling &&
          !has.contains(SimInclusionKind.feather) &&
          !has.contains(SimInclusionKind.openFeather) &&
          !has.contains(SimInclusionKind.filledFeather)) {
        out.addAll(_specimens(mesh, {InclusionType.feather}, s));
      }
      if (drilling && !has.contains(SimInclusionKind.darkCrystal)) {
        out.addAll(_specimens(mesh, {InclusionType.carbon}, s));
      }
    } else {
      final picked = filling || drilling;
      final r = (
        pin: mix.pin,
        needle: mix.needle,
        dark: math.max(mix.dark, drilling ? 2 : 0),
        clear: mix.clear,
        feather: math.max(mix.feather, filling ? 2 : 0),
        cloud: mix.cloud,
        s: (picked ? math.max(mix.s, 3.4) : mix.s) * visibility,
      );
      out = _place(mesh, grade, r, central: picked, pinScale: picked ? 4 : 1.8);
    }
    if (filling) out = _fill(mesh, out);
    if (drilling) out = _drill(mesh, out);
    return out.take(maxShown).toList();
  }

  /// Fills every feather with glass, first opening any closed one to the
  /// nearest facet: filler can only enter a crack that reaches the
  /// surface.
  static List<SimInclusion> _fill(SimMesh mesh, List<SimInclusion> found) => [
    for (final c in found)
      switch (c.kind) {
        SimInclusionKind.feather => breakSurface(
          mesh,
          c,
        ).as(SimInclusionKind.filledFeather),
        SimInclusionKind.openFeather => c.as(SimInclusionKind.filledFeather),
        _ => c,
      },
  ];

  /// Bleaches dark crystals and bores a tunnel from each out to the
  /// nearest facet, as a laser does to reach and dissolve them.
  static List<SimInclusion> _drill(SimMesh mesh, List<SimInclusion> found) {
    final out = <SimInclusion>[];
    final holes = <SimInclusion>[];
    for (final c in found) {
      if (c.kind != SimInclusionKind.darkCrystal) {
        out.add(c);
        continue;
      }
      out.add(c.as(SimInclusionKind.bleachedCrystal));
      final hole = _drillHole(mesh, (c.x, c.y, c.z), c.seed);
      if (hole != null) holes.add(hole);
    }
    // Tunnels before the smallest specks if slots run out.
    return [
      ...out.take(maxShown - holes.length),
      ...holes,
    ].take(maxShown).toList();
  }

  /// A drill hole from [from] out to the facet nearest it.
  static SimInclusion? _drillHole(SimMesh mesh, _V from, double seed) {
    final (n, _) = _nearestPlane(mesh, from.$1, from.$2, from.$3);
    // Lasers enter a little off the facet's normal.
    final dir = _norm((n.$1 + 0.18 * (seed - 0.5), n.$2, n.$3));
    final exit = _exit(mesh, from, dir);
    if (exit == null) return null;
    final (len, plane) = exit;
    final half = len / 2;
    if (half < 0.02) return null;
    return SimInclusion(
      kind: SimInclusionKind.laserDrillHole,
      x: from.$1 + dir.$1 * half,
      y: from.$2 + dir.$2 * half,
      z: from.$3 + dir.$3 * half,
      size: half,
      ax: dir.$1,
      ay: dir.$2,
      az: dir.$3,
      seed: seed,
      sx: plane.$1,
      sy: plane.$2,
      sz: plane.$3,
      sd: plane.$4,
    );
  }

  /// [c] moved so it breaks the facet nearest it: centre just inside,
  /// its plane turned to run in from the surface.
  static SimInclusion breakSurface(SimMesh mesh, SimInclusion c) {
    if (c.open) return c;
    final (n, d) = _nearestPlane(mesh, c.x, c.y, c.z);
    final depth = d - (n.$1 * c.x + n.$2 * c.y + n.$3 * c.z);
    final move = depth - c.size * 0.35;
    final at = (c.x + n.$1 * move, c.y + n.$2 * move, c.z + n.$3 * move);
    // Across the surface: the crack's plane holds the facet's normal.
    final dot = c.ax * n.$1 + c.ay * n.$2 + c.az * n.$3;
    var axis = (c.ax - n.$1 * dot, c.ay - n.$2 * dot, c.az - n.$3 * dot);
    if (_len(axis) < 1e-3) axis = _cross(n, (0, 1, 0));
    if (_len(axis) < 1e-3) axis = _cross(n, (1, 0, 0));
    return c.copy(
      x: at.$1,
      y: at.$2,
      z: at.$3,
      axis: _norm(axis),
      surface: (n.$1, n.$2, n.$3, d),
    );
  }

  /// One (or, for a short list, two) of each chosen kind, each in its own
  /// place so it can be told apart and labelled: a kind always sits in
  /// the same place, whatever else is chosen, so picking another never
  /// moves the rest. Closed kinds sit around the stone at alternating
  /// heights; open ones where each typically breaks the surface.
  static List<SimInclusion> _specimens(
    SimMesh mesh,
    Set<InclusionType> types,
    double s,
  ) {
    // A little over true scale even here: the stone is small on a phone
    // with labels either side.
    final k = s / (3.4 * visibility) * 1.25;
    final copies = types.length <= 3 ? 2 : 1;
    final out = <SimInclusion>[];
    for (final t in InclusionType.values) {
      if (!types.contains(t)) continue;
      for (var copy = 0; copy < copies; copy++) {
        out.addAll(_specimen(mesh, t, copy, k));
      }
    }
    return out;
  }

  /// Closed kinds, in their places around the stone.
  static const _closedSlots = [
    InclusionType.crystal,
    InclusionType.carbon,
    InclusionType.feather,
    InclusionType.cloud,
    InclusionType.pinpoint,
    InclusionType.needle,
    InclusionType.graining,
    InclusionType.twinningWisp,
    InclusionType.cleavage,
    InclusionType.grainCenter,
  ];

  /// Open kinds, in their places around the stone.
  static const _openSlots = [
    InclusionType.openFeather,
    InclusionType.knot,
    InclusionType.cavity,
    InclusionType.chip,
    InclusionType.bruise,
    InclusionType.bearding,
    InclusionType.indentedNatural,
    InclusionType.etchChannel,
    InclusionType.laserDrillHole,
    InclusionType.filledFeather,
  ];

  /// External characteristics (blemishes), in their places around the
  /// stone.
  static const _surfaceSlots = giaExternalKey;

  static List<SimInclusion> _specimen(
    SimMesh mesh,
    InclusionType type,
    int copy,
    double k,
  ) {
    final rng = math.Random(977 + type.index * 131 + copy * 17);
    final seed = rng.nextDouble() * 0.999;
    final girdleY = _girdleY(mesh);
    final closedSlot = _closedSlots.indexOf(type);
    if (closedSlot >= 0) {
      final az =
          closedSlot * 2 * math.pi / _closedSlots.length +
          0.35 +
          copy * math.pi;
      final high = (closedSlot + copy).isEven;
      final (kind, size, axis) = switch (type) {
        InclusionType.crystal => (
          SimInclusionKind.clearCrystal,
          0.095,
          _axis(rng),
        ),
        InclusionType.carbon => (
          SimInclusionKind.darkCrystal,
          0.09,
          _axis(rng, flat: 0.5),
        ),
        InclusionType.feather => (SimInclusionKind.feather, 0.24, _faceUp(rng)),
        InclusionType.cloud => (
          SimInclusionKind.cloud,
          0.2,
          _axis(rng, flat: 0.4),
        ),
        InclusionType.pinpoint => (SimInclusionKind.pinpoint, 0.02, _axis(rng)),
        InclusionType.needle => (
          SimInclusionKind.needle,
          0.17,
          _axis(rng, flat: 0.5),
        ),
        InclusionType.graining => (
          SimInclusionKind.graining,
          0.28,
          _axis(rng, flat: 0.6),
        ),
        InclusionType.cleavage => (
          SimInclusionKind.cleavage,
          0.22,
          _faceUp(rng),
        ),
        InclusionType.grainCenter => (
          SimInclusionKind.grainCenter,
          0.09,
          _axis(rng),
        ),
        _ => (SimInclusionKind.twinningWisp, 0.27, _axis(rng, flat: 0.5)),
      };
      final r = size * k;
      final at = _inside(
        mesh,
        az,
        reach: high ? 0.5 : 0.42,
        y: high
            ? girdleY + mesh.crownHeight * 0.4
            : girdleY - mesh.pavilionDepth * 0.28,
        margin: switch (kind) {
          SimInclusionKind.clearCrystal ||
          SimInclusionKind.darkCrystal => r * 1.6,
          SimInclusionKind.feather ||
          SimInclusionKind.cleavage ||
          SimInclusionKind.graining => r * 0.15,
          SimInclusionKind.pinpoint => 0.03,
          _ => r * 0.4,
        },
      );
      return [
        SimInclusion(
          kind: kind,
          x: at.$1,
          y: at.$2,
          z: at.$3,
          size: r,
          ax: axis.$1,
          ay: axis.$2,
          az: axis.$3,
          seed: seed,
        ),
      ];
    }

    final found = _surfaceSlots.contains(type)
        ? _surfaceSpecimen(mesh, type, copy, k, rng, seed, girdleY)
        : _openSpecimen(mesh, type, copy, k, rng, seed, girdleY);
    return [for (final c in found) _pullIn(mesh, c)];
  }

  /// A blemish where it typically shows: naturals and nicks on the
  /// girdle, abrasions along a facet junction, pits, polish lines and
  /// burn marks on the crown, scratches on the table, surface graining
  /// and extra facets on the pavilion.
  static List<SimInclusion> _surfaceSpecimen(
    SimMesh mesh,
    InclusionType type,
    int copy,
    double k,
    math.Random rng,
    double seed,
    double girdleY,
  ) {
    final slot = _surfaceSlots.indexOf(type);
    final az = slot * 2 * math.pi / _surfaceSlots.length + 0.2 + copy * math.pi;
    final top = _topY(mesh);
    final hx = mesh.length / 2, hz = mesh.width / 2;
    final cs = math.cos(az), sn = math.sin(az);
    final hit = switch (type) {
      InclusionType.natural => _girdlePoint(mesh, az, girdleY),
      InclusionType.nick => _girdlePoint(
        mesh,
        az,
        girdleY + mesh.girdleThickness * 0.5,
      ),
      InclusionType.abrasion ||
      InclusionType.pit ||
      InclusionType.polishLines ||
      InclusionType.burnMark => _crownPoint(mesh, az, girdleY, top),
      InclusionType.scratch => _cast(
        mesh,
        (cs * hx * 0.18, girdleY + (top - girdleY) * 0.5, sn * hz * 0.18),
        (0, 1, 0),
      ),
      InclusionType.extraFacet => _cast(mesh, (
        cs * hx * 0.5,
        girdleY - mesh.pavilionDepth * 0.1,
        sn * hz * 0.5,
      ), _norm((cs, -0.45, sn))),
      _ => _cast(mesh, (
        cs * hx * 0.35,
        girdleY - mesh.pavilionDepth * 0.25,
        sn * hz * 0.35,
      ), _norm((cs * 0.6, -1, sn * 0.6))),
    };
    if (hit == null) return const [];
    var (p, n, d) = hit;
    if (type == InclusionType.abrasion) {
      // Abrasions wear along the junctions where facets meet.
      final v = _nearestCorner(mesh, p, girdleY);
      if (v != null) {
        final (nn, dd) = _nearestPlane(mesh, v.$1, v.$2, v.$3);
        (p, n, d) = (v, nn, dd);
      }
    }
    final r =
        switch (type) {
          InclusionType.pit => 0.022,
          InclusionType.nick => 0.06,
          InclusionType.natural => 0.09,
          InclusionType.burnMark => 0.1,
          InclusionType.extraFacet => 0.08,
          InclusionType.scratch => 0.15,
          InclusionType.surfaceGraining => 0.16,
          _ => 0.12,
        } *
        k;
    final girdleRun = _norm(_cross(n, (0, 1, 0)));
    final (kind, axis, depth) = switch (type) {
      InclusionType.natural => (SimInclusionKind.natural, girdleRun, 0.006),
      InclusionType.nick => (SimInclusionKind.nick, girdleRun, 0.006),
      InclusionType.pit => (SimInclusionKind.pit, (-n.$1, -n.$2, -n.$3), 0.006),
      // A burn is a haze flattened against its facet.
      InclusionType.burnMark => (SimInclusionKind.burnMark, n, r * 0.45),
      // An extra facet is a small flat tipped off the facet it cuts.
      InclusionType.extraFacet => (
        SimInclusionKind.extraFacet,
        _norm((n.$1 + 0.3 * sn, n.$2 + 0.25, n.$3 - 0.3 * cs)),
        0.012,
      ),
      // The rest are lines along the facet.
      _ => (
        switch (type) {
          InclusionType.abrasion => SimInclusionKind.abrasion,
          InclusionType.polishLines => SimInclusionKind.polishLines,
          InclusionType.scratch => SimInclusionKind.scratch,
          _ => SimInclusionKind.surfaceGraining,
        },
        _tangent(n, rng.nextDouble() * math.pi),
        0.006,
      ),
    };
    final c = _inward(p, n, depth);
    return [
      SimInclusion(
        kind: kind,
        x: c.$1,
        y: c.$2,
        z: c.$3,
        size: r,
        ax: axis.$1,
        ay: axis.$2,
        az: axis.$3,
        seed: seed,
        sx: n.$1,
        sy: n.$2,
        sz: n.$3,
        sd: d,
      ),
    ];
  }

  /// Where the ray from [from] (inside) along unit [dir] leaves the
  /// stone: the point and the facet there.
  static (_V, _V, double)? _cast(SimMesh mesh, _V from, _V dir) {
    final exit = _exit(mesh, from, dir);
    if (exit == null) return null;
    final (t, plane) = exit;
    return (
      (from.$1 + dir.$1 * t, from.$2 + dir.$2 * t, from.$3 + dir.$3 * t),
      (plane.$1, plane.$2, plane.$3),
      plane.$4,
    );
  }

  /// A unit vector square to unit [n], turned by [a] about it.
  static _V _tangent(_V n, double a) {
    final u = _norm(_cross(n, n.$2.abs() < 0.9 ? (0, 1, 0) : (1, 0, 0)));
    final v = _cross(n, u);
    final c = math.cos(a), s = math.sin(a);
    return _norm((
      u.$1 * c + v.$1 * s,
      u.$2 * c + v.$2 * s,
      u.$3 * c + v.$3 * s,
    ));
  }

  /// [c] nudged toward the stone's axis until it is clear inside: at a
  /// corner (a radiant's, a princess's) a point just under one facet can
  /// lie beyond its neighbour.
  static SimInclusion _pullIn(SimMesh mesh, SimInclusion c) {
    const margin = 0.004;
    if (mesh.inset(c.x, c.y, c.z) > margin) return c;
    final y0 = _girdleY(mesh);
    for (var f = 0.96; f > 0.3; f -= 0.04) {
      final x = c.x * f, y = y0 + (c.y - y0) * f, z = c.z * f;
      if (mesh.inset(x, y, z) > margin) return c.copy(x: x, y: y, z: z);
    }
    return c.copy(x: 0, y: y0, z: 0);
  }

  static List<SimInclusion> _openSpecimen(
    SimMesh mesh,
    InclusionType type,
    int copy,
    double k,
    math.Random rng,
    double seed,
    double girdleY,
  ) {
    final slot = _openSlots.indexOf(type);
    final az = slot * 2 * math.pi / _openSlots.length + 0.9 + copy * math.pi;
    final top = _topY(mesh);

    switch (type) {
      case InclusionType.openFeather || InclusionType.filledFeather:
        final g = _girdlePoint(mesh, az, girdleY);
        if (g == null) return const [];
        final r = 0.24 * k;
        final (p, n, d) = g;
        // The crack runs in from the girdle, tipped off the horizontal.
        final tangent = _norm(_cross(n, (0, 1, 0)));
        final normal = _norm((
          tangent.$1,
          0.35 + 0.4 * rng.nextDouble(),
          tangent.$3,
        ));
        final c = _inward(p, n, r * 0.32);
        return [
          SimInclusion(
            kind: type == InclusionType.openFeather
                ? SimInclusionKind.openFeather
                : SimInclusionKind.filledFeather,
            x: c.$1,
            y: c.$2,
            z: c.$3,
            size: r,
            ax: normal.$1,
            ay: normal.$2,
            az: normal.$3,
            seed: seed,
            sx: n.$1,
            sy: n.$2,
            sz: n.$3,
            sd: d,
          ),
        ];
      case InclusionType.chip ||
          InclusionType.bearding ||
          InclusionType.indentedNatural:
        // Chips at the girdle's edge with the crown, the rest across it.
        final y = type == InclusionType.chip
            ? girdleY + mesh.girdleThickness * 0.5
            : girdleY;
        final g = _girdlePoint(mesh, az, y);
        if (g == null) return const [];
        final (p, n, d) = g;
        final r =
            switch (type) {
              InclusionType.chip => 0.1,
              InclusionType.bearding => 0.22,
              _ => 0.09,
            } *
            k;
        final tangent = _norm(_cross(n, (0, 1, 0)));
        final c = _inward(p, n, 0.006);
        return [
          SimInclusion(
            kind: switch (type) {
              InclusionType.chip => SimInclusionKind.chip,
              InclusionType.bearding => SimInclusionKind.bearding,
              _ => SimInclusionKind.indentedNatural,
            },
            x: c.$1,
            y: c.$2,
            z: c.$3,
            size: r,
            ax: tangent.$1,
            ay: tangent.$2,
            az: tangent.$3,
            seed: seed,
            sx: n.$1,
            sy: n.$2,
            sz: n.$3,
            sd: d,
          ),
        ];
      case InclusionType.knot ||
          InclusionType.cavity ||
          InclusionType.bruise ||
          InclusionType.etchChannel:
        final hit = _crownPoint(mesh, az, girdleY, top);
        if (hit == null) return const [];
        var (p, n, d) = hit;
        if (type == InclusionType.bruise) {
          // Bruises form where facets meet: at the nearest crown corner.
          final v = _nearestCorner(mesh, p, girdleY);
          if (v != null) {
            final (nn, dd) = _nearestPlane(mesh, v.$1, v.$2, v.$3);
            (p, n, d) = (v, nn, dd);
          }
        }
        final r =
            switch (type) {
              InclusionType.knot => 0.1,
              InclusionType.cavity => 0.075,
              InclusionType.bruise => 0.075,
              _ => 0.17,
            } *
            k;
        final c = switch (type) {
          InclusionType.knot => _inward(p, n, r * 0.4),
          InclusionType.etchChannel => _inward(p, n, r * 0.95),
          _ => _inward(p, n, r * 0.05 + 0.004),
        };
        // A tunnel runs out toward its opening, a little off the normal.
        final axis = switch (type) {
          InclusionType.etchChannel => _norm((
            n.$1 + 0.3 * (rng.nextDouble() - 0.5),
            n.$2,
            n.$3 + 0.3 * (rng.nextDouble() - 0.5),
          )),
          InclusionType.knot => _axis(rng),
          _ => (-n.$1, -n.$2, -n.$3),
        };
        return [
          SimInclusion(
            kind: switch (type) {
              InclusionType.knot => SimInclusionKind.knot,
              InclusionType.cavity => SimInclusionKind.cavity,
              InclusionType.bruise => SimInclusionKind.bruise,
              _ => SimInclusionKind.etchChannel,
            },
            x: c.$1,
            y: c.$2,
            z: c.$3,
            size: r,
            ax: axis.$1,
            ay: axis.$2,
            az: axis.$3,
            // A knot is diamond: colourless in the tracer's tints.
            seed: type == InclusionType.knot ? seed * 0.6 : seed,
            sx: n.$1,
            sy: n.$2,
            sz: n.$3,
            sd: d,
          ),
        ];
      case InclusionType.laserDrillHole:
        // A bleached crystal well inside, bored out to its nearest facet.
        final at = _inside(
          mesh,
          az,
          reach: 0.32,
          y: girdleY + mesh.crownHeight * 0.15,
          margin: 0.12,
        );
        final crystal = SimInclusion(
          kind: SimInclusionKind.bleachedCrystal,
          x: at.$1,
          y: at.$2,
          z: at.$3,
          size: 0.07 * k,
          seed: seed * 0.6,
        );
        final hole = _drillHole(mesh, at, seed);
        return [crystal, ?hole];
      default:
        return const [];
    }
  }

  /// A point at azimuth [az], [reach] of the way out to the girdle at
  /// height [y], pulled in until it is [margin] clear of every facet.
  static _V _inside(
    SimMesh mesh,
    double az, {
    required double reach,
    required double y,
    required double margin,
  }) {
    final hx = mesh.length / 2, hz = mesh.width / 2;
    for (var r = reach; r > 0.02; r *= 0.85) {
      final x = math.cos(az) * hx * r, z = math.sin(az) * hz * r;
      if (mesh.inset(x, y, z) > margin) return (x, y, z);
    }
    // On the axis just above the girdle: always well inside.
    return (0, _girdleY(mesh) + mesh.crownHeight * 0.1, 0);
  }

  /// Height of the girdle's middle.
  static double _girdleY(SimMesh mesh) =>
      _topY(mesh) - mesh.crownHeight - mesh.girdleThickness / 2;

  static double _topY(SimMesh mesh) {
    final pos = mesh.positions;
    var top = -double.infinity;
    for (var i = 1; i < pos.length; i += 3) {
      top = math.max(top, pos[i]);
    }
    return top;
  }

  /// Where the girdle is at azimuth [az] and height [y]: the point, and
  /// the facet there (outward normal, offset).
  static (_V, _V, double)? _girdlePoint(SimMesh mesh, double az, double y) {
    final from = (0.0, y, 0.0);
    final dir = _norm((
      math.cos(az) * mesh.length / 2,
      0,
      math.sin(az) * mesh.width / 2,
    ));
    final exit = _exit(mesh, from, dir);
    if (exit == null) return null;
    final (t, plane) = exit;
    return (
      (from.$1 + dir.$1 * t, from.$2 + dir.$2 * t, from.$3 + dir.$3 * t),
      (plane.$1, plane.$2, plane.$3),
      plane.$4,
    );
  }

  /// Where a line up and out from inside the crown at azimuth [az] meets
  /// the crown: the point and the facet there.
  static (_V, _V, double)? _crownPoint(
    SimMesh mesh,
    double az,
    double girdleY,
    double top,
  ) {
    final hx = mesh.length / 2, hz = mesh.width / 2;
    final from = (
      math.cos(az) * hx * 0.45,
      girdleY + (top - girdleY) * 0.3,
      math.sin(az) * hz * 0.45,
    );
    if (mesh.inset(from.$1, from.$2, from.$3) <= 0) return null;
    final dir = _norm((math.cos(az) * 0.55, 1, math.sin(az) * 0.55));
    final exit = _exit(mesh, from, dir);
    if (exit == null) return null;
    final (t, plane) = exit;
    return (
      (from.$1 + dir.$1 * t, from.$2 + dir.$2 * t, from.$3 + dir.$3 * t),
      (plane.$1, plane.$2, plane.$3),
      plane.$4,
    );
  }

  /// The crown corner nearest [p], nudged just inside the stone.
  static _V? _nearestCorner(SimMesh mesh, _V p, double girdleY) {
    final pos = mesh.positions;
    _V? best;
    var bestD = double.infinity;
    for (var i = 0; i < pos.length; i += 3) {
      final y = pos[i + 1];
      if (y < girdleY + mesh.girdleThickness) continue;
      final dx = pos[i] - p.$1, dy = y - p.$2, dz = pos[i + 2] - p.$3;
      final d = dx * dx + dy * dy + dz * dz;
      if (d < bestD) {
        bestD = d;
        best = (pos[i], y, pos[i + 2]);
      }
    }
    if (best == null) return null;
    final toC = _norm((-best.$1, girdleY - best.$2, -best.$3));
    final v = _inward(best, toC, -0.006);
    return mesh.inset(v.$1, v.$2, v.$3) > 0 ? v : null;
  }

  /// How far from [from] (inside) along unit [dir] the stone ends, and
  /// the facet it leaves through.
  static (double, (double, double, double, double))? _exit(
    SimMesh mesh,
    _V from,
    _V dir,
  ) {
    double at(double t) => mesh.inset(
      from.$1 + dir.$1 * t,
      from.$2 + dir.$2 * t,
      from.$3 + dir.$3 * t,
    );
    if (at(0) <= 0) return null;
    var lo = 0.0, hi = 0.25;
    while (at(hi) > 0) {
      lo = hi;
      hi *= 2;
      if (hi > 8) return null;
    }
    for (var i = 0; i < 40; i++) {
      final mid = (lo + hi) / 2;
      if (at(mid) > 0) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    final (n, d) = _nearestPlane(
      mesh,
      from.$1 + dir.$1 * lo,
      from.$2 + dir.$2 * lo,
      from.$3 + dir.$3 * lo,
    );
    return (lo, (n.$1, n.$2, n.$3, d));
  }

  /// The facet plane nearest (x, y, z) inside the stone: its outward unit
  /// normal and offset, unfolded for a mirrored heart.
  static (_V, double) _nearestPlane(
    SimMesh mesh,
    double x,
    double y,
    double z,
  ) {
    final (fx, fz) = SimMesh.foldIn(mesh.fold, x, z);
    final planes = mesh.planes;
    var best = double.infinity;
    var f = 0;
    for (var i = 0; i < mesh.tracedFacets; i++) {
      final d =
          planes[i * 4 + 3] -
          (planes[i * 4] * fx + planes[i * 4 + 1] * y + planes[i * 4 + 2] * fz);
      if (d < best) {
        best = d;
        f = i;
      }
    }
    var nx = planes[f * 4];
    final ny = planes[f * 4 + 1], nz = planes[f * 4 + 2];
    if (mesh.fold == 1 && x < 0) nx = -nx;
    return ((nx, ny, nz), planes[f * 4 + 3]);
  }

  /// The facet nearest an inclusion, as [SimFacetKind]: where a grader
  /// would say it sits.
  static SimFacetKind nearestFacet(SimMesh mesh, SimInclusion c) {
    final (fx, fz) = SimMesh.foldIn(mesh.fold, c.x, c.z);
    final planes = mesh.planes;
    var best = double.infinity;
    var f = 0;
    for (var i = 0; i < mesh.tracedFacets; i++) {
      final d =
          planes[i * 4 + 3] -
          (planes[i * 4] * fx +
              planes[i * 4 + 1] * c.y +
              planes[i * 4 + 2] * fz);
      if (d < best) {
        best = d;
        f = i;
      }
    }
    return SimFacetKind.values[mesh.kinds[f]];
  }

  static _V _inward(_V p, _V n, double by) =>
      (p.$1 - n.$1 * by, p.$2 - n.$2 * by, p.$3 - n.$3 * by);

  static double _len(_V v) =>
      math.sqrt(v.$1 * v.$1 + v.$2 * v.$2 + v.$3 * v.$3);

  static _V _norm(_V v) {
    final l = _len(v);
    return l < 1e-12 ? (0, 1, 0) : (v.$1 / l, v.$2 / l, v.$3 / l);
  }

  static _V _cross(_V a, _V b) => (
    a.$2 * b.$3 - a.$3 * b.$2,
    a.$3 * b.$1 - a.$1 * b.$3,
    a.$1 * b.$2 - a.$2 * b.$1,
  );

  /// A random unit vector; [flat] keeps it away from straight up.
  static _V _axis(math.Random rng, {double flat = 1}) {
    final a = rng.nextDouble() * math.pi * 2;
    final y = (rng.nextDouble() * 2 - 1) * flat;
    final h = math.sqrt(1 - y * y);
    return (math.cos(a) * h, y, math.sin(a) * h);
  }

  static _Mix? _mix(ClarityGrade grade) => switch (grade) {
    ClarityGrade.fl || ClarityGrade.internallyFlawless => null,
    ClarityGrade.vvs1 => (
      pin: 1,
      needle: 0,
      dark: 0,
      clear: 0,
      feather: 0,
      cloud: 0,
      s: 0.5,
    ),
    ClarityGrade.vvs2 => (
      pin: 2,
      needle: 1,
      dark: 0,
      clear: 0,
      feather: 0,
      cloud: 0,
      s: 0.6,
    ),
    ClarityGrade.vs1 => (
      pin: 2,
      needle: 0,
      dark: 0,
      clear: 1,
      feather: 1,
      cloud: 0,
      s: 0.9,
    ),
    ClarityGrade.vs2 => (
      pin: 2,
      needle: 1,
      dark: 1,
      clear: 1,
      feather: 1,
      cloud: 1,
      s: 1.15,
    ),
    ClarityGrade.si1 => (
      pin: 2,
      needle: 1,
      dark: 2,
      clear: 1,
      feather: 1,
      cloud: 1,
      s: 1.4,
    ),
    ClarityGrade.si2 => (
      pin: 2,
      needle: 1,
      dark: 3,
      clear: 1,
      feather: 2,
      cloud: 1,
      s: 1.8,
    ),
    ClarityGrade.i1 => (
      pin: 2,
      needle: 1,
      dark: 3,
      clear: 1,
      feather: 2,
      cloud: 2,
      s: 2.6,
    ),
    ClarityGrade.i2 => (
      pin: 1,
      needle: 1,
      dark: 4,
      clear: 1,
      feather: 3,
      cloud: 2,
      s: 3.4,
    ),
    ClarityGrade.i3 => (
      pin: 1,
      needle: 0,
      dark: 4,
      clear: 0,
      feather: 4,
      cloud: 3,
      s: 4.2,
    ),
  };

  static List<SimInclusion> _place(
    SimMesh mesh,
    ClarityGrade grade,
    _Mix r, {
    bool central = false,
    double pinScale = 1,
  }) {
    final rng = math.Random(31 + grade.index * 7);
    final out = <SimInclusion>[];
    final half = mesh.length / 2;
    final low = central || grade.index >= ClarityGrade.si1.index;
    double vary() => 0.7 + rng.nextDouble() * 0.6;

    // A random point inside the stone, [margin] clear of its surface.
    // Lower grades crowd under the table where they are easy to see;
    // higher grades hide out toward the girdle.
    (double, double, double)? inside({
      required bool central,
      double margin = 0.03,
    }) {
      for (var attempt = 0; attempt < 80; attempt++) {
        final reach = central ? 0.4 : 0.9;
        final x = (rng.nextDouble() * 2 - 1) * half * reach;
        final z = (rng.nextDouble() * 2 - 1) * reach;
        final y = (rng.nextDouble() * 2 - 1) * mesh.totalDepth * 0.4;
        if (!central && !low && x * x / (half * half) + z * z < 0.4) {
          continue;
        }
        if (_margin(mesh, x, y, z) > margin) return (x, y, z);
      }
      return null;
    }

    // A random unit vector; [flat] keeps it away from straight up so a
    // plane through it faces the viewer obliquely.
    (double, double, double) axis({double flat = 1}) {
      final a = rng.nextDouble() * math.pi * 2;
      final y = (rng.nextDouble() * 2 - 1) * flat;
      final h = math.sqrt(1 - y * y);
      return (math.cos(a) * h, y, math.sin(a) * h);
    }

    void add(
      SimInclusionKind kind,
      (double, double, double)? at,
      double size, [
      (double, double, double)? dir,
    ]) {
      if (at == null || out.length >= maxCount) return;
      final d = dir ?? axis();
      out.add(
        SimInclusion(
          kind: kind,
          x: at.$1,
          y: at.$2,
          z: at.$3,
          size: size,
          ax: d.$1,
          ay: d.$2,
          az: d.$3,
          seed: rng.nextDouble() * 0.999,
        ),
      );
    }

    // The defining inclusion first: lower grades show it under the table.
    for (var i = 0; i < r.dark; i++) {
      final big = low && i == 0;
      final size = 0.011 * r.s * vary() * (big ? 1.6 : 1);
      final at = inside(central: low && i < 2, margin: size * 2);
      add(SimInclusionKind.darkCrystal, at, size);
      // Large crystals strain the stone around them: a tension feather.
      if (big && grade.index >= ClarityGrade.i1.index && at != null) {
        add(SimInclusionKind.feather, at, size * 3.2, axis(flat: 0.7));
      }
    }
    for (var i = 0; i < r.feather; i++) {
      // Feathers commonly run in from the girdle.
      final edge = i.isOdd || !low;
      final size = 0.04 * r.s * vary();
      final at = edge
          ? _nearGirdle(mesh, rng, size * 0.4)
          : inside(central: true, margin: size * 0.2);
      // Chosen ones lie broad side up, so the crack shows through the
      // table rather than edge on.
      add(
        SimInclusionKind.feather,
        at,
        size,
        central ? _faceUp(rng) : axis(flat: 0.75),
      );
      // From SI2 down, those running in from the girdle break through it.
      if (edge &&
          grade.index >= ClarityGrade.si2.index &&
          at != null &&
          out.isNotEmpty &&
          out.last.kind == SimInclusionKind.feather) {
        out.last = breakSurface(
          mesh,
          out.last,
        ).as(SimInclusionKind.openFeather);
      }
    }
    for (var i = 0; i < r.clear; i++) {
      final size = 0.012 * r.s * vary();
      add(
        SimInclusionKind.clearCrystal,
        inside(central: low, margin: size * 2),
        size,
      );
    }
    for (var i = 0; i < r.cloud; i++) {
      final size = 0.035 * r.s * vary();
      add(
        SimInclusionKind.cloud,
        inside(central: false, margin: size * 0.5),
        size,
        axis(flat: 0.4),
      );
    }
    for (var i = 0; i < r.needle; i++) {
      final size = 0.03 * math.min(r.s, 2.0) * vary();
      add(
        SimInclusionKind.needle,
        inside(central: false, margin: size),
        size,
        axis(flat: 0.6),
      );
    }
    for (var i = 0; i < r.pin; i++) {
      add(
        SimInclusionKind.pinpoint,
        inside(central: false),
        (0.004 + rng.nextDouble() * 0.003) * pinScale,
      );
    }
    return out;
  }

  /// Packs [inclusions] the way the shader reads them: per inclusion,
  /// centre and size, then axis and `kind + seed`.
  static Float32List pack(List<SimInclusion> inclusions) {
    final out = Float32List(maxCount * 8);
    final n = math.min(inclusions.length, maxCount);
    for (var i = 0; i < n; i++) {
      final c = inclusions[i];
      out.setAll(i * 8, [
        c.x,
        c.y,
        c.z,
        c.size,
        c.ax,
        c.ay,
        c.az,
        c.kind.code + c.seed.clamp(0.0, 0.999),
      ]);
    }
    return out;
  }

  /// A unit normal tipped 20–45° from straight up.
  static (double, double, double) _faceUp(math.Random rng) {
    final a = rng.nextDouble() * math.pi * 2;
    final y = 0.7 + rng.nextDouble() * 0.24;
    final h = math.sqrt(1 - y * y);
    return (math.cos(a) * h, y, math.sin(a) * h);
  }

  /// A point just inside the girdle, [margin] clear of the surface.
  static (double, double, double)? _nearGirdle(
    SimMesh mesh,
    math.Random rng,
    double margin,
  ) {
    final half = mesh.length / 2;
    for (var attempt = 0; attempt < 60; attempt++) {
      final a = rng.nextDouble() * math.pi * 2;
      final reach = 0.72 + rng.nextDouble() * 0.18;
      final x = math.cos(a) * half * reach, z = math.sin(a) * reach;
      final y = (rng.nextDouble() - 0.6) * mesh.totalDepth * 0.25;
      if (_margin(mesh, x, y, z) > margin) return (x, y, z);
    }
    return null;
  }

  /// Smallest distance from (x, y, z) to any facet plane; negative when
  /// outside the stone.
  static double _margin(SimMesh mesh, double x, double y, double z) =>
      mesh.inset(x, y, z);
}
