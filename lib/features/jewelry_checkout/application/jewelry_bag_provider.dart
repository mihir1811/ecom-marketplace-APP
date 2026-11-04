import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../data/jewelry_bag_store.dart';
import '../data/repositories/jewelry_checkout_repository_impl.dart';
import '../domain/models/bag_line.dart';
import '../domain/models/marketplace_quote.dart';
import '../../../core/riverpod/dispose_tolerant.dart';

final jewelryBagStoreProvider = Provider<JewelryBagStore>(
  (ref) => const JewelryBagStore(),
);

/// Why adding to the bag did not go through.
enum BagAddIssue { full, maxQuantity }

/// The on-device jewellery bag. Loaded from storage on first read and
/// written back on every change.
class JewelryBagNotifier extends Notifier<List<BagLine>>
    with DisposeTolerantNotifier<List<BagLine>> {
  bool _loaded = false;
  final _ready = Completer<void>();

  /// Completes once the stored bag has been read, so callers never mistake
  /// the empty start for an empty bag.
  Future<void> get ready => _ready.future;

  JewelryBagStore get _store => ref.read(jewelryBagStoreProvider);

  @override
  List<BagLine> build() {
    Future.microtask(_load);
    return const [];
  }

  Future<void> _load() async {
    if (_loaded) return;
    final saved = await _store.read();
    if (!ref.mounted) return;
    _loaded = true;
    if (!_ready.isCompleted) _ready.complete();
    // Lines added before storage answered win over the stored copy.
    final keys = {for (final l in state) l.key};
    state = [
      ...state,
      for (final l in saved)
        if (!keys.contains(l.key)) l,
    ];
  }

  void _commit(List<BagLine> next) {
    state = List.unmodifiable(next);
    _store.write(state);
  }

  /// Adds [line], merging with an identical variant + personalisation.
  /// Returns null on success.
  BagAddIssue? add(BagLine line, {int maxQuantity = BagLine.maxQuantity}) {
    final cap = maxQuantity.clamp(1, BagLine.maxQuantity);
    final index = state.indexWhere((l) => l.key == line.key);
    if (index >= 0) {
      final existing = state[index];
      if (existing.quantity >= cap) return BagAddIssue.maxQuantity;
      final next = [...state];
      next[index] = existing.copyWith(
        quantity: (existing.quantity + line.quantity).clamp(1, cap),
        unitPrice: line.unitPrice,
      );
      _commit(next);
      return null;
    }
    if (state.length >= BagLine.maxLines) return BagAddIssue.full;
    _commit([...state, line.copyWith(quantity: line.quantity.clamp(1, cap))]);
    return null;
  }

  void setQuantity(String key, int quantity) {
    _commit([
      for (final l in state)
        if (l.key == key)
          l.copyWith(quantity: quantity.clamp(1, BagLine.maxQuantity))
        else
          l,
    ]);
  }

  void remove(String key) => _commit([
    for (final l in state)
      if (l.key != key) l,
  ]);

  /// Drops the lines an order just paid for.
  void removeAll(Iterable<String> keys) {
    final drop = keys.toSet();
    _commit([
      for (final l in state)
        if (!drop.contains(l.key)) l,
    ]);
  }

  /// Keeps shown prices current with the latest quote.
  void applyQuote(CartQuote quote) {
    var changed = false;
    final next = <BagLine>[];
    for (final l in state) {
      final q = quote.lineFor(l);
      if (q != null && q.problem == null && q.unitPrice != l.unitPrice) {
        changed = true;
        next.add(l.copyWith(unitPrice: q.unitPrice));
      } else {
        next.add(l);
      }
    }
    if (changed) _commit(next);
  }
}

final jewelryBagProvider = NotifierProvider<JewelryBagNotifier, List<BagLine>>(
  JewelryBagNotifier.new,
);

/// Pieces in the bag (sum of quantities) for badges.
final jewelryBagCountProvider = Provider<int>(
  (ref) => ref.watch(
    jewelryBagProvider.select(
      (lines) => lines.fold(0, (s, l) => s + l.quantity),
    ),
  ),
);

/// Whether this exact variant + personalisation is already in the bag.
final isInJewelryBagProvider = Provider.family<bool, String>(
  (ref, key) => ref.watch(
    jewelryBagProvider.select((lines) => lines.any((l) => l.key == key)),
  ),
);

/// Today's prices for the bag. Re-quotes whenever the bag changes.
final jewelryBagQuoteProvider = FutureProvider.autoDispose<CartQuote?>((
  ref,
) async {
  // Only what the API prices: price updates from the quote don't re-quote.
  ref.watch(
    jewelryBagProvider.select(
      (lines) => lines.map((l) => '${l.key}#${l.quantity}').join(','),
    ),
  );
  final lines = ref.read(jewelryBagProvider);
  if (lines.isEmpty) return null;
  final result = await ref.read(jewelryCheckoutRepositoryProvider).quote(lines);
  switch (result) {
    case Success(value: final quote):
      ref.read(jewelryBagProvider.notifier).applyQuote(quote);
      return quote;
    case ResultFailure(failure: final Failure failure):
      throw failure;
  }
});
