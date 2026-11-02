import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/utils/certificate_url.dart';
import '../../../../core/widgets/luxe/luxe_button.dart';

/// Opens a certificate in-app so it renders before anything is saved; the
/// viewer's download action hands the file to the system.
///
/// On web the certificate opens in a new browser tab (cross-origin pages
/// such as GIA Report Check refuse to be framed).
Future<void> openCertificateViewer(
  BuildContext context, {
  required String url,
  String title = 'Certificate',
}) async {
  final resolved = _resolveCertificateUrl(url);
  final uri = Uri.tryParse(resolved);
  if (uri == null || !uri.hasScheme) return;
  if (kIsWeb) {
    await launchUrl(uri, webOnlyWindowName: '_blank');
    return;
  }
  await Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      builder: (_) => CertificateViewerScreen(url: resolved, title: title),
    ),
  );
}

String _resolveCertificateUrl(String url) {
  var resolved = url.trim();
  if (resolved.toLowerCase().startsWith('www.')) {
    resolved = 'https://$resolved';
  }
  return resolved;
}

/// Full-screen certificate page (GIA Report Check or a hosted PDF).
class CertificateViewerScreen extends StatefulWidget {
  const CertificateViewerScreen({
    required this.url,
    required this.title,
    super.key,
  });

  final String url;
  final String title;

  @override
  State<CertificateViewerScreen> createState() =>
      _CertificateViewerScreenState();
}

class _CertificateViewerScreenState extends State<CertificateViewerScreen> {
  InAppWebViewController? _controller;
  double _progress = 0;
  bool _failed = false;
  int _generation = 0;

  /// PDF the page offered for download (e.g. GIA's "Download PDF").
  String? _pdfUrl;

  /// Android WebView cannot draw PDFs and saves them instead, so PDFs go
  /// through an embeddable viewer there; iOS renders them natively.
  static bool get _needsPdfProxy =>
      defaultTargetPlatform == TargetPlatform.android;

  static String _renderable(String url) =>
      _needsPdfProxy && CertificateUrl.isPdf(url)
      ? 'https://docs.google.com/gview?embedded=1&url=${Uri.encodeComponent(url)}'
      : url;

  /// The offered PDF when known, else the certificate page itself (GIA
  /// Report Check offers its PDF from there).
  String get _downloadUrl => _pdfUrl ?? widget.url;

  Future<void> _download() async {
    AppHaptics.selection();
    final uri = Uri.tryParse(_downloadUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _reload() {
    AppHaptics.selection();
    setState(() {
      _generation++;
      _failed = false;
      _progress = 0;
    });
  }

  Future<void> _showPdf(String pdfUrl) async {
    setState(() => _pdfUrl = pdfUrl);
    await _controller?.loadUrl(
      urlRequest: URLRequest(url: WebUri(_renderable(pdfUrl))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Scaffold(
      backgroundColor: p.canvas,
      appBar: AppBar(
        backgroundColor: p.surface,
        foregroundColor: p.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: LuxeType.display(19, p.ink),
        ),
        actions: [
          IconButton(
            tooltip: context.tr(CatalogL10n.tryAgain),
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _reload,
          ),
          IconButton(
            tooltip: context.tr(DiamondFlowL10n.downloadCertificate),
            icon: const Icon(Icons.download_rounded),
            onPressed: _download,
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: _progress < 1 && !_failed
              ? LinearProgressIndicator(
                  value: _progress == 0 ? null : _progress,
                  minHeight: 2,
                  color: p.accent,
                  backgroundColor: Colors.transparent,
                )
              : Container(height: 0.6, color: p.hairline),
        ),
      ),
      body: _failed
          ? _CertificateError(onRetry: _reload, onDownload: _download)
          : InAppWebView(
              key: ValueKey(_generation),
              initialUrlRequest: URLRequest(
                url: WebUri(_renderable(widget.url)),
              ),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
                useOnDownloadStart: true,
                useHybridComposition: true,
                supportZoom: true,
                builtInZoomControls: true,
                displayZoomControls: false,
                useWideViewPort: true,
                loadWithOverviewMode: true,
                thirdPartyCookiesEnabled: true,
                sharedCookiesEnabled: true,
                mixedContentMode: MixedContentMode.MIXED_CONTENT_NEVER_ALLOW,
              ),
              onWebViewCreated: (c) => _controller = c,
              onProgressChanged: (_, progress) {
                if (mounted) setState(() => _progress = progress / 100);
              },
              // Render offered PDFs in place instead of saving them.
              onDownloadStartRequest: (_, request) =>
                  _showPdf(request.url.toString()),
              onReceivedError: (_, request, _) {
                if (request.isForMainFrame ?? true) {
                  if (mounted) setState(() => _failed = true);
                }
              },
              onReceivedHttpError: (_, request, response) {
                final code = response.statusCode ?? 0;
                if ((request.isForMainFrame ?? true) && code >= 400) {
                  if (mounted) setState(() => _failed = true);
                }
              },
            ),
    );
  }
}

class _CertificateError extends StatelessWidget {
  const _CertificateError({required this.onRetry, required this.onDownload});

  final VoidCallback onRetry;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined, size: 48, color: p.inkMuted),
            const SizedBox(height: 10),
            Text(
              context.tr(DiamondFlowL10n.certificateLoadFailed),
              textAlign: TextAlign.center,
              style: LuxeType.label(p.ink, size: 14),
            ),
            const SizedBox(height: 14),
            LuxeButton(
              label: context.tr(CatalogL10n.tryAgain),
              icon: Icons.refresh_rounded,
              height: 44,
              onPressed: onRetry,
            ),
            const SizedBox(height: 8),
            LuxeButton(
              label: context.tr(DiamondFlowL10n.downloadCertificate),
              variant: LuxeButtonVariant.secondary,
              icon: Icons.download_rounded,
              height: 44,
              onPressed: onDownload,
            ),
          ],
        ),
      ),
    );
  }
}
