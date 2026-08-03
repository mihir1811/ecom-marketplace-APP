import 'auth_user.dart';

/// App-wide auth session state.
class AuthState {
  const AuthState({
    this.user,
    this.sellerId,
    this.rememberDevice = false,
    this.isLoading = false,
    this.isBootstrapping = false,
    this.errorMessage,
    this.resetLinkSent = false,
    this.pendingVerificationEmail,
    this.passwordResetSuccess = false,
  });

  final AuthUser? user;
  final String? sellerId;
  final bool rememberDevice;
  final bool isLoading;
  final bool isBootstrapping;
  final String? errorMessage;
  final bool resetLinkSent;

  /// Email awaiting OTP after register (or for resend).
  final String? pendingVerificationEmail;

  /// True after a successful reset-password call.
  final bool passwordResetSuccess;

  bool get isAuthenticated =>
      user != null && !user!.isBlocked && !user!.isDeleted;

  AuthState copyWith({
    AuthUser? user,
    String? sellerId,
    bool? rememberDevice,
    bool? isLoading,
    bool? isBootstrapping,
    String? errorMessage,
    bool? resetLinkSent,
    String? pendingVerificationEmail,
    bool? passwordResetSuccess,
    bool clearUser = false,
    bool clearSellerId = false,
    bool clearPendingEmail = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      sellerId: clearSellerId ? null : (sellerId ?? this.sellerId),
      rememberDevice: rememberDevice ?? this.rememberDevice,
      isLoading: isLoading ?? this.isLoading,
      isBootstrapping: isBootstrapping ?? this.isBootstrapping,
      errorMessage: errorMessage,
      resetLinkSent: resetLinkSent ?? this.resetLinkSent,
      pendingVerificationEmail: clearPendingEmail
          ? null
          : (pendingVerificationEmail ?? this.pendingVerificationEmail),
      passwordResetSuccess:
          passwordResetSuccess ?? this.passwordResetSuccess,
    );
  }
}
