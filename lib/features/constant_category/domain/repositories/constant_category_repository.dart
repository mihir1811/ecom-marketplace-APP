import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/constant_category.dart';

abstract class ConstantCategoryRepository {
  Future<Result<ConstantCategoryListPage, Failure>> list({
    required int page,
    int limit = 10,
    String? search,
    CancelToken? cancelToken,
  });

  Future<Result<ConstantCategoryEntry, Failure>> update({
    required String id,
    required ConstantCategoryUpdateInput input,
    CancelToken? cancelToken,
  });
}
