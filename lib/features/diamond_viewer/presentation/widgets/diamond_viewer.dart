import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../domain/models/diamond_viewer_config.dart';
import '../../domain/models/diamond_viewer_load_state.dart';
import '../../utils/viewer_js_bridge.dart';
import '../../utils/viewer_resource_policy.dart';
import '../../utils/viewer_url_resolver.dart';
import '../controllers/diamond_viewer_controller.dart';
import 'diamond_viewer_error.dart';
import 'diamond_viewer_loading.dart';
import 'diamond_viewer_web_embed_stub.dart'
    if (dart.library.html) 'diamond_viewer_web_embed_web.dart';

/// Production interactive 360° / Vision360 WebGL viewer.
///
/// Uses [flutter_inappwebview] so Canvas/WebGL touch events (rotate, pinch,
/// pan) reach the page. Prefer presenting this inside
/// [DiamondViewerScreen] fullscreen so parent scroll views cannot steal
/// gestures.
class DiamondViewer extends StatefulWidget {
  const DiamondViewer({
    required this.viewerUrl,
    super.key,
    this.config = DiamondViewerConfig.standard,
    this.controller,
    this.loadingBuilder,
    this.errorBuilder,
    this.onLoadStateChanged,
    this.onEngineDetected,
  });

  final String viewerUrl;
  final DiamondViewerConfig config;
  final DiamondViewerController? controller;
  final Widget Function(BuildContext context, double progress)? loadingBuilder;
  final Widget Function(
    BuildContext context,
    String message,
    VoidCallback retry,
  )?
  errorBuilder;
  final ValueChanged<DiamondViewerLoadState>? onLoadStateChanged;
  final ValueChanged<String>? onEngineDetected;

  @override
  State<DiamondViewer> createState() => _DiamondViewerState();
}

class _DiamondViewerState extends State<DiamondViewer> {
  InAppWebViewController? _controller;
  Timer? _timeout;
  DiamondViewerLoadState _state = const DiamondViewerLoading();
  var _loadGeneration = 0;

  String? get _resolvedUrl => ViewerUrlResolver.resolve(
    widget.viewerUrl,
    httpsOnly: widget.config.httpsOnly,
  );

  @override
  void initState() {
    super.initState();
    _emit(_state);
    _armTimeout();
  }

  @override
  void didUpdateWidget(covariant DiamondViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewerUrl != widget.viewerUrl) {
      _reload();
    }
  }

  @override
  void dispose() {
    _timeout?.cancel();
    widget.controller?.detach();
    _controller = null;
    super.dispose();
  }

  void _emit(DiamondViewerLoadState next) {
    _state = next;
    widget.onLoadStateChanged?.call(next);
    if (mounted) setState(() {});
  }

  void _armTimeout() {
    _timeout?.cancel();
    _timeout = Timer(widget.config.pageLoadTimeout, () {
      if (!mounted) return;
      if (_state is DiamondViewerReady) return;
      _emit(
        DiamondViewerFailed(message: context.tr(CatalogL10n.viewerTimeout)),
      );
    });
  }

  Future<void> _reload() async {
    _loadGeneration++;
    _emit(const DiamondViewerLoading());
    _armTimeout();
    final url = _resolvedUrl;
    if (url == null) {
      _emit(
        DiamondViewerFailed(
          message: context.tr(CatalogL10n.viewerInvalidUrl),
          canRetry: false,
        ),
      );
      return;
    }
    final controller = _controller;
    if (controller != null) {
      await controller.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    }
  }

  InAppWebViewSettings _settings() {
    final cfg = widget.config;
    return InAppWebViewSettings(
      javaScriptEnabled: true,
      domStorageEnabled: true,
      databaseEnabled: true,
      clearCache: false,
      cacheEnabled: true,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      allowsPictureInPictureMediaPlayback: true,
      allowsBackForwardNavigationGestures: false,
      supportZoom: cfg.enableZoom,
      builtInZoomControls: cfg.enableZoom,
      displayZoomControls: false,
      useWideViewPort: true,
      loadWithOverviewMode: true,
      transparentBackground: true,
      disableHorizontalScroll: false,
      disableVerticalScroll: false,
      disableContextMenu: true,
      hardwareAcceleration: true,
      // Hybrid Composition: better WebGL + touch forwarding on Android.
      useHybridComposition: !kIsWeb,
      mixedContentMode: MixedContentMode.MIXED_CONTENT_NEVER_ALLOW,
      thirdPartyCookiesEnabled: true,
      sharedCookiesEnabled: true,
      allowsLinkPreview: false,
      isFraudulentWebsiteWarningEnabled: true,
      preferredContentMode: UserPreferredContentMode.MOBILE,
      userAgent: cfg.userAgent ?? DiamondViewerConfig.defaultMobileUserAgent,
      iframeAllow:
          'accelerometer; autoplay; clipboard-write; encrypted-media; '
          'gyroscope; picture-in-picture; web-share',
      iframeAllowFullscreen: true,
    );
  }

  Set<Factory<OneSequenceGestureRecognizer>>? get _gestureRecognizers {
    if (!widget.config.claimAllGestures) return null;
    return const <Factory<OneSequenceGestureRecognizer>>{
      Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
    };
  }

  Future<void> _onPageFinished(WebUri? url) async {
    final generation = _loadGeneration;
    final controller = _controller;
    if (controller == null || !mounted) return;

    try {
      await controller.evaluateJavascript(source: ViewerJsBridge.layoutFix);
      // Second pass after Vision360 finishes sizing its canvas.
      await Future<void>.delayed(const Duration(milliseconds: 320));
      if (!mounted || generation != _loadGeneration) return;
      await controller.evaluateJavascript(source: ViewerJsBridge.layoutFix);

      final raw = await controller.evaluateJavascript(
        source: ViewerJsBridge.detectEngine,
      );
      if (!mounted || generation != _loadGeneration) return;
      final hint = raw?.toString().replaceAll('"', '') ?? 'unknown';
      widget.onEngineDetected?.call(hint);
      _timeout?.cancel();
      _emit(DiamondViewerReady(engineHint: hint));
    } catch (_) {
      if (!mounted || generation != _loadGeneration) return;
      _timeout?.cancel();
      _emit(const DiamondViewerReady());
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = _resolvedUrl;
    if (url == null) {
      final message = context.tr(CatalogL10n.viewerInvalidUrl);
      return widget.errorBuilder?.call(context, message, _reload) ??
          DiamondViewerErrorView(message: message);
    }

    final progress = switch (_state) {
      DiamondViewerLoading(:final progress) => progress,
      _ => 0.0,
    };

    return Stack(
      fit: StackFit.expand,
      children: [
        if (kIsWeb)
          DiamondViewerWebEmbed(
            url: url,
            loadingBuilder: widget.loadingBuilder,
            errorBuilder: widget.errorBuilder,
            onLoadStateChanged: (state) {
              _emit(state);
              if (state is DiamondViewerReady) _timeout?.cancel();
            },
            onRetry: _reload,
          )
        else
          InAppWebView(
            key: ValueKey(url),
            initialUrlRequest: URLRequest(url: WebUri(url)),
            initialSettings: _settings(),
            gestureRecognizers: _gestureRecognizers,
            onWebViewCreated: (controller) {
              _controller = controller;
              widget.controller?.attach(controller);
            },
            onLoadStart: (_, __) {
              _emit(const DiamondViewerLoading());
              _armTimeout();
            },
            onProgressChanged: (_, value) {
              if (_state is DiamondViewerReady) return;
              _emit(DiamondViewerLoading(progress: value / 100));
            },
            onLoadStop: (_, uri) => _onPageFinished(uri),
            onReceivedError: (controller, request, error) {
              if (!ViewerResourcePolicy.shouldFailViewer(
                isForMainFrame: request.isForMainFrame,
                requestUrl: request.url,
              )) {
                if (kDebugMode) {
                  debugPrint(
                    '[DiamondViewer] ignored resource error: '
                    '${request.url} ${error.description}',
                  );
                }
                return;
              }
              _timeout?.cancel();
              _emit(
                DiamondViewerFailed(
                  message: error.description.isEmpty
                      ? 'The 360° viewer could not be loaded.'
                      : error.description,
                ),
              );
            },
            onReceivedHttpError: (controller, request, response) {
              final code = response.statusCode ?? 0;
              if (!ViewerResourcePolicy.shouldFailViewer(
                isForMainFrame: request.isForMainFrame,
                requestUrl: request.url,
                statusCode: code,
              )) {
                if (kDebugMode) {
                  debugPrint(
                    '[DiamondViewer] ignored HTTP $code: ${request.url}',
                  );
                }
                return;
              }
              _timeout?.cancel();
              _emit(
                DiamondViewerFailed(
                  message: context.tr(CatalogL10n.viewerHttpError, {
                    'code': code,
                  }),
                ),
              );
            },
            onConsoleMessage: kDebugMode
                ? (_, msg) {
                    debugPrint('[DiamondViewer] ${msg.message}');
                  }
                : null,
          ),
        if (!kIsWeb && _state is DiamondViewerLoading)
          widget.loadingBuilder?.call(context, progress) ??
              DiamondViewerLoadingView(progress: progress),
        if (!kIsWeb && _state is DiamondViewerFailed)
          Builder(
            builder: (context) {
              final failed = _state as DiamondViewerFailed;
              return widget.errorBuilder?.call(
                    context,
                    failed.message,
                    _reload,
                  ) ??
                  DiamondViewerErrorView(
                    message: failed.message,
                    onRetry: failed.canRetry ? _reload : null,
                  );
            },
          ),
      ],
    );
  }
}
