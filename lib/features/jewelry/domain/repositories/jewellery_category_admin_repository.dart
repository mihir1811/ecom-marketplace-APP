import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/jewellery_category_admin.dart';

abstract class JewelleryCategoryAdminRepository {
  Future<Result<JewelleryCategoryListPage, Failure>> list({
    int page = 1,
    int limit = 50,
    String? search,
    CancelToken? cancelToken,
  });

  Future<Result<JewelleryCategoryAdmin, Failure>> getById(
    String id, {
    CancelToken? cancelToken,
  });

  Future<Result<JewelleryCategoryAdmin, Failure>> create(
    JewelleryCategoryInput input, {
    CancelToken? cancelToken,
  });

  Future<Result<JewelleryCategoryAdmin, Failure>> update(
    String id,
    JewelleryCategoryInput input, {
    CancelToken? cancelToken,
  });

  Future<Result<void, Failure>> deactivate(
    String id, {
    CancelToken? cancelToken,
  });

  Future<Result<JewellerySubcategoryAdmin, Failure>> addSubcategory(
    String categoryId,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  });

  Future<Result<JewellerySubcategoryAdmin, Failure>> updateSubcategory(
    String subcategoryId,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  });

  Future<Result<void, Failure>> deactivateSubcategory(
    String subcategoryId, {
    CancelToken? cancelToken,
  });
}
