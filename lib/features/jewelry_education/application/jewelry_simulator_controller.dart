import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../diamond_education/domain/diamond_spec.dart';
import '../domain/jewelry_design.dart';
import '../scene/jewelry_scene.dart';
import '../scene/scene_factory.dart';

/// A diamond handed over from the diamond simulator ("Use in jewelry"),
/// waiting to be set; the jewelry simulator opens with it as the centre
/// stone.
final jewelryStoneHandoffProvider = StateProvider<DiamondSpec?>((ref) => null);

/// The piece the simulator opens on; overridden per route.
final jewelryStartTypeProvider = Provider<JewelryType>(
  (ref) => JewelryType.ring,
);

/// The design being edited and the scene built from it. [scene] can lag
/// [design] by a moment while a slider moves.
@immutable
class JewelrySimState {
  const JewelrySimState({required this.design, required this.scene});

  final JewelryDesign design;
  final JScene scene;

  /// Whether a rebuilt scene is still on its way.
  bool get building =>
      !identical(scene.design, design) && scene.design != design;
}

/// Owns the design. A change of metal, purity, finish or two-tone restyles the
/// current scene at once; anything that changes the shape rebuilds it,
/// coalesced so a dragged slider rebuilds at most every few frames.
class JewelrySimulatorController extends AutoDisposeNotifier<JewelrySimState> {
  Timer? _rebuild;
  JewelryDesign? _initial;

  @override
  JewelrySimState build() {
    ref.onDispose(() => _rebuild?.cancel());
    final stone = ref.read(jewelryStoneHandoffProvider);
    final design = JewelryDesign.initial(
      stone: stone,
      type: ref.watch(jewelryStartTypeProvider),
    );
    _initial = design;
    return JewelrySimState(
      design: design,
      scene: JewelrySceneFactory.build(design),
    );
  }

  /// Rebuild coalescing window.
  static const _settle = Duration(milliseconds: 90);

  void update(JewelryDesign Function(JewelryDesign d) change) {
    final next = change(state.design);
    if (next == state.design) return;
    final shapeSame = _sameShape(next, state.scene.design);
    if (shapeSame) {
      _rebuild?.cancel();
      _rebuild = null;
      state = JewelrySimState(design: next, scene: state.scene.restyled(next));
      return;
    }
    state = JewelrySimState(design: next, scene: state.scene);
    if (_rebuild?.isActive ?? false) return;
    _rebuild = Timer(_settle, _build);
  }

  void _build() {
    final d = state.design;
    state = JewelrySimState(design: d, scene: JewelrySceneFactory.build(d));
  }

  /// Applies any pending rebuild now (e.g. when a slider is released).
  void flush() {
    if (!(_rebuild?.isActive ?? false)) return;
    _rebuild!.cancel();
    _build();
  }

  void setType(JewelryType t) => update((d) => d.copyWith(type: t));

  void reset() {
    _rebuild?.cancel();
    final d = _initial!.copyWith(type: state.design.type);
    state = JewelrySimState(design: d, scene: JewelrySceneFactory.build(d));
  }

  /// Whether [a] and [b] build the same geometry: they differ at most in
  /// metal, purity, finish or the setting's second metal.
  static bool _sameShape(JewelryDesign a, JewelryDesign b) =>
      a.copyWith(
        metal: b.metal,
        purity: b.purity,
        finish: b.finish,
        headMetal: b.headMetal,
        clearHeadMetal: b.headMetal == null,
      ) ==
      b;
}

/// The simulator's design; disposed with the simulator screen.
final jewelrySimulatorProvider =
    NotifierProvider.autoDispose<JewelrySimulatorController, JewelrySimState>(
      JewelrySimulatorController.new,
      dependencies: [jewelryStartTypeProvider],
    );
