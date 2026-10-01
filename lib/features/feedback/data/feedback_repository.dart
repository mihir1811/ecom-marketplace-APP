import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/app_feedback.dart';

final feedbackRepositoryProvider = Provider<FeedbackRepository>(
  (ref) => FeedbackRepository(ref.watch(dioProvider)),
);

/// `POST /feedback` and `GET /feedback/mine`.
class FeedbackRepository {
  FeedbackRepository(this._dio);

  final Dio _dio;

  Future<Result<AppFeedback, Failure>> submit({
    required FeedbackCategory category,
    required String message,
    int? rating,
    String? pageUrl,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.feedback,
        data: {
          'category': category.apiValue,
          'message': message,
          if (rating != null) 'rating': rating,
          if (pageUrl != null) 'pageUrl': pageUrl,
        },
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        return Result.failure(
          const NetworkFailure('Could not submit your feedback.'),
        );
      }
      return Result.success(AppFeedback.fromJson(data));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  Future<Result<List<AppFeedback>, Failure>> listMine({int limit = 50}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.feedbackMine,
        queryParameters: {'page': 1, 'limit': limit, 'sort': '-createdAt'},
      );
      final data = response.data?['data'];
      final rows = data is Map ? data['data'] : data;
      final out = <AppFeedback>[];
      if (rows is List) {
        for (final row in rows) {
          if (row is Map) {
            out.add(AppFeedback.fromJson(Map<String, dynamic>.from(row)));
          }
        }
      }
      return Result.success(out);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }
}
