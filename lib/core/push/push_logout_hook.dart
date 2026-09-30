/// Runs a device unregister just before the auth logout request.
abstract final class PushLogoutHook {
  static Future<void> Function()? beforeLogout;
}
