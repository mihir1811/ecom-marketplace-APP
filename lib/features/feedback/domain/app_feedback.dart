/// Categories accepted by `POST /feedback` (Swagger `CreateFeedbackDto`).
enum FeedbackCategory {
  bug('BUG'),
  suggestion('SUGGESTION'),
  uiUx('UI_UX'),
  performance('PERFORMANCE'),
  general('GENERAL');

  const FeedbackCategory(this.apiValue);

  final String apiValue;
}

/// One submitted app feedback entry (`AppFeedbackDataDto`).
class AppFeedback {
  const AppFeedback({
    required this.id,
    required this.category,
    required this.message,
    required this.status,
    this.rating,
    this.pageUrl,
    this.createdAt,
  });

  final String id;
  final String category;
  final String message;

  /// `NEW`, `REVIEWED` or `ARCHIVED`.
  final String status;
  final int? rating;
  final String? pageUrl;
  final DateTime? createdAt;

  factory AppFeedback.fromJson(Map<String, dynamic> json) {
    String? str(Object? v) {
      if (v == null || v is Map || v is List) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    final rating = json['rating'];
    return AppFeedback(
      id: str(json['id']) ?? '',
      category: str(json['category']) ?? FeedbackCategory.general.apiValue,
      message: str(json['message']) ?? '',
      status: str(json['status']) ?? 'NEW',
      rating: rating is num ? rating.toInt() : int.tryParse('$rating'),
      pageUrl: str(json['pageUrl']),
      createdAt: DateTime.tryParse(str(json['createdAt']) ?? '')?.toLocal(),
    );
  }
}

/// Website URL of a buyer order; feedback about an order is tagged with it
/// (`pageUrl`) so it can be matched back to the order.
String orderFeedbackPageUrl(String orderId) =>
    'https://www.gemworld.in/user/orders/$orderId';
