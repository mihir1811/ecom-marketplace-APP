import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_shadows.dart';
import 'package:gemstone/core/widgets/filters/filter_group_card.dart';
import '../../application/diamond_search_provider.dart';
import '../../domain/models/diamond_catalog_type.dart';
import '../../domain/models/diamond_filter_state.dart';

class ColorTabsSelector extends ConsumerStatefulWidget {
  const ColorTabsSelector({super.key});

  @override
  ConsumerState<ColorTabsSelector> createState() => _ColorTabsSelectorState();
}

class _ColorTabsSelectorState extends ConsumerState<ColorTabsSelector> {
  bool _isStandardExpanded = false;
  bool _isOvertonesExpanded = false;

  Color _getStandardColorBg(String letter, bool isSelected) {
    if (isSelected) {
      return AppColors.charcoal;
    }
    final allLetters = DiamondFilterState.colors;
    final idx = allLetters.indexOf(letter);
    final fraction = idx / (allLetters.length - 1);

    const Color startColor = Colors.white;
    const Color endColor = Color(0xFFFEF3C7);

    return Color.lerp(startColor, endColor, fraction) ?? startColor;
  }

  Widget _buildChunkRow({
    required List<String> chunk,
    required dynamic state,
    required dynamic notifier,
    required Color borderColor,
  }) {
    return Row(
      children: chunk.map((colorLetter) {
        final isSelected = state.selectedStandardColors.contains(colorLetter);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: GestureDetector(
              onTap: () => notifier.toggleStandardColor(colorLetter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _getStandardColorBg(colorLetter, isSelected),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.charcoal : borderColor,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Text(
                  colorLetter,
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? AppColors.warmWhite
                        : (AppColors.textPrimaryLight),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diamondSearchProvider);
    final notifier = ref.read(diamondSearchProvider.notifier);
    final isLabCatalog = ref.watch(diamondCatalogTypeProvider).isLabGrown;
    final useMeleeFilters = isLabCatalog
        ? state.labCategory == 'Lab Melee'
        : state.labNatural.usesMeleeFilters;
    final fancyColors = DiamondFilterState.fancyColorsForDisplay(
      isLabCatalog: isLabCatalog,
      useMeleeFilters: useMeleeFilters,
    );
    final activeTabColor = AppColors.warmWhite;
    final borderColor = AppColors.warmBorder;

    const chunks = [
      ['D', 'E', 'F'],
      ['G', 'H', 'I', 'J'],
      ['K', 'L', 'M'],
      ['N', 'O', 'P', 'Q', 'R'],
      ['S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
    ];

    final initialChunks = chunks.take(2).toList();
    final expandableChunks = chunks.skip(2).toList();

    return FilterGroupCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Color',
            style: AppTypography.label.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),

          Container(
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.sandSurface,
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
                              ? (AppColors.charcoal)
                              : AppColors.textMutedLight,
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
                              ? (AppColors.charcoal)
                              : AppColors.textMutedLight,
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
              children: [
                ...initialChunks.map((chunk) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _buildChunkRow(
                      chunk: chunk,
                      state: state,
                      notifier: notifier,
                      borderColor: borderColor,
                    ),
                  );
                }),

                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: _isStandardExpanded
                      ? Column(
                          children: expandableChunks.map((chunk) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: _buildChunkRow(
                                chunk: chunk,
                                state: state,
                                notifier: notifier,
                                borderColor: borderColor,
                              ),
                            );
                          }).toList(),
                        )
                      : const SizedBox(width: double.infinity, height: 0),
                ),

                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isStandardExpanded = !_isStandardExpanded;
                      });
                    },
                    icon: Icon(
                      _isStandardExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.bronze,
                      size: 18,
                    ),
                    label: Text(
                      _isStandardExpanded ? 'Show Less' : 'Show More',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.bronze,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              'Fancy Colors',
              style:
                  AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.s8),

            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: fancyColors.length,
                itemBuilder: (context, index) {
                  final colorName = fancyColors[index];
                  final isSelected =
                      state.selectedFancyColors.contains(colorName);
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: FancyColorDiamondButton(
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
              style:
                  AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.s8),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _isOvertonesExpanded
                    ? DiamondFilterState.overtones.length
                    : 12,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1.8,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  final overtone = DiamondFilterState.overtones[index];
                  final isSelected =
                      state.selectedOvertones.contains(overtone);
                  return GestureDetector(
                    onTap: () => notifier.toggleOvertone(overtone),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.charcoal
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              isSelected ? AppColors.charcoal : borderColor,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Text(
                        overtone,
                        textAlign: TextAlign.center,
                        style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? AppColors.warmWhite
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isOvertonesExpanded = !_isOvertonesExpanded;
                  });
                },
                icon: Icon(
                  _isOvertonesExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.bronze,
                  size: 18,
                ),
                label: Text(
                  _isOvertonesExpanded ? 'Show Less' : 'Show More',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.bronze,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s20),

            Text(
              'Intensity',
              style:
                  AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
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
                            color: isSelected
                                ? AppColors.charcoal
                                : borderColor,
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
                                : (AppColors.textPrimaryLight),
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
      ),
    );
  }
}

/// Diamond-shaped (rotated square) color swatch tile with a label below.
/// Shared by the diamond fancy-color selector and the gemstone color grid.
class FancyColorDiamondButton extends StatelessWidget {
  const FancyColorDiamondButton({
    required this.colorName,
    required this.isSelected,
    required this.onTap,
    super.key,
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
      'white' => Colors.white,
      'teal' => Colors.teal.shade500,
      _ => Colors.transparent,
    };
  }

  @override
  Widget build(BuildContext context) {
    final lower = colorName.toLowerCase();
    final isOther = lower == 'other';
    final isMulti = lower == 'multi';
    // Bi-color stones show a two-tone split swatch.
    final isBi = lower == 'bi';
    final hue = _getFancyHue(colorName);
    final useSpecialSwatch = isOther || isMulti || isBi;

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
                    color: useSpecialSwatch ? null : hue,
                    gradient: isOther || isMulti
                        ? LinearGradient(
                            colors: isMulti
                                ? const [
                                    Color(0xFFEF4444),
                                    Color(0xFFFACC15),
                                    Color(0xFF22C55E),
                                    Color(0xFF2563EB),
                                  ]
                                : [
                                    Colors.grey.shade400,
                                    Colors.grey.shade600,
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : isBi
                            ? const LinearGradient(
                                colors: [
                                  Color(0xFF2563EB),
                                  Color(0xFF2563EB),
                                  Color(0xFFFACC15),
                                  Color(0xFFFACC15),
                                ],
                                stops: [0.0, 0.5, 0.5, 1.0],
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
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.bronze : null,
            ),
          ),
        ],
      ),
    );
  }
}
