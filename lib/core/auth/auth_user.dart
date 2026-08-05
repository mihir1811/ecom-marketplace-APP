/// Authenticated user mapped from login / verify-otp API `data.user`.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    required this.role,
    this.profilePicture = '',
    this.phone,
    this.isVerified = true,
    this.isBlocked = false,
    this.isDeleted = false,
  });

  final String id;
  final String fullName;
  final String username;
  final String email;
  final String role;
  final String profilePicture;
  final String? phone;
  final bool isVerified;
  final bool isBlocked;
  final bool isDeleted;

  bool get isSeller => role.toLowerCase() == 'seller';

  bool get isAdmin => role.toLowerCase() == 'admin';

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] as String?)?.trim() ?? '',
      fullName: (json['name'] as String?)?.trim() ?? '',
      username: (json['userName'] as String?)?.trim() ?? '',
      email: (json['email'] as String?)?.trim() ?? '',
      role: (json['role'] as String?)?.trim() ?? '',
      profilePicture: (json['profilePicture'] as String?)?.trim() ?? '',
      phone: json['phone'] as String?,
      isVerified: json['isVerified'] as bool? ?? true,
      isBlocked: json['isBlocked'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  /// Rebuilds a minimal user from JWT claims + last-login cache.
  factory AuthUser.fromJwtClaims(
    Map<String, dynamic> claims, {
    String? cachedUserId,
    String? cachedUserName,
    String? cachedRole,
  }) {
    final id = _claimUserId(claims) ?? cachedUserId ?? '';
    final userName = _claimUserName(claims) ?? cachedUserName ?? '';
    final role = _claimRole(claims) ?? cachedRole ?? '';
    final name = (claims['name'] as String?)?.trim();
    final email = (claims['email'] as String?)?.trim() ?? '';

    return AuthUser(
      id: id,
      fullName: (name != null && name.isNotEmpty) ? name : userName,
      username: userName,
      email: email,
      role: role,
    );
  }

  /// Minimal user rebuilt from secure storage when JWT claims are thin.
  factory AuthUser.fromSessionCache({
    required String id,
    String? userName,
    String? role,
  }) {
    return AuthUser(
      id: id,
      fullName: userName ?? '',
      username: userName ?? '',
      email: '',
      role: role ?? '',
    );
  }

  static String? _claimUserId(Map<String, dynamic> claims) {
    final sub = claims['sub'];
    if (sub is String && sub.trim().isNotEmpty) return sub.trim();
    final id = claims['id'];
    if (id is String && id.trim().isNotEmpty) return id.trim();
    return null;
  }

  static String? _claimUserName(Map<String, dynamic> claims) {
    final userName = claims['userName'] ?? claims['username'];
    if (userName is String && userName.trim().isNotEmpty) {
      return userName.trim();
    }
    return null;
  }

  static String? _claimRole(Map<String, dynamic> claims) {
    final role = claims['role'];
    if (role is String && role.trim().isNotEmpty) return role.trim();
    return null;
  }
}
