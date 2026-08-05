import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../application/home_search_provider.dart';
import '../../domain/models/home_search_result.dart';

/// Real-time search hits under the sticky home search bar (infinite scroll).
class HomeSearchResultsList extends ConsumerStatefulWidget {
  const HomeSearchResultsList({super.key});

  @override
  ConsumerState<HomeSearchResultsList> createState() =>
      _HomeSearchResultsListState();
}

class _HomeSearchResultsListState
    extends ConsumerState<HomeSearchResultsList> {
  final _scrollController = ScrollController();

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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 240) {
      ref.read(homeSearchResultsProvider.notifier).loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(homeSearchQueryProvider).trim();
    if (query.length < 2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Text(
            'Type at least 2 characters to search all catalogs.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
      );
    }

    final async = ref.watch(homeSearchResultsProvider);
    final state = async.valueOrNull;

    if (state == null || state.isInitialLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.s32),
          child: CircularProgressIndicator(color: AppColors.bronze),
        ),
      );
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              TextButton(
                onPressed: () =>
                    ref.read(homeSearchResultsProvider.notifier).loadFirstPage(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final results = state.items;
    final meta = ref.watch(homeSearchMetaProvider);

    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Text(
            meta.notice ?? 'No results for “$query”.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
      );
    }

    final showFooter = state.isLoadingMore;
    final itemCount = results.length + (showFooter ? 1 : 0);
    final showNotice = meta.notice != null && meta.notice!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showNotice)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s20,
              AppSpacing.s4,
              AppSpacing.s20,
              AppSpacing.s8,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.warmWhite,
                borderRadius: BorderRadius.circular(AppSpacing.r8),
                border: Border.all(color: AppColors.warmBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s12,
                  vertical: AppSpacing.s8,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      meta.isApproximate
                          ? Icons.auto_awesome_outlined
                          : Icons.spellcheck_rounded,
                      size: 18,
                      color: AppColors.bronze,
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Expanded(
                      child: Text(
                        meta.notice!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.charcoal,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s20,
              AppSpacing.s8,
              AppSpacing.s20,
              AppSpacing.s32,
            ),
            itemCount: itemCount,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s8),
            itemBuilder: (context, index) {
              if (index >= results.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.s16),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.bronze,
                      ),
                    ),
                  ),
                );
              }

              final item = results[index];
              return _HomeSearchResultTile(
                result: item,
                onTap: () => openProductDetail(context, item.detail),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HomeSearchResultTile extends StatelessWidget {
  const _HomeSearchResultTile({
    required this.result,
    required this.onTap,
  });

  final HomeSearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warmWhite,
      borderRadius: BorderRadius.circular(AppSpacing.r12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.r8),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: _Thumb(url: result.imageUrl),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.categoryLabel,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.bronze,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      result.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoal,
                      ),
                    ),
                    if (result.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        result.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Text(
                result.priceLabel,
                style: AppTypography.label.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final trimmed = url?.trim() ?? '';
    if (trimmed.isEmpty) {
      return const ColoredBox(
        color: AppColors.creamBg,
        child: Icon(
          Icons.image_outlined,
          color: AppColors.textMutedLight,
          size: 22,
        ),
      );
    }
    return AppNetworkImage(
      url: trimmed,
      fit: BoxFit.cover,
      memCacheWidth: 128,
      error: const ColoredBox(
        color: AppColors.creamBg,
        child: Icon(
          Icons.broken_image_outlined,
          color: AppColors.textMutedLight,
          size: 22,
        ),
      ),
    );
  }
}
