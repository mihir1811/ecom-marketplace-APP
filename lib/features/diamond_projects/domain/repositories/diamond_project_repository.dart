import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/diamond_project.dart';
import '../models/diamond_project_item.dart';

/// Contract for authenticated `/diamond-projects` APIs.
abstract class DiamondProjectRepository {
  Future<Result<DiamondProjectPage, Failure>> listMine({
    int page = 1,
    int limit = 20,
    String? search,
    CancelToken? cancelToken,
  });

  Future<Result<DiamondProject, Failure>> getOne(
    String id, {
    CancelToken? cancelToken,
  });

  Future<Result<DiamondProject, Failure>> upsert({
    String? id,
    required String name,
    String? diamondType,
    Map<String, dynamic>? filters,
    Map<String, dynamic>? analytics,
    required List<DiamondProjectItem> items,
    CancelToken? cancelToken,
  });

  Future<Result<DiamondProject, Failure>> update({
    required String id,
    required String name,
    String? diamondType,
    Map<String, dynamic>? filters,
    Map<String, dynamic>? analytics,
    required List<DiamondProjectItem> items,
    CancelToken? cancelToken,
  });

  Future<Result<void, Failure>> remove(String id, {CancelToken? cancelToken});
}
