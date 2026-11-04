import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/dio_provider.dart';
import '../../jewelry/data/mappers/marketplace_json.dart';
import '../domain/models/jewelry_review.dart';
import 'jewelry_review_mapper.dart';

/// A new photo picked for a review, read into memory (works on web too).
class JewelryReviewPhoto {
  const JewelryReviewPhoto({
    required this.bytes,
    required this.name,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String name;

  /// `image/jpeg`, `image/png` or `image/webp`: the server checks the part's
  /// content type, not the file name.
  final String mimeType;
}

final jewelryReviewRepositoryProvider = Provider<JewelryReviewRepository>(
  (ref) => JewelryReviewRepository(ref.watch(dioProvider)),
);

/// Which public list to read.
enum JewelryReviewSource { listing, shop }

class JewelryReviewRepository {
  JewelryReviewRepository(this._dio);

  final Dio _dio;

  /// Reviews a delivered order line. Answers the new review.
  Future<Result<({JewelryOwnReview review, String? message}), Failure>> post({
    required String orderItemId,
    required int rating,
    String title = '',
    String body = '',
    List<JewelryReviewPhoto> photos = const [],
  }) => _guard(() async {
    final form = FormData()
      ..fields.add(MapEntry('orderItemId', orderItemId))
      ..fields.add(MapEntry('rating', '$rating'));
    _text(form, title, body);
    _photos(form, photos);
    final response = await _dio.post<Object?>(
      ApiEndpoints.marketplaceReviews,
      data: form,
    );
    return _own(response.data);
  });

  /// Replaces a review: the full text again, the saved photo URLs to keep,
  /// and any new photos. A title or body left out is removed.
  Future<Result<({JewelryOwnReview review, String? message}), Failure>> edit({
    required String reviewId,
    required int rating,
    required List<String> keepPhotos,
    String title = '',
    String body = '',
    List<JewelryReviewPhoto> photos = const [],
  }) => _guard(() async {
    final form = FormData()
      ..fields.add(MapEntry('rating', '$rating'))
      ..fields.add(MapEntry('keepPhotos', jsonEncode(keepPhotos)));
    _text(form, title, body);
    _photos(form, photos);
    final response = await _dio.put<Object?>(
      ApiEndpoints.marketplaceReview(reviewId),
      data: form,
    );
    return _own(response.data);
  });

  /// One page of a piece's or a shop's reviews. A 404 (piece not live,
  /// shop hidden, or an older server) reads as no reviews.
  Future<Result<JewelryReviewPage, Failure>> list({
    required JewelryReviewSource source,
    required String slug,
    int page = 1,
    int? rating,
    JewelryReviewSort sort = JewelryReviewSort.newest,
  }) async {
    try {
      final response = await _dio.get<Object?>(
        source == JewelryReviewSource.listing
            ? ApiEndpoints.marketplaceListingReviews(slug)
            : ApiEndpoints.marketplaceShopReviews(slug),
        queryParameters: {
          'page': page,
          'limit': JewelryReviewRules.pageSize,
          'sort': sort.api,
          'rating': ?rating,
        },
      );
      return Result.success(
        JewelryReviewMapper.page(MarketplaceJson.data(response.data)),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return Result.success(JewelryReviewPage.empty);
      }
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  /// The signed-in shop's reviews, hidden ones included.
  Future<Result<JewelryReviewPage, Failure>> sellerList({
    int page = 1,
    int? rating,
    JewelryReviewSort sort = JewelryReviewSort.newest,
    JewelrySellerReviewShow show = JewelrySellerReviewShow.all,
  }) => _guard(() async {
    final response = await _dio.get<Object?>(
      ApiEndpoints.marketplaceSellerReviews,
      queryParameters: {
        'page': page,
        'limit': JewelryReviewRules.pageSize,
        'sort': sort.api,
        'show': show.api,
        'rating': ?rating,
      },
    );
    return JewelryReviewMapper.page(MarketplaceJson.data(response.data));
  });

  /// Posts or replaces the shop's public reply.
  Future<Result<({JewelryReview? review, String? message}), Failure>> reply(
    String reviewId,
    String reply,
  ) => _guard(() async {
    final response = await _dio.put<Object?>(
      ApiEndpoints.marketplaceSellerReviewReply(reviewId),
      data: {'reply': reply.trim()},
    );
    return _sellerReview(response.data);
  });

  /// Removes the shop's reply.
  Future<Result<({JewelryReview? review, String? message}), Failure>>
  deleteReply(String reviewId) => _guard(() async {
    final response = await _dio.delete<Object?>(
      ApiEndpoints.marketplaceSellerReviewReply(reviewId),
    );
    return _sellerReview(response.data);
  });

  /// The `reviews` card of the seller dashboard; null when it is missing.
  Future<Result<JewelrySellerReviewStats?, Failure>> sellerStats() =>
      _guard(() async {
        final response = await _dio.get<Object?>(
          ApiEndpoints.marketplaceSellerDashboard,
        );
        final data = MarketplaceJson.obj(MarketplaceJson.data(response.data));
        return JewelryReviewMapper.stats(data['reviews']);
      });

  static void _text(FormData form, String title, String body) {
    if (title.trim().isNotEmpty) {
      form.fields.add(MapEntry('title', title.trim()));
    }
    if (body.trim().isNotEmpty) form.fields.add(MapEntry('body', body.trim()));
  }

  static void _photos(FormData form, List<JewelryReviewPhoto> photos) {
    for (final p in photos) {
      form.files.add(
        MapEntry(
          'photos',
          MultipartFile.fromBytes(
            p.bytes,
            filename: p.name,
            contentType: DioMediaType.parse(p.mimeType),
          ),
        ),
      );
    }
  }

  static ({JewelryOwnReview review, String? message}) _own(Object? root) => (
    review: JewelryReviewMapper.own(
      MarketplaceJson.obj(MarketplaceJson.data(root)),
    ),
    message: MarketplaceJson.text(MarketplaceJson.obj(root)['message']),
  );

  static ({JewelryReview? review, String? message}) _sellerReview(
    Object? root,
  ) {
    final data = MarketplaceJson.obj(MarketplaceJson.data(root));
    return (
      review: MarketplaceJson.text(data['id']) == null
          ? null
          : JewelryReviewMapper.review(data),
      message: MarketplaceJson.text(MarketplaceJson.obj(root)['message']),
    );
  }

  static Future<Result<T, Failure>> _guard<T>(Future<T> Function() run) async {
    try {
      return Result.success(await run());
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }
}

/// The server's first message (validation errors arrive as a list, which
/// [ApiError] joins with new lines).
String jewelryReviewError(Failure failure) {
  final first = failure.message
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .firstOrNull;
  return first ?? failure.message;
}
