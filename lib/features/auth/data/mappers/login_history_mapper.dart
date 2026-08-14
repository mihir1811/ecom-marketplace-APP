import '../../domain/models/login_session.dart';

abstract final class LoginHistoryMapper {
  static LoginSession sessionFromJson(Map<String, dynamic> json) {
    return LoginSession(
      id: json['id']?.toString() ?? '',
      scope: json['scope']?.toString() ?? '',
      ipAddress: json['ipAddress']?.toString() ?? '',
      userAgent: json['userAgent']?.toString() ?? '',
      deviceInfo: json['deviceInfo']?.toString() ?? '',
      isRemembered: json['isRemembered'] == true,
      isActive: json['isActive'] == true,
      loginAtLabel: _label(_parseDate(json['loginAt'])),
      logoutAtLabel: _label(_parseDate(json['logoutAt'])),
    );
  }

  static ActiveSellerDevice deviceFromJson(Map<String, dynamic> json) {
    return ActiveSellerDevice(
      id: json['id']?.toString() ?? '',
      deviceInfo: json['deviceInfo']?.toString() ?? '',
      ipAddress: json['ipAddress']?.toString() ?? '',
      loginAtLabel: _label(_parseDate(json['loginAt'])),
      isRemembered: json['isRemembered'] == true,
    );
  }

  static List<LoginSession> sessionsFromRoot(Map<String, dynamic>? root) {
    final data = root?['data'];
    final list = data is List ? data : const [];
    return [
      for (final item in list)
        if (item is Map<String, dynamic>) sessionFromJson(item),
    ];
  }

  static List<ActiveSellerDevice> devicesFromRoot(Map<String, dynamic>? root) {
    final data = root?['data'];
    final list = data is List ? data : const [];
    return [
      for (final item in list)
        if (item is Map<String, dynamic>) deviceFromJson(item),
    ];
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  static String _label(DateTime? date) {
    if (date == null) return '—';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}, '
        '${two(date.hour)}:${two(date.minute)}';
  }
}
