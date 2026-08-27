import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../data/repositories/api_share_repository_impl.dart';
import '../domain/models/api_share.dart';
import '../domain/repositories/api_share_repository.dart';

class ApiShareState {
  const ApiShareState({
    this.keys = const [],
    this.isLoading = false,
    this.isMutating = false,
    this.errorMessage,
    this.lastGenerated,
  });

  final List<ApiShareKey> keys;
  final bool isLoading;
  final bool isMutating;
  final String? errorMessage;
  final ApiShareKey? lastGenerated;

  ApiShareState copyWith({
    List<ApiShareKey>? keys,
    bool? isLoading,
    bool? isMutating,
    String? errorMessage,
    ApiShareKey? lastGenerated,
    bool clearError = false,
    bool clearLastGenerated = false,
  }) {
    return ApiShareState(
      keys: keys ?? this.keys,
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastGenerated: clearLastGenerated
          ? null
          : (lastGenerated ?? this.lastGenerated),
    );
  }
}

class ApiShareNotifier extends Notifier<ApiShareState> {
  ApiShareRepository get _repo => ref.read(apiShareRepositoryProvider);

  @override
  ApiShareState build() {
    Future.microtask(refresh);
    return const ApiShareState(isLoading: true);
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repo.list();
    switch (result) {
      case Success(value: final keys):
        state = state.copyWith(
          keys: keys,
          isLoading: false,
          clearError: true,
        );
      case ResultFailure(failure: final failure):
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
    }
  }

  Future<Result<ApiShareKey, Failure>> generate({
    required String name,
    required String email,
    required List<ApiSharePermission> permissions,
  }) async {
    state = state.copyWith(isMutating: true, clearError: true);
    final result = await _repo.generate(
      name: name,
      email: email,
      permissions: permissions,
    );
    switch (result) {
      case Success(value: final key):
        final next = [key, ...state.keys.where((k) => k.id != key.id)];
        state = state.copyWith(
          keys: next,
          isMutating: false,
          lastGenerated: key,
          clearError: true,
        );
      case ResultFailure(failure: final failure):
        state = state.copyWith(
          isMutating: false,
          errorMessage: failure.message,
        );
    }
    return result;
  }

  Future<Result<ApiShareKey, Failure>> updatePermissions({
    required String id,
    required List<ApiSharePermission> permissions,
  }) async {
    state = state.copyWith(isMutating: true, clearError: true);
    final result = await _repo.updatePermissions(
      id: id,
      permissions: permissions,
    );
    switch (result) {
      case Success(value: final key):
        state = state.copyWith(
          keys: state.keys.map((k) => k.id == key.id ? key : k).toList(),
          isMutating: false,
          clearError: true,
        );
      case ResultFailure(failure: final failure):
        state = state.copyWith(
          isMutating: false,
          errorMessage: failure.message,
        );
    }
    return result;
  }

  Future<Result<void, Failure>> revoke(String id) async {
    state = state.copyWith(isMutating: true, clearError: true);
    final result = await _repo.delete(id: id);
    switch (result) {
      case Success():
        state = state.copyWith(
          keys: state.keys.where((k) => k.id != id).toList(),
          isMutating: false,
          clearLastGenerated: state.lastGenerated?.id == id,
          clearError: true,
        );
      case ResultFailure(failure: final failure):
        state = state.copyWith(
          isMutating: false,
          errorMessage: failure.message,
        );
    }
    return result;
  }

  void clearLastGenerated() {
    state = state.copyWith(clearLastGenerated: true);
  }
}

final apiShareProvider =
    NotifierProvider<ApiShareNotifier, ApiShareState>(ApiShareNotifier.new);
