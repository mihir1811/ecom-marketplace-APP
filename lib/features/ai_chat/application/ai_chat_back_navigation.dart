import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import 'ai_chat_providers.dart';
import 'ai_pending_filters.dart';

/// Back handling for catalog screens opened via Gem AI "See more".
abstract final class AiChatBackNavigation {
  /// Returns `true` when the back action was handled (home + reopen chat).
  static bool handleListingBack(BuildContext context, WidgetRef ref) {
    final expectedRoute = ref.read(aiResumeChatFromRouteProvider);
    if (expectedRoute == null) return false;

    final currentPath = GoRouter.of(
      context,
    ).routerDelegate.currentConfiguration.uri.path;
    if (currentPath != expectedRoute) {
      ref.read(aiResumeChatFromRouteProvider.notifier).state = null;
      return false;
    }

    ref.read(aiResumeChatFromRouteProvider.notifier).state = null;
    ref.read(aiChatUiProvider.notifier).open();
    context.go(AppRouteNames.home);
    return true;
  }

  /// Drops a stale resume marker when the user leaves the AI listing route.
  static void clearIfRouteLeft(WidgetRef ref, String currentPath) {
    final expected = ref.read(aiResumeChatFromRouteProvider);
    if (expected != null && expected != currentPath) {
      ref.read(aiResumeChatFromRouteProvider.notifier).state = null;
    }
  }
}
