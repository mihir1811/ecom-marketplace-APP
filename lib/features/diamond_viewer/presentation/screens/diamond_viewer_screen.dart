import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/diamond_viewer_args.dart';
import '../../domain/models/diamond_viewer_config.dart';
import '../widgets/diamond_viewer.dart';

/// Immersive fullscreen 360° experience — preferred UX over in-list embeds.
class DiamondViewerScreen extends StatefulWidget {
  const DiamondViewerScreen({
    required this.args,
    super.key,
    this.config = DiamondViewerConfig.standard,
  });

  final DiamondViewerArgs args;
  final DiamondViewerConfig config;

  @override
  State<DiamondViewerScreen> createState() => _DiamondViewerScreenState();
}

class _DiamondViewerScreenState extends State<DiamondViewerScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = widget.args.subtitle;

    return Scaffold(
      backgroundColor: AppColors.charcoal,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s8,
                AppSpacing.s8,
                AppSpacing.s8,
                AppSpacing.s8,
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: context.tr(CatalogL10n.close),
                    onPressed: () => context.goBack(),
                    icon: const Icon(Icons.close, color: AppColors.warmWhite),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.args.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.title.copyWith(
                            color: AppColors.warmWhite,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (subtitle != null && subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.bronzeLight,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(right: AppSpacing.s12),
                    child: Icon(
                      Icons.touch_app_outlined,
                      color: AppColors.bronzeLight,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  context.tr(CatalogL10n.viewerGestureHint),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.bronzeLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Expanded(
              child: ColoredBox(
                color: AppColors.charcoal,
                child: DiamondViewer(
                  viewerUrl: widget.args.viewerUrl,
                  config: widget.config,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
