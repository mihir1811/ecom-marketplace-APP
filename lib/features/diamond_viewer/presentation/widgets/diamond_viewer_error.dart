import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/luxe/luxe_button.dart';

/// Luxe failure state for the 360° viewer with a retry action.
class DiamondViewerErrorView extends StatelessWidget {
  const DiamondViewerErrorView({
    required this.message,
    super.key,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    Widget body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: LuxeStage.glass,
            border: Border.all(color: LuxeStage.glassBorder),
          ),
          child: Icon(
            Icons.threed_rotation_rounded,
            size: 34,
            color: LuxeStage.gold,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Unable to open 360° view',
          textAlign: TextAlign.center,
          style: LuxeType.display(26, LuxeStage.ink),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: LuxeType.body(LuxeStage.inkMuted, size: 14),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 16),
          LuxeButton(
            label: context.tr(CatalogL10n.tryAgain),
            icon: Icons.refresh_rounded,
            variant: LuxeButtonVariant.accent,
            onPressed: onRetry,
          ),
        ],
      ],
    );
    if (!MediaQuery.disableAnimationsOf(context)) {
      body = body
          .animate()
          .fadeIn(duration: 500.ms)
          .moveY(begin: 14, end: 0, duration: 700.ms, curve: LuxeMotion.settle);
    }
    return ColoredBox(
      color: LuxeStage.obsidian,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: body,
          ),
        ),
      ),
    );
  }
}
