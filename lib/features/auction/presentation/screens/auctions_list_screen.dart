import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/catalog_empty_state.dart';
import '../../../../core/widgets/view_mode_toggle.dart';
import '../../application/auction_providers.dart';
import '../widgets/auction_card.dart';

/// Live auctions, my activity, or my wins.
class AuctionsListScreen extends ConsumerStatefulWidget {
  const AuctionsListScreen({
    required this.kind,
    required this.title,
    this.outcomes = const [],
    super.key,
  });

  final AuctionFeedKind kind;
  final String title;
  final List<String> outcomes;

  @override
  ConsumerState<AuctionsListScreen> createState() => _AuctionsListScreenState();
}

class _AuctionsListScreenState extends ConsumerState<AuctionsListScreen> {
  String? _productType;
  String _outcome = 'all';
  bool _grid = false;

  AuctionFeedQuery get _query => AuctionFeedQuery(
    kind: widget.kind,
    outcome: _outcome,
    productType: _productType,
  );

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(auctionFeedProvider(_query));
    return AppScaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppTopBar(title: widget.title),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.outcomes.isNotEmpty)
            _Chips(
              labels: widget.outcomes,
              selected: _outcome,
              onSelected: (value) => setState(() => _outcome = value),
            ),
          _Chips(
            labels: const ['all', 'diamond', 'gemstone', 'meleeDiamond', 'jewellery'],
            selected: _productType ?? 'all',
            onSelected: (value) => setState(() {
              _productType = value == 'all' ? null : value;
            }),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s16,
                0,
                AppSpacing.s16,
                AppSpacing.s8,
              ),
              child: ViewModeToggle(
                isGrid: _grid,
                onGrid: () => setState(() => _grid = true),
                onList: () => setState(() => _grid = false),
              ),
            ),
          ),
          Expanded(child: _body(feed)),
        ],
      ),
    );
  }

  Widget _body(AuctionFeedState feed) {
    if (feed.isLoading && feed.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (feed.errorMessage != null && feed.items.isEmpty) {
      return CatalogEmptyState(
        title: 'Auctions unavailable',
        message: feed.errorMessage!,
        icon: Icons.cloud_off_outlined,
        actionLabel: 'Retry',
        onAction: () => ref.read(auctionFeedProvider(_query).notifier).refresh(),
      );
    }
    if (feed.items.isEmpty) {
      return const CatalogEmptyState(
        title: 'No auctions',
        message: 'Nothing matches this filter yet.',
        icon: Icons.gavel_outlined,
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < 400) {
          ref.read(auctionFeedProvider(_query).notifier).loadMore();
        }
        return false;
      },
      child: _grid ? _gridView(feed) : _listView(feed),
    );
  }

  Widget _listView(AuctionFeedState feed) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.s16),
      itemCount: feed.items.length + (feed.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s12),
      itemBuilder: (context, index) {
        if (index >= feed.items.length) return const _MoreLoader();
        return AuctionCard(auction: feed.items[index]);
      },
    );
  }

  Widget _gridView(AuctionFeedState feed) {
    final extra = feed.isLoadingMore ? 1 : 0;
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.s16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.s12,
        crossAxisSpacing: AppSpacing.s12,
        childAspectRatio: 0.62,
      ),
      itemCount: feed.items.length + extra,
      itemBuilder: (context, index) {
        if (index >= feed.items.length) return const _MoreLoader();
        return AuctionCard(auction: feed.items[index], grid: true);
      },
    );
  }
}

class _MoreLoader extends StatelessWidget {
  const _MoreLoader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.s16),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _Chips extends StatelessWidget {
  const _Chips({
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  final List<String> labels;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final label = labels[index];
          return ChoiceChip(
            label: Text(label == 'all' ? 'All' : label),
            selected: selected == label,
            onSelected: (_) => onSelected(label),
          );
        },
      ),
    );
  }
}
