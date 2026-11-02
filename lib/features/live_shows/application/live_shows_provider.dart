import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../data/repositories/live_show_repository_impl.dart';
import '../domain/models/live_show_models.dart';

class LiveShowsState {
  const LiveShowsState({
    this.shows = const [],
    this.isLoading = true,
    this.errorMessage,
  });

  final List<LiveShow> shows;
  final bool isLoading;
  final String? errorMessage;
}

/// Shows on air. Fetched once when first needed, then only on pull to
/// refresh or retry. No polling. The list stays cached for a short while
/// after the last listener leaves, so moving between home and the live
/// list does not refetch.
final liveShowsProvider =
    NotifierProvider.autoDispose<LiveShowsNotifier, LiveShowsState>(
      LiveShowsNotifier.new,
    );

class LiveShowsNotifier extends AutoDisposeNotifier<LiveShowsState> {
  static const _linger = Duration(minutes: 2);

  Future<void>? _inFlight;
  var _disposed = false;

  @override
  LiveShowsState build() {
    _disposed = false;
    final link = ref.keepAlive();
    Timer? linger;
    ref.onCancel(() => linger = Timer(_linger, link.close));
    ref.onResume(() => linger?.cancel());
    ref.onDispose(() {
      _disposed = true;
      linger?.cancel();
    });
    Future<void>.microtask(refresh);
    return const LiveShowsState();
  }

  /// Fetches now. Concurrent calls share one request.
  Future<void> refresh() =>
      _inFlight ??= _fetch().whenComplete(() => _inFlight = null);

  Future<void> _fetch() async {
    final result = await ref.read(liveShowRepositoryProvider).shows();
    if (_disposed) return;
    state = switch (result) {
      Success(:final value) => LiveShowsState(
        shows: value.where((s) => s.isLive).toList(),
        isLoading: false,
      ),
      // Keep what is on screen when a refresh fails.
      ResultFailure(:final failure) => LiveShowsState(
        shows: state.shows,
        isLoading: false,
        errorMessage: state.shows.isEmpty ? failure.message : null,
      ),
    };
  }
}
