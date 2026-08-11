import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/ai_chat_language.dart';
import '../../domain/models/ai_chat_message.dart';
import '../../domain/models/ai_chat_reply.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import '../mappers/ai_chat_mapper.dart';

final aiChatRepositoryProvider = Provider<AiChatRepository>(
  (ref) => AiChatRepositoryImpl(ref.watch(dioProvider)),
);

class AiChatRepositoryImpl implements AiChatRepository {
  AiChatRepositoryImpl(this._dio);

  final Dio _dio;

  static const _chatReceiveTimeout = Duration(seconds: 120);

  @override
  Future<Result<AiChatReply, Failure>> chat({
    String? message,
    List<AiChatHistoryTurn> history = const [],
    String? sessionId,
    List<String> imageUrls = const [],
    AiChatLanguage language = AiChatLanguage.en,
    CancelToken? cancelToken,
  }) async {
    try {
      final body = <String, dynamic>{
        'language': language.apiValue,
      };
      final trimmed = message?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        body['message'] = trimmed;
      }
      if (sessionId != null && sessionId.isNotEmpty) {
        body['sessionId'] = sessionId;
      }
      if (imageUrls.isNotEmpty) {
        body['imageUrls'] = imageUrls.take(1).toList();
      }
      if (history.isNotEmpty) {
        body['history'] = history.map((t) => t.toJson()).toList();
      }

      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.aiChat,
        data: body,
        cancelToken: cancelToken,
        options: Options(receiveTimeout: _chatReceiveTimeout),
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        return Result.failure(const UnknownFailure('Unexpected chat response.'));
      }
      return Result.success(AiChatMapper.replyFromJson(data));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<String, Failure>> uploadImage({
    required XFile file,
    CancelToken? cancelToken,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      final filename = file.name.trim().isEmpty ? 'chat-image.jpg' : file.name;
      final form = FormData.fromMap({
        'image': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.aiChatUploadImage,
        data: form,
        cancelToken: cancelToken,
      );
      final data = response.data?['data'];
      final url = data is Map ? data['url']?.toString() : null;
      if (url == null || url.isEmpty) {
        return Result.failure(const UnknownFailure('Unexpected upload response.'));
      }
      return Result.success(url);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<AiChatSessionSummary>, Failure>> listSessions({
    List<String> sessionKeys = const [],
    int limit = 30,
    CancelToken? cancelToken,
  }) async {
    try {
      final query = <String, dynamic>{
        'limit': limit < 1 ? 30 : limit,
      };
      if (sessionKeys.isNotEmpty) {
        query['sessionKeys'] = sessionKeys.join(',');
      }
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.aiChatSessions,
        queryParameters: query,
        cancelToken: cancelToken,
      );
      final data = response.data?['data'];
      if (data is! List) {
        return Result.success(const []);
      }
      final sessions = <AiChatSessionSummary>[];
      for (final item in data) {
        if (item is! Map<String, dynamic>) continue;
        final session = AiChatMapper.sessionSummaryFromJson(item);
        if (session.sessionId.isEmpty) continue;
        sessions.add(session);
      }
      return Result.success(sessions);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<AiChatSessionDetail, Failure>> getSession({
    required String sessionId,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.aiChatSessionById(sessionId),
        cancelToken: cancelToken,
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        return Result.failure(const ValidationFailure('Session not found.'));
      }
      return Result.success(AiChatMapper.sessionDetailFromJson(data));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }
}
