import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../theme/app_spacing.dart';

typedef CatalogGridItemBuilder =
    Widget Function(BuildContext context, int index);

/// Two-column catalog grid where each card sizes to its content.
///
/// Avoids fixed [childAspectRatio] clipping on phones / large text scale.
class CatalogContentSizedGrid extends StatelessWidget {
  const CatalogContentSizedGrid({
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.isLoadingMore = false,
    this.padding = const EdgeInsets.only(
      left: AppSpacing.s16,
      right: AppSpacing.s16,
      top: AppSpacing.s8,
      bottom: AppSpacing.s24,
    ),
    super.key,
  });

  final int itemCount;
  final CatalogGridItemBuilder itemBuilder;
  final ScrollController? controller;
  final bool isLoadingMore;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final rowCount = (itemCount + 1) ~/ 2;
    final total = rowCount + (isLoadingMore ? 1 : 0);

    return ListView.builder(
      scrollCacheExtent: const ScrollCacheExtent.pixels(600),
      controller: controller,
      addAutomaticKeepAlives: false,
      padding: padding,
      itemCount: total,
      itemBuilder: (context, rowIndex) {
        if (rowIndex >= rowCount) {
          return const _CatalogGridLoadingRow();
        }
        return _CatalogGridRow(
          rowIndex: rowIndex,
          rowCount: rowCount,
          itemCount: itemCount,
          isLoadingMore: isLoadingMore,
          itemBuilder: itemBuilder,
        );
      },
    );
  }
}

/// Sliver variant for [CustomScrollView] catalogs.
class CatalogContentSizedGridSliver extends StatelessWidget {
  const CatalogContentSizedGridSliver({
    required this.itemCount,
    required this.itemBuilder,
    this.isLoadingMore = false,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
    super.key,
  });

  final int itemCount;
  final CatalogGridItemBuilder itemBuilder;
  final bool isLoadingMore;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final rowCount = (itemCount + 1) ~/ 2;
    final total = rowCount + (isLoadingMore ? 1 : 0);

    return SliverPadding(
      padding: padding,
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, rowIndex) {
          if (rowIndex >= rowCount) {
            return const _CatalogGridLoadingRow();
          }
          return _CatalogGridRow(
            rowIndex: rowIndex,
            rowCount: rowCount,
            itemCount: itemCount,
            isLoadingMore: isLoadingMore,
            itemBuilder: itemBuilder,
          );
        }, childCount: total),
      ),
    );
  }
}

class _CatalogGridRow extends StatelessWidget {
  const _CatalogGridRow({
    required this.rowIndex,
    required this.rowCount,
    required this.itemCount,
    required this.isLoadingMore,
    required this.itemBuilder,
  });

  final int rowIndex;
  final int rowCount;
  final int itemCount;
  final bool isLoadingMore;
  final CatalogGridItemBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    final leftIndex = rowIndex * 2;
    final rightIndex = leftIndex + 1;

    return Padding(
      padding: EdgeInsets.only(
        bottom: rowIndex == rowCount - 1 && !isLoadingMore ? 0 : AppSpacing.s12,
      ),
      // Match both cards to the taller sibling so bottoms align.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: RepaintBoundary(child: itemBuilder(context, leftIndex)),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: rightIndex >= itemCount
                  ? const SizedBox.shrink()
                  : RepaintBoundary(child: itemBuilder(context, rightIndex)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogGridLoadingRow extends StatelessWidget {
  const _CatalogGridLoadingRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.s16),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
