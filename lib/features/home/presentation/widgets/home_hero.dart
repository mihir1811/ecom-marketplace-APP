import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/l10n/translations/remaining_messages.dart';
import '../../../../core/l10n/app_localizations.dart';

/// Full-bleed marketplace hero — brand, one line, two CTAs, network image.
class HomeHero extends StatelessWidget {
  const HomeHero({
    required this.imageUrl,
    required this.onPrimary,
    required this.onSecondary,
    super.key,
  });

  final String imageUrl;
  final ValueChanged<BuildContext> onPrimary;
  final ValueChanged<BuildContext> onSecondary;

  @override
  Widget build(BuildContext context) {
    final height = (MediaQuery.sizeOf(context).height * 0.42).clamp(
      280.0,
      420.0,
    );

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AppNetworkImage(url: imageUrl, memCacheWidth: 1600),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66111827),
                  Color(0x99111827),
                  Color(0xE6111827),
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s24,
              AppSpacing.s24,
              AppSpacing.s24,
              AppSpacing.s24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Text(
                  'GemWorld',
                  style: AppTypography.display.copyWith(
                    color: AppColors.warmWhite,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  context.tr(
                    RemainingL10n.certifiedDiamondsGemsAndFineJewelryIn,
                  ),
                  style: AppTypography.body.copyWith(
                    color: AppColors.warmWhite.withValues(alpha: 0.88),
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.s20),
                Wrap(
                  spacing: AppSpacing.s12,
                  runSpacing: AppSpacing.s12,
                  children: [
                    FilledButton(
                      onPressed: () => onPrimary(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.warmWhite,
                        foregroundColor: AppColors.charcoal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s20,
                          vertical: AppSpacing.s16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.r8),
                        ),
                      ),
                      child: Text(
                        context.tr(RemainingL10n.findDiamonds),
                        style: AppTypography.label.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => onSecondary(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.warmWhite,
                        side: BorderSide(
                          color: AppColors.warmWhite.withValues(alpha: 0.55),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s20,
                          vertical: AppSpacing.s16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.r8),
                        ),
                      ),
                      child: Text(
                        context.tr(RemainingL10n.browseJewelry),
                        style: AppTypography.label.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.warmWhite,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
