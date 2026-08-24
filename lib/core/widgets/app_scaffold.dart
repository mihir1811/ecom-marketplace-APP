import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/buyer/presentation/widgets/buyer_drawer.dart';
import '../auth/auth_providers.dart';
import '../auth/verification_pending_banner.dart';
import 'keyboard_aware.dart';

/// App-wide [Scaffold] that keeps the status/nav bars clear of content.
///
/// - When an [appBar] is present, top inset is left to the app bar.
/// - Bottom inset is applied to [body] (or to [bottomNavigationBar] when set)
///   so sticky footers clear the system nav bar.
/// - Nested [SafeArea]s remain safe (padding is consumed for descendants).
/// - When authenticated and no [drawer] is provided, attaches [BuyerDrawer]
///   unless a parent scaffold already has a drawer (avoids nesting).
class AppScaffold extends ConsumerWidget {
  const AppScaffold({
    super.key,
    this.scaffoldKey,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.drawer,
    this.enableAppDrawer = true,
    this.endDrawer,
    this.endDrawerEnableOpenDragGesture = true,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.safeTop,
    this.safeBottom = true,
    this.safeLeft = true,
    this.safeRight = true,
  });

  /// Forwards to the underlying [Scaffold] so drawers can be opened by key.
  final GlobalKey<ScaffoldState>? scaffoldKey;

  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? drawer;

  /// When true (default), attaches [BuyerDrawer] for signed-in users if
  /// [drawer] is null and no ancestor scaffold already exposes a drawer.
  final bool enableAppDrawer;
  final Widget? endDrawer;
  final bool endDrawerEnableOpenDragGesture;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;
  final bool extendBody;
  final bool extendBodyBehindAppBar;

  /// When null, top safe area is applied only if there is no [appBar].
  final bool? safeTop;
  final bool safeBottom;
  final bool safeLeft;
  final bool safeRight;

  bool _parentHasDrawer(BuildContext context) {
    var found = false;
    context.visitAncestorElements((element) {
      if (element is! StatefulElement) return true;
      final state = element.state;
      if (state is ScaffoldState && state.hasDrawer) {
        found = true;
        return false;
      }
      return true;
    });
    return found;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applyTop = safeTop ?? appBar == null;
    // When a bottomNavigationBar is present, only pad that bar — otherwise
    // body bottom padding would leave a gap above the bar.
    final bodySafeBottom = safeBottom && bottomNavigationBar == null;
    final pending =
        ref.watch(authProvider.select((s) => s.isVerificationPending));
    final isAuthenticated =
        ref.watch(authProvider.select((s) => s.isAuthenticated));
    final content = body == null
        ? null
        : pending
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const VerificationPendingBanner(),
                  Expanded(child: body!),
                ],
              )
            : body;

    final resolvedDrawer = drawer ??
        (enableAppDrawer && isAuthenticated && !_parentHasDrawer(context)
            ? const BuyerDrawer()
            : null);

    return Scaffold(
      key: scaffoldKey,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      drawer: resolvedDrawer == null
          ? null
          : AppKeyboardInset(child: resolvedDrawer),
      endDrawer: endDrawer == null ? null : AppKeyboardInset(child: endDrawer!),
      endDrawerEnableOpenDragGesture: endDrawerEnableOpenDragGesture,
      bottomNavigationBar: bottomNavigationBar == null
          ? null
          : SafeArea(
              top: false,
              left: safeLeft,
              right: safeRight,
              bottom: safeBottom,
              child: bottomNavigationBar!,
            ),
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset ?? true,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      body: content == null
          ? null
          : SafeArea(
              top: applyTop,
              bottom: bodySafeBottom,
              left: safeLeft,
              right: safeRight,
              child: content,
            ),
    );
  }
}
