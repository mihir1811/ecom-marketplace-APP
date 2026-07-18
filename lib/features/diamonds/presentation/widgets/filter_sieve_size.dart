import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/diamond_search_provider.dart';
import '../../domain/models/sieve_size.dart';
import 'filter_section_header.dart';

class FilterSieveSize extends ConsumerStatefulWidget {
  const FilterSieveSize({super.key});

  @override
  ConsumerState<FilterSieveSize> createState() => _FilterSieveSizeState();
}

class _FilterSieveSizeState extends ConsumerState<FilterSieveSize> {
  static const double _tableHeight = 280.0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diamondSearchProvider);
    final notifier = ref.read(diamondSearchProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.slateBorder : AppColors.warmBorder;

    const sieves = SieveSize.defaultSieves;
    final selectedSet = state.selectedSieveIndices.toSet();

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FilterSectionHeader(title: 'Sieve Size'),
          const SizedBox(height: AppSpacing.s12),

          // ---- Lot Type Presets ----
          const FilterSectionHeader(title: 'Lot Type Presets'),
          const SizedBox(height: AppSpacing.s8),
          Row(
            children: SieveSize.lotTypePresets.keys.map((label) {
              final isActive = state.activeSievePresets.contains(label);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _CompactPresetChip(
                    label: label,
                    isActive: isActive,
                    onTap: () => notifier.applySievePreset(label),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.s16),

          // ---- Scrollable Sieve Table ----
          Container(
            height: _tableHeight,
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(AppSpacing.r8),
            ),
            child: Column(
              children: [
                _SieveTableHeader(isDark: isDark, borderColor: borderColor),
                Expanded(
                  child: Scrollbar(
                    child: ListView.builder(
                      itemCount: sieves.length,
                      itemExtent: 36.0,
                      itemBuilder: (context, index) {
                        final sieve = sieves[index];
                        final isSelected = selectedSet.contains(sieve.index);
                        return _SieveTableRow(
                          sieve: sieve,
                          isSelected: isSelected,
                          isDark: isDark,
                          borderColor: borderColor,
                          onTap: () => notifier.toggleSieveSize(sieve.index),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s16),

          // ---- Selection Summary ----
          _SelectionSummaryCard(
            count: state.selectedSieveIndices.length,
            isDark: isDark,
            borderColor: borderColor,
            onClear: state.selectedSieveIndices.isEmpty
                ? null
                : () => notifier.clearSieves(),
          ),
        ],
      ),
    );
  }
}

class _CompactPresetChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _CompactPresetChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.charcoal : (isDark ? AppColors.obsidianBg : AppColors.warmWhite),
          borderRadius: BorderRadius.circular(AppSpacing.r8),
          border: Border.all(
            color: isActive ? AppColors.charcoal : (isDark ? AppColors.slateBorder : AppColors.warmBorder),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.visible,
          style: AppTypography.caption.copyWith(
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 11,
            height: 1.2,
            color: isActive ? AppColors.warmWhite : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
          ),
        ),
      ),
    );
  }
}

class _SieveTableHeader extends StatelessWidget {
  final bool isDark;
  final Color borderColor;

  const _SieveTableHeader({
    required this.isDark,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: isDark ? AppColors.slateSurface : AppColors.sandSurface,
        border: Border(
          bottom: BorderSide(color: borderColor),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: _HeaderCell(label: 'Sieve'),
          ),
          Container(width: 1, color: borderColor),
          const Expanded(
            child: _HeaderCell(label: 'MM'),
          ),
          Container(width: 1, color: borderColor),
          const Expanded(
            child: _HeaderCell(label: 'Carat'),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  const _HeaderCell({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _SieveTableRow extends StatelessWidget {
  final SieveSize sieve;
  final bool isSelected;
  final bool isDark;
  final Color borderColor;
  final VoidCallback onTap;

  const _SieveTableRow({
    required this.sieve,
    required this.isSelected,
    required this.isDark,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.charcoal : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: borderColor, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _DataCell(
                text: sieve.sieve,
                isSelected: isSelected,
                isDark: isDark,
              ),
            ),
            Container(width: 1, color: borderColor),
            Expanded(
              child: _DataCell(
                text: '${sieve.mmMin.toStringAsFixed(2)}-${sieve.mmMax.toStringAsFixed(2)}',
                isSelected: isSelected,
                isDark: isDark,
              ),
            ),
            Container(width: 1, color: borderColor),
            Expanded(
              child: _DataCell(
                text: sieve.carat.toStringAsFixed(3),
                isSelected: isSelected,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String text;
  final bool isSelected;
  final bool isDark;

  const _DataCell({
    required this.text,
    required this.isSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
          fontSize: 11,
          color: isSelected
              ? AppColors.warmWhite
              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
        ),
      ),
    );
  }
}

class _SelectionSummaryCard extends StatelessWidget {
  final int count;
  final bool isDark;
  final Color borderColor;
  final VoidCallback? onClear;

  const _SelectionSummaryCard({
    required this.count,
    required this.isDark,
    required this.borderColor,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slateSurface : AppColors.sandSurface,
        borderRadius: BorderRadius.circular(AppSpacing.r8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            count > 0 ? Icons.check_circle : Icons.circle_outlined,
            size: 18,
            color: count > 0 ? AppColors.bronze : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
          ),
          const SizedBox(width: AppSpacing.s8),
          Text(
            count == 0
                ? '0 Selected'
                : '$count Selected',
            style: AppTypography.label.copyWith(
              fontWeight: FontWeight.bold,
              color: count > 0
                  ? AppColors.bronze
                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
          ),
          const Spacer(),
          if (onClear != null)
            GestureDetector(
              onTap: onClear,
              child: Text(
                'Clear',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.terracotta,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
