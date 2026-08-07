import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/help_question.dart';
import '../models/help_question_list_page.dart';

abstract class HelpCenterRepository {
  Future<Result<HelpQuestionListPage, Failure>> listMyQuestions({
    required int page,
    int limit = 10,
    CancelToken? cancelToken,
  });

  Future<Result<HelpQuestion, Failure>> getQuestion({
    required String id,
    CancelToken? cancelToken,
  });

  Future<Result<HelpQuestion, Failure>> createQuestion({
    required HelpIssueType issueType,
    required String subject,
    required String body,
    CancelToken? cancelToken,
  });

  Future<Result<HelpQuestion, Failure>> closeQuestion({
    required String id,
    CancelToken? cancelToken,
  });
}
