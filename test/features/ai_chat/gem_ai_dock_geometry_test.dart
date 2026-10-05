import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/features/ai_chat/presentation/widgets/gem_ai_fab.dart';

void main() {
  const screen = Size(390, 844);
  const insets = EdgeInsets.only(top: 47, bottom: 34);
  const geo = GemAiDockGeometry(screen, insets);
  const s = GemAiDockGeometry.size;

  test('a release in the middle docks to the nearer edge, never centre', () {
    final left = geo.resolve(const Offset(150 - s / 2, 400), Offset.zero);
    final right = geo.resolve(const Offset(240 - s / 2, 400), Offset.zero);
    expect(left.right, isFalse);
    expect(right.right, isTrue);
    expect(geo.xFor(right: false), GemAiDockGeometry.edge);
    expect(
      geo.xFor(right: true),
      screen.width - s - GemAiDockGeometry.edge,
    );
  });

  test('a sideways fling overrides position', () {
    final flung = geo.resolve(
      const Offset(60, 400),
      const Offset(2400, 0),
    );
    expect(flung.right, isTrue);
  });

  test('near the top or bottom it snaps into the corner', () {
    final top = geo.resolve(Offset(10, geo.minY + 40), Offset.zero);
    final bottom = geo.resolve(Offset(10, geo.maxY - 40), Offset.zero);
    final middle = geo.resolve(const Offset(10, 400), Offset.zero);
    expect(top.y, geo.minY);
    expect(bottom.y, geo.maxY);
    expect(middle.y, 400);
  });

  test('vertical position is clamped inside the safe area', () {
    final above = geo.resolve(const Offset(10, -300), Offset.zero);
    final below = geo.resolve(const Offset(10, 3000), Offset.zero);
    expect(above.y, geo.minY);
    expect(below.y, geo.maxY);
    expect(geo.yFor(geo.fractionOf(500)), closeTo(500, 1e-9));
  });
}
