import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_providers.dart';
import '../router/app_navigation.dart';
import '../router/route_names.dart';
import '../theme/app_colors.dart';
import 'app_bar_actions.dart';
import 'app_drawer_button.dart';
import 'navigation/top_bar/top_bar_actions.dart';

/// Material top app bar for screens that draw their own bar (detail and
/// flow pages).
///
/// Its shortcuts are not chosen here: they come from the current section in
/// [TopBarRegistry], same as [SectionTopBar]. [extraActions] (screen-specific
/// tools) render before them.
class AppTopBar extends ConsumerWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.leading,
    this.showDrawerButton = true,
    this.transparent = false,
    this.extraActions = const [],
    this.onBack,
    this.centerTitle = false,
    this.backgroundColor,
    this.elevation = 0,
    this.scrolledUnderElevation = 0,
  });

  final String title;
  final Widget? titleWidget;
  final Widget? leading;
  final bool showDrawerButton;
  final bool transparent;
  final List<Widget> extraActions;

  /// When set, the back button uses this instead of popping the stack.
  final VoidCallback? onBack;
  final bool centerTitle;
  final Color? backgroundColor;
  final double elevation;
  final double scrolledUnderElevation;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(
      authProvider.select((s) => s.isAuthenticated),
    );

    final location = GoRouterState.of(context).uri.path;
    final showBack =
        leading == null &&
        (GoRouter.of(context).canPop() || location != AppRouteNames.home);

    final actions = <Widget>[
      ...extraActions,
      TopBarActions(location: location, look: TopBarActionLook.plain),
      ...buildAppBarActions(),
    ];

    final effectiveLeading =
        leading ??
        (showBack
            ? BackButton(onPressed: onBack ?? () => context.goBack())
            : (showDrawerButton && isAuthenticated
                  ? const AppDrawerButton()
                  : null));

    final hasBackButton = showBack || leading is BackButton;

    // AppBar packs [actions] into a min-size Row. On narrow widths that row
    // overflows (and can report a ~1px trailing slot). Keep actions flexible
    // and horizontally scrollable so chrome never throws a layout overflow.
    final trailing = <Widget>[
      Flexible(
        child: Align(
          alignment: Alignment.centerRight,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            physics: const ClampingScrollPhysics(),
            child: Row(mainAxisSize: MainAxisSize.min, children: actions),
          ),
        ),
      ),
    ];

    return AppBar(
      backgroundColor: transparent
          ? Colors.transparent
          : (backgroundColor ?? AppColors.bg(context)),
      surfaceTintColor: Colors.transparent,
      elevation: elevation,
      scrolledUnderElevation: scrolledUnderElevation,
      centerTitle: hasBackButton ? false : centerTitle,
      titleSpacing: hasBackButton ? 0 : null,
      // Screen names are unused app-wide; keep bar chrome (back / actions) only.
      title: null,
      leading: effectiveLeading,
      automaticallyImplyLeading: false,
      actions: trailing,
    );
  }
}

/// Simplified [AppTopBar].
class SimpleAppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const SimpleAppTopBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.leading,
    this.showDrawerButton = true,
    this.transparent = false,
    this.centerTitle = false,
    this.backgroundColor,
  });

  final String title;
  final Widget? titleWidget;
  final Widget? leading;
  final bool showDrawerButton;
  final bool transparent;
  final bool centerTitle;
  final Color? backgroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppTopBar(
      title: title,
      titleWidget: titleWidget,
      leading: leading,
      showDrawerButton: showDrawerButton,
      transparent: transparent,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
    );
  }
}
