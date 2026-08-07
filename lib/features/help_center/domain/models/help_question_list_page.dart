import 'help_question.dart';

class HelpQuestionListPage {
  const HelpQuestionListPage({
    required this.items,
    required this.total,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.hasMore,
  });

  final List<HelpQuestion> items;
  final int total;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final bool hasMore;

  static const empty = HelpQuestionListPage(
    items: [],
    total: 0,
    currentPage: 1,
    lastPage: 0,
    perPage: 10,
    hasMore: false,
  );
}
