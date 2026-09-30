import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../payment/domain/models/payment_models.dart';
import '../../domain/models/auction_models.dart';
import '../../domain/repositories/auction_repository.dart';
import '../mappers/auction_mapper.dart';

final auctionRepositoryProvider = Provider<AuctionRepository>(
  (ref) => AuctionRepositoryImpl(ref.watch(dioProvider)),
);

class AuctionRepositoryImpl implements AuctionRepository {
  AuctionRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<AuctionSettings, Failure>> settings() {
    return _guard(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.auctionSettings,
      );
      return AuctionMapper.settingsFromEnvelope(response.data);
    });
  }

  @override
  Future<Result<AuctionPenalty, Failure>> myPenalty() {
    return _guard(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.auctionMyPenalty,
      );
      return AuctionMapper.penaltyFromEnvelope(response.data);
    });
  }

  @override
  Future<Result<AuctionPage, Failure>> live({
    int page = 1,
    int limit = 20,
    String? productType,
  }) {
    return _page(
      ApiEndpoints.auctionLive,
      page: page,
      limit: limit,
      productType: productType,
    );
  }

  @override
  Future<Result<AuctionListing, Failure>> byId(String id) {
    return _guard(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.auctionById(id),
      );
      return AuctionMapper.listingFromEnvelope(response.data);
    });
  }

  @override
  Future<Result<AuctionPage, Failure>> myWins({
    int page = 1,
    int limit = 20,
    String? productType,
  }) {
    return _page(
      ApiEndpoints.auctionMyWins,
      page: page,
      limit: limit,
      productType: productType,
    );
  }

  @override
  Future<Result<AuctionPage, Failure>> myActivity({
    int page = 1,
    int limit = 20,
    String? productType,
    String outcome = 'all',
  }) {
    return _page(
      ApiEndpoints.auctionMyActivity,
      page: page,
      limit: limit,
      productType: productType,
      extra: {'outcome': outcome},
    );
  }

  @override
  Future<Result<AuctionPage, Failure>> sellerAuctions({
    int page = 1,
    int limit = 20,
    String? productType,
    String? status,
  }) {
    return _page(
      ApiEndpoints.auctionSeller,
      page: page,
      limit: limit,
      productType: productType,
      extra: {if (status != null && status.isNotEmpty) 'status': status},
    );
  }

  @override
  Future<Result<List<AuctionBid>, Failure>> bids(String auctionId) {
    return _guard(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.auctionBids(auctionId),
      );
      return AuctionMapper.bidsFromEnvelope(response.data);
    });
  }

  @override
  Future<Result<AuctionMutation, Failure>> placeBid({
    required String auctionId,
    required double amount,
  }) {
    return _mutation(
      () => _dio.post<Map<String, dynamic>>(
        ApiEndpoints.auctionBid,
        data: {'auctionId': auctionId, 'amount': amount},
      ),
    );
  }

  @override
  Future<Result<AuctionMutation, Failure>> cancelBid(String bidId) {
    return _mutation(
      () => _dio.delete<Map<String, dynamic>>(
        ApiEndpoints.auctionCancelBid(bidId),
      ),
    );
  }

  @override
  Future<Result<AuctionMutation, Failure>> declineWin(String auctionId) {
    return _mutation(
      () => _dio.post<Map<String, dynamic>>(
        ApiEndpoints.auctionDeclineWin(auctionId),
      ),
    );
  }

  @override
  Future<Result<PaymentCheckoutSession, Failure>> createPayment({
    required String auctionId,
    required bool useWallet,
  }) {
    return _guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.auctionCreatePayment(auctionId),
        data: {'useWallet': useWallet},
      );
      return AuctionMapper.paymentFromEnvelope(response.data);
    });
  }

  @override
  Future<Result<AuctionMutation, Failure>> verifyPayment({
    required String auctionId,
    required String orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) {
    return _mutation(
      () => _dio.post<Map<String, dynamic>>(
        ApiEndpoints.auctionVerifyPayment(auctionId),
        data: {
          'orderId': orderId,
          'razorpayOrderId': razorpayOrderId,
          'razorpayPaymentId': razorpayPaymentId,
          'razorpaySignature': razorpaySignature,
        },
      ),
    );
  }

  @override
  Future<Result<AuctionMutation, Failure>> create({
    required String productId,
    required String productType,
    required DateTime startTime,
    required DateTime endTime,
    required double minimumBid,
    double? reservePrice,
  }) {
    return _mutation(
      () => _dio.post<Map<String, dynamic>>(
        ApiEndpoints.auctionCreate,
        data: {
          'productId': productId,
          'productType': productType,
          'startTime': startTime.toUtc().toIso8601String(),
          'endTime': endTime.toUtc().toIso8601String(),
          'minimumBid': minimumBid,
          if (reservePrice != null) 'reservePrice': reservePrice,
        },
      ),
    );
  }

  @override
  Future<Result<AuctionBulkResult, Failure>> bulkCreate({
    required DateTime startTime,
    required DateTime endTime,
    required List<AuctionBulkDraft> items,
  }) {
    return _guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.auctionBulkCreate,
        data: {
          'startTime': startTime.toUtc().toIso8601String(),
          'endTime': endTime.toUtc().toIso8601String(),
          'items': [
            for (final item in items)
              {
                'productId': item.productId,
                'productType': item.productType,
                'minimumBid': item.minimumBid,
                if (item.reservePrice != null) 'reservePrice': item.reservePrice,
              },
          ],
        },
      );
      return AuctionMapper.bulkFromEnvelope(response.data);
    });
  }

  @override
  Future<Result<AuctionMutation, Failure>> end(String auctionId) {
    return _mutation(
      () => _dio.post<Map<String, dynamic>>(ApiEndpoints.auctionEnd(auctionId)),
    );
  }

  @override
  Future<Result<AuctionMutation, Failure>> accept({
    required String auctionId,
    String? bidId,
  }) {
    return _mutation(
      () => _dio.post<Map<String, dynamic>>(
        ApiEndpoints.auctionAccept(auctionId),
        data: {if (bidId != null && bidId.isNotEmpty) 'bidId': bidId},
      ),
    );
  }

  @override
  Future<Result<AuctionMutation, Failure>> reject({
    required String auctionId,
    required String action,
    DateTime? startTime,
    DateTime? endTime,
    double? minimumBid,
    double? reservePrice,
  }) {
    return _mutation(
      () => _dio.post<Map<String, dynamic>>(
        ApiEndpoints.auctionReject(auctionId),
        data: {
          'action': action,
          if (startTime != null) 'startTime': startTime.toUtc().toIso8601String(),
          if (endTime != null) 'endTime': endTime.toUtc().toIso8601String(),
          if (minimumBid != null) 'minimumBid': minimumBid,
          if (reservePrice != null) 'reservePrice': reservePrice,
        },
      ),
    );
  }

  @override
  Future<Result<AuctionMutation, Failure>> selectWinner({
    required String auctionId,
    required String bidderId,
  }) {
    return _mutation(
      () => _dio.post<Map<String, dynamic>>(
        ApiEndpoints.auctionSelectWinner,
        data: {'auctionId': auctionId, 'bidderId': bidderId},
      ),
    );
  }

  @override
  Future<Result<AuctionMutation, Failure>> delete(String auctionId) {
    return _mutation(
      () => _dio.delete<Map<String, dynamic>>(
        ApiEndpoints.auctionById(auctionId),
      ),
    );
  }

  Future<Result<AuctionPage, Failure>> _page(
    String path, {
    required int page,
    required int limit,
    String? productType,
    Map<String, Object?> extra = const {},
  }) {
    return _guard(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: {
          'page': page < 1 ? 1 : page,
          'limit': limit.clamp(1, 100),
          if (productType != null && productType.isNotEmpty)
            'productType': productType,
          ...extra,
        },
      );
      return AuctionMapper.pageFromEnvelope(
        response.data,
        page: page,
        limit: limit,
      );
    });
  }

  Future<Result<AuctionMutation, Failure>> _mutation(
    Future<Response<Map<String, dynamic>>> Function() call,
  ) {
    return _guard(() async {
      final response = await call();
      return AuctionMapper.mutationFromEnvelope(response.data);
    });
  }

  Future<Result<T, Failure>> _guard<T>(Future<T> Function() body) async {
    try {
      return Result.success(await body());
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }
}
