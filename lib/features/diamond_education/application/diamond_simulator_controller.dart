import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/average_hand.dart';
import '../domain/cut_grade_estimator.dart';
import '../domain/diamond_grades.dart';
import '../domain/diamond_proportions.dart';
import '../domain/diamond_shape.dart';
import '../domain/diamond_spec.dart';
import '../simulation/sim_inclusions.dart';
import '../simulation/sim_mesh.dart';

/// Live simulator state: the stone as specified, the stone as built from
/// that spec, and what it measures.
@immutable
class DiamondSimulatorState {
  const DiamondSimulatorState({
    required this.spec,
    required this.mesh,
    required this.inclusions,
    required this.estimatedCut,
    this.lighting = SimLighting.daylight,
  });

  final DiamondSpec spec;
  final SimMesh mesh;
  final List<SimInclusion> inclusions;
  final CutGrade estimatedCut;
  final SimLighting lighting;

  /// One carat of diamond (0.2 g at 3.515 g/cm³) fills 56.9 mm³.
  static const mm3PerCarat = 56.9;

  /// Matches the model's spread to trade size charts: a 1 ct ideal round
  /// measures 6.5 mm across (1.5 ct 7.4, 2 ct 8.1, 3 ct 9.4, 5 ct
  /// 11.0). The model's slightly fuller girdle and culet would otherwise
  /// read about 2% small.
  static const spreadCalibration = 1.0236;

  /// Millimetres per model unit for the current carat weight.
  double get mmPerUnit =>
      math.pow(spec.carat * mm3PerCarat / mesh.volume, 1 / 3).toDouble() *
      spreadCalibration;

  double get lengthMm => mesh.length * mmPerUnit;
  double get widthMm => mesh.width * mmPerUnit;
  double get depthMm => mesh.totalDepth * mmPerUnit;

  DiamondSimulatorState copyWith({
    DiamondSpec? spec,
    SimMesh? mesh,
    List<SimInclusion>? inclusions,
    CutGrade? estimatedCut,
    SimLighting? lighting,
  }) => DiamondSimulatorState(
    spec: spec ?? this.spec,
    mesh: mesh ?? this.mesh,
    inclusions: inclusions ?? this.inclusions,
    estimatedCut: estimatedCut ?? this.estimatedCut,
    lighting: lighting ?? this.lighting,
  );
}

/// Owns the simulated stone. Every setter rebuilds only what it affects:
/// the stone's geometry when shape or proportions change, its
/// inclusions when geometry or clarity change.
class DiamondSimulatorController
    extends AutoDisposeNotifier<DiamondSimulatorState> {
  @override
  DiamondSimulatorState build() =>
      _withSpec(null, _initial(ref.watch(simulatorStartShapeProvider)));

  static DiamondSpec _initial(SimShape shape) =>
      DiamondSpec(shape: shape, proportions: DiamondProportions.ideal(shape));

  DiamondSimulatorState _withSpec(
    DiamondSimulatorState? from,
    DiamondSpec spec,
  ) {
    final reshape =
        from == null ||
        from.spec.shape != spec.shape ||
        from.spec.proportions != spec.proportions;
    final mesh = reshape
        ? SimMesh.build(spec.shape, spec.proportions)
        : from.mesh;
    final inclusions =
        reshape ||
            from.spec.clarity != spec.clarity ||
            !setEquals(from.spec.inclusionTypes, spec.inclusionTypes) ||
            (from.spec.enhancement != spec.enhancement &&
                (from.spec.enhancement.altersInclusions ||
                    spec.enhancement.altersInclusions))
        ? SimInclusions.generate(
            mesh,
            spec.clarity,
            only: spec.inclusionTypes,
            enhancement: spec.enhancement,
          )
        : from.inclusions;
    return DiamondSimulatorState(
      spec: spec,
      mesh: mesh,
      inclusions: inclusions,
      estimatedCut: CutGradeEstimator.estimate(spec.shape, spec.proportions),
      lighting: from?.lighting ?? SimLighting.daylight,
    );
  }

  void _update(DiamondSpec spec) {
    if (spec == state.spec) return;
    state = _withSpec(state, spec);
  }

  SimCutFamily get _family => state.spec.shape.family;

  /// Switches shape, keeping the current cut quality. Leaves the hearts &
  /// arrows scope for shapes that cannot show the pattern.
  void setShape(SimShape shape) {
    if (shape == state.spec.shape) return;
    _update(
      state.spec.copyWith(
        shape: shape,
        proportions: DiamondProportions.forGrade(shape, state.estimatedCut),
      ),
    );
    if (state.lighting == SimLighting.heartsArrows &&
        !shape.showsHeartsArrows) {
      setLighting(SimLighting.daylight);
    }
  }

  void setColorGrade(ColorGrade grade) =>
      _update(state.spec.copyWith(colorGrade: grade, clearFancy: true));

  void setFancyColor(FancyColor color) =>
      _update(state.spec.copyWith(fancyColor: color));

  void useColorScale() => _update(state.spec.copyWith(clearFancy: true));

  void setFancyIntensity(FancyIntensity intensity) =>
      _update(state.spec.copyWith(fancyIntensity: intensity));

  void setClarity(ClarityGrade grade) =>
      _update(state.spec.copyWith(clarity: grade));

  /// Shows only [types] inside the stone; null returns to the grade's
  /// usual mix.
  void setInclusionTypes(Set<InclusionType>? types) => _update(
    types == null
        ? state.spec.copyWith(gradedInclusions: true)
        : state.spec.copyWith(inclusionTypes: Set.unmodifiable(types)),
  );

  void toggleInclusionType(InclusionType type) {
    final current = state.spec.inclusionTypes;
    final next = {...?current}..toggle(type);
    setInclusionTypes(next.isEmpty ? null : next);
  }

  void setBrown(TingeLevel level) => _update(state.spec.copyWith(brown: level));

  void setGreen(TingeLevel level) => _update(state.spec.copyWith(green: level));

  void setMilky(MilkyLevel level) => _update(state.spec.copyWith(milky: level));

  void setEnhancement(Enhancement enhancement) =>
      _update(state.spec.copyWith(enhancement: enhancement));

  void setCarat(double carat) => _update(state.spec.copyWith(carat: carat));

  void setFluorescence(FluorescenceIntensity intensity) =>
      _update(state.spec.copyWith(fluorescence: intensity));

  void setFluorescenceColor(FluorescenceColor color) =>
      _update(state.spec.copyWith(fluorescenceColor: color));

  void setLighting(SimLighting lighting) {
    if (lighting == state.lighting) return;
    state = state.copyWith(lighting: lighting);
  }

  /// Puts the stone in a hearts & arrows scope, or back in daylight. The
  /// pattern only forms in a precisely cut round, so a stone cut below
  /// Excellent is recut to ideal proportions first.
  void setHeartsArrows(bool on) {
    if (!on) {
      if (state.lighting == SimLighting.heartsArrows) {
        setLighting(SimLighting.daylight);
      }
      return;
    }
    if (!state.spec.shape.showsHeartsArrows) return;
    if (state.estimatedCut != CutGrade.excellent) resetProportions();
    setLighting(SimLighting.heartsArrows);
  }

  /// Cuts the stone to the representative proportions of [grade].
  void applyCutGrade(CutGrade grade) => _update(
    state.spec.copyWith(
      proportions: DiamondProportions.forGrade(state.spec.shape, grade),
    ),
  );

  void _proportions(DiamondProportions p) =>
      _update(state.spec.copyWith(proportions: p));

  void setTable(double pct) =>
      _proportions(state.spec.proportions.copyWith(tablePct: pct));

  void setCrownAngle(double deg) =>
      _proportions(state.spec.proportions.copyWith(crownAngle: deg));

  void setCrownHeight(double pct) =>
      _proportions(state.spec.proportions.withCrownHeight(pct));

  void setPavilionAngle(double deg) =>
      _proportions(state.spec.proportions.copyWith(pavilionAngle: deg));

  void setPavilionDepth(double pct) =>
      _proportions(state.spec.proportions.withPavilionDepth(pct, _family));

  void setGirdle(GirdleThickness girdle) =>
      _proportions(state.spec.proportions.copyWith(girdle: girdle));

  void setCulet(CuletSize culet) =>
      _proportions(state.spec.proportions.copyWith(culet: culet));

  /// Total depth is crown + girdle + pavilion: reach it through the
  /// pavilion first (the larger, more forgiving part), then the crown if
  /// the pavilion runs out of range.
  void setTotalDepth(double pct) {
    var p = state.spec.proportions;
    final shape = state.spec.shape;
    for (var i = 0; i < 3; i++) {
      final mesh = SimMesh.build(shape, p);
      final rest = mesh.totalDepthPct - mesh.pavilionDepthPct;
      final (lo, hi) = p.pavilionDepthRange(_family);
      final pavilion = (pct - rest).clamp(lo, hi);
      p = p.withPavilionDepth(pavilion, _family);
      final missing = pct - rest - pavilion;
      if (missing.abs() > 0.05) {
        p = p.withCrownHeight(p.crownHeightPct + missing);
      }
    }
    _proportions(p);
  }

  void resetProportions() =>
      _proportions(DiamondProportions.ideal(state.spec.shape));

  void reset() =>
      state = _withSpec(null, _initial(ref.read(simulatorStartShapeProvider)));

  /// Makes [stone] the one being edited, e.g. another finger's stone.
  void load(DiamondSimulatorState stone) => state = stone;

  /// A new stone like [from] but cut as [shape], at [from]'s cut quality.
  DiamondSimulatorState recut(DiamondSimulatorState from, SimShape shape) =>
      _withSpec(
        from,
        from.spec.copyWith(
          shape: shape,
          proportions: DiamondProportions.forGrade(shape, from.estimatedCut),
        ),
      ).copyWith(lighting: SimLighting.daylight);
}

extension on Set<InclusionType> {
  void toggle(InclusionType t) {
    if (!remove(t)) add(t);
  }
}

/// Shape the simulator opens on; overridden per route.
final simulatorStartShapeProvider = Provider<SimShape>((ref) => SimShape.round);

/// The simulator's stone; disposed with the simulator screen.
final diamondSimulatorProvider =
    NotifierProvider.autoDispose<
      DiamondSimulatorController,
      DiamondSimulatorState
    >(
      DiamondSimulatorController.new,
      dependencies: [simulatorStartShapeProvider],
    );

/// The hand view: whether it shows, which finger's stone is being edited,
/// and the stones parked on the other fingers. The edited stone itself
/// lives in [diamondSimulatorProvider], so every control keeps working on
/// whichever stone is selected.
@immutable
class SimHand {
  const SimHand({
    this.onHand = false,
    this.active = HandFinger.ring,
    this.parked = const {},
  });

  final bool onHand;
  final HandFinger active;
  final Map<HandFinger, DiamondSimulatorState> parked;

  bool wears(HandFinger f) => f == active || parked.containsKey(f);

  int get count => parked.length + 1;

  SimHand copyWith({
    bool? onHand,
    HandFinger? active,
    Map<HandFinger, DiamondSimulatorState>? parked,
  }) => SimHand(
    onHand: onHand ?? this.onHand,
    active: active ?? this.active,
    parked: parked ?? this.parked,
  );
}

/// Moves stones between fingers. Each stone keeps its own spec; only the
/// selected one is edited.
class SimHandController extends AutoDisposeNotifier<SimHand> {
  @override
  SimHand build() => const SimHand();

  DiamondSimulatorController get _stone =>
      ref.read(diamondSimulatorProvider.notifier);

  void show(bool onHand) {
    if (onHand == state.onHand) return;
    // A scope cannot sit on a finger.
    if (onHand) _stone.setHeartsArrows(false);
    state = state.copyWith(onHand: onHand);
  }

  /// Edits [finger]'s stone, first placing one there if it is bare: a
  /// copy of the selected stone in a shape not yet on the hand, for an
  /// easy comparison.
  void select(HandFinger finger) {
    if (finger == state.active) return;
    final current = ref.read(diamondSimulatorProvider);
    final parked = {...state.parked, state.active: current};
    final next = parked.remove(finger) ?? _newStone(current);
    _stone.load(next);
    state = state.copyWith(active: finger, parked: parked);
  }

  DiamondSimulatorState _newStone(DiamondSimulatorState from) {
    final worn = {
      from.spec.shape,
      for (final s in state.parked.values) s.spec.shape,
    };
    const order = [
      SimShape.oval,
      SimShape.princess,
      SimShape.pear,
      SimShape.emerald,
      SimShape.cushion,
      SimShape.marquise,
      SimShape.round,
    ];
    final shape = order.firstWhere((s) => !worn.contains(s));
    return _stone.recut(from, shape);
  }

  /// Takes [finger]'s stone off; the last stone always stays.
  void remove(HandFinger finger) {
    if (!state.wears(finger) || state.count <= 1) return;
    if (finger != state.active) {
      state = state.copyWith(parked: {...state.parked}..remove(finger));
      return;
    }
    final parked = {...state.parked};
    final next = parked.containsKey(HandFinger.ring)
        ? HandFinger.ring
        : parked.keys.first;
    _stone.load(parked.remove(next)!);
    state = state.copyWith(active: next, parked: parked);
  }

  void reset() => state = SimHand(onHand: state.onHand);
}

/// The hand view; disposed with the simulator screen.
final simHandProvider =
    NotifierProvider.autoDispose<SimHandController, SimHand>(
      SimHandController.new,
      dependencies: [diamondSimulatorProvider],
    );
