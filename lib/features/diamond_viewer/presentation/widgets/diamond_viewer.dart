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
  Timer? _probeTimer;
  DateTime? _pageReadyAt;
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
    _probeTimer?.cancel();
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

  void _fail(String message, {bool canRetry = true}) {
    _probeTimer?.cancel();
    _timeout?.cancel();
    _emit(DiamondViewerFailed(message: message, canRetry: canRetry));
  }

  bool _isAccessDenied(int? code, String? description) {
    if (code == 401 || code == 403) return true;
    final text = description?.toLowerCase() ?? '';
    return text.contains('access denied') || text.contains('403');
  }

  Future<void> _reload() async {
    _loadGeneration++;
    _probeTimer?.cancel();
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
      preferredContentMode: UserPreferredContentMode.DESKTOP,
      userAgent: cfg.userAgent ?? DiamondViewerConfig.defaultDesktopUserAgent,
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

      _pageReadyAt = DateTime.now();
      await _probeMedia(generation);
    } catch (_) {
      if (!mounted || generation != _loadGeneration) return;
      _pageReadyAt = DateTime.now();
      await _probeMedia(generation);
    }
  }

  Future<void> _probeMedia(int generation) async {
    if (!mounted || generation != _loadGeneration) return;
    if (_state is DiamondViewerFailed) return;
    final controller = _controller;
    if (controller == null) return;

    var status = 'pending';
    try {
      final raw = await controller.evaluateJavascript(
        source: ViewerJsBridge.mediaStatus,
      );
      status = raw?.toString().replaceAll('"', '').trim() ?? 'pending';
    } catch (_) {
      status = 'pending';
    }
    if (!mounted || generation != _loadGeneration) return;
    if (_state is DiamondViewerFailed) return;

    if (status == 'ok') {
      _probeTimer?.cancel();
      _timeout?.cancel();
      widget.onEngineDetected?.call('media');
      _emit(const DiamondViewerReady(engineHint: 'media'));
      return;
    }
    if (status == 'denied') {
      _fail(context.tr(CatalogL10n.viewerAccessDenied));
      return;
    }

    // Keep the Flutter loader up while frames are still arriving.
    if (_state is! DiamondViewerLoading) {
      _emit(const DiamondViewerLoading());
    }

    final elapsed = DateTime.now().difference(_pageReadyAt ?? DateTime.now());
    final giveUp = status == 'empty'
        ? const Duration(seconds: 6)
        : const Duration(seconds: 25);
    if (elapsed >= giveUp) {
      _fail(context.tr(CatalogL10n.viewerNoMedia));
      return;
    }

    _probeTimer?.cancel();
    _probeTimer = Timer(const Duration(milliseconds: 500), () {
      _probeMedia(generation);
    });
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
    final mediaReady = _state is DiamondViewerReady;
    final showLoader = !kIsWeb && _state is DiamondViewerLoading;
    final showError = !kIsWeb && _state is DiamondViewerFailed;

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
          // Hybrid Composition draws above Flutter siblings — hide the WebView
          // until diamond media is confirmed so the loader stays visible.
          Opacity(
            opacity: mediaReady ? 1 : 0,
            child: IgnorePointer(
              ignoring: !mediaReady,
              child: InAppWebView(
                key: ValueKey(url),
                initialUrlRequest: URLRequest(url: WebUri(url)),
                initialSettings: _settings(),
                gestureRecognizers: _gestureRecognizers,
                onWebViewCreated: (controller) {
                  _controller = controller;
                  widget.controller?.attach(controller);
                },
                onLoadStart: (_, __) {
                  _probeTimer?.cancel();
                  _emit(const DiamondViewerLoading());
                  _armTimeout();
                },
                onProgressChanged: (_, value) {
                  if (_state is DiamondViewerReady ||
                      _state is DiamondViewerFailed) {
                    return;
                  }
                  // Cap below 1.0 so the bar does not look finished while frames
                  // are still loading after HTML arrives.
                  final capped = (value / 100).clamp(0.0, 0.92);
                  _emit(DiamondViewerLoading(progress: capped));
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
                  _fail(
                    _isAccessDenied(null, error.description)
                        ? context.tr(CatalogL10n.viewerAccessDenied)
                        : (error.description.isEmpty
                              ? context.tr(CatalogL10n.viewerNoMedia)
                              : error.description),
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
                  _fail(
                    _isAccessDenied(code, null)
                        ? context.tr(CatalogL10n.viewerAccessDenied)
                        : context.tr(CatalogL10n.viewerHttpError, {
                            'code': code,
                          }),
                  );
                },
                onConsoleMessage: kDebugMode
                    ? (_, msg) {
                        debugPrint('[DiamondViewer] ${msg.message}');
                      }
                    : null,
              ),
            ),
          ),
        if (showLoader)
          widget.loadingBuilder?.call(context, progress) ??
              DiamondViewerLoadingView(progress: progress),
        if (showError)
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
