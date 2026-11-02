import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/help_question.dart';
import '../../domain/models/help_question_list_page.dart';
import '../../domain/repositories/help_center_repository.dart';
import '../mappers/help_question_mapper.dart';

final helpCenterRepositoryProvider = Provider<HelpCenterRepository>(
  (ref) => HelpCenterRepositoryImpl(ref.watch(dioProvider)),
);

class HelpCenterRepositoryImpl implements HelpCenterRepository {
  HelpCenterRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<HelpQuestionListPage, Failure>> listMyQuestions({
    required int page,
    int limit = 10,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.helpCenterQuestionsMine,
        queryParameters: {
          'page': page < 1 ? 1 : page,
          'limit': limit < 1 ? 10 : limit,
          'sort': '-createdAt',
        },
        cancelToken: cancelToken,
      );

      return Result.success(_parseListPage(response.data, page, limit));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<HelpQuestion, Failure>> getQuestion({
    required String id,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.helpCenterQuestionById(id),
        cancelToken: cancelToken,
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        return Result.failure(const ValidationFailure('Question not found.'));
      }
      return Result.success(HelpQuestionMapper.fromJson(data));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<HelpQuestion, Failure>> createQuestion({
    required HelpIssueType issueType,
    required String subject,
    required String body,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.helpCenterQuestions,
        data: {
          'issueType': issueType.apiValue,
          'subject': subject,
          'body': body,
        },
        cancelToken: cancelToken,
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        return Result.failure(
          const UnknownFailure('Unexpected create response.'),
        );
      }
      return Result.success(HelpQuestionMapper.fromJson(data));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<HelpQuestion, Failure>> closeQuestion({
    required String id,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.helpCenterQuestionClose(id),
        cancelToken: cancelToken,
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        return Result.failure(
          const UnknownFailure('Unexpected close response.'),
        );
      }
      return Result.success(HelpQuestionMapper.fromJson(data));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  HelpQuestionListPage _parseListPage(
    Map<String, dynamic>? root,
    int page,
    int limit,
  ) {
    final dataNode = root?['data'];
    final payload = dataNode is Map<String, dynamic>
        ? dataNode
        : const <String, dynamic>{};
    final itemsJson = payload['data'];
    final metaJson = payload['meta'];
    final meta = metaJson is Map<String, dynamic>
        ? metaJson
        : const <String, dynamic>{};

    final list = itemsJson is List ? itemsJson : const [];
    final items = <HelpQuestion>[];
    for (final item in list) {
      if (item is! Map<String, dynamic>) continue;
      final question = HelpQuestionMapper.fromJson(item);
      if (question.id.isEmpty) continue;
      items.add(question);
    }

    final total = _asInt(meta['total']) ?? items.length;
    final currentPage = _asInt(meta['currentPage']) ?? page;
    final lastPage = _asInt(meta['lastPage']) ?? currentPage;
    final perPage = _asInt(meta['perPage']) ?? limit;
    final hasMore = meta.containsKey('next')
        ? meta['next'] != null
        : currentPage < lastPage;

    return HelpQuestionListPage(
      items: items,
      total: total,
      currentPage: currentPage,
      lastPage: lastPage,
      perPage: perPage,
      hasMore: hasMore,
    );
  }

  int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
