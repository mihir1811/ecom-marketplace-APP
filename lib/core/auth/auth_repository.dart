import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../error/failure.dart';
import '../error/result.dart';
import '../network/api_endpoints.dart';
import '../network/dio_provider.dart';
import '../push/push_logout_hook.dart';
import 'auth_api_error.dart';
import 'auth_session.dart';
import 'auth_token_store.dart';
import 'auth_user.dart';
import 'business_registration_data.dart';
import 'seller_account_snapshot.dart';

/// Contract for authentication API calls (§5–§11).
abstract class AuthRepository {
  Future<Result<AuthSession, Failure>> login({
    required String userName,
    required String password,
    required bool rememberDevice,
  });

  Future<Result<RegisterPendingVerification, Failure>> register({
    required String name,
    required String userName,
    required String email,
    required String password,
    RegistrationAccountType registrationType =
        RegistrationAccountType.individual,
    BusinessRegistrationData? business,
    XFile? profilePicture,
    String? referralEmail,
    String? referralCode,

    /// `YYYY-MM-DD` — required by API for individual registration.
    String? dateOfBirth,
  });

  Future<Result<AuthSession, Failure>> verifyOtp({
    required String email,
    required String otp,
  });

  Future<Result<ResendOtpResult, Failure>> resendOtp({required String email});

  Future<Result<void, Failure>> logout();

  Future<Result<void, Failure>> forgetPassword({required String email});

  Future<Result<void, Failure>> resetPassword({
    required String resetToken,
    required String newPassword,
  });

  /// Schedules account deletion (Bearer). Clears local session on success.
  Future<Result<AccountDeletionScheduled, Failure>> requestAccountDeletion({
    required String password,
  });

  /// Recovers a scheduled-for-deletion account (public).
  /// Send [token] **or** [email] + [password].
  Future<Result<void, Failure>> recoverAccount({
    String? token,
    String? email,
    String? password,
  });
}

/// Result of a successful account-deletion request.
class AccountDeletionScheduled {
  const AccountDeletionScheduled({required this.message, this.recoverUntil});

  final String message;
  final DateTime? recoverUntil;
}

/// Register succeeded; OTP must be verified before a session exists.
class RegisterPendingVerification {
  const RegisterPendingVerification({
    required this.email,
    required this.requiresVerification,
    this.registrationType = RegistrationAccountType.individual,
  });

  final String email;
  final bool requiresVerification;
  final RegistrationAccountType registrationType;
}

/// Result of resend-otp.
class ResendOtpResult {
  const ResendOtpResult({required this.email, this.expiresInMinutes});

  final String email;
  final int? expiresInMinutes;
}

/// Live [AuthRepository] using Dio against `/auth/*`.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dio, this._tokenStore);

  final Dio _dio;
  final AuthTokenStore _tokenStore;

  @override
  Future<Result<AuthSession, Failure>> login({
    required String userName,
    required String password,
    required bool rememberDevice,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.authLogin,
        data: {
          'userName': userName,
          'password': password,
          'rememberDevice': rememberDevice,
        },
      );
      final session = _parseSession(
        response.data,
        rememberDevice: rememberDevice,
      );
      if (session == null) {
        return Result.failure(
          const AuthFailure('Unexpected login response. Please try again.'),
        );
      }
      if (session.user.isBlocked || session.user.isDeleted) {
        return Result.failure(
          const AuthFailure('This account is not available. Contact support.'),
        );
      }
      await _persist(session);
      return Result.success(session);
    } on DioException catch (e) {
      return Result.failure(AuthApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<RegisterPendingVerification, Failure>> register({
    required String name,
    required String userName,
    required String email,
    required String password,
    RegistrationAccountType registrationType =
        RegistrationAccountType.individual,
    BusinessRegistrationData? business,
    XFile? profilePicture,
    String? referralEmail,
    String? referralCode,
    String? dateOfBirth,
  }) async {
    try {
      if (registrationType == RegistrationAccountType.business &&
          business == null) {
        return Result.failure(
          const AuthFailure('Business registration details are required.'),
        );
      }

      final map = <String, dynamic>{
        'name': name,
        'userName': userName,
        'email': email,
        'password': password,
        'registrationType': registrationType.apiValue,
      };

      final dob = dateOfBirth?.trim();
      if (dob != null && dob.isNotEmpty) {
        map['dateOfBirth'] = dob;
      }

      final referralEmailValue = referralEmail?.trim();
      if (referralEmailValue != null && referralEmailValue.isNotEmpty) {
        map['referralEmail'] = referralEmailValue;
      }
      final referralCodeValue = referralCode?.trim();
      if (referralCodeValue != null && referralCodeValue.isNotEmpty) {
        map['referralCode'] = referralCodeValue;
      }

      if (business != null) {
        map.addAll({
          'companyName': business.companyName,
          'addressLine1': business.addressLine1,
          'addressLine2': business.addressLine2,
          'city': business.city,
          'state': business.state,
          'country': business.country,
          'zipCode': business.zipCode,
          'sellerType': business.sellerType.apiValue,
          'phone1': business.phone1,
          'phone2': business.phone2,
          'representativeName1': business.representativeName1,
          'representativeName2': business.representativeName2,
          'panCardNumber': business.panCardNumber,
          'aadhaarNumber': business.aadhaarNumber,
          'iecNumber': business.iecNumber,
          'accountHolderName': business.accountHolderName,
          'accountNumber': business.accountNumber,
          'ifscCode': business.ifscCode,
          'bankName': business.bankName,
        });
        final accountType = business.accountType;
        if (accountType != null) {
          map['accountType'] = accountType.apiValue;
        }
        final gst = business.gstNumber?.trim();
        if (gst != null && gst.isNotEmpty) {
          map['gstNumber'] = gst;
        }
        final upi = business.upiId?.trim();
        if (upi != null && upi.isNotEmpty) {
          map['upiId'] = upi;
        }
        map['companyLogo'] = await _multipartFromXFile(
          business.companyLogo,
          fallbackName: 'company-logo.jpg',
        );
        final banner = business.bannerImage;
        if (banner != null) {
          map['bannerImage'] = await _multipartFromXFile(
            banner,
            fallbackName: 'banner.jpg',
          );
        }
        final panCard = business.panCard;
        if (panCard != null) {
          map['panCard'] = await _multipartFromXFile(
            panCard,
            fallbackName: 'pan-card.jpg',
          );
        }
      }

      if (profilePicture != null) {
        map['profilePicture'] = await _multipartFromXFile(
          profilePicture,
          fallbackName: 'profile.jpg',
        );
      }
      final form = FormData.fromMap(map);
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.authRegister,
        data: form,
      );
      final root = response.data ?? const <String, dynamic>{};
      final data = root['data'];
      final payload = data is Map<String, dynamic>
          ? data
          : const <String, dynamic>{};
      final resolvedEmail =
          (payload['email'] as String?)?.trim().isNotEmpty == true
          ? (payload['email'] as String).trim()
          : email;
      final requires = payload['requiresVerification'] as bool? ?? true;
      final typeRaw = (payload['registrationType'] as String?)
          ?.trim()
          .toLowerCase();
      final resolvedType = typeRaw == 'business'
          ? RegistrationAccountType.business
          : registrationType;
      return Result.success(
        RegisterPendingVerification(
          email: resolvedEmail,
          requiresVerification: requires,
          registrationType: resolvedType,
        ),
      );
    } on DioException catch (e) {
      return Result.failure(AuthApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  Future<MultipartFile> _multipartFromXFile(
    XFile file, {
    required String fallbackName,
  }) async {
    final bytes = await file.readAsBytes();
    final filename = file.name.trim().isNotEmpty
        ? file.name.trim()
        : fallbackName;
    return MultipartFile.fromBytes(bytes, filename: filename);
  }

  @override
  Future<Result<AuthSession, Failure>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.authVerifyOtp,
        data: {'email': email, 'otp': otp},
      );
      final session = _parseSession(response.data, rememberDevice: true);
      if (session == null) {
        return Result.failure(
          const AuthFailure(
            'Unexpected verification response. Please try again.',
          ),
        );
      }
      await _persist(session);
      return Result.success(session);
    } on DioException catch (e) {
      return Result.failure(AuthApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<ResendOtpResult, Failure>> resendOtp({
    required String email,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.authResendOtp,
        data: {'email': email},
      );
      final root = response.data ?? const <String, dynamic>{};
      final data = root['data'];
      final payload = data is Map<String, dynamic>
          ? data
          : const <String, dynamic>{};
      return Result.success(
        ResendOtpResult(
          email: (payload['email'] as String?)?.trim() ?? email,
          expiresInMinutes: payload['expiresInMinutes'] is int
              ? payload['expiresInMinutes'] as int
              : int.tryParse('${payload['expiresInMinutes']}'),
        ),
      );
    } on DioException catch (e) {
      return Result.failure(AuthApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> logout() async {
    try {
      try {
        await PushLogoutHook.beforeLogout?.call();
      } catch (_) {
        // Logout must continue if device unregister fails.
      }
      await _dio.post<Map<String, dynamic>>(ApiEndpoints.authLogout);
      await _tokenStore.clear();
      return Result.success(null);
    } on DioException catch (e) {
      // Always clear locally even if the network call fails.
      await _tokenStore.clear();
      if (e.response?.statusCode == 401) {
        return Result.success(null);
      }
      return Result.failure(AuthApiError.fromDio(e));
    } catch (e) {
      await _tokenStore.clear();
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> forgetPassword({required String email}) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.authForgetPassword,
        data: {'email': email},
      );
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(AuthApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.authResetPassword,
        data: {'newPassword': newPassword},
        options: Options(headers: {'Authorization': 'Bearer $resetToken'}),
      );
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(AuthApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<AccountDeletionScheduled, Failure>> requestAccountDeletion({
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.accountDeletionRequest,
        data: {'password': password},
      );
      final root = response.data ?? const <String, dynamic>{};
      final message = (root['message'] as String?)?.trim().isNotEmpty == true
          ? (root['message'] as String).trim()
          : 'Your account is scheduled for deletion. You have 7 days to recover it.';
      final data = root['data'];
      final payload = data is Map<String, dynamic>
          ? data
          : data is Map
          ? Map<String, dynamic>.from(data)
          : const <String, dynamic>{};
      final untilRaw = payload['recoverUntil'];
      DateTime? recoverUntil;
      if (untilRaw is String && untilRaw.trim().isNotEmpty) {
        recoverUntil = DateTime.tryParse(untilRaw.trim());
      }
      await _tokenStore.clear();
      return Result.success(
        AccountDeletionScheduled(message: message, recoverUntil: recoverUntil),
      );
    } on DioException catch (e) {
      return Result.failure(AuthApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> recoverAccount({
    String? token,
    String? email,
    String? password,
  }) async {
    try {
      final body = <String, dynamic>{};
      final tokenValue = token?.trim();
      if (tokenValue != null && tokenValue.isNotEmpty) {
        body['token'] = tokenValue;
      }
      final emailValue = email?.trim();
      if (emailValue != null && emailValue.isNotEmpty) {
        body['email'] = emailValue;
      }
      final passwordValue = password;
      if (passwordValue != null && passwordValue.isNotEmpty) {
        body['password'] = passwordValue;
      }
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.accountDeletionRecover,
        data: body,
      );
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(AuthApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  Future<void> _persist(AuthSession session) async {
    final previousUserId = await _tokenStore.readUserId();
    if (previousUserId != null &&
        previousUserId.isNotEmpty &&
        previousUserId != session.user.id) {
      // Full wipe before writing the new account so no identity key can linger.
      await _tokenStore.clear();
    }
    await _tokenStore.saveSession(
      accessToken: session.accessToken,
      userId: session.user.id,
      sellerId: session.sellerId,
      userName: session.user.username,
      role: session.user.role,
      isVerified: session.user.isVerified,
      rememberDevice: session.rememberDevice,
    );
    final snap = session.user.sellerAccount;
    await _tokenStore.saveSellerAccountSnapshot(
      snap == null || !snap.hasAnyField ? null : jsonEncode(snap.toJson()),
    );
  }

  AuthSession? _parseSession(
    Map<String, dynamic>? root, {
    required bool rememberDevice,
  }) {
    if (root == null) return null;
    final dataRaw = root['data'];
    final data = dataRaw is Map<String, dynamic>
        ? dataRaw
        : dataRaw is Map
        ? Map<String, dynamic>.from(dataRaw)
        : null;
    if (data == null) return null;
    final userRaw = data['user'];
    final userJson = userRaw is Map<String, dynamic>
        ? userRaw
        : userRaw is Map
        ? Map<String, dynamic>.from(userRaw)
        : null;
    if (userJson == null) return null;
    final token = (data['accessToken'] as String?)?.trim() ?? '';
    if (token.isEmpty) return null;
    final user = AuthUser.fromJson(userJson);
    if (user.id.isEmpty) return null;
    final mergedAccount = SellerAccountSnapshot.merge(
      user.sellerAccount,
      SellerAccountSnapshot.tryParse(data['sellerData']) ??
          SellerAccountSnapshot.tryParse(data['seller']) ??
          SellerAccountSnapshot.tryParse(data['business']),
    );
    final sellerRaw = data['sellerId'];
    final sellerId = sellerRaw is String && sellerRaw.trim().isNotEmpty
        ? sellerRaw.trim()
        : null;
    return AuthSession(
      accessToken: token,
      user: mergedAccount == null
          ? user
          : user.copyWith(sellerAccount: mergedAccount),
      sellerId: sellerId,
      rememberDevice: rememberDevice,
    );
  }
}

/// Auth repository provider.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(dioProvider),
    ref.watch(authTokenStoreProvider),
  );
});
