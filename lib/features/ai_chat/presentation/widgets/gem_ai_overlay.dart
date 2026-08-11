import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/router/route_names.dart';
import '../../application/ai_chat_back_navigation.dart';
import '../../application/ai_chat_providers.dart';
import '../../application/ai_chat_visibility.dart';
import 'gem_ai_chat_panel.dart';
import 'gem_ai_fab.dart';

/// App-wide Gem AI layer: fixed FAB + animated slide-up chat panel.
class GemAiOverlay extends ConsumerStatefulWidget {
  const GemAiOverlay({super.key});

  @override
  ConsumerState<GemAiOverlay> createState() => _GemAiOverlayState();
}

class _GemAiOverlayState extends ConsumerState<GemAiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;
  bool _visible = false;
  Offset? _fabOffset;

  @override
  void initState() {
    super.initState();
    appRouter.routerDelegate.addListener(_onRoute);
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
      reverseDuration: const Duration(milliseconds: 380),
    );
    _fade = CurvedAnimation(
      parent: _anim,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0.06, 0.14),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _anim,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );
    _scale = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(
        parent: _anim,
        curve: Curves.easeOutCubic,
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
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.32),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: ScaleTransition(
                    scale: _scale,
                    alignment: Alignment.bottomRight,
                    child: const _GemAiPanelHost(),
                  ),
                ),
              ),
            ),
          ],
          GemAiDraggableFabHost(
            isOpen: ui.isOpen,
            offset: _fabOffset,
            onOffsetChanged: (next) => setState(() => _fabOffset = next),
            onDragDelta: (delta) {
              final media = MediaQuery.of(context);
              final current = _fabOffset ??
                  GemAiDraggableFabHost.defaultOffset(
                    media.size,
                    media.padding,
                  );
              setState(() {
                _fabOffset = GemAiDraggableFabHost.clampToScreen(
                  current + delta,
                  media.size,
                  media.padding,
                );
              });
            },
            onPressed: () => _onFabPressed(isOpen: ui.isOpen),
          ),
        ],
      ),
    );
  }
}

class _GemAiPanelHost extends ConsumerWidget {
  const _GemAiPanelHost();

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
                onClose: () => ref.read(aiChatUiProvider.notifier).close(),
              ),
            );
          },
        );
      },
    );
  }
}
