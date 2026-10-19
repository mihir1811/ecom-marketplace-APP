import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/pagination/paginated_async_notifier.dart';
import '../../domain/agent_effect.dart';
import '../../domain/agent_tool.dart';
import '../../domain/tool_result.dart';
import 'catalog_args.dart';

/// Parsed request for one catalog: the finder filters plus a readable echo.
class CatalogQuery<F> {
  const CatalogQuery({
    required this.filters,
    required this.description,
    required this.applied,
  });

  final F filters;

  /// Short line for the user, e.g. "Rolex · Diver · under $20k".
  final String description;

  /// Machine-readable echo kept in the model's memory.
  final Map<String, Object?> applied;
}

/// Shared search → hand-off → navigate flow for catalog tools.
///
/// A subclass declares its schema and vocabulary, validates required slots,
/// builds filters, fetches page 1 with the screen's own repository, and
/// says how to present the results. The first page is handed to the list
/// screen so it renders without refetching.
abstract class CatalogSearchTool<F, T> extends AgentTool {
  const CatalogSearchTool();

  /// Plural noun for summaries ("watches").
  String get itemNoun;

  /// Required-slot check. Return a question to hold the search.
  ToolNeedsInput? checkRequired(
    Map<String, Object?> args,
    AgentToolContext context,
  ) => null;

  CatalogQuery<F> buildQuery(CatalogArgs args);

  Future<Result<PaginatedPage<T>, Failure>> fetchFirstPage(
    Ref ref,
    F filters,
    CancelToken cancelToken,
  );

  /// Effect that hands [page] to the list screen and opens it.
  AgentEffect present(F filters, PaginatedPage<T> page);

  @override
  String progressLabel(Map<String, Object?> args) => 'Searching $itemNoun…';

  @override
  Future<ToolResult> execute(
    Map<String, Object?> args,
    AgentToolContext context,
  ) async {
    final hold = checkRequired(args, context);
    if (hold != null) return hold;

    final reader = CatalogArgs(args);
    final query = buildQuery(reader);
    final result = await fetchFirstPage(
      context.ref,
      query.filters,
      context.cancelToken,
    );
    switch (result) {
      case ResultFailure(failure: final failure):
        return ToolFailure(
          failure is NetworkFailure && failure.isCancelled
              ? 'Cancelled.'
              : failure.message,
        );
      case Success(value: final page):
        final total = page.totalCount > 0 ? page.totalCount : page.items.length;
        final label = query.description.isEmpty
            ? 'all $itemNoun'
            : query.description;
        return ToolSuccess(
          summary: total == 0
              ? 'No exact matches for $label. Opened results so you can adjust.'
              : 'Found $total $itemNoun · $label',
          data: {
            'total': total,
            'applied_filters': query.applied,
            if (reader.ignored.isNotEmpty) 'ignored_values': reader.ignored,
          },
          effects: [present(query.filters, page)],
          completesTurn: true,
        );
    }
  }
}

/// Publishes a prefetched page via [publish], then opens [route].
class PresentResultsEffect extends AgentEffect {
  const PresentResultsEffect({required this.publish, required this.route});

  final void Function(Ref ref) publish;
  final String route;

  @override
  Future<void> apply(Ref ref) async {
    publish(ref);
    await NavigateEffect(route).apply(ref);
  }
}

/// Wraps a feature list response as a [PaginatedPage].
PaginatedPage<T> pageOf<T>(List<T> items, int total, bool hasMore) =>
    PaginatedPage<T>(items: items, hasMore: hasMore, totalCount: total);
