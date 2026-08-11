class LoginSession {
  const LoginSession({
    required this.id,
    required this.scope,
    required this.ipAddress,
    required this.userAgent,
    required this.deviceInfo,
    required this.isRemembered,
    required this.isActive,
    required this.loginAtLabel,
    this.logoutAtLabel,
  });

  final String id;
  final String scope;
  final String ipAddress;
  final String userAgent;
  final String deviceInfo;
  final bool isRemembered;
  final bool isActive;
  final String loginAtLabel;
  final String? logoutAtLabel;
}

class ActiveSellerDevice {
  const ActiveSellerDevice({
    required this.id,
    required this.deviceInfo,
    required this.ipAddress,
    required this.loginAtLabel,
    required this.isRemembered,
  });

  final String id;
  final String deviceInfo;
  final String ipAddress;
  final String loginAtLabel;
  final bool isRemembered;
}
