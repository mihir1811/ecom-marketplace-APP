import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../payment/domain/models/payment_models.dart';
import '../../domain/models/wallet.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../mappers/wallet_mapper.dart';

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => WalletRepositoryImpl(ref.watch(dioProvider)),
);

/// Live wallet repository backed by `/wallet*` APIs.
class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<Wallet, Failure>> getWallet() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.wallet,
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        return Result.failure(
          const NetworkFailure('Could not load your wallet.'),
        );
      }
      return Result.success(WalletMapper.walletFromJson(data));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<WalletTransactionsPage, Failure>> getTransactions({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.walletTransactions,
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );
      return Result.success(
        WalletMapper.transactionsPageFromJson(
          response.data ?? const <String, dynamic>{},
        ),
      );
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<WalletTopUpSession, Failure>> createTopUp({
    required double amountInr,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.walletTopUp,
        data: {'amount': amountInr},
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        return Result.failure(
          const NetworkFailure('Could not start the wallet top-up.'),
        );
      }
      final session = WalletMapper.topUpSessionFromJson(data);
      if (session.razorpayOrderId.isEmpty ||
          session.keyId.isEmpty ||
          session.amountPaise <= 0) {
        return Result.failure(
          const NetworkFailure('Top-up order response was incomplete.'),
        );
      }
      return Result.success(session);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<Wallet, Failure>> verifyTopUp({
    required RazorpayPaymentSuccess success,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.walletTopUpVerify,
        data: {
          'razorpayOrderId': success.razorpayOrderId,
          'razorpayPaymentId': success.razorpayPaymentId,
          'razorpaySignature': success.razorpaySignature,
        },
      );
      final data = response.data?['data'];
      if (data is Map<String, dynamic> && data['balance'] != null) {
        return Result.success(WalletMapper.walletFromJson(data));
      }
      return getWallet();
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }
}
