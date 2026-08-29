import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../mappers/user_profile_mapper.dart';

final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (ref) => UserProfileRepositoryImpl(ref.watch(dioProvider)),
);

class UserProfileRepositoryImpl implements UserProfileRepository {
  UserProfileRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<UserProfile, Failure>> getProfile({
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.userProfile,
        cancelToken: cancelToken,
      );
      final raw = response.data;
      final root = raw is Map<String, dynamic>
          ? raw
          : raw is Map
          ? Map<String, dynamic>.from(raw)
          : null;
      final profile = UserProfileMapper.fromResponse(root);
      if (profile == null) {
        return Result.failure(
          const NetworkFailure('Profile response was empty.'),
        );
      }
      return Result.success(profile);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }
}
