import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/user_bank_account.dart';

abstract class UserBankAccountRepository {
  Future<Result<UserBankAccountStatus, Failure>> getStatus({
    CancelToken? cancelToken,
  });

  Future<Result<UserBankAccount, Failure>> getAccount({
    CancelToken? cancelToken,
  });

  Future<Result<UserBankAccount, Failure>> upsert(
    UserBankAccountInput input, {
    CancelToken? cancelToken,
  });

  Future<Result<void, Failure>> delete({CancelToken? cancelToken});
}
