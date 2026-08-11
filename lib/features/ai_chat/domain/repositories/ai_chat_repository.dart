import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/ai_chat_language.dart';
import '../models/ai_chat_message.dart';
import '../models/ai_chat_reply.dart';

abstract class AiChatRepository {
  Future<Result<AiChatReply, Failure>> chat({
    String? message,
    List<AiChatHistoryTurn> history = const [],
    String? sessionId,
    List<String> imageUrls = const [],
    AiChatLanguage language = AiChatLanguage.en,
    CancelToken? cancelToken,
  });

  Future<Result<String, Failure>> uploadImage({
    required XFile file,
    CancelToken? cancelToken,
  });

  Future<Result<List<AiChatSessionSummary>, Failure>> listSessions({
    List<String> sessionKeys = const [],
    int limit = 30,
    CancelToken? cancelToken,
  });

  Future<Result<AiChatSessionDetail, Failure>> getSession({
    required String sessionId,
    CancelToken? cancelToken,
  });
}
