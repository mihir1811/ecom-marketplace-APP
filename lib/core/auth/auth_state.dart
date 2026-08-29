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
    this.accountDeletionMessage,
    this.accountDeletionRecoverUntil,
    this.accountRecovered = false,
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

  /// Server message after scheduling account deletion.
  final String? accountDeletionMessage;

  /// End of the 7-day recovery window (ISO from API).
  final DateTime? accountDeletionRecoverUntil;

  /// True after a successful recover-account call.
  final bool accountRecovered;

  bool get isAuthenticated =>
      user != null && !user!.isBlocked && !user!.isDeleted;

  /// Seller workspace (dashboard, listings, seller chat) is seller-only.
  bool get isSeller => isAuthenticated && (user?.isSeller ?? false);

  /// Signed-in but still waiting for admin verification.
  bool get isVerificationPending =>
      isAuthenticated && !(user?.isVerified ?? true);

  /// Buying and selling require an admin-verified account.
  bool get canTransact => isAuthenticated && (user?.isVerified ?? true);

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
    String? accountDeletionMessage,
    DateTime? accountDeletionRecoverUntil,
    bool? accountRecovered,
    bool clearUser = false,
    bool clearSellerId = false,
    bool clearPendingEmail = false,
    bool clearAccountDeletion = false,
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
      passwordResetSuccess: passwordResetSuccess ?? this.passwordResetSuccess,
      accountDeletionMessage: clearAccountDeletion
          ? null
          : (accountDeletionMessage ?? this.accountDeletionMessage),
      accountDeletionRecoverUntil: clearAccountDeletion
          ? null
          : (accountDeletionRecoverUntil ?? this.accountDeletionRecoverUntil),
      accountRecovered: accountRecovered ?? this.accountRecovered,
    );
  }
}
