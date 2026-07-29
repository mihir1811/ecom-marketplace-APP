import 'package:flutter/material.dart';

import '../../domain/models/diamond_viewer_load_state.dart';

/// Stub for non-web platforms — real iframe lives in `diamond_viewer_web_embed.dart`.
class DiamondViewerWebEmbed extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
