import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/navigator_keys.dart';
import '../../../core/router/route_names.dart';
import '../../diamonds/application/diamond_list_provider.dart';
import '../../diamonds/application/diamond_search_provider.dart';
import '../../diamonds/domain/models/diamond_filter_state.dart';
import '../../gemstones/application/gemstone_list_provider.dart';
import '../../gemstones/application/gemstone_search_provider.dart';
import '../../gemstones/domain/models/gemstone_filter_state.dart';
import '../domain/ai_chat_filter_inference.dart';
import '../domain/models/ai_chat_product.dart';
import 'ai_pending_filters.dart';

/// Applies inferred filters and opens the matching catalog listings screen.
abstract final class AiChatListingNavigation {
  static Future<void> seeMore(
    BuildContext context,
    WidgetRef ref, {
    required String userQuery,
    required List<AiChatProduct> products,
    List<AiChatProductGroup> productGroups = const [],
    VoidCallback? beforeNavigate,
  }) async {
    final inferred = AiChatFilterInference.infer(
      userQuery: userQuery,
      products: products,
      productGroups: productGroups,
    );

    beforeNavigate?.call();
    await Future<void>.delayed(Duration.zero);
    final nav = rootNavigatorKey.currentContext;
    if (nav == null || !nav.mounted) return;

    final targetRoute = switch (inferred.kind) {
      AiChatListingKind.diamondNatural => AppRouteNames.diamondResults,
      AiChatListingKind.diamondLabGrown => AppRouteNames.labGrownDiamondResults,
      AiChatListingKind.gemstone => AppRouteNames.gemstoneResults,
      AiChatListingKind.jewelry => AppRouteNames.jewelryListing,
      AiChatListingKind.other => AppRouteNames.diamonds,
    };

    // Listing was opened from chat — back should return home + reopen chat.
    ref.read(aiResumeChatFromRouteProvider.notifier).state = targetRoute;

    switch (inferred.kind) {
      case AiChatListingKind.diamondNatural:
        ref.read(aiPendingDiamondFiltersProvider.notifier).state = null;
        final filters = inferred.diamondFilters ?? const DiamondFilterState();
        ref.read(diamondSearchProvider.notifier).replaceFilters(filters);
        ref.invalidate(diamondListProvider);
      case AiChatListingKind.diamondLabGrown:
        final filters = inferred.diamondFilters ?? const DiamondFilterState();
        ref.read(aiPendingDiamondFiltersProvider.notifier).state =
            AiPendingDiamondFilters(filters: filters, isLabGrown: true);
      case AiChatListingKind.gemstone:
        ref.read(aiPendingDiamondFiltersProvider.notifier).state = null;
        final filters =
            inferred.gemstoneFilters ?? const GemstoneFilterState();
        ref.read(gemstoneSearchProvider.notifier).replaceFilters(filters);
        ref.invalidate(gemstoneListProvider);
      case AiChatListingKind.jewelry:
        ref.read(aiPendingDiamondFiltersProvider.notifier).state = null;
      case AiChatListingKind.other:
        ref.read(aiPendingDiamondFiltersProvider.notifier).state = null;
    }

    nav.go(targetRoute);
  }
}
