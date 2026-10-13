import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/rewards.dart';

/// Contract for the buyer's reward points APIs.
abstract class RewardsRepository {
  Future<Result<RewardsSummary, Failure>> getSummary();

  Future<Result<RewardTransactionsPage, Failure>> getTransactions({
    int page = 1,
    int limit = 20,
  });
}
