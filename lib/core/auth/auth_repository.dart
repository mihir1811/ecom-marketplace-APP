import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../error/failure.dart';
import '../error/result.dart';
import '../network/api_endpoints.dart';
import '../network/dio_provider.dart';
import 'auth_api_error.dart';
import 'auth_session.dart';
import 'auth_token_store.dart';
import 'auth_user.dart';

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
    XFile? profilePicture,
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
}

/// Register succeeded; OTP must be verified before a session exists.
class RegisterPendingVerification {
  const RegisterPendingVerification({
    required this.email,
    required this.requiresVerification,
  });

  final String email;
  final bool requiresVerification;
}

/// Result of resend-otp.
class ResendOtpResult {
  const ResendOtpResult({
    required this.email,
    this.expiresInMinutes,
  });

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
          AuthFailure('Unexpected login response. Please try again.'),
        );
      }
      if (session.user.isBlocked || session.user.isDeleted) {
        return Result.failure(
          AuthFailure('This account is not available. Contact support.'),
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
    XFile? profilePicture,
  }) async {
    try {
      final map = <String, dynamic>{
        'name': name,
        'userName': userName,
        'email': email,
        'password': password,
      };
      if (profilePicture != null) {
        final bytes = await profilePicture.readAsBytes();
        final filename = profilePicture.name.isNotEmpty
            ? profilePicture.name
            : 'profile.jpg';
        map['profilePicture'] = MultipartFile.fromBytes(
          bytes,
          filename: filename,
        );
      }
      final form = FormData.fromMap(map);
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.authRegister,
        data: form,
      );
      final root = response.data ?? const <String, dynamic>{};
      final data = root['data'];
      final payload =
          data is Map<String, dynamic> ? data : const <String, dynamic>{};
      final resolvedEmail =
          (payload['email'] as String?)?.trim().isNotEmpty == true
              ? (payload['email'] as String).trim()
              : email;
      final requires =
          payload['requiresVerification'] as bool? ?? true;
      return Result.success(
        RegisterPendingVerification(
          email: resolvedEmail,
          requiresVerification: requires,
        ),
      );
    } on DioException catch (e) {
      return Result.failure(AuthApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
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
          AuthFailure('Unexpected verification response. Please try again.'),
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
      final payload =
          data is Map<String, dynamic> ? data : const <String, dynamic>{};
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
  Future<Result<void, Failure>> forgetPassword({
    required String email,
  }) async {
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
        options: Options(
          headers: {'Authorization': 'Bearer $resetToken'},
        ),
      );
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(AuthApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  Future<void> _persist(AuthSession session) {
    return _tokenStore.saveSession(
      accessToken: session.accessToken,
      userId: session.user.id,
      sellerId: session.sellerId,
      userName: session.user.username,
      role: session.user.role,
      rememberDevice: session.rememberDevice,
    );
  }

  AuthSession? _parseSession(
    Map<String, dynamic>? root, {
    required bool rememberDevice,
  }) {
    if (root == null) return null;
    final data = root['data'];
    if (data is! Map<String, dynamic>) return null;
    final userJson = data['user'];
    if (userJson is! Map<String, dynamic>) return null;
    final token = (data['accessToken'] as String?)?.trim() ?? '';
    if (token.isEmpty) return null;
    final user = AuthUser.fromJson(userJson);
    if (user.id.isEmpty) return null;
    final sellerRaw = data['sellerId'];
    final sellerId = sellerRaw is String && sellerRaw.trim().isNotEmpty
        ? sellerRaw.trim()
        : null;
    return AuthSession(
      accessToken: token,
      user: user,
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
