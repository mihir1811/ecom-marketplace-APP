import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Thin handle around [InAppWebViewController] for callers that need reload /
/// JS evaluation outside the widget tree.
class DiamondViewerController {
  InAppWebViewController? _web;

  void attach(InAppWebViewController controller) => _web = controller;

  void detach() => _web = null;

  bool get isAttached => _web != null;

  Future<void> reload() async {
    await _web?.reload();
  }

  Future<void> loadUrl(String url) async {
    await _web?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
  }

  Future<dynamic> evaluateJavascript(String source) async {
    return _web?.evaluateJavascript(source: source);
  }
}
