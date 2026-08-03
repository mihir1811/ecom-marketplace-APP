import 'auth_user.dart';

/// Hydrated session after login / verify-otp / cold-start restore.
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.user,
    this.sellerId,
    required this.rememberDevice,
  });

  final String accessToken;
  final AuthUser user;
  final String? sellerId;
  final bool rememberDevice;
}
