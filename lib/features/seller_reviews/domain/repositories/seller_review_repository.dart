import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/seller_review.dart';

abstract class SellerReviewRepository {
  Future<Result<SellerReviewsPage, Failure>> listReviews({
    String? orderId,
    String? sellerId,
    int page = 1,
    int limit = 20,
  });

  Future<Result<SellerReview, Failure>> submitReview(
    SubmitSellerReviewInput input,
  );
}
