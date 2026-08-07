enum HelpIssueType {
  accountIssues('ACCOUNT_ISSUES', 'Account issues'),
  billingPayments('BILLING_PAYMENTS', 'Billing and payments'),
  technicalIssues('TECHNICAL_ISSUES', 'Technical issue'),
  featureRequests('FEATURE_REQUESTS', 'Feature request'),
  generalInquiry('GENERAL_INQUIRY', 'General inquiry'),
  others('OTHERS', 'Other');

  const HelpIssueType(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static HelpIssueType? fromApi(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final type in HelpIssueType.values) {
      if (type.apiValue == raw) return type;
    }
    return null;
  }
}

enum HelpQuestionStatus {
  open('OPEN', 'Open'),
  answered('ANSWERED', 'Answered'),
  closed('CLOSED', 'Closed');

  const HelpQuestionStatus(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static HelpQuestionStatus fromApi(String? raw) {
    for (final status in HelpQuestionStatus.values) {
      if (status.apiValue == raw) return status;
    }
    return HelpQuestionStatus.open;
  }

  bool get canClose => this == HelpQuestionStatus.open;
}

class HelpQuestionUser {
  const HelpQuestionUser({
    required this.id,
    required this.name,
    required this.email,
  });

  final String id;
  final String name;
  final String email;
}

class HelpQuestion {
  const HelpQuestion({
    required this.id,
    required this.subject,
    required this.body,
    required this.issueType,
    required this.status,
    required this.userId,
    required this.createdAtLabel,
    required this.updatedAtLabel,
    this.answer,
    this.answeredAtLabel,
    this.answeredById,
    this.user,
    this.answeredBy,
  });

  final String id;
  final String subject;
  final String body;
  final HelpIssueType issueType;
  final HelpQuestionStatus status;
  final String userId;
  final String createdAtLabel;
  final String updatedAtLabel;
  final String? answer;
  final String? answeredAtLabel;
  final String? answeredById;
  final HelpQuestionUser? user;
  final HelpQuestionUser? answeredBy;

  bool get hasAdminReply =>
      (answer != null && answer!.trim().isNotEmpty) ||
      status == HelpQuestionStatus.answered;

  /// Close only while still open and unanswered.
  bool get canClose => status.canClose && !hasAdminReply;
}
