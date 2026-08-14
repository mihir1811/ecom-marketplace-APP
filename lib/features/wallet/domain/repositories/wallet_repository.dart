import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../payment/domain/models/payment_models.dart';
import '../models/wallet.dart';

/// Contract for authenticated wallet APIs.
abstract class WalletRepository {
  Future<Result<Wallet, Failure>> getWallet();

  Future<Result<WalletTransactionsPage, Failure>> getTransactions({
    int page = 1,
    int limit = 20,
  });

  Future<Result<WalletTopUpSession, Failure>> createTopUp({
    required double amountInr,
  });

  Future<Result<Wallet, Failure>> verifyTopUp({
    required RazorpayPaymentSuccess success,
  });
}
