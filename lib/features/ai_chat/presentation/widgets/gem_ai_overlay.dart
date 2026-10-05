import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/router/route_names.dart';
import '../../application/ai_chat_back_navigation.dart';
import '../../application/ai_chat_providers.dart';
import '../../application/ai_chat_visibility.dart';
import 'gem_ai_chat_panel.dart';
import 'gem_ai_fab.dart';

/// App-wide Gem AI layer: edge-docking orb + chat panel that blooms out of
/// the orb's position.
class GemAiOverlay extends ConsumerStatefulWidget {
  const GemAiOverlay({super.key});

  @override
  ConsumerState<GemAiOverlay> createState() => _GemAiOverlayState();
}

class _GemAiOverlayState extends ConsumerState<GemAiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  bool _visible = false;
  // Dock position survives route changes: edge side + vertical fraction.
  bool _dockRight = true;
  double _dockFraction = 1;

  @override
  void initState() {
    super.initState();
    appRouter.routerDelegate.addListener(_onRoute);
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
      reverseDuration: const Duration(milliseconds: 320),
    );
    _fade = CurvedAnimation(
      parent: _anim,
      curve: const Interval(0, 0.6, curve: Curves.easeOut),
      reverseCurve: Curves.easeInCubic,
    );
    _scale = Tween<double>(begin: 0.12, end: 1).animate(
      CurvedAnimation(
        parent: _anim,
        curve: const Cubic(0.16, 1, 0.3, 1),
        reverseCurve: Curves.easeInCubic,
      ),
    );
    _anim.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && mounted) {
        setState(() => _visible = false);
      }
    });
  }

  @override
  void dispose() {
    appRouter.routerDelegate.removeListener(_onRoute);
    _anim.dispose();
    super.dispose();
  }

  void _onRoute() {
    if (!mounted) return;
    final location = _currentPath;
    AiChatBackNavigation.clearIfRouteLeft(ref, location);
    if (!_isAllowedRoute(location)) {
      if (ref.read(aiChatUiProvider).isOpen) {
        ref.read(aiChatUiProvider.notifier).close();
      }
      if (_visible) {
        _anim.value = 0;
        _visible = false;
      }
    }
    setState(() {});
  }

  String get _currentPath {
    // Prefer GoRouter's resolved location — more reliable than delegate uri
    // during nested pushes (cart / compare / product detail).
    String path;
    try {
      path = appRouter.state.uri.path;
    } catch (_) {
      path = appRouter.routerDelegate.currentConfiguration.uri.path;
    }
    if (path.length > 1 && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    return path;
  }

  bool _isAllowedRoute(String path) => AiChatVisibility.isVisibleOn(path);

  bool get _showOnCurrentRoute => _isAllowedRoute(_currentPath);

  void _syncOpen(bool isOpen) {
    if (!_showOnCurrentRoute) return;
    if (isOpen) {
      if (!_visible) {
        setState(() => _visible = true);
      }
      if (_anim.status != AnimationStatus.forward &&
          _anim.status != AnimationStatus.completed) {
        _anim.forward();
      }
    } else if (_visible) {
      if (_anim.status != AnimationStatus.reverse &&
          _anim.status != AnimationStatus.dismissed) {
        _anim.reverse();
      }
    }
  }

  void _onFabPressed({required bool isOpen}) {
    final notifier = ref.read(aiChatUiProvider.notifier);
    if (isOpen) {
      notifier.close();
      return;
    }

    final authenticated = ref.read(authProvider).isAuthenticated;
    if (!authenticated) {
      final nav = rootNavigatorKey.currentContext;
      if (nav != null && nav.mounted) {
        nav.go(AppRouteNames.login);
      }
      return;
    }

    notifier.open();
    _syncOpen(true);
  }

  @override
  Widget build(BuildContext context) {
    // Always keep the host mounted so FAB drag position survives brief route
    // transitions; only paint when the current route allows Gem AI.
    final show = _showOnCurrentRoute;
    final ui = ref.watch(aiChatUiProvider);
    final notifier = ref.read(aiChatUiProvider.notifier);

    ref.listen<bool>(
      aiChatUiProvider.select((s) => s.isOpen),
      (previous, next) => _syncOpen(next),
    );

    if (!show) {
      return const SizedBox.shrink();
    }

    final media = MediaQuery.of(context);
    final geo = GemAiDockGeometry(
      media.size,
      GemAiDockGeometry.insetsOf(media),
    );
    final orb =
        geo.rest(right: _dockRight, fraction: _dockFraction) +
        const Offset(GemAiDockGeometry.size / 2, GemAiDockGeometry.size / 2);
    // The panel scales out of (and back into) the orb.
    final origin = Alignment(
      (orb.dx / media.size.width) * 2 - 1,
      (orb.dy / media.size.height) * 2 - 1,
    );

    return SizedBox.expand(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (_visible) ...[
            Positioned.fill(
              child: FadeTransition(
                opacity: _fade,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: notifier.close,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.38),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  alignment: origin,
                  child: _GemAiPanelHost(alignRight: _dockRight),
                ),
              ),
            ),
          ],
          Positioned.fill(
            child: GemAiDock(
              hidden: ui.isOpen,
              right: _dockRight,
              fraction: _dockFraction,
              semanticLabel: ui.isOpen
                  ? context.tr(RemainingL10n.closeGemAi)
                  : context.tr(RemainingL10n.openGemAi),
              onPressed: () => _onFabPressed(isOpen: ui.isOpen),
              onDocked: (right, fraction) => setState(() {
                _dockRight = right;
                _dockFraction = fraction;
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _GemAiPanelHost extends ConsumerWidget {
  const _GemAiPanelHost({required this.alignRight});

  final bool alignRight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Nested navigator supplies the Overlay EditableText needs. The chat panel
    // sits outside MaterialApp.router's navigator Overlay.
    return Navigator(
      onGenerateRoute: (_) {
        return PageRouteBuilder<void>(
          opaque: false,
          barrierDismissible: false,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) {
            return PopScope(
              canPop: false,
              child: GemAiChatPanel(
                alignRight: alignRight,
                onClose: () => ref.read(aiChatUiProvider.notifier).close(),
              ),
            );
          },
        );
      },
    );
  }
}
