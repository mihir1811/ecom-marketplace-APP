import 'package:flutter/material.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_shadows.dart';
import 'package:gemstone/core/widgets/filters/filter_group_card.dart';
import 'package:gemstone/core/widgets/filters/filter_section_divider.dart';
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

  /// Selected grades use a dark fill so the letter stays readable.
  Color _standardGradeSelectedFill(BuildContext context) =>
      AppColors.isDark(context) ? AppColors.bronze : AppColors.charcoal;

  /// Same yellow from D to Z. Opacity runs 0 at D through 1 at Z.
  static const Color _standardGradeYellow = Color(0xFFFFEB3B);
  static const Color _standardGradeYellowBorder = Color(0xFFF9A825);

  double _gradeOpacity(String letter) {
    const letters = DiamondFilterState.colors;
    final index = letters.indexOf(letter);
    if (index <= 0 || letters.length < 2) return 0;
    return index / (letters.length - 1);
  }

  Color _getStandardColorBg(
    BuildContext context,
    String letter,
    bool isSelected,
  ) {
    if (isSelected) return _standardGradeSelectedFill(context);
    return _standardGradeYellow.withValues(alpha: _gradeOpacity(letter));
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
                        : Color.lerp(
                            AppColors.border(context),
                            _standardGradeYellowBorder,
                            _gradeOpacity(colorLetter),
                          )!,
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
            const FilterSectionDivider(),

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
            const FilterSectionDivider(),

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

/// Faceted fancy-colour gem tile: a lit round brilliant on a soft glow of
/// its own hue. Selected tiles lift, ring in the hue and show a check.
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

  static const _tile = 58.0;
  static const _gem = 38.0;

  static Color hueFor(String name) {
    return switch (name.toLowerCase()) {
      'yellow' => const Color(0xFFF7C726),
      'orange' => const Color(0xFFF7841F),
      'blue' => const Color(0xFF2F6FEB),
      'red' => const Color(0xFFD8232F),
      'pink' => const Color(0xFFF26BAE),
      'green' => const Color(0xFF1FA559),
      'olive' => const Color(0xFF8C8A1E),
      'brown' => const Color(0xFF9A6236),
      'purple' => const Color(0xFF8E3BE0),
      'violet' => const Color(0xFF6A3FD8),
      'grey' || 'gray' => const Color(0xFF9AA3AE),
      'black' => const Color(0xFF2A2F38),
      'white' => const Color(0xFFE9ECF1),
      'teal' => const Color(0xFF16B3A3),
      _ => const Color(0xFFB08BE0),
    };
  }

  @override
  Widget build(BuildContext context) {
    final lower = colorName.toLowerCase();
    final isRainbow = lower == 'other' || lower == 'multi';
    final isBi = lower == 'bi';
    final hue = isRainbow ? const Color(0xFFB07CE8) : hueFor(colorName);
    final ring = isSelected ? (isRainbow ? AppColors.bronze : hue) : null;

    return Semantics(
      button: true,
      selected: isSelected,
      label: colorName,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptics.selection();
          onTap();
        },
        child: SizedBox(
          width: _tile + 6,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: _tile,
                height: _tile,
                transform: Matrix4.translationValues(0, isSelected ? -2 : 0, 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      hue.withValues(alpha: isSelected ? 0.30 : 0.16),
                      hue.withValues(alpha: 0.0),
                    ],
                  ),
                  border: Border.all(
                    color: ring ?? AppColors.border(context),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: (ring ?? hue).withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ]
                      : const [],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    AnimatedScale(
                      scale: isSelected ? 1.08 : 1,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutBack,
                      child: CustomPaint(
                        size: const Size.square(_gem),
                        painter: FancyColorGemPainter(
                          fillColors: isBi
                              ? const [Color(0xFF2F6FEB), Color(0xFFF7C726)]
                              : [hue],
                          rainbow: isRainbow,
                          splitTone: isBi,
                          sparkle: isSelected ? 1 : 0.7,
                        ),
                      ),
                    ),
                    Positioned(
                      top: -2,
                      right: -2,
                      child: AnimatedScale(
                        scale: isSelected ? 1 : 0,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutBack,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.charcoal,
                            border: Border.all(
                              color: AppColors.card(context),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            size: 11,
                            color: AppColors.warmWhite,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                colorName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.textPrimary(context)
                      : AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
