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
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.userProfile,
        cancelToken: cancelToken,
      );
      final root = response.data;
      final data = root?['data'];
      final map = data is Map<String, dynamic>
          ? data
          : (root is Map<String, dynamic> ? root : null);
      if (map == null) {
        return Result.failure(
          NetworkFailure('Could not load profile details.'),
        );
      }
      final profile = UserProfileMapper.fromJson(map);
      if (profile.id.isEmpty && profile.email.isEmpty) {
        return Result.failure(
          NetworkFailure('Profile response was empty.'),
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
