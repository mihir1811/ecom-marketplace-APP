import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/catalog_empty_state.dart';
import '../../../../core/widgets/catalog_error_state.dart';
import '../../../../core/widgets/catalog_list_loading.dart';
import '../../application/diamond_project_list_provider.dart';
import '../../application/diamond_project_selection_provider.dart';
import '../../domain/models/diamond_project.dart';

/// Paginated list of the seller's saved diamond projects.
class SavedDiamondProjectsScreen extends ConsumerStatefulWidget {
  const SavedDiamondProjectsScreen({super.key});

  @override
  ConsumerState<SavedDiamondProjectsScreen> createState() =>
      _SavedDiamondProjectsScreenState();
}

class _SavedDiamondProjectsScreenState
    extends ConsumerState<SavedDiamondProjectsScreen> {
  final _scrollController = ScrollController();
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
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final state = ref.read(diamondProjectListProvider).valueOrNull;
    if (state == null || !state.hasMore || state.isLoadingMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 240) {
      ref.read(diamondProjectListProvider.notifier).loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(diamondProjectListProvider);

    return AppScaffold(
      backgroundColor: AppColors.bg(context),
      appBar: SimpleAppTopBar(title: context.tr(CatalogL10n.savedProjects)),
      body: async.when(
        loading: () => const CatalogListLoading(isGrid: false),
        error: (error, _) => CatalogErrorState(
          message: error is Failure
              ? error.message
              : context.tr(CatalogL10n.loadProjectsError),
          onRetry: () =>
              ref.read(diamondProjectListProvider.notifier).loadFirstPage(),
        ),
        data: (state) {
          if (state.isInitialLoading) {
            return const CatalogListLoading(isGrid: false);
          }
          if (state.errorMessage != null && state.items.isEmpty) {
            return CatalogErrorState(
              message: state.errorMessage!,
              onRetry: () =>
                  ref.read(diamondProjectListProvider.notifier).loadFirstPage(),
            );
          }
          if (state.items.isEmpty) {
            return CatalogEmptyState(
              icon: Icons.folder_outlined,
              title: context.tr(CatalogL10n.noSavedProjects),
              message: context.tr(CatalogL10n.savedProjectsHelp),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(diamondProjectListProvider.notifier).refresh(),
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.s16),
              itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.s12),
              itemBuilder: (context, index) {
                if (index >= state.items.length) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.s16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final project = state.items[index];
                return _ProjectTile(
                  project: project,
                  opening: _openingId == project.id,
                  onOpen: () => _open(project),
                  onDelete: () => _delete(project),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _open(DiamondProject project) async {
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<void> _delete(DiamondProject project) async {
    final confirmed = await showDialog<bool>(
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
            child: Text(context.tr(CatalogL10n.delete)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(diamondProjectListProvider.notifier).remove(project.id);
    } catch (error) {
      if (!mounted) return;
      final message = error is Failure
          ? error.message
          : context.tr(CatalogL10n.deleteProjectError);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: ListTile(
        onTap: opening ? null : onOpen,
        title: Text(
          project.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.label.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          context.tr(CatalogL10n.projectSummary, {
            'count': project.itemCount,
            'carat': project.totalCarat.toStringAsFixed(2),
            'price': AppCurrency.usd(project.totalPrice, decimals: 0),
          }),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (opening)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                tooltip: context.tr(CatalogL10n.deleteProject),
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
      ),
    );
  }
}
