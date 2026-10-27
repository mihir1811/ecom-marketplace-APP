import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/live_show_models.dart';
import '../../domain/repositories/live_show_repository.dart';
import '../mappers/live_show_mapper.dart';

final liveShowRepositoryProvider = Provider<LiveShowRepository>(
  (ref) => LiveShowRepositoryImpl(ref.watch(dioProvider)),
);

class LiveShowRepositoryImpl implements LiveShowRepository {
  LiveShowRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<List<LiveShow>, Failure>> shows() {
    return _guard(() async {
      final response = await _dio.get<Object>(ApiEndpoints.liveShows);
      return LiveShowMapper.showsFromEnvelope(response.data);
    });
  }

  @override
  Future<Result<LiveShow, Failure>> show(String showId) {
    return _guard(() async {
      final response = await _dio.get<Object>(
        ApiEndpoints.liveShowById(showId),
      );
      final show = LiveShowMapper.showFromEnvelope(response.data);
      if (show == null) throw const _Malformed('live show');
      return show;
    });
  }

  @override
  Future<Result<LiveViewerToken, Failure>> viewerToken(String showId) {
    return _guard(() async {
      final response = await _dio.post<Object>(
        ApiEndpoints.liveShowViewerToken(showId),
      );
      final token = LiveShowMapper.tokenFromEnvelope(response.data);
      if (token == null) throw const _Malformed('viewer token');
      return token;
    });
  }

  @override
  Future<Result<ShowAuction, Failure>> auction(String showId) {
    return _guard(() async {
      final response = await _dio.get<Object>(
        ApiEndpoints.liveShowAuction(showId),
      );
      return LiveShowMapper.auctionFromEnvelope(response.data);
    });
  }

  @override
  Future<Result<MyShowState, Failure>> me(String showId) {
    return _guard(() async {
      final response = await _dio.get<Object>(
        ApiEndpoints.liveShowAuctionMe(showId),
      );
      return LiveShowMapper.meFromEnvelope(response.data);
    });
  }

  @override
  Future<Result<LiveBidResult, LiveBidError>> bid({
    required String lotId,
    required int amount,
  }) async {
    try {
      final response = await _dio.post<Object>(
        ApiEndpoints.liveLotBids(lotId),
        data: {'amount': amount},
      );
      final result = LiveShowMapper.bidFromEnvelope(response.data);
      if (result == null) {
        return Result.failure(
          const LiveBidError(
            code: LiveBidErrorCode.network,
            message: 'Your bid was sent but the reply was unreadable.',
          ),
        );
      }
      return Result.success(result);
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) {
        return Result.failure(
          LiveBidError(
            code: LiveBidErrorCode.network,
            message: NetworkFailure.fromDioException(e).message,
          ),
        );
      }
      return Result.failure(
        LiveShowMapper.bidErrorFromBody(response.data, response.statusCode),
      );
    } catch (_) {
      return Result.failure(
        const LiveBidError(
          code: LiveBidErrorCode.network,
          message: 'Your bid could not be placed. Please try again.',
        ),
      );
    }
  }

  @override
  Future<Result<List<LiveChatMessage>, Failure>> chat(String showId) {
    return _guard(() async {
      final response = await _dio.get<Object>(
        ApiEndpoints.liveShowChat(showId),
      );
      return LiveShowMapper.chatFromEnvelope(response.data);
    });
  }

  @override
  Future<Result<LiveChatMessage, LiveActionError>> sendChat({
    required String showId,
    required String body,
  }) {
    return _action(() async {
      final response = await _dio.post<Object>(
        ApiEndpoints.liveShowChat(showId),
        data: {'body': body},
      );
      final message = LiveShowMapper.messageFromJson(
        LiveShowMapper.data(response.data),
      );
      if (message == null) throw const _Malformed('chat message');
      return message;
    });
  }

  @override
  Future<Result<void, LiveActionError>> like({
    required String showId,
    required int count,
  }) {
    return _action(() async {
      await _dio.post<Object>(
        ApiEndpoints.liveShowLikes(showId),
        data: {'count': count},
      );
    });
  }

  Future<Result<T, LiveActionError>> _action<T>(
    Future<T> Function() body,
  ) async {
    try {
      return Result.success(await body());
    } on DioException catch (e) {
      return Result.failure(
        LiveActionError(
          message: ApiError.fromDio(e).message,
          status: e.response?.statusCode,
        ),
      );
    } catch (_) {
      return Result.failure(
        const LiveActionError(message: 'Something went wrong. Try again.'),
      );
    }
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

class _Malformed implements Exception {
  const _Malformed(this.what);

  final String what;

  @override
  String toString() => 'Malformed $what response';
}
