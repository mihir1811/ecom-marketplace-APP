import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../data/repositories/login_history_repository_impl.dart';
import '../domain/models/login_session.dart';
import '../domain/repositories/login_history_repository.dart';

class LoginHistoryState {
  const LoginHistoryState({
    this.sessions = const [],
    this.activeDevices = const [],
    this.isLoading = false,
    this.isMutating = false,
    this.errorMessage,
  });

  final List<LoginSession> sessions;
  final List<ActiveSellerDevice> activeDevices;
  final bool isLoading;
  final bool isMutating;
  final String? errorMessage;

  LoginHistoryState copyWith({
    List<LoginSession>? sessions,
    List<ActiveSellerDevice>? activeDevices,
    bool? isLoading,
    bool? isMutating,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LoginHistoryState(
      sessions: sessions ?? this.sessions,
      activeDevices: activeDevices ?? this.activeDevices,
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class LoginHistoryNotifier extends Notifier<LoginHistoryState> {
  LoginHistoryRepository get _repo => ref.read(loginHistoryRepositoryProvider);

  @override
  LoginHistoryState build() {
    Future.microtask(refresh);
    return const LoginHistoryState(isLoading: true);
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final historyResult = await _repo.listHistory();
    final devicesResult = await _repo.listActiveSellerDevices();
    switch ((historyResult, devicesResult)) {
      case (Success(value: final sessions), Success(value: final devices)):
        state = LoginHistoryState(
          sessions: sessions,
          activeDevices: devices,
        );
      case (ResultFailure(failure: final f), _):
        state = LoginHistoryState(errorMessage: f.message);
      case (_, ResultFailure(failure: final f)):
        state = LoginHistoryState(errorMessage: f.message);
    }
  }

  Future<Result<void, Failure>> revoke(String sessionId) async {
    state = state.copyWith(isMutating: true, clearError: true);
    final result = await _repo.revokeSession(sessionId: sessionId);
    switch (result) {
      case Success():
        state = LoginHistoryState(
          sessions: state.sessions.where((s) => s.id != sessionId).toList(),
          activeDevices:
              state.activeDevices.where((d) => d.id != sessionId).toList(),
        );
      case ResultFailure(failure: final failure):
        state = state.copyWith(
          isMutating: false,
          errorMessage: failure.message,
        );
    }
    return result;
  }
}

final loginHistoryProvider =
    NotifierProvider<LoginHistoryNotifier, LoginHistoryState>(
  LoginHistoryNotifier.new,
);
