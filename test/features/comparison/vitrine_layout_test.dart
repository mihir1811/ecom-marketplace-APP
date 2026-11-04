import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/features/comparison/domain/models/compare_category.dart';
import 'package:gemstone/features/comparison/domain/models/compare_insights.dart';
import 'package:gemstone/features/comparison/domain/models/compare_item.dart';
import 'package:gemstone/features/comparison/domain/models/compare_spec.dart';
import 'package:gemstone/features/comparison/presentation/widgets/vitrine/vitrine_rail.dart';
import 'package:gemstone/features/comparison/presentation/widgets/vitrine/vitrine_specs.dart';

CompareItem _diamond(String id, String shape, double carat, double price) =>
    CompareItem(
      id: id,
      category: CompareCategory.diamond,
      title: '${carat}ct $shape',
      price: price,
      shape: shape,
      displayValues: {
        'price': '\$$price',
        'carat': '${carat}ct',
        'shape': shape,
        'cut': '-',
        'color': '-',
        'clarity': 'SI2',
      },
      numericValues: {'price': price, 'carat': carat},
    );

void main() {

  final items = [
    _diamond('a', 'Pear', 0.18, 571.43),
    _diamond('b', 'Marquise', 0.23, 1072),
    _diamond('c', 'Oval', 0.23, 2674),
    _diamond('d', 'Pear', 0.28, 803.08),
  ];

  Future<void> pump(WidgetTester tester, {double textScale = 1}) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final insights = CompareInsights.of(items, diamondCompareSpecs);
    const columns = VitrineColumns(count: 4, width: 375);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(375, 812),
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: VitrineRailDelegate(
                    items: items,
                    insights: insights,
                    columns: columns,
                    onTapPiece: (_) {},
                    onRemove: (_) {},
                    onReorder: (_, _) {},
                    onAdd: () {},
                  ),
                ),
                SliverList.list(
                  children: [
                    for (final g in groupSpecs(
                      CompareCategory.diamond,
                      diamondCompareSpecs,
                    ))
                      VitrineSpecGroup(
                        group: g,
                        items: items,
                        insights: insights,
                        columns: columns,
                        differencesOnly: false,
                      ),
                    const SizedBox(height: 1200),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
  }

  testWidgets('four pieces lay out without overflow while folding', (
    tester,
  ) async {
    await pump(tester);
    expect(tester.takeException(), isNull);
    for (final dy in [-30.0, -40.0, -60.0, -200.0]) {
      await tester.drag(find.byType(CustomScrollView), Offset(0, dy));
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('large text does not break the rail', (tester) async {
    await pump(tester, textScale: 1.6);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rows nobody has data for are hidden', (tester) async {
    await pump(tester);
    expect(find.text('CUT'), findsNothing);
    expect(find.text('CLARITY'), findsOneWidget);
  });
}
