import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
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
  CancelToken? _cancelToken;

  SellerInsightsRepository get _repo =>
      ref.read(sellerInsightsRepositoryProvider);

  @override
  SellerDashboardState build(SellerDashboardParams arg) {
    ref.onDispose(() {
      _cancelToken?.cancel();
    });
    Future.microtask(refresh);
    return const SellerDashboardState(isLoading: true);
  }

  Future<void> refresh() async {
    _cancelToken?.cancel('refresh');
    _cancelToken = CancelToken();
    if (state.snapshot == null) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    final result = await _repo.getDashboard(
      params: arg,
      cancelToken: _cancelToken,
    );
    switch (result) {
      case Success(:final value):
        state = SellerDashboardState(snapshot: value);
      case ResultFailure(:final failure):
        if (failure is NetworkFailure && failure.isCancelled) return;
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
    }
  }
}

final sellerDashboardProvider = NotifierProvider.family<
    SellerDashboardNotifier, SellerDashboardState, SellerDashboardParams>(
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
  CancelToken? _cancelToken;
  Timer? _poll;

  SellerInsightsRepository get _repo =>
      ref.read(sellerInsightsRepositoryProvider);

  @override
  SellerAnalyticsState build(AnalyticsRange arg) {
    ref.onDispose(() {
      _poll?.cancel();
      _cancelToken?.cancel();
    });
    _poll = Timer.periodic(const Duration(seconds: 20), (_) {
      refresh(silent: true);
    });
    Future.microtask(refresh);
    return const SellerAnalyticsState(isLoading: true);
  }

  Future<void> refresh({bool silent = false}) async {
    _cancelToken?.cancel('refresh');
    _cancelToken = CancelToken();
    if (!silent || state.snapshot == null) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    final result = await _repo.getAnalytics(
      range: arg,
      cancelToken: _cancelToken,
    );
    switch (result) {
      case Success(:final value):
        state = SellerAnalyticsState(snapshot: value);
      case ResultFailure(:final failure):
        if (failure is NetworkFailure && failure.isCancelled) return;
        if (silent && state.snapshot != null) return;
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
    }
  }
}

final sellerAnalyticsProvider = NotifierProvider.family<
    SellerAnalyticsNotifier, SellerAnalyticsState, AnalyticsRange>(
  SellerAnalyticsNotifier.new,
);
