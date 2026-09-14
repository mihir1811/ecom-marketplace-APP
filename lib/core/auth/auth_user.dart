import 'seller_account_snapshot.dart';
import '../utils/media_url.dart';

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
    this.sellerAccount,
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
  final SellerAccountSnapshot? sellerAccount;

  bool get isSeller => role.toLowerCase() == 'seller';

  bool get isAdmin => role.toLowerCase() == 'admin';

  AuthUser copyWith({
    String? fullName,
    String? username,
    String? email,
    String? role,
    String? profilePicture,
    String? phone,
    bool? isVerified,
    bool? isBlocked,
    bool? isDeleted,
    SellerAccountSnapshot? sellerAccount,
    bool clearPhone = false,
  }) {
    return AuthUser(
      id: id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      profilePicture: profilePicture ?? this.profilePicture,
      phone: clearPhone ? null : (phone ?? this.phone),
      isVerified: isVerified ?? this.isVerified,
      isBlocked: isBlocked ?? this.isBlocked,
      isDeleted: isDeleted ?? this.isDeleted,
      sellerAccount: sellerAccount ?? this.sellerAccount,
    );
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: _str(json['id']) ?? _str(json['_id']) ?? _str(json['userId']) ?? '',
      fullName: _str(json['name']) ?? _str(json['fullName']) ?? '',
      username: _str(json['userName']) ?? _str(json['username']) ?? '',
      email: _str(json['email']) ?? '',
      role: _str(json['role']) ?? '',
      profilePicture:
          MediaUrl.resolve(
            _str(json['profilePicture']) ??
                _str(json['avatar']) ??
                _str(json['image']) ??
                _str(json['photo']),
          ) ??
          '',
      phone: _str(json['phone']),
      isVerified: parseAccountVerified(json),
      isBlocked: json['isBlocked'] == true,
      isDeleted: json['isDeleted'] == true,
      sellerAccount:
          SellerAccountSnapshot.tryParse(json['sellerData']) ??
          SellerAccountSnapshot.tryParse(json['seller']) ??
          SellerAccountSnapshot.tryParse(json['business']),
    );
  }

  /// Rebuilds a minimal user from JWT claims + last-login cache.
  factory AuthUser.fromJwtClaims(
    Map<String, dynamic> claims, {
    String? cachedUserId,
    String? cachedUserName,
    String? cachedRole,
    bool? cachedIsVerified,
    SellerAccountSnapshot? cachedSellerAccount,
  }) {
    final id = _claimUserId(claims) ?? cachedUserId ?? '';
    final userName = _claimUserName(claims) ?? cachedUserName ?? '';
    final role = _claimRole(claims) ?? cachedRole ?? '';
    final name = _str(claims['name']);
    final email = _str(claims['email']) ?? '';

    return AuthUser(
      id: id,
      fullName: (name != null && name.isNotEmpty) ? name : userName,
      username: userName,
      email: email,
      role: role,
      isVerified: parseAccountVerified(
        claims,
        fallback: cachedIsVerified ?? true,
      ),
      sellerAccount: SellerAccountSnapshot.merge(
        SellerAccountSnapshot.tryParse(claims['sellerData']) ??
            SellerAccountSnapshot.tryParse(claims['seller']),
        cachedSellerAccount,
      ),
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

  static String? _str(Object? value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }
}

/// Admin / account verification from login, profile, or JWT claims.
///
/// Login sets `user.isVerified` after email OTP. Admin KYC for sellers lives
/// on `sellerData.isVerified` / JWT `seller.isVerified`.
bool parseAccountVerified(Map<String, dynamic> json, {bool fallback = true}) {
  final seller = _asMap(json['sellerData']) ?? _asMap(json['seller']);
  if (seller != null) {
    return _readFlag(seller['isVerified']) ?? false;
  }

  final role = '${json['role'] ?? ''}'.trim().toLowerCase();
  final registrationType = '${json['registrationType'] ?? ''}'
      .trim()
      .toLowerCase();
  if (role == 'seller' || registrationType == 'business') {
    return false;
  }

  final status =
      '${json['verificationStatus'] ?? json['accountStatus'] ?? json['status'] ?? ''}'
          .trim()
          .toLowerCase();
  if (status == 'pending' ||
      status == 'unverified' ||
      status == 'under_review' ||
      status == 'under-review' ||
      status == 'review') {
    return false;
  }

  final approved = json['isApproved'];
  if (approved is bool && !approved) return false;
  if (approved is num && approved == 0) return false;

  final verified = _readFlag(json['isVerified'] ?? json['verified']);
  if (verified != null) return verified;

  if (status == 'verified' || status == 'approved' || status == 'active') {
    return true;
  }
  return fallback;
}

Map<String, dynamic>? _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), v));
  }
  return null;
}

bool? _readFlag(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final s = value.trim().toLowerCase();
    if (s == 'true' || s == '1' || s == 'verified' || s == 'approved') {
      return true;
    }
    if (s == 'false' || s == '0' || s == 'pending' || s == 'unverified') {
      return false;
    }
  }
  return null;
}
