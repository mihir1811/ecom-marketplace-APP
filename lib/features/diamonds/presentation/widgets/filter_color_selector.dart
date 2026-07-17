import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';

import '../../../../core/theme/app_spacing.dart';

import '../../../../core/theme/app_typography.dart';

import '../../../../core/theme/app_shadows.dart';

import '../../application/diamond_search_provider.dart';

import '../../domain/models/diamond_filter_state.dart';

class ColorTabsSelector extends ConsumerWidget {
  const ColorTabsSelector({super.key});

  Color _getStandardColorBg(String letter, bool isSelected, bool isDark) {
    if (isSelected) {
      return AppColors.bronze.withOpacity(0.35);
    }

    final allLetters = DiamondFilterState.colors;

    final idx = allLetters.indexOf(letter);

    final fraction = idx / (allLetters.length - 1);

    final Color startColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.white;

    final Color endColor = isDark
        ? const Color(0xFFF59E0B)
        : const Color(0xFFD97706);

    return Color.lerp(startColor, endColor, fraction) ?? startColor;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(diamondSearchProvider);

    final notifier = ref.read(diamondSearchProvider.notifier);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeTabColor = isDark
        ? AppColors.charcoalLight
        : AppColors.warmWhite;

    final borderColor = isDark ? AppColors.slateBorder : AppColors.warmBorder;

    const chunks = [
      ['D', 'E', 'F'],

      ['G', 'H', 'I', 'J'],

      ['K', 'L', 'M'],

      ['N', 'O', 'P', 'Q', 'R'],

      ['S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: [
            Row(
              children: [
                Text(
                  'Color',

                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(width: 6),

                Tooltip(
                  message:
                      "Filter by diamond color grading (D is colorless, Z is yellow/tinted).",

                  triggerMode: TooltipTriggerMode.tap,

                  preferBelow: false,

                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.9),

                    borderRadius: BorderRadius.circular(6),
                  ),

                  textStyle: const TextStyle(color: Colors.white, fontSize: 11),

                  child: const Icon(
                    Icons.info_outline,

                    size: 16,

                    color: AppColors.bronze,
                  ),
                ),
              ],
            ),

            if (!state.isFancyColor)
              TextButton(
                onPressed: () => notifier.selectAllStandardColors(),

                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,

                  minimumSize: const Size(60, 24),

                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),

                child: Text(
                  'Select All',

                  style: AppTypography.caption.copyWith(
                    color: AppColors.bronze,

                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: AppSpacing.s8),

        Container(
          height: 38,

          decoration: BoxDecoration(
            color: isDark ? Colors.black26 : AppColors.sandSurface,

            borderRadius: BorderRadius.circular(AppSpacing.r8),
          ),

          padding: const EdgeInsets.all(2),

          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => notifier.updateColorMode(false),

                  child: Container(
                    alignment: Alignment.center,

                    decoration: BoxDecoration(
                      color: !state.isFancyColor
                          ? activeTabColor
                          : Colors.transparent,

                      borderRadius: BorderRadius.circular(AppSpacing.r8 - 2),

                      boxShadow: !state.isFancyColor
                          ? AppShadows.cardLight
                          : null,
                    ),

                    child: Text(
                      'Standard',

                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.bold,

                        color: !state.isFancyColor
                            ? (isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.charcoal)
                            : AppColors.textMutedDark,
                      ),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: GestureDetector(
                  onTap: () => notifier.updateColorMode(true),

                  child: Container(
                    alignment: Alignment.center,

                    decoration: BoxDecoration(
                      color: state.isFancyColor
                          ? activeTabColor
                          : Colors.transparent,

                      borderRadius: BorderRadius.circular(AppSpacing.r8 - 2),

                      boxShadow: state.isFancyColor
                          ? AppShadows.cardLight
                          : null,
                    ),

                    child: Text(
                      'Fancy',

                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.bold,

                        color: state.isFancyColor
                            ? (isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.charcoal)
                            : AppColors.textMutedDark,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.s16),

        if (!state.isFancyColor) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: chunks.map((chunk) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),

                child: Row(
                  children: chunk.map((colorLetter) {
                    final isSelected = state.selectedStandardColors.contains(
                      colorLetter,
                    );

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),

                        child: GestureDetector(
                          onTap: () =>
                              notifier.toggleStandardColor(colorLetter),

                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),

                            height: 40,

                            alignment: Alignment.center,

                            decoration: BoxDecoration(
                              color: _getStandardColorBg(
                                colorLetter,

                                isSelected,

                                isDark,
                              ),

                              borderRadius: BorderRadius.circular(8),

                              border: Border.all(
                                color: isSelected
                                    ? AppColors.bronze
                                    : borderColor,

                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),

                            child: Text(
                              colorLetter,

                              style: AppTypography.label.copyWith(
                                fontWeight: FontWeight.bold,

                                color: isSelected
                                    ? AppColors.bronze
                                    : (isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimaryLight),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            }).toList(),
          ),
        ] else ...[
          Text(
            'Fancy Colors',

            style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: AppSpacing.s8),

          SizedBox(
            height: 80,

            child: ListView.builder(
              scrollDirection: Axis.horizontal,

              itemCount: DiamondFilterState.fancyColors.length,

              itemBuilder: (context, index) {
                final colorName = DiamondFilterState.fancyColors[index];

                final isSelected = state.selectedFancyColors.contains(
                  colorName,
                );

                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),

                  child: _FancyDiamondButton(
                    colorName: colorName,

                    isSelected: isSelected,

                    onTap: () => notifier.toggleFancyColor(colorName),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: AppSpacing.s20),

          Text(
            'Overtone',

            style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: AppSpacing.s8),

          GridView.builder(
            shrinkWrap: true,

            physics: const NeverScrollableScrollPhysics(),

            itemCount: DiamondFilterState.overtones.length,

            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,

              childAspectRatio: 1.8,

              crossAxisSpacing: 8,

              mainAxisSpacing: 8,
            ),

            itemBuilder: (context, index) {
              final overtone = DiamondFilterState.overtones[index];

              final isSelected = state.selectedOvertones.contains(overtone);

              return GestureDetector(
                onTap: () => notifier.toggleOvertone(overtone),

                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),

                  alignment: Alignment.center,

                  padding: const EdgeInsets.symmetric(horizontal: 2),

                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.bronze.withOpacity(0.12)
                        : Colors.transparent,

                    borderRadius: BorderRadius.circular(8),

                    border: Border.all(
                      color: isSelected ? AppColors.bronze : borderColor,

                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),

                  child: Text(
                    overtone,

                    textAlign: TextAlign.center,

                    style: AppTypography.caption.copyWith(
                      fontSize: 9,

                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,

                      color: isSelected
                          ? AppColors.bronze
                          : (isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textSecondaryLight),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: AppSpacing.s20),

          Text(
            'Intensity',

            style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: AppSpacing.s8),

          SizedBox(
            height: 38,

            child: ListView.builder(
              scrollDirection: Axis.horizontal,

              itemCount: DiamondFilterState.intensities.length,

              itemBuilder: (context, index) {
                final intensity = DiamondFilterState.intensities[index];

                final isSelected = state.selectedIntensities.contains(
                  intensity,
                );

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),

                  child: GestureDetector(
                    onTap: () => notifier.toggleIntensity(intensity),

                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),

                      padding: const EdgeInsets.symmetric(horizontal: 12),

                      alignment: Alignment.center,

                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.charcoal
                            : Colors.transparent,

                        borderRadius: BorderRadius.circular(AppSpacing.r8),

                        border: Border.all(
                          color: isSelected ? AppColors.charcoal : borderColor,
                        ),
                      ),

                      child: Text(
                        intensity,

                        style: AppTypography.caption.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,

                          color: isSelected
                              ? AppColors.warmWhite
                              : (isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _FancyDiamondButton extends StatelessWidget {
  const _FancyDiamondButton({
    required this.colorName,

    required this.isSelected,

    required this.onTap,
  });

  final String colorName;

  final bool isSelected;

  final VoidCallback onTap;

  Color _getFancyHue(String name) {
    return switch (name.toLowerCase()) {
      'yellow' => Colors.yellow.shade600,

      'orange' => Colors.orange.shade600,

      'blue' => Colors.blue.shade600,

      'red' => Colors.red.shade600,

      'pink' => Colors.pink.shade300,

      'green' => Colors.green.shade500,

      'olive' => const Color(0xFF808000),

      'brown' => Colors.brown.shade500,

      'purple' => Colors.purple.shade600,

      'violet' => const Color(0xFF7F00FF),

      'grey' => Colors.grey.shade500,

      'black' => Colors.black87,

      _ => Colors.transparent,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isOther = colorName.toLowerCase() == 'other';

    final hue = _getFancyHue(colorName);

    return GestureDetector(
      onTap: onTap,

      child: Column(
        children: [
          SizedBox(
            width: 44,

            height: 44,

            child: Center(
              child: Transform.rotate(
                angle: 0.785398,

                child: Container(
                  width: 26,

                  height: 26,

                  decoration: BoxDecoration(
                    color: isOther ? null : hue,

                    gradient: isOther
                        ? const LinearGradient(
                            colors: [
                              Colors.red,

                              Colors.yellow,

                              Colors.blue,

                              Colors.green,
                            ],

                            begin: Alignment.topLeft,

                            end: Alignment.bottomRight,
                          )
                        : null,

                    border: Border.all(
                      color: isSelected
                          ? AppColors.bronze
                          : Colors.grey.shade400,

                      width: isSelected ? 2.5 : 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.s8),

          Text(
            colorName,

            style: AppTypography.caption.copyWith(
              fontSize: 10,

              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,

              color: isSelected ? AppColors.bronze : null,
            ),
          ),
        ],
      ),
    );
  }
}
