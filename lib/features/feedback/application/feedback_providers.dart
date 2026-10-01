import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../data/feedback_repository.dart';
import '../domain/app_feedback.dart';

/// Feedback the buyer already sent about [orderId] (newest first).
final orderFeedbackProvider = FutureProvider.autoDispose
    .family<List<AppFeedback>, String>((ref, orderId) async {
      final result = await ref.watch(feedbackRepositoryProvider).listMine();
      final pageUrl = orderFeedbackPageUrl(orderId);
      return switch (result) {
        Success(:final value) =>
          value.where((f) => f.pageUrl == pageUrl).toList(),
        ResultFailure(:final failure) => throw failure,
      };
    });

/// `true` while a feedback submission is in flight.
class FeedbackSubmitNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  Future<Result<AppFeedback, Failure>> submitForOrder({
    required String orderId,
    required String message,
    required int rating,
  }) async {
    if (state) {
      return Result.failure(
        const ValidationFailure('Your feedback is already being sent.'),
      );
    }
    state = true;
    try {
      final result = await ref
          .read(feedbackRepositoryProvider)
          .submit(
            category: FeedbackCategory.general,
            message: message,
            rating: rating,
            pageUrl: orderFeedbackPageUrl(orderId),
          );
      ref.invalidate(orderFeedbackProvider(orderId));
      return result;
    } finally {
      state = false;
    }
  }
}

final feedbackSubmitProvider = NotifierProvider<FeedbackSubmitNotifier, bool>(
  FeedbackSubmitNotifier.new,
);
