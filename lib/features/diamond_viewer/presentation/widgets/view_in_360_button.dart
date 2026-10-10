import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../domain/models/diamond_viewer_args.dart';
import '../../utils/viewer_url_resolver.dart';

/// Hero CTA that opens the fullscreen interactive 360° viewer.
class ViewIn360Button extends StatelessWidget {
  const ViewIn360Button({
    required this.viewerUrl,
    super.key,
    this.title = '360° View',
    this.subtitle,
    this.label = '360° View',
    this.compact = false,
  });

  final String viewerUrl;
  final String title;
  final String? subtitle;
  final String label;
  final bool compact;

  static void open(
    BuildContext context, {
    required String viewerUrl,
    String title = '360° View',
    String? subtitle,
  }) {
    final resolved = ViewerUrlResolver.resolve(viewerUrl);
    if (resolved == null) return;
    context.push(
      AppRouteNames.diamondViewer,
      extra: DiamondViewerArgs(
        viewerUrl: resolved,
        title: title,
        subtitle: subtitle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = ViewerUrlResolver.resolve(viewerUrl);
    if (resolved == null) return const SizedBox.shrink();

    void go() =>
        open(context, viewerUrl: resolved, title: title, subtitle: subtitle);

    if (compact) {
      return FilledButton.icon(
        onPressed: go,
        icon: const Icon(Icons.threed_rotation_rounded, size: 18),
        label: Text(label, style: LuxeType.label(LuxeStage.ink)),
        style: FilledButton.styleFrom(
          foregroundColor: LuxeStage.gold,
          backgroundColor: LuxeStage.obsidian,
          shape: const StadiumBorder(
            side: BorderSide(color: LuxeStage.glassBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );
    }

    return Material(
      color: LuxeStage.obsidian,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
        side: const BorderSide(color: LuxeStage.glassBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: go,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.threed_rotation_rounded, color: LuxeStage.gold),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: LuxeType.label(LuxeStage.ink)),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: LuxeStage.gold,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
