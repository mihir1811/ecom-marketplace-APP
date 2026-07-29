/// Resolved viewer launch arguments passed through GoRouter `extra`.
class DiamondViewerArgs {
  const DiamondViewerArgs({
    required this.viewerUrl,
    this.title = '360° View',
    this.subtitle,
  });

  final String viewerUrl;
  final String title;
  final String? subtitle;
}
