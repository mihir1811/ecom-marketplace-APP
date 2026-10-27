import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/error/result.dart';
import '../data/repositories/jewelry_checkout_repository_impl.dart';
import '../domain/models/bag_line.dart';
import 'jewelry_bag_provider.dart';

/// Copies the signed-in buyer's bag to `PUT /marketplace/cart` so sellers
/// can see who has their pieces in a bag. Sent 800 ms after the last change
/// and once after sign-in; a guest's bag is never sent. Failures are ignored
/// and the next change retries.
final jewelryBagSyncProvider = Provider<void>((ref) {
  final sync = _BagSync(ref);
  ref.onDispose(sync.reset);

  ref.listen(jewelryBagProvider, (_, _) => sync.schedule());
  ref.listen(authProvider.select((s) => s.user?.id), (prev, next) {
    sync.reset();
    if (next != null) sync.schedule();
  }, fireImmediately: true);
});

class _BagSync {
  _BagSync(this._ref);

  static const _debounce = Duration(milliseconds: 800);

  final Ref _ref;
  Timer? _timer;

  /// Signature of the last bag the server accepted; null when unknown.
  String? _sent;
  int _epoch = 0;

  void schedule() {
    if (!_signedIn) return;
    _timer?.cancel();
    _timer = Timer(_debounce, _send);
  }

  void reset() {
    _timer?.cancel();
    _timer = null;
    _sent = null;
    _epoch++;
  }

  bool get _signedIn => _ref.read(authProvider).user != null;

  Future<void> _send() async {
    final epoch = _epoch;
    // The stored bag must be read first: the empty start would clear the
    // server copy.
    await _ref.read(jewelryBagProvider.notifier).ready;
    if (epoch != _epoch || !_signedIn) return;

    final lines = _merged(_ref.read(jewelryBagProvider));
    final signature = [
      for (final l in lines) '${l.skuId}#${l.quantity}',
    ].join(',');
    if (signature == _sent) return;

    final result = await _ref
        .read(jewelryCheckoutRepositoryProvider)
        .syncBag(lines);
    if (epoch != _epoch) return;
    if (result is Success) _sent = signature;
  }

  /// One line per variant: engraved copies add up, capped at 20.
  static List<BagLine> _merged(List<BagLine> bag) {
    final bySku = <String, BagLine>{};
    for (final l in bag) {
      final prev = bySku[l.skuId];
      bySku[l.skuId] = BagLine(
        skuId: l.skuId,
        listingSlug: l.listingSlug,
        title: l.title,
        quantity: ((prev?.quantity ?? 0) + l.quantity).clamp(
          1,
          BagLine.maxQuantity,
        ),
      );
    }
    return bySku.values.take(BagLine.maxLines).toList();
  }
}
