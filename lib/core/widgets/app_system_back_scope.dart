import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_navigation.dart';

/// Intercepts system back when [GoRouter] cannot pop.
///
/// - If [fallbackLocation] is set and the current path differs, navigates there.
/// - Otherwise delegates to [AppNavigation.back] (home / exit confirmation).
class AppSystemBackScope extends StatelessWidget {
  const AppSystemBackScope({
    super.key,
    required this.child,
    this.fallbackLocation,
  });

  final Widget child;

  /// Optional parent route used when the stack is empty (e.g. auth → login).
  final String? fallbackLocation;

  @override
  Widget build(BuildContext context) {
    final canPop = GoRouter.of(context).canPop();

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (!context.mounted) return;
        AppNavigation.back(context, fallbackLocation: fallbackLocation);
      },
      child: child,
    );
  }
}
