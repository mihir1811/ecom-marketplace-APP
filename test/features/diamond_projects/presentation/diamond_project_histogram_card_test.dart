import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/features/diamond_projects/domain/models/diamond_project_stats.dart';
import 'package:gemstone/features/diamond_projects/presentation/widgets/diamond_project_histogram_card.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('histogram bars share a baseline and equal spacing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: DiamondProjectHistogramCard(
              title: 'Price per carat distribution',
              entries: [
                NamedCount(label: r'$0 - $100/ct', count: 375),
                NamedCount(label: r'$100 - $120/ct', count: 269),
                NamedCount(label: r'$120 - $140/ct', count: 95),
                NamedCount(label: r'$140 - $160/ct', count: 52),
                NamedCount(label: r'$160 - $200/ct', count: 26),
                NamedCount(label: r'$200+/ct', count: 17),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);

    final boxes = <RenderBox>[
      for (var i = 0; i < 6; i++)
        tester.renderObject<RenderBox>(
          find.byKey(ValueKey('histogram-bar-$i')),
        ),
    ];
    final rects = [
      for (final box in boxes) box.localToGlobal(Offset.zero) & box.size,
    ];

    for (final rect in rects) {
      expect((rect.bottom - rects.first.bottom).abs(), lessThan(0.5));
      expect((rect.width - rects.first.width).abs(), lessThan(0.5));
    }

    final gaps = <double>[
      for (var i = 1; i < rects.length; i++) rects[i].left - rects[i - 1].left,
    ];
    for (final gap in gaps) {
      expect((gap - gaps.first).abs(), lessThan(0.5));
    }

    expect(rects.first.top, lessThan(rects.last.top));
    expect(rects.first.height, greaterThan(rects.last.height));
  });
}
