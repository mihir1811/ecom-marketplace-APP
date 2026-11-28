import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/riverpod/dispose_tolerant.dart';
import '../data/repositories/rough_diamond_repository_impl.dart';
import '../domain/models/rough_facets.dart';
import '../domain/models/rough_parcel.dart';

/// Filter chips and slider limits per tab. A failed load shows no chips
/// rather than an error: the filter screen still works without counts.
final roughFacetsProvider = FutureProvider.autoDispose
    .family<RoughFacets, RoughDiamondType>((ref, type) async {
      final result = await ref
          .read(roughDiamondRepositoryProvider)
          .facets(type);
      return switch (result) {
        Success(:final value) => value,
        ResultFailure() => RoughFacets.empty,
      };
    });

/// Outcome of re-reading one parcel for its detail page.
sealed class RoughParcelLookup {
  const RoughParcelLookup();
}

class RoughParcelFound extends RoughParcelLookup {
  const RoughParcelFound(this.parcel);

  final RoughParcel parcel;
}

/// Deleted parcel (404): "no longer available".
class RoughParcelGone extends RoughParcelLookup {
  const RoughParcelGone();
}

/// The parcel as the server sees it now: its `buy` decides every button,
/// so the detail page re-reads it instead of trusting the list copy.
/// Network errors keep the list copy (null).
final roughParcelProvider = FutureProvider.autoDispose
    .family<RoughParcelLookup?, String>((ref, id) async {
      final result = await ref.read(roughDiamondRepositoryProvider).getById(id);
      return switch (result) {
        Success(:final value) => RoughParcelFound(value),
        ResultFailure(:final failure) =>
          failure is NotFoundFailure ? const RoughParcelGone() : null,
      };
    });

/// Lots the buyer ticked on a parcel's page (ids, in tick order).
class RoughLotSelectionNotifier extends Notifier<List<String>>
    with DisposeTolerantNotifier<List<String>> {
  RoughLotSelectionNotifier(this.parcelId);

  final String parcelId;

  @override
  List<String> build() => const [];

  void toggle(String lotId) {
    state = state.contains(lotId)
        ? [
            for (final id in state)
              if (id != lotId) id,
          ]
        : [...state, lotId];
  }

  /// Keeps only lots still free (after the parcel is re-read).
  void retainFree(Set<String> freeIds) {
    final kept = [
      for (final id in state)
        if (freeIds.contains(id)) id,
    ];
    if (kept.length != state.length) state = kept;
  }

  void clear() => state = const [];
}

final roughLotSelectionProvider =
    NotifierProvider.family<RoughLotSelectionNotifier, List<String>, String>(
      RoughLotSelectionNotifier.new,
    );
