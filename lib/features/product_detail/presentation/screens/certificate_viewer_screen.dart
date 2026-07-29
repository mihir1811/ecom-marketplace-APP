import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class CertificateViewerArgs {
  const CertificateViewerArgs({
    required this.url,
    this.title = 'Certificate',
  });

  final String url;
  final String title;
}

/// In-app certificate viewer for mobile. Web opens externally (X-Frame-Options).
class CertificateViewerScreen extends StatefulWidget {
  const CertificateViewerScreen({required this.args, super.key});

  final CertificateViewerArgs args;

  @override
  State<CertificateViewerScreen> createState() =>
      _CertificateViewerScreenState();
}

class _CertificateViewerScreenState extends State<CertificateViewerScreen> {
  var _loading = true;

  void _setLoaded() {
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      appBar: AppBar(
        title: Text(
          widget.args.title,
          style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/'),
        ),
        actions: [
          IconButton(
            tooltip: 'Open in browser',
            icon: const Icon(Icons.open_in_new),
            onPressed: () => _launchCertificateUrl(widget.args.url),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.r16),
            child: kIsWeb
                ? _WebCertificateFallback(
                    url: widget.args.url,
                    title: widget.args.title,
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      InAppWebView(
                        initialUrlRequest:
                            URLRequest(url: WebUri(widget.args.url)),
                        initialSettings: InAppWebViewSettings(
                          javaScriptEnabled: true,
                          domStorageEnabled: true,
                          useHybridComposition: true,
                          hardwareAcceleration: true,
                          mediaPlaybackRequiresUserGesture: false,
                          allowsInlineMediaPlayback: true,
                          mixedContentMode:
                              MixedContentMode.MIXED_CONTENT_NEVER_ALLOW,
                        ),
                        onLoadStart: (_, __) {
                          if (mounted) setState(() => _loading = true);
                        },
                        onLoadStop: (_, __) => _setLoaded(),
                      ),
                      if (_loading)
                        const ColoredBox(
                          color: AppColors.creamBg,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _WebCertificateFallback extends StatelessWidget {
  const _WebCertificateFallback({
    required this.url,
    required this.title,
  });

  final String url;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.warmWhite,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.description_outlined, size: 40),
              const SizedBox(height: AppSpacing.s16),
              Text(
                title,
                style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'This certificate cannot be shown inside the app. '
                'Open it in a new browser tab.',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s24),
              FilledButton.icon(
                onPressed: () => _launchCertificateUrl(url),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open certificate'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _resolveCertificateUrl(String url) {
  var resolved = url.trim();
  if (resolved.toLowerCase().startsWith('www.')) {
    resolved = 'https://$resolved';
  }
  return resolved;
}

/// Labs like IGI/GIA set `X-Frame-Options: sameorigin`, so iframes fail on web.
bool _mustOpenExternally(String url) => kIsWeb;

Future<void> _launchCertificateUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
    webOnlyWindowName: '_blank',
  );
}

void openCertificateViewer(
  BuildContext context, {
  required String url,
  String title = 'Certificate',
}) {
  final resolved = _resolveCertificateUrl(url);
  if (_mustOpenExternally(resolved)) {
    _launchCertificateUrl(resolved);
    return;
  }
  context.push(
    AppRouteNames.certificateViewer,
    extra: CertificateViewerArgs(url: resolved, title: title),
  );
}
