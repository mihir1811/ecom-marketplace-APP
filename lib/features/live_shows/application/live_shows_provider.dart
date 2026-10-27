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

/// Shows on air, polled every 30 s while something watches it. There is no
/// socket event for a show starting or ending.
final liveShowsProvider =
    NotifierProvider.autoDispose<LiveShowsNotifier, LiveShowsState>(
      LiveShowsNotifier.new,
    );

class LiveShowsNotifier extends AutoDisposeNotifier<LiveShowsState> {
  static const _poll = Duration(seconds: 30);

  @override
  LiveShowsState build() {
    final timer = Timer.periodic(_poll, (_) => unawaited(refresh()));
    ref.onDispose(timer.cancel);
    Future<void>.microtask(refresh);
    return const LiveShowsState();
  }

  Future<void> refresh() async {
    final result = await ref.read(liveShowRepositoryProvider).shows();
    state = switch (result) {
      Success(:final value) => LiveShowsState(
        shows: value.where((s) => s.isLive).toList(),
        isLoading: false,
      ),
      // Keep what is on screen when a background poll fails.
      ResultFailure(:final failure) => LiveShowsState(
        shows: state.shows,
        isLoading: false,
        errorMessage: state.shows.isEmpty ? failure.message : null,
      ),
    };
  }
}
