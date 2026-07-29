/// Policy for which WebView resource failures should fail the viewer UI.
abstract final class ViewerResourcePolicy {
  static const Set<String> ignorableHosts = {
    'analytics.360view.link',
    'www.google-analytics.com',
    'www.googletagmanager.com',
    'connect.facebook.net',
  };

  static bool isIgnorableHost(String? host) {
    if (host == null || host.isEmpty) return false;
    final lower = host.toLowerCase();
    if (ignorableHosts.contains(lower)) return true;
    // Any analytics.* subdomain of 360view.link
    if (lower.endsWith('.360view.link') && lower.startsWith('analytics')) {
      return true;
    }
    return false;
  }

  /// True when an HTTP/resource error should surface as a viewer failure.
  static bool shouldFailViewer({
    required bool? isForMainFrame,
    required Uri? requestUrl,
    int? statusCode,
  }) {
    if (isIgnorableHost(requestUrl?.host)) return false;

    // Subresource / iframe / XHR failures (e.g. analytics 404) must not
    // tear down a working Vision360 / 360view page.
    if (isForMainFrame == false) return false;

    if (statusCode != null && statusCode < 400) return false;

    // When the platform omits isForMainFrame, only fail hard 4xx/5xx on the
    // document URL host patterns we care about — never analytics.
    return true;
  }
}
