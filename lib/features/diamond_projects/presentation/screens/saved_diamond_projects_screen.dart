import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_layout.dart';
import '../../application/diamond_project_list_provider.dart';
import '../../application/diamond_project_selection_provider.dart';
import '../../domain/models/diamond_project.dart';

/// Paginated archive of the seller's saved diamond projects.
class SavedDiamondProjectsScreen extends ConsumerStatefulWidget {
  const SavedDiamondProjectsScreen({super.key});

  @override
  ConsumerState<SavedDiamondProjectsScreen> createState() =>
      _SavedDiamondProjectsScreenState();
}

class _SavedDiamondProjectsScreenState
    extends ConsumerState<SavedDiamondProjectsScreen> {
  final _scrollController = ScrollController();
  final _offset = ValueNotifier<double>(0);
  String? _openingId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _offset.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    _offset.value = _scrollController.offset;
    final state = ref.read(diamondProjectListProvider).valueOrNull;
    if (state == null || !state.hasMore || state.isLoadingMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 240) {
      ref.read(diamondProjectListProvider.notifier).loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LuxeScope(child: Builder(builder: _buildScaffold));
  }

  Widget _buildScaffold(BuildContext context) {
    final p = LuxePalette.of(context);
    final async = ref.watch(diamondProjectListProvider);
    void retry() =>
        ref.read(diamondProjectListProvider.notifier).loadFirstPage();

    Widget errorView(String message) => LuxeStateView(
      icon: Icons.cloud_off_rounded,
      tone: LuxeTone.error,
      title: context.tr(CatalogL10n.loadProjectsError),
      message: message,
      actionLabel: context.tr(CoreL10n.retry),
      onAction: retry,
    );

    return AppScaffold(
      backgroundColor: p.canvas,
      appBar: LuxeTopBar(
        title: context.tr(CatalogL10n.savedProjects),
        scrollOffset: _offset,
      ),
      body: async.when(
        loading: () => const _ArchiveSkeleton(),
        error: (error, _) => errorView(
          error is Failure
              ? error.message
              : context.tr(CatalogL10n.loadProjectsError),
        ),
        data: (state) {
          if (state.isInitialLoading) return const _ArchiveSkeleton();
          if (state.errorMessage != null && state.items.isEmpty) {
            return errorView(state.errorMessage!);
          }
          if (state.items.isEmpty) {
            return LuxeStateView(
              icon: Icons.folder_open_outlined,
              title: context.tr(CatalogL10n.noSavedProjects),
              message: context.tr(CatalogL10n.savedProjectsHelp),
            );
          }
          final still = MediaQuery.disableAnimationsOf(context);
          return RefreshIndicator(
            color: p.accent,
            onRefresh: () =>
                ref.read(diamondProjectListProvider.notifier).refresh(),
            child: ListView.separated(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 20),
              itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index >= state.items.length) {
                  return const LuxeSkeleton(height: 128, radius: 22);
                }
                final project = state.items[index];
                Widget tile = _ProjectTile(
                  key: ValueKey(project.id),
                  project: project,
                  opening: _openingId == project.id,
                  onOpen: () => _open(project),
                  onDelete: () => _delete(project),
                );
                if (!still && index < 8) {
                  tile = tile
                      .animate()
                      .fadeIn(delay: (50 * index).ms, duration: 360.ms)
                      .moveY(
                        begin: 14,
                        end: 0,
                        delay: (50 * index).ms,
                        duration: 600.ms,
                        curve: LuxeMotion.settle,
                      );
                }
                return tile;
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _open(DiamondProject project) async {
    AppHaptics.selection();
    setState(() => _openingId = project.id);
    final result = await ref
        .read(diamondProjectListProvider.notifier)
        .fetchOne(project.id);
    if (!mounted) return;
    setState(() => _openingId = null);
    switch (result) {
      case Success(value: final loaded):
        ref.read(diamondProjectSelectionProvider.notifier).hydrate(loaded);
        context.push(AppRouteNames.diamondProject);
      case ResultFailure(failure: final failure):
        showLuxeToast(context, failure.message, tone: LuxeTone.error);
    }
  }

  Future<void> _delete(DiamondProject project) async {
    AppHaptics.warning();
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr(CatalogL10n.deleteProject)),
        content: Text(
          context.tr(CatalogL10n.deleteProjectConfirm, {'name': project.name}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr(CatalogL10n.cancel)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: LuxePalette.of(context).caution,
            ),
            child: Text(context.tr(CatalogL10n.delete)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(diamondProjectListProvider.notifier).remove(project.id);
      AppHaptics.medium();
    } catch (error) {
      if (!mounted) return;
      final message = error is Failure
          ? error.message
          : context.tr(CatalogL10n.deleteProjectError);
      showLuxeToast(context, message, tone: LuxeTone.error);
    }
  }
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({
    super.key,
    required this.project,
    required this.opening,
    required this.onOpen,
    required this.onDelete,
  });

  final DiamondProject project;
  final bool opening;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final updated = project.updatedAt ?? project.createdAt;
    String? when;
    if (updated != null) {
      final d = updated.toLocal();
      when = context.tr(ExperienceL10n.projectUpdated, {
        'date':
            '${d.day.toString().padLeft(2, '0')}/'
            '${d.month.toString().padLeft(2, '0')}/${d.year}',
      });
    }

    Widget stat(String value, String label) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: LuxeType.figure(
                p.ink,
                size: 15,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LuxeType.label(p.inkMuted, size: 11),
          ),
        ],
      ),
    );

    return Material(
      color: p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LuxeSpace.radius),
        side: BorderSide(color: p.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: opening ? null : onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.accentSoft,
                    ),
                    child: Icon(
                      Icons.analytics_outlined,
                      size: 19,
                      color: p.accent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LuxeType.display(21, p.ink),
                        ),
                        if (when != null)
                          Text(
                            when,
                            style: LuxeType.label(p.inkFaint, size: 11.5),
                          ),
                      ],
                    ),
                  ),
                  if (opening)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: p.accent,
                        ),
                      ),
                    )
                  else
                    IconButton(
                      tooltip: context.tr(CatalogL10n.deleteProject),
                      onPressed: onDelete,
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: p.inkMuted,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  children: [
                    stat(
                      '${project.itemCount}',
                      context.tr(CatalogL10n.projectStonesKpi),
                    ),
                    stat(
                      '${project.totalCarat.toStringAsFixed(2)} ct',
                      context.tr(CatalogL10n.projectTotalCaratKpi),
                    ),
                    stat(
                      AppCurrency.usd(project.totalPrice, decimals: 0),
                      context.tr(CatalogL10n.projectTotalPriceKpi),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: p.accent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder cards while the archive loads.
class _ArchiveSkeleton extends StatelessWidget {
  const _ArchiveSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      children: [
        for (var i = 0; i < 4; i++)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: LuxeSkeleton(height: 128, radius: 22),
          ),
      ],
    );
  }
}
