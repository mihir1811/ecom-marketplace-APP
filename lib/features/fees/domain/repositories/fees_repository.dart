import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/fee_rule.dart';

abstract class FeesRepository {
  Future<Result<FeeRulesCatalog, Failure>> listActive({
    CancelToken? cancelToken,
  });
}
