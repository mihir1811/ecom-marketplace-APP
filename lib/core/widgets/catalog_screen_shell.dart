import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import 'app_scaffold.dart';
import 'app_top_bar.dart';

/// Shared app scaffold and top-level layout for catalog listing screens.
class CatalogScreenShell extends ConsumerWidget {
  const CatalogScreenShell({
    required this.title,
    required this.child,
    this.scaffoldKey,
    this.endDrawer,
    this.backgroundColor,
    this.showThemeToggle = true,
    super.key,
  });

  final String title;
  final Widget child;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final bool showThemeToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      scaffoldKey: scaffoldKey,
      endDrawer: endDrawer,
      endDrawerEnableOpenDragGesture: false,
      backgroundColor: backgroundColor ?? AppColors.bg(context),
      appBar: SimpleAppTopBar(title: title, showThemeToggle: showThemeToggle),
      body: child,
    );
  }
}
