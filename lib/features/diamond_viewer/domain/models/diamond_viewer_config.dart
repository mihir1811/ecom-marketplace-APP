import 'package:flutter/foundation.dart';

/// Configurable behavior for [DiamondViewer].
@immutable
class DiamondViewerConfig {
  const DiamondViewerConfig({
    this.enableZoom = true,
    this.enableRotation = true,
    this.enableFullscreen = true,
    this.backgroundColor = 0x00000000,
    this.claimAllGestures = true,
    this.userAgent,
    this.httpsOnly = true,
    this.pageLoadTimeout = const Duration(seconds: 45),
  });

  /// Allow pinch / built-in zoom controls (display chrome stays hidden).
  final bool enableZoom;

  /// Prefer forwarding drag/rotation touches to the WebGL page.
  final bool enableRotation;

  /// Whether callers may open a fullscreen route from this embed.
  final bool enableFullscreen;

  /// ARGB background behind the WebView (transparent avoids white flash).
  final int backgroundColor;

  /// When true, registers [EagerGestureRecognizer] so parents cannot steal
  /// pointers (critical inside [PageView] / [ListView]).
  final bool claimAllGestures;

  /// Optional override UA. S3 Vision360 pages serve a blank shell to mobile UAs.
  final String? userAgent;

  /// Reject non-HTTPS URLs in production embeds.
  final bool httpsOnly;

  final Duration pageLoadTimeout;

  static const DiamondViewerConfig standard = DiamondViewerConfig();

  static const String defaultMobileUserAgent =
      'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

  /// Desktop Chrome. Vision360 / diamondshow HTML hides the canvas for mobile UAs.
  static const String defaultDesktopUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
}
