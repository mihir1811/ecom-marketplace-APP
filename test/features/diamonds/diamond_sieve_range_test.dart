import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemworld/features/diamonds/application/diamond_search_provider.dart';

void main() {
  test('selecting two sieve rows selects the inclusive range', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(diamondSearchProvider.notifier);

    notifier.toggleSieveSize(3);
    notifier.toggleSieveSize(8);

    expect(
      container.read(diamondSearchProvider).selectedSieveIndices,
      [3, 4, 5, 6, 7, 8],
    );
  });

  test('sieve range can be narrowed and deselected like color range', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(diamondSearchProvider.notifier);

    notifier.toggleSieveSize(8);
    notifier.toggleSieveSize(3);
    expect(
      container.read(diamondSearchProvider).selectedSieveIndices,
      [3, 4, 5, 6, 7, 8],
    );

    notifier.toggleSieveSize(3);
    expect(container.read(diamondSearchProvider).selectedSieveIndices, [3]);

    notifier.toggleSieveSize(3);
    expect(container.read(diamondSearchProvider).selectedSieveIndices, isEmpty);
  });
}
