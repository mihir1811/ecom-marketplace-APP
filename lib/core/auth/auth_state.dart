import 'auth_user.dart';

/// App-wide auth session state (UI-only).
class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.resetLinkSent = false,
  });

  final AuthUser? user;
  final bool isLoading;
  final String? errorMessage;
  final bool resetLinkSent;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    AuthUser? user,
    bool? isLoading,
    String? errorMessage,
    bool? resetLinkSent,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      resetLinkSent: resetLinkSent ?? this.resetLinkSent,
    );
  }
}

