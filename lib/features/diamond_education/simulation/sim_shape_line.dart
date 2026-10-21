import '../domain/diamond_shape.dart';
import 'sim_fancy.dart';

/// One shape on the shape dial's half ring: a classic shape, which can be
/// chosen, or a fancy cut, which is only shown.
class SimLineShape {
  const SimLineShape.classic(SimShape this.classic) : fancy = null;
  const SimLineShape.fancy(SimFancyShape this.fancy) : classic = null;

  final SimShape? classic;
  final SimFancyShape? fancy;

  String get svgAsset => classic?.svgAsset ?? fancy!.svgAsset;

  @override
  bool operator ==(Object other) =>
      other is SimLineShape &&
      other.classic == classic &&
      identical(other.fancy, fancy);

  @override
  int get hashCode => Object.hash(classic, fancy);
}

/// Every shape the simulator shows, classic and fancy, on one line: the
/// fancy cuts in slider order with the classic ones set in among them,
/// each step a small recut ([SimShapeMorph]).
abstract final class SimShapeLine {
  /// The classic shapes as the dial has them, opened between radiant and
  /// asscher so both ends are plain convex stones: heart, traced as a
  /// mirrored half, keeps its dial neighbours.
  static const classics = [
    SimShape.asscher,
    SimShape.heart,
    SimShape.round,
    SimShape.princess,
    SimShape.cushion,
    SimShape.oval,
    SimShape.emerald,
    SimShape.pear,
    SimShape.marquise,
    SimShape.radiant,
  ];

  /// The fancy cut the classic shapes follow: an octagonal step cut
  /// leads into asscher, and radiant leads on into square.
  static const after = 'flanders';

  static List<SimLineShape> of(List<SimFancyShape> fancy) {
    final at = fancy.indexWhere((s) => s.id == after) + 1;
    return [
      for (final s in fancy.take(at)) SimLineShape.fancy(s),
      for (final s in classics) SimLineShape.classic(s),
      for (final s in fancy.skip(at)) SimLineShape.fancy(s),
    ];
  }
}
