/// Jewellery piece reviews (`/marketplace/reviews`).
///
/// One review per delivered order line, 1–5 stars, optional headline (120)
/// and text (2,000), up to 4 photos. Buyers can change a review for 30
/// days; GemWorld can hide one (it then leaves public lists and stars).
library;

/// Limits the server enforces; the app checks them first.
abstract final class JewelryReviewRules {
  static const maxTitle = 120;
  static const maxBody = 2000;
  static const maxPhotos = 4;
  static const maxPhotoBytes = 10 * 1024 * 1024;
  static const maxReply = 1000;
  static const pageSize = 10;
}

/// The buyer's own review, as it sits on an order line.
class JewelryOwnReview {
  const JewelryOwnReview({
    required this.id,
    required this.rating,
    this.title,
    this.body,
    this.imageUrls = const [],
    this.createdAt,
    this.editedAt,
    this.editableUntil,
    this.canEdit = false,
    this.sellerReply,
    this.sellerRepliedAt,
    this.hidden = false,
    this.hiddenReason,
  });

  final String id;
  final int rating;
  final String? title;
  final String? body;
  final List<String> imageUrls;
  final DateTime? createdAt;
  final DateTime? editedAt;

  /// 30 days after [createdAt].
  final DateTime? editableUntil;
  final bool canEdit;
  final String? sellerReply;
  final DateTime? sellerRepliedAt;
  final bool hidden;
  final String? hiddenReason;
}

/// The piece a public review is about.
class JewelryReviewPiece {
  const JewelryReviewPiece({
    required this.title,
    this.imageUrl,
    this.options = const {},
    this.listingSlug,
  });

  final String title;
  final String? imageUrl;

  /// The variant bought, e.g. `Metal: 18K Yellow gold`.
  final Map<String, String> options;

  /// Null once the piece is no longer for sale (show it without a link).
  final String? listingSlug;
}

/// A review in a public list (piece or shop), or in the shop's own list.
class JewelryReview {
  const JewelryReview({
    required this.id,
    required this.rating,
    required this.buyerName,
    required this.piece,
    this.title,
    this.body,
    this.imageUrls = const [],
    this.createdAt,
    this.editedAt,
    this.sellerReply,
    this.sellerRepliedAt,
    this.orderId,
    this.orderNumber,
    this.hidden = false,
    this.hiddenReason,
  });

  final String id;
  final int rating;

  /// Public lists: "Asha M."; the shop's list: the full name.
  final String buyerName;
  final JewelryReviewPiece piece;
  final String? title;
  final String? body;
  final List<String> imageUrls;
  final DateTime? createdAt;
  final DateTime? editedAt;
  final String? sellerReply;
  final DateTime? sellerRepliedAt;

  /// Shop's list only.
  final String? orderId;
  final String? orderNumber;
  final bool hidden;
  final String? hiddenReason;

  bool get hasReply => (sellerReply ?? '').trim().isNotEmpty;

  JewelryReview withReply(String? reply, DateTime? at) => JewelryReview(
    id: id,
    rating: rating,
    buyerName: buyerName,
    piece: piece,
    title: title,
    body: body,
    imageUrls: imageUrls,
    createdAt: createdAt,
    editedAt: editedAt,
    sellerReply: reply,
    sellerRepliedAt: at,
    orderId: orderId,
    orderNumber: orderNumber,
    hidden: hidden,
    hiddenReason: hiddenReason,
  );
}

/// Star summary of every visible review (not just the filtered page).
class JewelryReviewSummary {
  const JewelryReviewSummary({
    this.average,
    this.count = 0,
    this.breakdown = const {},
    this.unanswered,
    this.hidden,
  });

  static const empty = JewelryReviewSummary();

  /// Null with no reviews.
  final double? average;
  final int count;

  /// Stars → reviews.
  final Map<int, int> breakdown;

  /// Shop's list only.
  final int? unanswered;
  final int? hidden;
}

class JewelryReviewPage {
  const JewelryReviewPage({
    required this.summary,
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  static const empty = JewelryReviewPage(
    summary: JewelryReviewSummary.empty,
    items: [],
    total: 0,
    page: 1,
    limit: JewelryReviewRules.pageSize,
  );

  final JewelryReviewSummary summary;
  final List<JewelryReview> items;

  /// Reviews matching the rating filter, for paging.
  final int total;
  final int page;
  final int limit;

  bool get hasMore => page * limit < total;
}

/// `sort` of the review lists.
enum JewelryReviewSort {
  newest('newest'),
  highest('highest'),
  lowest('lowest');

  const JewelryReviewSort(this.api);

  final String api;
}

/// `show` of the shop's list.
enum JewelrySellerReviewShow {
  all('all'),
  unanswered('unanswered'),
  hidden('hidden');

  const JewelrySellerReviewShow(this.api);

  final String api;
}

/// The seller dashboard's review card: `{average, count, unanswered}`.
class JewelrySellerReviewStats {
  const JewelrySellerReviewStats({
    this.average,
    this.count = 0,
    this.unanswered = 0,
  });

  final double? average;
  final int count;
  final int unanswered;
}
