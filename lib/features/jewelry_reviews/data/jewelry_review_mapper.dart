import '../../jewelry/data/mappers/marketplace_json.dart';
import '../domain/models/jewelry_review.dart';

typedef _J = MarketplaceJson;

/// Maps review JSON. Every field is read defensively: older servers leave
/// the review fields out.
abstract final class JewelryReviewMapper {
  /// Order line `review` (null when absent or not an object).
  static JewelryOwnReview? ownOrNull(Object? raw) {
    final j = _J.obj(raw);
    final id = _J.text(j['id']);
    if (id == null) return null;
    return own(j);
  }

  static JewelryOwnReview own(Map<String, dynamic> j) => JewelryOwnReview(
    id: _J.text(j['id']) ?? '',
    rating: _stars(j['rating']),
    title: _J.text(j['title']),
    body: _J.text(j['body']),
    imageUrls: _J.stringList(j['imageUrls']),
    createdAt: _J.date(j['createdAt']),
    editedAt: _J.date(j['editedAt']),
    editableUntil: _J.date(j['editableUntil']),
    canEdit: j['canEdit'] == true,
    sellerReply: _J.text(j['sellerReply']),
    sellerRepliedAt: _J.date(j['sellerRepliedAt']),
    hidden: j['hidden'] == true,
    hiddenReason: _J.text(j['hiddenReason']),
  );

  static JewelryReview review(Map<String, dynamic> j) {
    final piece = _J.obj(j['piece']);
    final order = _J.obj(j['order']);
    return JewelryReview(
      id: _J.text(j['id']) ?? '',
      rating: _stars(j['rating']),
      buyerName: _J.text(j['buyerName']) ?? 'GemWorld buyer',
      piece: JewelryReviewPiece(
        title: _J.text(piece['title']) ?? '',
        imageUrl: _J.text(piece['imageUrl']),
        options: _J.strings(piece['options']),
        listingSlug: _J.text(piece['listingSlug']),
      ),
      title: _J.text(j['title']),
      body: _J.text(j['body']),
      imageUrls: _J.stringList(j['imageUrls']),
      createdAt: _J.date(j['createdAt']),
      editedAt: _J.date(j['editedAt']),
      sellerReply: _J.text(j['sellerReply']),
      sellerRepliedAt: _J.date(j['sellerRepliedAt']),
      orderId: _J.text(order['id']),
      orderNumber: _J.text(order['orderNumber']),
      hidden: j['hidden'] == true,
      hiddenReason: _J.text(j['hiddenReason']),
    );
  }

  static JewelryReviewSummary summary(Object? raw) {
    final j = _J.obj(raw);
    final breakdown = _J.obj(j['breakdown']);
    return JewelryReviewSummary(
      average: _J.decimal(j['average']),
      count: _J.asInt(j['count']),
      breakdown: {for (var s = 1; s <= 5; s++) s: _J.asInt(breakdown['$s'])},
      unanswered: _J.intOrNull(j['unanswered']),
      hidden: _J.intOrNull(j['hidden']),
    );
  }

  static JewelryReviewPage page(Object? raw) {
    final j = _J.obj(raw);
    return JewelryReviewPage(
      summary: summary(j['summary']),
      items: [
        for (final r in _J.listOf(j['items'], review))
          if (r.id.isNotEmpty) r,
      ],
      total: _J.asInt(j['total']),
      page: _J.asInt(j['page'], 1),
      limit: _J.asInt(j['limit'], JewelryReviewRules.pageSize),
    );
  }

  static JewelrySellerReviewStats? stats(Object? raw) {
    final j = _J.obj(raw);
    if (j.isEmpty) return null;
    return JewelrySellerReviewStats(
      average: _J.decimal(j['average']),
      count: _J.asInt(j['count']),
      unanswered: _J.asInt(j['unanswered']),
    );
  }

  /// Shop and listing `ratingAverage`: a string ("4.67"), or null.
  static double? ratingAverage(Object? v) => _J.decimal(v);

  static int _stars(Object? v) => _J.asInt(v, 0).clamp(0, 5);
}
