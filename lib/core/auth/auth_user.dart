/// Minimal authenticated user model used by UI-only session state.
class AuthUser {
  const AuthUser({
    required this.fullName,
    required this.username,
    required this.email,
  });

  final String fullName;
  final String username;
  final String email;
}

