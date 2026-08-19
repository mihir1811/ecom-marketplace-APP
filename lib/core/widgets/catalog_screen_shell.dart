import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_scaffold.dart';

/// Shared app scaffold and top-level layout for catalog listing screens.
class CatalogScreenShell extends StatelessWidget {
  const CatalogScreenShell({
    required this.title,
    required this.onBack,
    required this.child,
    this.scaffoldKey,
    this.endDrawer,
    this.backgroundColor,
    this.automaticallyImplyActions = false,
    this.trailingActions = const [],
    super.key,
  });

  final String title;
  final VoidCallback onBack;
  final Widget child;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final bool automaticallyImplyActions;
  final List<Widget> trailingActions;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      scaffoldKey: scaffoldKey,
      endDrawer: endDrawer,
      endDrawerEnableOpenDragGesture: false,
      backgroundColor: backgroundColor ?? AppColors.bg(context),
      appBar: AppBar(
        automaticallyImplyActions: automaticallyImplyActions,
        title: Text(
          title,
          style: AppTypography.headline.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        actions: trailingActions,
      ),
      body: child,
    );
  }
}
