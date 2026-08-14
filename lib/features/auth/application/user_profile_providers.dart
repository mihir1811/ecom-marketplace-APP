import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_user.dart';
import '../../../core/error/result.dart';
import '../data/repositories/user_profile_repository_impl.dart';
import '../domain/models/user_profile.dart';
import '../domain/repositories/user_profile_repository.dart';

final userProfileProvider =
    AsyncNotifierProvider.autoDispose<UserProfileNotifier, UserProfile>(
  UserProfileNotifier.new,
);

class UserProfileNotifier extends AutoDisposeAsyncNotifier<UserProfile> {
  UserProfileRepository get _repo => ref.read(userProfileRepositoryProvider);

  @override
  Future<UserProfile> build() async {
    final result = await _repo.getProfile();
    return switch (result) {
      Success(value: final profile) => profile,
      ResultFailure(failure: final failure) => throw failure,
    };
  }
}

/// Seeds a lightweight profile from the signed-in [AuthUser] when the API
/// profile call is unavailable.
UserProfile userProfileFromAuth(AuthUser user) {
  return UserProfile(
    id: user.id,
    fullName: user.fullName,
    username: user.username,
    email: user.email,
    role: user.role,
    profilePicture: user.profilePicture,
    isVerified: user.isVerified,
  );
}
