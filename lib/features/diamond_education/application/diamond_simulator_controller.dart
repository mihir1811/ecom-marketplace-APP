import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  /// Millimetres per model unit for the current carat weight.
  double get mmPerUnit =>
      math.pow(spec.carat * mm3PerCarat / mesh.volume, 1 / 3).toDouble();

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
    final inclusions = reshape || from.spec.clarity != spec.clarity
        ? SimInclusions.generate(mesh, spec.clarity)
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

  /// Switches shape, keeping the current cut quality.
  void setShape(SimShape shape) {
    if (shape == state.spec.shape) return;
    _update(
      state.spec.copyWith(
        shape: shape,
        proportions: DiamondProportions.forGrade(shape, state.estimatedCut),
      ),
    );
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

  void setCarat(double carat) => _update(state.spec.copyWith(carat: carat));

  void setFluorescence(FluorescenceIntensity intensity) =>
      _update(state.spec.copyWith(fluorescence: intensity));

  void setFluorescenceColor(FluorescenceColor color) =>
      _update(state.spec.copyWith(fluorescenceColor: color));

  void setLighting(SimLighting lighting) {
    if (lighting == state.lighting) return;
    state = state.copyWith(lighting: lighting);
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
