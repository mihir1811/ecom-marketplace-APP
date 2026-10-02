import 'package:flutter/material.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';

import '../router/app_navigation.dart';
import '../router/route_names.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_top_bar.dart';
import 'global_search_bar.dart';
import 'melee_background_shell.dart';
import 'search_action_bottom_bar.dart';
import '../l10n/app_localizations.dart';

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
    this.clearLabel,
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
  final String? clearLabel;
  final bool Function(ScrollNotification notification)? onScrollNotification;

  void _leaveToHome(BuildContext context) {
    context.resetTo(AppRouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _leaveToHome(context);
      },
      child: MeleeBackgroundShell(
        isMelee: isMelee,
        family: meleeFamily,
        child: AppScaffold(
          backgroundColor: Colors.transparent,
          appBar: AppTopBar(
            title: title,
            transparent: true,
            onBack: () => _leaveToHome(context),
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
                              onNotification:
                                  onScrollNotification ?? (_) => false,
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
                          clearLabel:
                              clearLabel ?? context.tr(RemainingL10n.clearAll),
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
      ),
    );
  }
}
