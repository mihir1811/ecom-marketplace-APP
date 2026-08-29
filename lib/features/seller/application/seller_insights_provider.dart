import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../data/repositories/seller_insights_repository_impl.dart';
import '../domain/models/seller_insights.dart';
import '../domain/repositories/seller_insights_repository.dart';

class SellerDashboardState {
  const SellerDashboardState({
    this.snapshot,
    this.isLoading = false,
    this.errorMessage,
  });

  final SellerDashboardSnapshot? snapshot;
  final bool isLoading;
  final String? errorMessage;

  SellerDashboardState copyWith({
    SellerDashboardSnapshot? snapshot,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SellerDashboardState(
      snapshot: snapshot ?? this.snapshot,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class SellerDashboardNotifier
    extends FamilyNotifier<SellerDashboardState, SellerDashboardParams> {
  bool _started = false;
  Future<void>? _inFlight;
  SellerDashboardState _latest = const SellerDashboardState(isLoading: true);

  SellerInsightsRepository get _repo =>
      ref.read(sellerInsightsRepositoryProvider);

  @override
  SellerDashboardState build(SellerDashboardParams arg) {
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

    final result = await _repo.getDashboard(params: arg);
    switch (result) {
      case Success(:final value):
        _latest = SellerDashboardState(snapshot: value);
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

final sellerDashboardProvider =
    NotifierProvider.family<
      SellerDashboardNotifier,
      SellerDashboardState,
      SellerDashboardParams
    >(SellerDashboardNotifier.new);

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

  SellerInsightsRepository get _repo =>
      ref.read(sellerInsightsRepositoryProvider);

  @override
  SellerAnalyticsState build(AnalyticsRange arg) {
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
