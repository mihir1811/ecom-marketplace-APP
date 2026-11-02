import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/spotlight_repository.dart';
import '../domain/spotlight_models.dart';

/// Live ads for one spot. Kept for 30 seconds after the last listener goes
/// away, matching the server's own cache, so going back and forth between
/// screens doesn't refetch.
final spotlightProvider = FutureProvider.autoDispose
    .family<List<SpotlightItem>, SpotlightQuery>((ref, query) async {
      final cancel = CancelToken();
      ref.onDispose(cancel.cancel);
      final link = ref.keepAlive();
      final timer = Timer(const Duration(seconds: 30), link.close);
      ref.onDispose(timer.cancel);
      return ref
          .read(spotlightRepositoryProvider)
          .fetch(query, cancelToken: cancel);
    });

/// The ads of [query] of type [T] (blocks only draw their own shape).
List<T> spotlightItemsOf<T extends SpotlightItem>(
  AsyncValue<List<SpotlightItem>> value,
) => value.valueOrNull?.whereType<T>().toList() ?? const [];

/// Counts views and clicks and sends them in batches.
///
/// Views wait about 2 seconds so a screen's worth goes in one call; a click
/// or the app going to the background sends straight away.
final spotlightEventsProvider = Provider<SpotlightEvents>((ref) {
  final events = SpotlightEvents(ref.watch(spotlightRepositoryProvider));
  ref.onDispose(events.dispose);
  return events;
});

class SpotlightEvents with WidgetsBindingObserver {
  SpotlightEvents(this._repo) {
    WidgetsBinding.instance.addObserver(this);
  }

  final SpotlightRepository _repo;
  final _pending = <({String adId, SpotlightEventType type})>[];
  Timer? _timer;

  static const _batchWindow = Duration(seconds: 2);

  void impression(String adId) {
    if (adId.isEmpty) return;
    _pending.add((adId: adId, type: SpotlightEventType.impression));
    if (_pending.length >= SpotlightRepository.maxEventsPerCall) {
      flush();
      return;
    }
    _timer ??= Timer(_batchWindow, flush);
  }

  void click(String adId) {
    if (adId.isEmpty) return;
    _pending.add((adId: adId, type: SpotlightEventType.click));
    flush();
  }

  /// Sends everything queued, in calls of up to 50 events.
  void flush() {
    _timer?.cancel();
    _timer = null;
    if (_pending.isEmpty) return;
    final batch = List.of(_pending);
    _pending.clear();
    unawaited(_repo.sendEvents(batch));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) flush();
  }

  void dispose() {
    flush();
    WidgetsBinding.instance.removeObserver(this);
  }
}
