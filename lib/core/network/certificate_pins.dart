import 'package:flutter/foundation.dart';

import 'isrg_roots.dart';

/// Certificate pinning for the GemWorld API.
///
/// The API certificate is issued by Let's Encrypt: the leaf renews every 90
/// days and the intermediate (YE2 today) rotates without notice, so the pins
/// are the four ISRG *roots* ([IsrgRoots]). Any Let's Encrypt certificate
/// keeps working; a certificate from any other CA, or a TLS-intercepting
/// proxy, is refused.
///
/// The same roots are pinned for platform networking (WebViews, native SDKs)
/// in android/app/src/main/res/xml/network_security_config.xml, by SPKI
/// SHA-256 hash, with the same [expiresAt].
///
/// Safety: pinning switches itself off after [expiresAt] (fail-open), so an
/// app that is never updated cannot lock its users out forever.
///
/// Rotation:
/// - Moving the API to another CA: ship an app update that adds the new CA's
///   root here and in network_security_config.xml *before* switching the
///   server, and keep the old roots until that update is widely installed.
/// - Before [expiresAt]: re-check https://letsencrypt.org/certificates/,
///   update [IsrgRoots] / the XML pins if needed, and move both dates forward.
/// - Emergency: set `CERT_PINNING=false` via --dart-define for a build that
///   only uses system trust in Dart (the XML pins still apply until expiry).
abstract final class CertificatePins {
  /// Hosts whose TLS chain must end at an ISRG root.
  static const hosts = {'api.gemworld.in'};

  /// After this date pinning is off and normal system trust applies.
  static final expiresAt = DateTime.utc(2028, 6, 30);

  static const _enabledByBuild = bool.fromEnvironment(
    'CERT_PINNING',
    defaultValue: true,
  );

  /// Off in debug builds (so HTTP debugging proxies work), on web (the
  /// browser owns TLS), and after [expiresAt].
  static bool get active =>
      _enabledByBuild &&
      !kDebugMode &&
      !kIsWeb &&
      DateTime.now().toUtc().isBefore(expiresAt);

  /// PEM trust anchors for [hosts].
  static List<String> get roots => IsrgRoots.all;
}
