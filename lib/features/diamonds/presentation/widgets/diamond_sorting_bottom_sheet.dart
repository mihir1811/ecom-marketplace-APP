import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/diamond_list_provider.dart';
import '../../domain/models/sorting_criteria.dart';

/// Production-grade multi-criteria sorting bottom sheet.
/// Allows users to add, remove, reorder, and configure sorting criteria.
class DiamondSortingBottomSheet extends ConsumerStatefulWidget {
  const DiamondSortingBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DiamondSortingBottomSheet(),
    );
  }

  @override
  ConsumerState<DiamondSortingBottomSheet> createState() =>
      _DiamondSortingBottomSheetState();
}

class _DiamondSortingBottomSheetState
    extends ConsumerState<DiamondSortingBottomSheet> {
  late List<SortingCriteria> _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected = List<SortingCriteria>.from(
      ref.read(diamondSortingProvider),
    );
  }

  List<SortingCriteria> get _availableFields {
    final selectedKeys = _tempSelected.map((s) => s.fieldKey).toSet();
    return DiamondSortingFields.all
        .where((f) => !selectedKeys.contains(f.key))
        .map((f) => SortingCriteria(
              fieldKey: f.key,
              displayName: f.displayName,
              priority: 0,
            ))
        .toList();
  }

  void _addField(String fieldKey, String displayName) {
    setState(() {
      _tempSelected.add(SortingCriteria(
        fieldKey: fieldKey,
        displayName: displayName,
        direction: SortDirection.ascending,
        priority: _tempSelected.length + 1,
      ));
      _recalculatePriorities();
    });
  }

  void _removeField(int index) {
    setState(() {
      _tempSelected.removeAt(index);
      _recalculatePriorities();
    });
  }

  void _toggleDirection(int index) {
    setState(() {
      final current = _tempSelected[index];
      _tempSelected[index] = current.copyWith(
        direction: current.direction == SortDirection.ascending
            ? SortDirection.descending
            : SortDirection.ascending,
      );
    });
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _tempSelected.removeAt(oldIndex);
      _tempSelected.insert(newIndex, item);
      _recalculatePriorities();
    });
  }

  void _recalculatePriorities() {
    for (int i = 0; i < _tempSelected.length; i++) {
      _tempSelected[i] = _tempSelected[i].copyWith(priority: i + 1);
    }
  }

  void _apply() {
    ref.read(diamondSortingProvider.notifier).state =
        List<SortingCriteria>.from(_tempSelected);
    ref.read(diamondListProvider.notifier).applyFiltersAndSort();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.slateSurface : AppColors.warmWhite;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final mutedColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor =
        isDark ? AppColors.slateBorder : AppColors.warmBorder;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.r20),
            ),
            boxShadow: isDark ? AppShadows.modalDark : AppShadows.modalLight,
          ),
          child: Column(
            children: [
              _buildHandle(),
              _buildHeader(context, textColor, mutedColor),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSelectedSection(textColor, mutedColor, borderColor),
                      const SizedBox(height: AppSpacing.s20),
                      _buildAvailableSection(textColor, mutedColor, borderColor),
                      const SizedBox(height: AppSpacing.s24),
                    ],
                  ),
                ),
              ),
              _buildApplyButton(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(
          top: AppSpacing.s12,
          bottom: AppSpacing.s4,
        ),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.textMutedLight.withOpacity(0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, Color textColor, Color mutedColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Sorting',
              style: AppTypography.headline.copyWith(
                color: textColor,
                fontSize: 20,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.s8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: mutedColor.withOpacity(0.1),
              ),
              child: Icon(
                Icons.close,
                size: 18,
                color: mutedColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedSection(
      Color textColor, Color mutedColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected Sorting Filters',
          style: AppTypography.label.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          'Drag and drop the 6-dot icon to prioritize your sorting criteria.',
          style: AppTypography.caption.copyWith(color: mutedColor),
        ),
        const SizedBox(height: AppSpacing.s12),
        if (_tempSelected.isEmpty)
          _buildEmptySelected(mutedColor)
        else
          _buildSelectedList(textColor, mutedColor, borderColor),
      ],
    );
  }

  Widget _buildEmptySelected(Color mutedColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s24),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.textMutedLight.withOpacity(0.2),
        ),
        borderRadius: BorderRadius.circular(AppSpacing.r12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.sort,
            size: 32,
            color: mutedColor.withOpacity(0.4),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'No sorting criteria selected',
            style: AppTypography.body.copyWith(color: mutedColor),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            'Add fields from below to start sorting',
            style: AppTypography.caption.copyWith(color: mutedColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedList(
      Color textColor, Color mutedColor, Color borderColor) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _tempSelected.length,
      onReorder: _reorder,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(AppSpacing.r12),
              child: child,
            );
          },
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final criteria = _tempSelected[index];
        return _buildSortingCard(
          key: ValueKey(criteria.fieldKey),
          criteria: criteria,
          index: index,
          textColor: textColor,
          mutedColor: mutedColor,
          borderColor: borderColor,
        );
      },
    );
  }

  Widget _buildSortingCard({
    required Key key,
    required SortingCriteria criteria,
    required int index,
    required Color textColor,
    required Color mutedColor,
    required Color borderColor,
  }) {
    final isAscending = criteria.direction == SortDirection.ascending;

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: AppSpacing.s8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s8,
        ),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.s4),
                child: Icon(
                  Icons.drag_handle,
                  color: mutedColor,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s4),
            GestureDetector(
              onTap: () => _toggleDirection(index),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.s4),
                decoration: BoxDecoration(
                  color: AppColors.bronze.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.r4),
                ),
                child: Icon(
                  isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  color: AppColors.bronze,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    criteria.displayName,
                    style: AppTypography.body.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    isAscending ? 'Ascending' : 'Descending',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.bronze,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '#${criteria.priority}',
              style: AppTypography.caption.copyWith(
                color: mutedColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            GestureDetector(
              onTap: () => _removeField(index),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.s4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.terracotta.withOpacity(0.1),
                ),
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: AppColors.terracotta,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableSection(
      Color textColor, Color mutedColor, Color borderColor) {
    final available = _availableFields;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Sorting Fields',
          style: AppTypography.label.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        if (available.isEmpty)
          _buildEmptyAvailable(mutedColor)
        else
          ...available.map((field) => _buildAvailableRow(
                field: field,
                textColor: textColor,
                mutedColor: mutedColor,
                borderColor: borderColor,
              )),
      ],
    );
  }

  Widget _buildEmptyAvailable(Color mutedColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s20),
      child: Text(
        'All fields are already selected',
        style: AppTypography.body.copyWith(color: mutedColor),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildAvailableRow({
    required SortingCriteria field,
    required Color textColor,
    required Color mutedColor,
    required Color borderColor,
  }) {
    return GestureDetector(
      onTap: () => _addField(field.fieldKey, field.displayName),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.s4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.r8),
          border: Border.all(color: borderColor.withOpacity(0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12,
            vertical: AppSpacing.s12,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  field.displayName,
                  style: AppTypography.body.copyWith(color: textColor),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.s4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.bronze,
                ),
                child: const Icon(
                  Icons.add,
                  size: 16,
                  color: AppColors.warmWhite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApplyButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s12,
        AppSpacing.s16,
        MediaQuery.of(context).padding.bottom + AppSpacing.s12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.textMutedLight.withOpacity(0.15),
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: _apply,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.bronze,
            foregroundColor: AppColors.warmWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.r12),
            ),
            elevation: 0,
          ),
          child: Text(
            'Apply',
            style: AppTypography.label.copyWith(
              color: AppColors.warmWhite,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
