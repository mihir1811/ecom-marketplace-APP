/// Load lifecycle for the interactive 360° WebView.
sealed class DiamondViewerLoadState {
  const DiamondViewerLoadState();
}

final class DiamondViewerLoading extends DiamondViewerLoadState {
  const DiamondViewerLoading({this.progress = 0});

  /// 0.0 – 1.0 when the platform reports progress; otherwise 0.
  final double progress;
}

final class DiamondViewerReady extends DiamondViewerLoadState {
  const DiamondViewerReady({this.engineHint});

  /// Best-effort detection string (canvas / three.js / Vision360 / …).
  final String? engineHint;
}

final class DiamondViewerFailed extends DiamondViewerLoadState {
  const DiamondViewerFailed({
    required this.message,
    this.canRetry = true,
  });

  final String message;
  final bool canRetry;
}
