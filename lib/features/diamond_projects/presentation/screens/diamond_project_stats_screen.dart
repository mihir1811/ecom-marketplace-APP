import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/result.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/catalog_empty_state.dart';
import '../../application/diamond_project_save_provider.dart';
import '../../application/diamond_project_selection_provider.dart';
import '../widgets/diamond_project_histogram_card.dart';
import '../widgets/diamond_project_kpi_grid.dart';
import '../widgets/diamond_project_mix_card.dart';
import '../widgets/diamond_project_price_stats_card.dart';
import '../widgets/diamond_project_scatter_card.dart';
import '../widgets/diamond_project_selected_table.dart';

/// Local analytics dashboard for the current diamond selection.
class DiamondProjectStatsScreen extends ConsumerStatefulWidget {
  const DiamondProjectStatsScreen({super.key});

  @override
  ConsumerState<DiamondProjectStatsScreen> createState() =>
      _DiamondProjectStatsScreenState();
}

class _DiamondProjectStatsScreenState
    extends ConsumerState<DiamondProjectStatsScreen> {
  bool _showAnalytics = true;

  @override
  Widget build(BuildContext context) {
    final selection = ref.watch(diamondProjectSelectionProvider);
    final stats = ref.watch(diamondProjectStatsProvider);
    final saving = ref.watch(diamondProjectSaveProvider).isLoading;

    final wide = MediaQuery.sizeOf(context).width >= 720;

    return AppScaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppTopBar(
        title: 'Diamond project',
        extraActions: [
          if (wide) ...[
            TextButton(
              onPressed: () =>
                  context.push(AppRouteNames.savedDiamondProjects),
              child: const Text('Saved Statistics'),
            ),
            TextButton(
              onPressed: saving || selection.isEmpty ? null : _save,
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save now'),
            ),
            TextButton(
              onPressed: selection.isEmpty
                  ? null
                  : () =>
                      ref.read(diamondProjectSelectionProvider.notifier).clear(),
              child: const Text('Clear selection'),
            ),
          ] else ...[
            IconButton(
              tooltip: 'Save now',
              onPressed: saving || selection.isEmpty ? null : _save,
              icon: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
            ),
            PopupMenuButton<String>(
              tooltip: 'Project actions',
              onSelected: (value) {
                switch (value) {
                  case 'saved':
                    context.push(AppRouteNames.savedDiamondProjects);
                  case 'clear':
                    ref.read(diamondProjectSelectionProvider.notifier).clear();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'saved',
                  child: Text('Saved statistics'),
                ),
                const PopupMenuItem(
                  value: 'clear',
                  child: Text('Clear selection'),
                ),
              ],
            ),
          ],
        ],
      ),
      body: selection.isEmpty
          ? CatalogEmptyState(
              icon: Icons.analytics_outlined,
              title: 'No diamonds selected',
              message:
                  'Use Select current page on a diamond listing to analyze loaded stones.',
              actionLabel: 'Back to listings',
              onAction: () => context.goBack(),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.s16),
              children: [
                _SummaryCard(
                  name: selection.name,
                  projectId: selection.projectId,
                  stoneCount: selection.items.length,
                  showAnalytics: _showAnalytics,
                  onToggleAnalytics: () {
                    setState(() => _showAnalytics = !_showAnalytics);
                  },
                ),
                const SizedBox(height: AppSpacing.s16),
                DiamondProjectKpiGrid(stats: stats),
                if (_showAnalytics) ...[
                  const SizedBox(height: AppSpacing.s16),
                  DiamondProjectPriceStatsCard(stats: stats),
                  const SizedBox(height: AppSpacing.s16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 720;
                      final mixes = [
                        DiamondProjectMixCard(
                          title: 'Shape mix',
                          entries: stats.shapeMix,
                        ),
                        DiamondProjectMixCard(
                          title: 'Color mix',
                          entries: stats.colorMix,
                        ),
                      ];
                      if (wide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var i = 0; i < mixes.length; i++) ...[
                              if (i > 0) const SizedBox(width: AppSpacing.s12),
                              Expanded(child: mixes[i]),
                            ],
                          ],
                        );
                      }
                      return Column(
                        children: [
                          mixes[0],
                          const SizedBox(height: AppSpacing.s12),
                          mixes[1],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 720;
                      final charts = [
                        DiamondProjectMixCard(
                          title: 'Clarity mix',
                          entries: stats.clarityMix,
                        ),
                        DiamondProjectHistogramCard(
                          title: 'Price distribution',
                          entries: stats.priceBuckets,
                        ),
                        DiamondProjectHistogramCard(
                          title: 'Price per carat distribution',
                          entries: stats.ppcBuckets,
                        ),
                        DiamondProjectHistogramCard(
                          title: 'Carat distribution',
                          entries: stats.caratBuckets,
                        ),
                      ];
                      if (!wide) {
                        return Column(
                          children: [
                            for (var i = 0; i < charts.length; i++) ...[
                              if (i > 0) const SizedBox(height: AppSpacing.s12),
                              charts[i],
                            ],
                          ],
                        );
                      }
                      return Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: charts[0]),
                              const SizedBox(width: AppSpacing.s12),
                              Expanded(child: charts[1]),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.s12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: charts[2]),
                              const SizedBox(width: AppSpacing.s12),
                              Expanded(child: charts[3]),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  DiamondProjectScatterCard(stats: stats),
                ],
                const SizedBox(height: AppSpacing.s16),
                DiamondProjectSelectedTable(
                  items: selection.items,
                  onRemove: (id) {
                    ref
                        .read(diamondProjectSelectionProvider.notifier)
                        .removeItem(id);
                  },
                ),
                const SizedBox(height: AppSpacing.s32),
              ],
            ),
    );
  }

  Future<void> _save() async {
    final result =
        await ref.read(diamondProjectSaveProvider.notifier).save();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case Success(:final value):
        messenger.showSnackBar(
          SnackBar(content: Text('Saved ${value.name}')),
        );
      case ResultFailure(:final failure):
        messenger.showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.name,
    required this.projectId,
    required this.stoneCount,
    required this.showAnalytics,
    required this.onToggleAnalytics,
  });

  final String name;
  final String? projectId;
  final int stoneCount;
  final bool showAnalytics;
  final VoidCallback onToggleAnalytics;

  @override
  Widget build(BuildContext context) {
    final id = projectId;
    final idLabel = id == null || id.isEmpty
        ? 'Unsaved'
        : 'ID ${id.length > 8 ? id.substring(0, 8) : id}…';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        border: Border.all(color: AppColors.warmBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.title.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    '$stoneCount diamonds selected · $idLabel',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onToggleAnalytics,
              child: Text(showAnalytics ? 'Hide analytics →' : 'Show analytics →'),
            ),
          ],
        ),
      ),
    );
  }
}
