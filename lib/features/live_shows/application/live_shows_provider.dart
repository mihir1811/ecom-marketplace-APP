import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
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

/// Shows on air. There is no socket event for a show starting or ending, so
/// the list is polled every 30 s, but only while a [LiveShowsPolling] widget
/// is on screen and the app is in the foreground. Data stays cached for a
/// short while after the last listener leaves, so coming back within the
/// poll window does not refetch.
final liveShowsProvider =
    NotifierProvider.autoDispose<LiveShowsNotifier, LiveShowsState>(
      LiveShowsNotifier.new,
    );

class LiveShowsNotifier extends AutoDisposeNotifier<LiveShowsState> {
  static const _poll = Duration(seconds: 30);
  static const _linger = Duration(minutes: 2);

  Timer? _timer;
  Future<void>? _inFlight;
  DateTime? _fetchedAt;
  var _viewers = 0;
  var _foreground = true;
  var _disposed = false;

  bool get _active => _viewers > 0 && _foreground;

  @override
  LiveShowsState build() {
    _disposed = false;
    _viewers = 0;
    _fetchedAt = null;
    final life = SchedulerBinding.instance.lifecycleState;
    _foreground = life == null || _isForeground(life);

    final lifecycle = AppLifecycleListener(
      onStateChange: (s) {
        _foreground = _isForeground(s);
        _sync();
      },
    );

    // Keep the last list for a bit after everyone leaves.
    final link = ref.keepAlive();
    Timer? linger;
    ref.onCancel(() => linger = Timer(_linger, link.close));
    ref.onResume(() => linger?.cancel());

    ref.onDispose(() {
      _disposed = true;
      linger?.cancel();
      _timer?.cancel();
      _timer = null;
      lifecycle.dispose();
    });

    Future<void>.microtask(refresh);
    return const LiveShowsState();
  }

  static bool _isForeground(AppLifecycleState s) =>
      s == AppLifecycleState.resumed || s == AppLifecycleState.inactive;

  /// A visible live list appeared. Starts polling, fetching now only if the
  /// data is stale.
  void attachViewer() {
    _viewers++;
    _sync();
  }

  void detachViewer() {
    if (_viewers > 0) _viewers--;
    _sync();
  }

  /// Fetches now. Concurrent calls share one request.
  Future<void> refresh() =>
      _inFlight ??= _fetch().whenComplete(() => _inFlight = null);

  void _sync() {
    if (_disposed) return;
    if (!_active) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    if (_timer != null || _inFlight != null) return;
    final fetched = _fetchedAt;
    final age = fetched == null ? _poll : DateTime.now().difference(fetched);
    if (age >= _poll) {
      unawaited(refresh());
    } else {
      _schedule(_poll - age);
    }
  }

  void _schedule(Duration delay) {
    _timer?.cancel();
    _timer = Timer(delay, () {
      _timer = null;
      unawaited(refresh());
    });
  }

  Future<void> _fetch() async {
    _timer?.cancel();
    _timer = null;
    final result = await ref.read(liveShowRepositoryProvider).shows();
    if (_disposed) return;
    _fetchedAt = DateTime.now();
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
    if (_active) _schedule(_poll);
  }
}

/// Marks its subtree as a visible live list: polling runs only while one of
/// these is on screen. Routes covered by another page and inactive tabs turn
/// [TickerMode] off, which pauses it.
class LiveShowsPolling extends ConsumerStatefulWidget {
  const LiveShowsPolling({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<LiveShowsPolling> createState() => _LiveShowsPollingState();
}

class _LiveShowsPollingState extends ConsumerState<LiveShowsPolling> {
  LiveShowsNotifier? _attached;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible && _attached == null) {
      final notifier = ref.read(liveShowsProvider.notifier);
      notifier.attachViewer();
      _attached = notifier;
    } else if (!visible && _attached != null) {
      _attached!.detachViewer();
      _attached = null;
    }
  }

  @override
  void dispose() {
    _attached?.detachViewer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
