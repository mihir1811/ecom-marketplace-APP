import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../payment/domain/models/payment_models.dart';
import '../models/auction_models.dart';

/// Auction HTTP API. Screens depend on this, not on Dio.
abstract class AuctionRepository {
  Future<Result<AuctionSettings, Failure>> settings();

  Future<Result<AuctionPenalty, Failure>> myPenalty();

  Future<Result<AuctionPage, Failure>> live({
    int page = 1,
    int limit = 20,
    String? productType,
  });

  Future<Result<AuctionListing, Failure>> byId(String id);

  Future<Result<AuctionPage, Failure>> myWins({
    int page = 1,
    int limit = 20,
    String? productType,
  });

  Future<Result<AuctionPage, Failure>> myActivity({
    int page = 1,
    int limit = 20,
    String? productType,
    String outcome = 'all',
  });

  Future<Result<AuctionPage, Failure>> sellerAuctions({
    int page = 1,
    int limit = 20,
    String? productType,
    String? status,
  });

  /// Active, upcoming, ended, sold, and bid totals for the signed-in seller.
  Future<Result<SellerAuctionStanding, Failure>> sellerStanding();

  Future<Result<List<AuctionBid>, Failure>> bids(String auctionId);

  Future<Result<AuctionMutation, Failure>> placeBid({
    required String auctionId,
    required double amount,
  });

  Future<Result<AuctionMutation, Failure>> cancelBid(String bidId);

  Future<Result<AuctionMutation, Failure>> declineWin(String auctionId);

  Future<Result<PaymentCheckoutSession, Failure>> createPayment({
    required String auctionId,
    required bool useWallet,
  });

  Future<Result<AuctionMutation, Failure>> verifyPayment({
    required String auctionId,
    required String orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  });

  Future<Result<AuctionMutation, Failure>> create({
    required String productId,
    required String productType,
    required DateTime startTime,
    required DateTime endTime,
    required double minimumBid,
    double? reservePrice,
  });

  Future<Result<AuctionBulkResult, Failure>> bulkCreate({
    required DateTime startTime,
    required DateTime endTime,
    required List<AuctionBulkDraft> items,
  });

  Future<Result<AuctionMutation, Failure>> end(String auctionId);

  Future<Result<AuctionMutation, Failure>> accept({
    required String auctionId,
    String? bidId,
  });

  Future<Result<AuctionMutation, Failure>> reject({
    required String auctionId,
    required String action,
    DateTime? startTime,
    DateTime? endTime,
    double? minimumBid,
    double? reservePrice,
  });

  Future<Result<AuctionMutation, Failure>> selectWinner({
    required String auctionId,
    required String bidderId,
  });

  Future<Result<AuctionMutation, Failure>> delete(String auctionId);
}
