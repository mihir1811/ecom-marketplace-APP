import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/auth_user.dart';
import '../../../core/auth/seller_account_snapshot.dart';
import '../../../core/error/failure.dart';
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
    ref.watch(authProvider.select((s) => s.user?.id));
    final authUser = ref.read(authProvider).user;
    final result = await _repo.getProfile();
    return switch (result) {
      Success(value: final profile) => () {
          final merged = overlaySellerAccount(profile, authUser);
          _syncAuth(merged);
          return merged;
        }(),
      ResultFailure(failure: final failure) => () {
          if (authUser != null && _isEmptyProfile(failure)) {
            return userProfileFromAuth(authUser);
          }
          throw failure;
        }(),
    };
  }

  void _syncAuth(UserProfile profile) {
    Future.microtask(() {
      ref.read(authProvider.notifier).applyAccountProfile(
            fullName: profile.fullName.trim().isEmpty ? null : profile.fullName,
            username: profile.username.trim().isEmpty ? null : profile.username,
            email: profile.email.trim().isEmpty ? null : profile.email,
            role: profile.role.trim().isEmpty ? null : profile.role,
            profilePicture: profile.profilePicture.trim().isEmpty
                ? null
                : profile.profilePicture,
            isVerified: profile.isVerified,
            sellerAccount: sellerAccountFromProfile(profile),
          );
    });
  }
}

bool _isEmptyProfile(Failure failure) {
  return failure is NetworkFailure &&
      failure.message.toLowerCase().contains('empty');
}

/// Seeds a lightweight profile from the signed-in [AuthUser] when the API
/// profile call is unavailable.
UserProfile userProfileFromAuth(AuthUser user) {
  final snap = user.sellerAccount;
  return UserProfile(
    id: user.id,
    fullName: user.fullName,
    username: user.username,
    email: user.email,
    role: user.role,
    profilePicture: user.profilePicture,
    isVerified: user.isVerified,
    companyName: snap?.companyName,
    addressLine1: snap?.addressLine1,
    addressLine2: snap?.addressLine2,
    city: snap?.city,
    state: snap?.state,
    country: snap?.country,
    zipCode: snap?.zipCode,
    sellerType: snap?.sellerType,
    businessPhone1: snap?.businessPhone1,
    businessPhone2: snap?.businessPhone2,
    representativeName1: snap?.representativeName1,
    representativeName2: snap?.representativeName2,
    panCardNumber: snap?.panCardNumber,
    aadhaarNumber: snap?.aadhaarNumber,
    iecNumber: snap?.iecNumber,
    gstNumber: snap?.gstNumber,
    companyLogoUrl: snap?.companyLogoUrl,
    bannerImageUrl: snap?.bannerImageUrl,
    panCardUrl: snap?.panCardUrl,
  );
}

/// Fills blank profile API fields from the login/JWT seller snapshot.
UserProfile overlaySellerAccount(UserProfile profile, AuthUser? user) {
  if (user == null) return profile;
  final seeded = userProfileFromAuth(user);
  return UserProfile(
    id: _prefer(profile.id, seeded.id) ?? '',
    fullName: _prefer(profile.fullName, seeded.fullName) ?? '',
    username: _prefer(profile.username, seeded.username) ?? '',
    email: _prefer(profile.email, seeded.email) ?? '',
    role: _prefer(profile.role, seeded.role) ?? '',
    profilePicture:
        _prefer(profile.profilePicture, seeded.profilePicture) ?? '',
    isVerified: user.isVerified,
    companyName: _prefer(profile.companyName, seeded.companyName),
    addressLine1: _prefer(profile.addressLine1, seeded.addressLine1),
    addressLine2: _prefer(profile.addressLine2, seeded.addressLine2),
    city: _prefer(profile.city, seeded.city),
    state: _prefer(profile.state, seeded.state),
    country: _prefer(profile.country, seeded.country),
    zipCode: _prefer(profile.zipCode, seeded.zipCode),
    sellerType: _prefer(profile.sellerType, seeded.sellerType),
    businessPhone1: _prefer(profile.businessPhone1, seeded.businessPhone1),
    businessPhone2: _prefer(profile.businessPhone2, seeded.businessPhone2),
    representativeName1:
        _prefer(profile.representativeName1, seeded.representativeName1),
    representativeName2:
        _prefer(profile.representativeName2, seeded.representativeName2),
    panCardNumber: _prefer(profile.panCardNumber, seeded.panCardNumber),
    aadhaarNumber: _prefer(profile.aadhaarNumber, seeded.aadhaarNumber),
    iecNumber: _prefer(profile.iecNumber, seeded.iecNumber),
    gstNumber: _prefer(profile.gstNumber, seeded.gstNumber),
    companyLogoUrl: _prefer(profile.companyLogoUrl, seeded.companyLogoUrl),
    bannerImageUrl: _prefer(profile.bannerImageUrl, seeded.bannerImageUrl),
    panCardUrl: _prefer(profile.panCardUrl, seeded.panCardUrl),
    accountHolderName: profile.accountHolderName,
    accountNumber: profile.accountNumber,
    ifscCode: profile.ifscCode,
    bankName: profile.bankName,
    accountType: profile.accountType,
    upiId: profile.upiId,
  );
}

String? _prefer(String? a, String? b) {
  if (a != null && a.trim().isNotEmpty) return a;
  if (b != null && b.trim().isNotEmpty) return b;
  return null;
}

SellerAccountSnapshot? sellerAccountFromProfile(UserProfile profile) {
  final snap = SellerAccountSnapshot(
    companyName: profile.companyName,
    sellerType: profile.sellerType,
    addressLine1: profile.addressLine1,
    addressLine2: profile.addressLine2,
    city: profile.city,
    state: profile.state,
    country: profile.country,
    zipCode: profile.zipCode,
    businessPhone1: profile.businessPhone1,
    businessPhone2: profile.businessPhone2,
    representativeName1: profile.representativeName1,
    representativeName2: profile.representativeName2,
    panCardNumber: profile.panCardNumber,
    aadhaarNumber: profile.aadhaarNumber,
    iecNumber: profile.iecNumber,
    gstNumber: profile.gstNumber,
    companyLogoUrl: profile.companyLogoUrl,
    bannerImageUrl: profile.bannerImageUrl,
    panCardUrl: profile.panCardUrl,
  );
  return snap.hasAnyField ? snap : null;
}
