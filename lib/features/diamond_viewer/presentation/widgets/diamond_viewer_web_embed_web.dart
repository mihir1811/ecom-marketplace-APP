import 'dart:async';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../domain/models/diamond_viewer_load_state.dart';
import 'diamond_viewer_error.dart';
import 'diamond_viewer_loading.dart';

/// Chrome / Flutter-web embed via iframe (InAppWebView web impl is unreliable).
class DiamondViewerWebEmbed extends StatefulWidget {
  const DiamondViewerWebEmbed({
    required this.url,
    super.key,
    this.loadingBuilder,
    this.errorBuilder,
    this.onLoadStateChanged,
    this.onRetry,
  });

  final String url;
  final Widget Function(BuildContext context, double progress)? loadingBuilder;
  final Widget Function(
    BuildContext context,
    String message,
    VoidCallback retry,
  )? errorBuilder;
  final ValueChanged<DiamondViewerLoadState>? onLoadStateChanged;
  final VoidCallback? onRetry;

  @override
  State<DiamondViewerWebEmbed> createState() => _DiamondViewerWebEmbedState();
}

class _DiamondViewerWebEmbedState extends State<DiamondViewerWebEmbed> {
  late final String _viewType;
  DiamondViewerLoadState _state = const DiamondViewerLoading();
  Timer? _readyTimer;

  @override
  void initState() {
    super.initState();
    _viewType = 'diamond-viewer-${identityHashCode(this)}';
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final iframe = web.HTMLIFrameElement()
        ..src = widget.url
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.display = 'block'
        ..allowFullscreen = true
        ..setAttribute(
          'allow',
          'accelerometer; autoplay; clipboard-write; encrypted-media; '
              'gyroscope; picture-in-picture; web-share',
        )
        ..setAttribute('referrerpolicy', 'no-referrer-when-downgrade');

      iframe.onLoad.listen((_) {
        if (!mounted) return;
        _emit(const DiamondViewerReady(engineHint: 'iframe'));
      });
      iframe.onError.listen((_) {
        if (!mounted) return;
        _emit(
          const DiamondViewerFailed(
            message: 'The 360° viewer could not be loaded in this browser.',
          ),
        );
      });

      return iframe;
    });

    // Safety: mark ready after a short delay even if onLoad is delayed by
    // cross-origin restrictions (analytics 404s must not block this).
    _readyTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (_state is DiamondViewerLoading) {
        _emit(const DiamondViewerReady(engineHint: 'iframe'));
      }
    });
  }

  @override
  void dispose() {
    _readyTimer?.cancel();
    super.dispose();
  }

  void _emit(DiamondViewerLoadState next) {
    _state = next;
    widget.onLoadStateChanged?.call(next);
    if (mounted) setState(() {});
  }

  void _retry() {
    widget.onRetry?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        HtmlElementView(viewType: _viewType),
        if (_state is DiamondViewerLoading)
          widget.loadingBuilder?.call(context, 0) ??
              const DiamondViewerLoadingView(),
        if (_state case DiamondViewerFailed(:final message, :final canRetry))
          widget.errorBuilder?.call(context, message, _retry) ??
              DiamondViewerErrorView(
                message: message,
                onRetry: canRetry ? _retry : null,
              ),
      ],
    );
  }
}
