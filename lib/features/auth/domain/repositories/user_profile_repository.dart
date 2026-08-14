import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/user_profile.dart';

abstract class UserProfileRepository {
  Future<Result<UserProfile, Failure>> getProfile({CancelToken? cancelToken});
}
