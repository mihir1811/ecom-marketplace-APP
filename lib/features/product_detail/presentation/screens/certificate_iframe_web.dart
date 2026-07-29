import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class CertificateIFrame extends StatefulWidget {
  const CertificateIFrame({
    required this.url,
    required this.onLoaded,
    super.key,
  });

  final String url;
  final VoidCallback onLoaded;

  @override
  State<CertificateIFrame> createState() => _CertificateIFrameState();
}

class _CertificateIFrameState extends State<CertificateIFrame> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'certificate-${identityHashCode(this)}';
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final iframe = web.HTMLIFrameElement()
        ..src = widget.url
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
      iframe.onLoad.listen((_) => widget.onLoaded());
      return iframe;
    });
    // Cross-origin PDFs may not fire onLoad reliably.
    Future<void>.delayed(const Duration(milliseconds: 800), widget.onLoaded);
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
