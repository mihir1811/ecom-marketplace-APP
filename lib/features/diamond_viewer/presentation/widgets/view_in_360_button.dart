import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/diamond_viewer_args.dart';
import '../../utils/viewer_url_resolver.dart';

/// Hero CTA that opens the fullscreen interactive 360° viewer.
class ViewIn360Button extends StatelessWidget {
  const ViewIn360Button({
    required this.viewerUrl,
    super.key,
    this.title = '360° View',
    this.subtitle,
    this.label = 'View in 360°',
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

    if (compact) {
      return FilledButton.tonalIcon(
        onPressed: () => open(
          context,
          viewerUrl: resolved,
          title: title,
          subtitle: subtitle,
        ),
        icon: const Icon(Icons.threed_rotation, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          foregroundColor: AppColors.warmWhite,
          backgroundColor: AppColors.charcoal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s12,
          ),
        ),
      );
    }

    return Material(
      color: AppColors.charcoal,
      borderRadius: BorderRadius.circular(AppSpacing.r16),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.r16),
        onTap: () => open(
          context,
          viewerUrl: resolved,
          title: title,
          subtitle: subtitle,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s12,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.threed_rotation,
                color: AppColors.warmWhite,
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.label.copyWith(
                        color: AppColors.warmWhite,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Rotate, pinch, and inspect at full quality',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.bronzeLight,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.warmWhite,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
