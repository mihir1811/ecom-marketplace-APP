import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/metal_spot_price.dart';

// Metal prices (AURUM) — disabled. Uncomment to re-enable live spot ticker.
//
// import '../../../core/error/result.dart';
// import '../data/repositories/metal_prices_repository_impl.dart';
//
// final metalSpotPricesProvider =
//     AsyncNotifierProvider<MetalSpotPricesNotifier, List<MetalSpotPrice>>(
//   MetalSpotPricesNotifier.new,
// );
//
// class MetalSpotPricesNotifier extends AsyncNotifier<List<MetalSpotPrice>> {
//   @override
//   Future<List<MetalSpotPrice>> build() async {
//     return _load();
//   }
//
//   Future<void> retry() async {
//     state = const AsyncLoading();
//     state = await AsyncValue.guard(_load);
//   }
//
//   Future<List<MetalSpotPrice>> _load() async {
//     final result =
//         await ref.read(metalPricesRepositoryProvider).fetchSpotPrices();
//     return switch (result) {
//       Success(value: final prices) => prices,
//       ResultFailure(failure: final failure) =>
//         throw Exception(failure.message),
//     };
//   }
// }

/// Stub so nothing watches AURUM while the metal-prices section is disabled.
final metalSpotPricesProvider =
    AsyncNotifierProvider<MetalSpotPricesNotifier, List<MetalSpotPrice>>(
  MetalSpotPricesNotifier.new,
);

class MetalSpotPricesNotifier extends AsyncNotifier<List<MetalSpotPrice>> {
  @override
  Future<List<MetalSpotPrice>> build() async {
    // Intentionally no AURUM / network call while section is commented out.
    return const <MetalSpotPrice>[];
  }
}
