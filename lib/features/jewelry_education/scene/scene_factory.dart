import '../domain/jewelry_design.dart';
import 'bracelet_scene.dart';
import 'earring_scene.dart';
import 'jewelry_scene.dart';
import 'necklace_scene.dart';
import 'ring_scene.dart';

/// Builds the scene for a design: its meshes, centre stones, display
/// and physics, settled at rest.
abstract final class JewelrySceneFactory {
  static JScene build(JewelryDesign d) => switch (d.type) {
    JewelryType.ring => RingScene.build(d),
    JewelryType.earrings => EarringScene.build(d),
    JewelryType.necklace => NecklaceScene.build(d),
    JewelryType.bracelet => BraceletScene.build(d),
  };
}
