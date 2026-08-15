import 'package:flutter/material.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';
import 'package:go_router/go_router.dart';

import '../router/route_names.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'global_search_bar.dart';
import 'melee_background_shell.dart';
import 'search_action_bottom_bar.dart';

/// Shared chrome for diamond/gemstone finder screens:
/// melee background, transparent app bar, global search, sticky nav,
/// scrollable body, and sticky bottom actions.
class CatalogSearchFilterShell extends StatelessWidget {
  const CatalogSearchFilterShell({
    required this.title,
    required this.isMelee,
    required this.meleeFamily,
    required this.stickyNav,
    required this.scrollController,
    required this.bodyChildren,
    required this.primaryLabel,
    required this.onPrimary,
    required this.onClear,
    this.clearLabel = 'CLEAR ALL',
    this.onBack,
    this.onScrollNotification,
    super.key,
  });

  final String title;
  final bool isMelee;
  final MeleeBgFamily meleeFamily;
  final Widget stickyNav;
  final ScrollController scrollController;
  final List<Widget> bodyChildren;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onClear;
  final String clearLabel;
  final VoidCallback? onBack;
  final bool Function(ScrollNotification notification)? onScrollNotification;

  @override
  Widget build(BuildContext context) {
    return MeleeBackgroundShell(
      isMelee: isMelee,
      family: meleeFamily,
      child: AppScaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack ??
                () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRouteNames.home);
                  }
                },
          ),
          title: Text(
            title,
            style: AppTypography.title.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            const GlobalSearchBar(),
            Expanded(
              child: SafeArea(
                top: false,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        stickyNav,
                        Expanded(
                          child: NotificationListener<ScrollNotification>(
                            onNotification: onScrollNotification ?? (_) => false,
                            child: SingleChildScrollView(
                              controller: scrollController,
                              padding: const EdgeInsets.only(
                                left: AppSpacing.s16,
                                right: AppSpacing.s16,
                                bottom: 120,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: bodyChildren,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: SearchActionBottomBar(
                        primaryLabel: primaryLabel,
                        onPrimary: onPrimary,
                        clearLabel: clearLabel,
                        onClear: onClear,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
