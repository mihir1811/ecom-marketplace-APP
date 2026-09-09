import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/error/result.dart';
import '../data/repositories/seller_insights_repository_impl.dart';
import '../domain/models/seller_insights.dart';
import '../domain/repositories/seller_insights_repository.dart';

class SellerDashboardState {
  const SellerDashboardState({
    this.snapshot,
    this.params = const SellerDashboardParams(),
    this.isLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
  });

  final SellerDashboardSnapshot? snapshot;
  final SellerDashboardParams params;
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;

  SellerDashboardState copyWith({
    SellerDashboardSnapshot? snapshot,
    SellerDashboardParams? params,
    bool? isLoading,
    bool? isRefreshing,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SellerDashboardState(
      snapshot: snapshot ?? this.snapshot,
      params: params ?? this.params,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class SellerDashboardNotifier extends Notifier<SellerDashboardState> {
  Future<void>? _inFlight;

  SellerInsightsRepository get _repo =>
      ref.read(sellerInsightsRepositoryProvider);

  @override
  SellerDashboardState build() {
    final userId = ref.watch(authProvider.select((s) => s.user?.id));
    _inFlight = null;
    if (userId == null || userId.isEmpty) {
      return const SellerDashboardState();
    }
    Future.microtask(refresh);
    return const SellerDashboardState(isLoading: true);
  }

  Future<void> setParams(SellerDashboardParams params) async {
    if (params == state.params && state.snapshot != null) return;
    state = state.copyWith(params: params);
    await _doRefresh(keepVisible: true);
  }

  Future<void> refresh() async {
    _repo.invalidateCache();
    await _doRefresh(keepVisible: state.snapshot != null);
  }

  Future<void> _doRefresh({required bool keepVisible}) async {
    final pending = _inFlight;
    if (pending != null) {
      await pending;
    }

    late final Future<void> run;
    run = () async {
      if (keepVisible && state.snapshot != null) {
        state = state.copyWith(isRefreshing: true, clearError: true);
      } else {
        state = state.copyWith(
          isLoading: true,
          isRefreshing: false,
          clearError: true,
        );
      }

      final result = await _repo.getDashboard(params: state.params);
      switch (result) {
        case Success(:final value):
          state = SellerDashboardState(
            snapshot: value,
            params: state.params,
          );
        case ResultFailure(:final failure):
          state = state.copyWith(
            isLoading: false,
            isRefreshing: false,
            errorMessage: failure.message,
          );
      }
    }();

    _inFlight = run;
    try {
      await run;
    } finally {
      if (identical(_inFlight, run)) _inFlight = null;
    }
  }
}

final sellerDashboardProvider =
    NotifierProvider<SellerDashboardNotifier, SellerDashboardState>(
      SellerDashboardNotifier.new,
    );

class SellerAnalyticsState {
  const SellerAnalyticsState({
    this.snapshot,
    this.isLoading = false,
    this.errorMessage,
  });

  final SellerAnalyticsSnapshot? snapshot;
  final bool isLoading;
  final String? errorMessage;

  SellerAnalyticsState copyWith({
    SellerAnalyticsSnapshot? snapshot,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SellerAnalyticsState(
      snapshot: snapshot ?? this.snapshot,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class SellerAnalyticsNotifier
    extends FamilyNotifier<SellerAnalyticsState, AnalyticsRange> {
  bool _started = false;
  Future<void>? _inFlight;
  SellerAnalyticsState _latest = const SellerAnalyticsState(isLoading: true);
  String? _boundUserId;

  SellerInsightsRepository get _repo =>
      ref.read(sellerInsightsRepositoryProvider);

  @override
  SellerAnalyticsState build(AnalyticsRange arg) {
    final userId = ref.watch(authProvider.select((s) => s.user?.id));
    if (userId != _boundUserId) {
      _boundUserId = userId;
      _started = false;
      _inFlight = null;
      _latest = const SellerAnalyticsState(isLoading: true);
      _repo.invalidateCache();
    }
    if (userId == null || userId.isEmpty) {
      return const SellerAnalyticsState();
    }
    if (!_started) {
      _started = true;
      Future.microtask(_loadOnce);
    }
    return _latest;
  }

  Future<void> refresh() async {
    _repo.invalidateCache();
    return _doRefresh();
  }

  Future<void> _loadOnce() async {
    final pending = _inFlight;
    if (pending != null) return pending;
    final done = _doRefresh();
    _inFlight = done;
    try {
      await done;
    } finally {
      if (identical(_inFlight, done)) _inFlight = null;
    }
  }

  Future<void> _doRefresh() async {
    if (_latest.snapshot == null) {
      _latest = _latest.copyWith(isLoading: true, clearError: true);
      state = _latest;
    }

    final result = await _repo.getAnalytics(range: arg);
    switch (result) {
      case Success(:final value):
        _latest = SellerAnalyticsState(snapshot: value);
        state = _latest;
      case ResultFailure(:final failure):
        _latest = _latest.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
        state = _latest;
    }
  }
}

final sellerAnalyticsProvider =
    NotifierProvider.family<
      SellerAnalyticsNotifier,
      SellerAnalyticsState,
      AnalyticsRange
    >(SellerAnalyticsNotifier.new);
