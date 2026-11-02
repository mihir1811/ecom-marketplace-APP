import '../../domain/models/help_question.dart';

abstract final class HelpQuestionMapper {
  static HelpQuestion fromJson(Map<String, dynamic> json) {
    final user = _userFromJson(json['user']);
    final answeredBy = _userFromJson(json['answeredBy']);
    final createdAt = _parseDate(json['createdAt']);
    final updatedAt = _parseDate(json['updatedAt']) ?? createdAt;
    final answeredAt = _parseDate(json['answeredAt']);

    return HelpQuestion(
      id: json['id']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      issueType:
          HelpIssueType.fromApi(json['issueType']?.toString()) ??
          HelpIssueType.generalInquiry,
      status: HelpQuestionStatus.fromApi(json['status']?.toString()),
      userId: json['userId']?.toString() ?? user?.id ?? '',
      createdAtLabel: _label(createdAt),
      updatedAtLabel: _label(updatedAt),
      answer: json['answer']?.toString(),
      answeredAtLabel: answeredAt != null ? _label(answeredAt) : null,
      answeredById: json['answeredById']?.toString(),
      user: user,
      answeredBy: answeredBy,
    );
  }

  static HelpQuestionUser? _userFromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    return HelpQuestionUser(
      id: raw['id']?.toString() ?? '',
      name: raw['name']?.toString() ?? '',
      email: raw['email']?.toString() ?? '',
    );
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  static String _label(DateTime? date) {
    if (date == null) return '—';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}, '
        '${two(date.hour)}:${two(date.minute)}:${two(date.second)}';
  }
}
