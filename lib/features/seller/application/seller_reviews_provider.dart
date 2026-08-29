import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../data/repositories/seller_review_repository_impl.dart';
import '../domain/models/seller_review.dart';

final mySellerReviewsProvider = FutureProvider.autoDispose<List<SellerReview>>((
  ref,
) async {
  final result = await ref
      .watch(sellerReviewRepositoryProvider)
      .listReviews(page: 1, limit: 50);
  return switch (result) {
    Success(:final value) => value.reviews,
    ResultFailure(:final failure) => throw failure,
  };
});

final orderSellerReviewsProvider = FutureProvider.autoDispose
    .family<List<SellerReview>, String>((ref, orderId) async {
      final result = await ref
          .watch(sellerReviewRepositoryProvider)
          .listReviews(orderId: orderId, page: 1, limit: 20);
      return switch (result) {
        Success(:final value) => value.reviews,
        ResultFailure(:final failure) => throw failure,
      };
    });

/// Public reviews for a seller — visible regardless of order payment status.
final publicSellerReviewsProvider = FutureProvider.autoDispose
    .family<List<SellerReview>, String>((ref, sellerId) async {
      if (sellerId.isEmpty) return const [];
      final result = await ref
          .watch(sellerReviewRepositoryProvider)
          .listReviews(sellerId: sellerId, page: 1, limit: 20);
      return switch (result) {
        Success(:final value) => value.reviews,
        ResultFailure(:final failure) => throw failure,
      };
    });

/// Imperative submit helper — invalidates review lists on success.
Future<Result<SellerReview, Failure>> submitSellerReview(
  WidgetRef ref,
  SubmitSellerReviewInput input,
) async {
  final result = await ref
      .read(sellerReviewRepositoryProvider)
      .submitReview(input);
  if (result case Success()) {
    ref.invalidate(mySellerReviewsProvider);
    ref.invalidate(orderSellerReviewsProvider(input.orderId));
    ref.invalidate(publicSellerReviewsProvider(input.sellerId));
  }
  return result;
}
