/// Buyer review of a seller after a paid order (`/seller-reviews`).
class SellerReview {
  const SellerReview({
    required this.id,
    required this.sellerId,
    required this.userId,
    required this.orderId,
    required this.rating,
    this.title,
    this.comment,
    this.imageUrls = const [],
    this.isVisible = true,
    this.sellerReply,
    this.repliedAt,
    this.createdAt,
    this.updatedAt,
    this.userName,
    this.sellerName,
    this.sellerLogo,
  });

  final String id;
  final String sellerId;
  final String userId;
  final String orderId;
  final int rating;
  final String? title;
  final String? comment;
  final List<String> imageUrls;
  final bool isVisible;
  final String? sellerReply;
  final DateTime? repliedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? userName;
  final String? sellerName;
  final String? sellerLogo;
}

class SellerReviewsPage {
  const SellerReviewsPage({
    required this.reviews,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<SellerReview> reviews;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;
}

class SubmitSellerReviewInput {
  const SubmitSellerReviewInput({
    required this.sellerId,
    required this.orderId,
    required this.rating,
    this.title,
    this.comment,
  });

  final String sellerId;
  final String orderId;
  final int rating;
  final String? title;
  final String? comment;
}
