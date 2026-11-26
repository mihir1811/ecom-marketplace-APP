import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/interested_buyer.dart';
import '../mappers/interested_buyer_mapper.dart';

final interestedBuyersRepositoryProvider = Provider<InterestedBuyersRepository>(
  (ref) => InterestedBuyersRepository(ref.watch(dioProvider)),
);

/// `/interested-buyers`: the seller's list and its two contact actions, and
/// the buyer's opt-out preference.
class InterestedBuyersRepository {
  InterestedBuyersRepository(this._dio);

  final Dio _dio;

  static const int pageSize = 20;

  Future<Result<InterestedBuyersPage, Failure>> list({
    required InterestedBuyersTab tab,
    String? search,
    int page = 1,
    CancelToken? cancelToken,
  }) {
    final q = search?.trim() ?? '';
    return _run(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.interestedBuyers,
        queryParameters: {
          'tab': tab.apiValue,
          if (q.isNotEmpty) 'search': q.length > 100 ? q.substring(0, 100) : q,
          'page': page < 1 ? 1 : page,
          'limit': pageSize,
        },
        cancelToken: cancelToken,
      );
      return InterestedBuyerMapper.pageFromJson(response.data, page: page);
    });
  }

  /// Uses the seller's one contact for this buyer and item.
  Future<Result<bool, Failure>> sendMessage({
    required String cartId,
    required String message,
  }) => _run(() async {
    await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.interestedBuyerMessage(cartId),
      data: {'message': message.trim()},
    );
    return true;
  });

  /// Private offer for the whole item; [amount] is a USD decimal string
  /// with at most two places.
  Future<Result<bool, Failure>> sendOffer({
    required String cartId,
    required String amount,
    String? message,
  }) => _run(() async {
    final note = message?.trim() ?? '';
    await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.interestedBuyerOffer(cartId),
      data: {'amount': num.parse(amount), if (note.isNotEmpty) 'message': note},
    );
    return true;
  });

  Future<Result<bool, Failure>> readPreference() => _run(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.interestedBuyersPreference,
    );
    return _preference(response.data) ?? true;
  });

  Future<Result<bool, Failure>> savePreference(bool allow) => _run(() async {
    final response = await _dio.patch<Map<String, dynamic>>(
      ApiEndpoints.interestedBuyersPreference,
      data: {'allowSellerCartOutreach': allow},
    );
    return _preference(response.data) ?? allow;
  });

  static bool? _preference(Map<String, dynamic>? root) {
    final data = root?['data'];
    if (data is! Map) return null;
    final value = data['allowSellerCartOutreach'];
    return value is bool ? value : null;
  }

  /// Field errors arrive as a list; the first one is shown.
  static Future<Result<T, Failure>> _run<T>(Future<T> Function() call) async {
    try {
      return Result.success(await call());
    } on DioException catch (e) {
      final failure = ApiError.fromDio(e);
      final first = failure.message.split('\n').first;
      if (first == failure.message) return Result.failure(failure);
      return Result.failure(switch (failure) {
        ValidationFailure(:final code) => ValidationFailure(first, code: code),
        _ => failure,
      });
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }
}
