import '../../domain/models/seller_review.dart';

abstract final class SellerReviewMapper {
  static SellerReview fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final userMap = user is Map<String, dynamic>
        ? user
        : const <String, dynamic>{};
    final seller = json['seller'];
    final sellerMap = seller is Map<String, dynamic>
        ? seller
        : const <String, dynamic>{};

    final images = <String>[];
    final rawImages = json['imageUrls'];
    if (rawImages is List) {
      for (final i in rawImages) {
        final s = _str(i);
        if (s != null) images.add(s);
      }
    }

    return SellerReview(
      id: _str(json['id']) ?? '',
      sellerId: _str(json['sellerId']) ?? '',
      userId: _str(json['userId']) ?? '',
      orderId: _str(json['orderId']) ?? '',
      rating: _int(json['rating']) ?? 0,
      title: _str(json['title']),
      comment: _str(json['comment']),
      imageUrls: images,
      isVisible: json['isVisible'] != false,
      sellerReply: _str(json['sellerReply']),
      repliedAt: _date(json['repliedAt']),
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
      userName: _buyerDisplayName(userMap),
      sellerName:
          _str(sellerMap['companyName']) ??
          _str(sellerMap['name']) ??
          _str(sellerMap['fullName']),
      sellerLogo: _str(sellerMap['companyLogo']),
    );
  }

  static String? _buyerDisplayName(Map<String, dynamic> user) {
    return _str(user['fullName']) ??
        _str(user['name']) ??
        _str(user['username']) ??
        _str(user['email']);
  }

  static SellerReviewsPage pageFromResponse(Map<String, dynamic> root) {
    final data = root['data'];
    final dataMap = data is Map<String, dynamic>
        ? data
        : const <String, dynamic>{};
    final listJson = dataMap['data'] ?? data;
    final reviews = <SellerReview>[];
    if (listJson is List) {
      for (final item in listJson) {
        if (item is! Map<String, dynamic>) continue;
        final review = fromJson(item);
        if (review.id.isEmpty) continue;
        reviews.add(review);
      }
    }

    final meta = dataMap['meta'] ?? root['meta'];
    final metaMap = meta is Map<String, dynamic>
        ? meta
        : const <String, dynamic>{};

    return SellerReviewsPage(
      reviews: reviews,
      page: _int(metaMap['currentPage']) ?? 1,
      limit: _int(metaMap['perPage']) ?? reviews.length,
      total: _int(metaMap['total']) ?? reviews.length,
      totalPages: _int(metaMap['lastPage']) ?? 1,
    );
  }

  static String? _str(Object? v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static int? _int(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static DateTime? _date(Object? v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}
