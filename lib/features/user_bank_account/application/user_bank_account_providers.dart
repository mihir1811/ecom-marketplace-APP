import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../data/repositories/user_bank_account_repository_impl.dart';
import '../domain/models/user_bank_account.dart';
import '../domain/repositories/user_bank_account_repository.dart';
import '../../../core/riverpod/dispose_tolerant.dart';

class UserBankAccountState {
  const UserBankAccountState({
    this.status,
    this.account,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  final UserBankAccountStatus? status;
  final UserBankAccount? account;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  bool get hasAccount => status?.hasBankAccount == true || account != null;

  UserBankAccountState copyWith({
    UserBankAccountStatus? status,
    UserBankAccount? account,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
    bool clearAccount = false,
  }) {
    return UserBankAccountState(
      status: status ?? this.status,
      account: clearAccount ? null : (account ?? this.account),
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class UserBankAccountNotifier extends Notifier<UserBankAccountState>
    with DisposeTolerantNotifier<UserBankAccountState> {
  UserBankAccountRepository get _repo =>
      ref.read(userBankAccountRepositoryProvider);

  @override
  UserBankAccountState build() {
    final userId = ref.watch(authProvider.select((s) => s.user?.id));
    if (userId == null || userId.isEmpty) {
      return const UserBankAccountState();
    }
    Future.microtask(load);
    return const UserBankAccountState(isLoading: true);
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final statusResult = await _repo.getStatus();
    if (!ref.mounted) return;
    switch (statusResult) {
      case Success(value: final status):
        if (status.hasBankAccount) {
          final accountResult = await _repo.getAccount();
          if (!ref.mounted) return;
          switch (accountResult) {
            case Success(value: final account):
              state = UserBankAccountState(status: status, account: account);
            case ResultFailure(failure: final failure):
              state = UserBankAccountState(
                status: status,
                errorMessage: failure.message,
              );
          }
        } else {
          state = UserBankAccountState(status: status);
        }
      case ResultFailure(failure: final failure):
        state = UserBankAccountState(errorMessage: failure.message);
    }
  }

  Future<Result<UserBankAccount, Failure>> save(
    UserBankAccountInput input,
  ) async {
    state = state.copyWith(isSaving: true, clearError: true);
    final result = await _repo.upsert(input);
    switch (result) {
      case Success(value: final account):
        state = UserBankAccountState(
          status: UserBankAccountStatus(
            hasBankAccount: true,
            bankAccount: account,
          ),
          account: account,
        );
      case ResultFailure(failure: final failure):
        state = state.copyWith(isSaving: false, errorMessage: failure.message);
    }
    return result;
  }

  Future<Result<void, Failure>> remove() async {
    state = state.copyWith(isSaving: true, clearError: true);
    final result = await _repo.delete();
    switch (result) {
      case Success():
        state = const UserBankAccountState(
          status: UserBankAccountStatus(hasBankAccount: false),
        );
      case ResultFailure(failure: final failure):
        state = state.copyWith(isSaving: false, errorMessage: failure.message);
    }
    return result;
  }
}

final userBankAccountProvider =
    NotifierProvider<UserBankAccountNotifier, UserBankAccountState>(
      UserBankAccountNotifier.new,
    );
