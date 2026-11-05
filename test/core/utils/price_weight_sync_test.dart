import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemworld/core/utils/price_weight_sync.dart';

void main() {
  late TextEditingController carat;
  late TextEditingController ppc;
  late TextEditingController total;
  late PriceWeightSync sync;

  setUp(() {
    carat = TextEditingController(text: '1.5');
    ppc = TextEditingController();
    total = TextEditingController();
    sync = PriceWeightSync(
      unitPrice: ppc,
      total: total,
      weight: () => PriceWeightSync.parseAmount(carat.text),
      weightSources: [carat],
    );
  });

  tearDown(() => sync.dispose());

  test('per carat updates total', () {
    ppc.text = '1,000';
    expect(total.text, '1500');
  });

  test('total updates per carat', () {
    total.text = '1000';
    expect(ppc.text, '666.67');
  });

  test('carat change recomputes total from per carat', () {
    ppc.text = '200';
    carat.text = '2';
    expect(total.text, '400');
    expect(ppc.text, '200');
  });

  test('no weight leaves fields alone', () {
    carat.text = '';
    ppc.text = '200';
    expect(total.text, '');
  });
}
