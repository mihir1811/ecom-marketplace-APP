import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/app_router.dart';
import '../../application/ai_chat_back_navigation.dart';
import '../../application/ai_chat_providers.dart';
import '../../application/ai_chat_visibility.dart';
import 'gem_ai_chat_panel.dart';

/// App-wide Gem AI layer: the chat panel, opened from search's AI Mode or
/// the home Gem AI card, blooming up from the bottom of the screen.
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

  @override
  Widget build(BuildContext context) {
    // Only paint when the current route allows Gem AI.
    final show = _showOnCurrentRoute;
    final notifier = ref.read(aiChatUiProvider.notifier);

    ref.listen<bool>(
      aiChatUiProvider.select((s) => s.isOpen),
      (previous, next) => _syncOpen(next),
    );

    if (!show || !_visible) {
      return const SizedBox.shrink();
    }

    return SizedBox.expand(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
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
                alignment: Alignment.bottomCenter,
                child: const _GemAiPanelHost(),
              ),
            ),
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
