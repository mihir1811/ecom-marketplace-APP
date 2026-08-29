import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../data/repositories/fees_repository_impl.dart';
import '../domain/models/fee_rule.dart';
import '../domain/repositories/fees_repository.dart';

/// Active checkout fee rules for the signed-in session.
final activeFeesProvider =
    AsyncNotifierProvider<ActiveFeesNotifier, FeeRulesCatalog>(
      ActiveFeesNotifier.new,
    );

class ActiveFeesNotifier extends AsyncNotifier<FeeRulesCatalog> {
  CancelToken? _cancelToken;

  FeesRepository get _repo => ref.read(feesRepositoryProvider);

  @override
  Future<FeeRulesCatalog> build() async {
    ref.onDispose(() => _cancelToken?.cancel());
    final authenticated = ref.watch(
      authProvider.select((s) => s.isAuthenticated),
    );
    if (!authenticated) return FeeRulesCatalog.empty;

    _cancelToken?.cancel('rebuild');
    _cancelToken = CancelToken();
    final result = await _repo.listActive(cancelToken: _cancelToken);
    return switch (result) {
      Success(value: final catalog) => catalog,
      ResultFailure(failure: final failure) =>
        failure is NetworkFailure && failure.isCancelled
            ? FeeRulesCatalog.empty
            : FeeRulesCatalog.empty,
    };
  }

  Future<void> refresh() async {
    final authenticated = ref.read(
      authProvider.select((s) => s.isAuthenticated),
    );
    if (!authenticated) {
      state = const AsyncValue.data(FeeRulesCatalog.empty);
      return;
    }
    _cancelToken?.cancel('refresh');
    _cancelToken = CancelToken();
    final result = await _repo.listActive(cancelToken: _cancelToken);
    state = switch (result) {
      Success(value: final catalog) => AsyncValue.data(catalog),
      ResultFailure(failure: final failure) =>
        failure is NetworkFailure && failure.isCancelled
            ? state
            : const AsyncValue.data(FeeRulesCatalog.empty),
    };
  }
}
