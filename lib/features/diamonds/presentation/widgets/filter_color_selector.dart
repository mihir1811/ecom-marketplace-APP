import 'package:flutter/material.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_shadows.dart';
import 'package:gemstone/core/widgets/filters/filter_group_card.dart';
import '../../application/diamond_search_provider.dart';
import '../../domain/models/diamond_catalog_type.dart';
import '../../domain/models/diamond_filter_state.dart';
import 'fancy_color_gem_painter.dart';

class ColorTabsSelector extends ConsumerStatefulWidget {
  const ColorTabsSelector({super.key});

  @override
  ConsumerState<ColorTabsSelector> createState() => _ColorTabsSelectorState();
}

class _ColorTabsSelectorState extends ConsumerState<ColorTabsSelector> {
  bool _isStandardExpanded = false;
  bool _isOvertonesExpanded = false;

  /// Pale D–Z swatches already read as white, so the inverted white
  /// selected fill is invisible in dark mode. Bronze stays readable.
  Color _standardGradeSelectedFill(BuildContext context) =>
      AppColors.isDark(context) ? AppColors.bronze : AppColors.charcoal;

  Color _getStandardColorBg(
    BuildContext context,
    String letter,
    bool isSelected,
  ) {
    if (isSelected) {
      return _standardGradeSelectedFill(context);
    }
    const allLetters = DiamondFilterState.colors;
    final idx = allLetters.indexOf(letter);
    final fraction = idx / (allLetters.length - 1);

    const Color startColor = Color(0xFFE4E2DC);
    const Color endColor = Color(0xFFF0D24A);

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
              onTap: () {
                AppHaptics.selection();
                notifier.toggleStandardColor(colorLetter);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _getStandardColorBg(context, colorLetter, isSelected),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? _standardGradeSelectedFill(context)
                        : const Color(0xFFC8C3B8),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Text(
                  colorLetter,
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? AppColors.warmWhite
                        : AppColors.textPrimaryLight,
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
    final borderColor = AppColors.border(context);

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
            context.tr(CatalogL10n.color),
            style: AppTypography.label.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.s8),

          Container(
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(AppSpacing.r8),
            ),
            padding: const EdgeInsets.all(2),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (state.isFancyColor) AppHaptics.selection();
                      notifier.updateColorMode(false);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: !state.isFancyColor
                            ? AppColors.selectedFill(context)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppSpacing.r8 - 2),
                        boxShadow: !state.isFancyColor
                            ? AppShadows.cardLight
                            : null,
                      ),
                      child: Text(
                        context.tr(CatalogL10n.standard),
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: !state.isFancyColor
                              ? AppColors.onSelected(context)
                              : AppColors.textSecondary(context),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (!state.isFancyColor) AppHaptics.selection();
                      notifier.updateColorMode(true);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: state.isFancyColor
                            ? AppColors.selectedFill(context)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppSpacing.r8 - 2),
                        boxShadow: state.isFancyColor
                            ? AppShadows.cardLight
                            : null,
                      ),
                      child: Text(
                        context.tr(CatalogL10n.fancy),
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: state.isFancyColor
                              ? AppColors.onSelected(context)
                              : AppColors.textSecondary(context),
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
              context.tr(CatalogL10n.fancyColors),
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),

            SizedBox(
              height: 96,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: fancyColors.length,
                itemBuilder: (context, index) {
                  final colorName = fancyColors[index];
                  final isSelected = state.selectedFancyColors.contains(
                    colorName,
                  );
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
              context.tr(CatalogL10n.overtone),
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
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
                  final isSelected = state.selectedOvertones.contains(overtone);
                  return GestureDetector(
                    onTap: () {
                      AppHaptics.selection();
                      notifier.toggleOvertone(overtone);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.selectedFill(context)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.selectedFill(context)
                              : borderColor,
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
                              ? AppColors.onSelected(context)
                              : AppColors.textSecondary(context),
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
              context.tr(CatalogL10n.intensity),
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
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
                      onTap: () {
                        AppHaptics.selection();
                        notifier.toggleIntensity(intensity);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.selectedFill(context)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppSpacing.r8),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.selectedFill(context)
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
                                ? AppColors.onSelected(context)
                                : (AppColors.textPrimary(context)),
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

/// Cut-shaped fancy-color swatch with a faded reflection and label.
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

  static const _gemSize = 36.0;

  Color _getFancyHue(String name) {
    return switch (name.toLowerCase()) {
      'yellow' => const Color(0xFFF5C518),
      'orange' => const Color(0xFFF97316),
      'blue' => const Color(0xFF2563EB),
      'red' => const Color(0xFFDC2626),
      'pink' => const Color(0xFFF472B6),
      'green' => const Color(0xFF16A34A),
      'olive' => const Color(0xFF808000),
      'brown' => const Color(0xFF8B5E3C),
      'purple' => const Color(0xFF9333EA),
      'violet' => const Color(0xFF6D28D9),
      'grey' || 'gray' => const Color(0xFF9CA3AF),
      'black' => const Color(0xFF1F2937),
      'white' => const Color(0xFFF3F4F6),
      'teal' => const Color(0xFF14B8A6),
      _ => const Color(0xFF9CA3AF),
    };
  }

  FancyGemCut _cutFor(String name) {
    return switch (name.toLowerCase()) {
      'yellow' ||
      'red' ||
      'grey' ||
      'gray' ||
      'other' ||
      'multi' => FancyGemCut.emerald,
      'orange' || 'blue' || 'brown' || 'teal' || 'bi' => FancyGemCut.oval,
      'pink' || 'violet' => FancyGemCut.heart,
      'green' || 'black' || 'white' => FancyGemCut.princess,
      'olive' || 'purple' => FancyGemCut.cushion,
      _ => FancyGemCut.emerald,
    };
  }

  @override
  Widget build(BuildContext context) {
    final lower = colorName.toLowerCase();
    final isRainbow = lower == 'other' || lower == 'multi';
    final isBi = lower == 'bi';
    final hue = _getFancyHue(colorName);
    final fillColors = isBi
        ? const [Color(0xFF2563EB), Color(0xFFFACC15)]
        : [hue];
    final painter = FancyColorGemPainter(
      cut: _cutFor(colorName),
      fillColors: fillColors,
      isSelected: isSelected,
      rainbow: isRainbow,
      splitTone: isBi,
    );

    return Semantics(
      button: true,
      selected: isSelected,
      label: colorName,
      child: GestureDetector(
        onTap: () {
          AppHaptics.selection();
          onTap();
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 52,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  CustomPaint(
                    size: const Size(_gemSize, _gemSize),
                    painter: painter,
                  ),
                  Positioned(
                    top: 30,
                    child: IgnorePointer(
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.topCenter,
                          heightFactor: 0.42,
                          child: Opacity(
                            opacity: 0.28,
                            child: ShaderMask(
                              blendMode: BlendMode.dstIn,
                              shaderCallback: (bounds) => const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.white, Colors.transparent],
                              ).createShader(bounds),
                              child: Transform.flip(
                                flipY: true,
                                child: CustomPaint(
                                  size: const Size(_gemSize, _gemSize),
                                  painter: painter,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              colorName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.bronze : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
