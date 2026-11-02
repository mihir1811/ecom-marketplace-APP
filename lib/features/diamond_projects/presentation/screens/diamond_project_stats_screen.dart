import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/result.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/luxe/luxe_button.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_layout.dart';
import '../../../../core/widgets/luxe/luxe_listing.dart';
import '../../application/diamond_project_save_provider.dart';
import '../../application/diamond_project_selection_provider.dart';
import '../widgets/diamond_project_overview.dart';

/// Local analytics dashboard for the current diamond selection.
///
/// A dark hero carries the headline numbers; the sticky tab bar splits the
/// analytics (overview, mix, spread) from the stone list so every chart is
/// one tap away without one long scroll.
class DiamondProjectStatsScreen extends ConsumerStatefulWidget {
  const DiamondProjectStatsScreen({super.key});

  @override
  ConsumerState<DiamondProjectStatsScreen> createState() =>
      _DiamondProjectStatsScreenState();
}

class _DiamondProjectStatsScreenState
    extends ConsumerState<DiamondProjectStatsScreen> {
  final _scroll = ScrollController();
  final _offset = ValueNotifier<double>(0);
  DiamondProjectTab _tab = DiamondProjectTab.overview;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() => _offset.value = _scroll.offset);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _offset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LuxeScope(child: Builder(builder: _buildScaffold));
  }

  Widget _buildScaffold(BuildContext context) {
    final p = LuxePalette.of(context);
    final selection = ref.watch(diamondProjectSelectionProvider);
    final stats = ref.watch(diamondProjectStatsProvider);
    final saving = ref.watch(diamondProjectSaveProvider).isLoading;

    return AppScaffold(
      backgroundColor: p.canvas,
      appBar: LuxeTopBar(
        title: selection.isEmpty
            ? context.tr(CatalogL10n.diamondProject)
            : selection.name,
        scrollOffset: _offset,
        actions: [
          LuxeIconButton(
            icon: Icons.folder_open_outlined,
            tooltip: context.tr(CatalogL10n.savedStatistics),
            size: 40,
            onPressed: () => context.push(AppRouteNames.savedDiamondProjects),
          ),
          const SizedBox(width: 6),
          LuxeIconButton(
            icon: Icons.bookmark_add_outlined,
            tooltip: context.tr(CatalogL10n.saveNow),
            size: 40,
            loading: saving,
            onPressed: saving || selection.isEmpty ? null : _save,
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            tooltip: context.tr(CatalogL10n.projectActions),
            icon: Icon(Icons.more_vert_rounded, color: p.ink),
            onSelected: (value) {
              switch (value) {
                case 'saved':
                  context.push(AppRouteNames.savedDiamondProjects);
                case 'clear':
                  AppHaptics.warning();
                  ref.read(diamondProjectSelectionProvider.notifier).clear();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'saved',
                child: Text(context.tr(CatalogL10n.savedStatistics)),
              ),
              PopupMenuItem(
                value: 'clear',
                enabled: !selection.isEmpty,
                child: Text(
                  context.tr(CatalogL10n.clearSelection),
                  style: TextStyle(color: p.caution),
                ),
              ),
            ],
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: LuxeMotion.medium,
        child: selection.isEmpty
            ? LuxeStateView(
                key: const ValueKey('empty'),
                icon: Icons.analytics_outlined,
                title: context.tr(CatalogL10n.noDiamondsSelected),
                message: context.tr(CatalogL10n.selectPageHelp),
                actionLabel: context.tr(CatalogL10n.backToListings),
                onAction: () => context.goBack(),
                secondaryLabel: context.tr(CatalogL10n.savedStatistics),
                onSecondary: () =>
                    context.push(AppRouteNames.savedDiamondProjects),
              )
            : CustomScrollView(
                key: const ValueKey('content'),
                controller: _scroll,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                    sliver: SliverToBoxAdapter(
                      child: _reveal(
                        DiamondProjectHero(
                          name: selection.name,
                          status: _statusOf(context, selection.projectId),
                          highlighted: selection.projectId?.isNotEmpty ?? false,
                          stats: stats,
                        ),
                        0,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 5),
                    sliver: SliverToBoxAdapter(
                      child: _reveal(DiamondProjectAverages(stats: stats), 1),
                    ),
                  ),
                  LuxePinnedBar(
                    extent: 64,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Center(
                        child: DiamondProjectTabBar(
                          selected: _tab,
                          onChanged: (t) => setState(() => _tab = t),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 5, 12, 40),
                    sliver: SliverToBoxAdapter(
                      child: DiamondProjectTabView(
                        tab: _tab,
                        stats: stats,
                        items: selection.items,
                        onRemove: (id) => ref
                            .read(diamondProjectSelectionProvider.notifier)
                            .removeItem(id),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _reveal(Widget child, int index) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return child
        .animate()
        .fadeIn(delay: (80 * index).ms, duration: 420.ms)
        .moveY(
          begin: 18,
          end: 0,
          delay: (80 * index).ms,
          duration: 700.ms,
          curve: LuxeMotion.settle,
        );
  }

  String _statusOf(BuildContext context, String? id) {
    if (id == null || id.isEmpty) return context.tr(CatalogL10n.projectUnsaved);
    return 'ID ${id.length > 8 ? id.substring(0, 8) : id}…';
  }

  Future<void> _save() async {
    AppHaptics.medium();
    final result = await ref.read(diamondProjectSaveProvider.notifier).save();
    if (!mounted) return;
    switch (result) {
      case Success(:final value):
        showLuxeToast(
          context,
          context.tr(CatalogL10n.savedProject, {'name': value.name}),
          tone: LuxeTone.success,
          actionLabel: context.tr(CatalogL10n.savedStatistics),
          onAction: () => context.push(AppRouteNames.savedDiamondProjects),
        );
      case ResultFailure(:final failure):
        showLuxeToast(context, failure.message, tone: LuxeTone.error);
    }
  }
}
