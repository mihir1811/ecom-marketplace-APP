import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../ai_chat/application/ai_chat_providers.dart';
import '../../application/home_search_provider.dart';
import '../../application/recent_searches_provider.dart';
import '../theme/home_tokens.dart';
import 'home_search_ai_mode.dart';
import 'home_search_browse.dart';
import 'home_search_results_list.dart';

/// Opens the spotlight search over the home screen. Picking a collection
/// closes the overlay and navigates from the home [context].
///
/// Search has two modes: catalogue search and **AI Mode**, which hands the
/// query to Gem AI. [aiMode] opens straight into AI Mode.
Future<void> showHomeSearch(BuildContext context, {bool aiMode = false}) async {
  final route = await Navigator.of(context, rootNavigator: true).push(
    _HomeSearchRoute(aiMode: aiMode, label: context.tr(HomeL10n.closeSearch)),
  );
  if (route != null && context.mounted) context.openRoute(route);
}

/// The panel drops in from the top and its parts follow in a short cascade,
/// all keyed off this route's animation; closing rewinds it, a little faster.
class _HomeSearchRoute extends PopupRoute<String> {
  _HomeSearchRoute({required this.aiMode, required this.label});

  final bool aiMode;
  final String label;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => label;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 620);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 320);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => _HomeSearchOverlay(aiMode: aiMode, animation: animation);
}

class _HomeSearchOverlay extends ConsumerStatefulWidget {
  const _HomeSearchOverlay({required this.aiMode, required this.animation});

  final bool aiMode;
  final Animation<double> animation;

  @override
  ConsumerState<_HomeSearchOverlay> createState() => _HomeSearchOverlayState();
}

class _HomeSearchOverlayState extends ConsumerState<_HomeSearchOverlay> {
  static const _debounce = Duration(milliseconds: 280);
  final _controller = TextEditingController();
  Timer? _timer;
  late bool _aiMode = widget.aiMode;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {});
    // AI Mode leaves catalogue results alone until it is submitted.
    if (_aiMode) return;
    _timer?.cancel();
    _timer = Timer(_debounce, () {
      if (mounted) ref.read(homeSearchQueryProvider.notifier).state = value;
    });
  }

  void _onSubmitted(String value) {
    if (_aiMode) {
      _askAi(value);
      return;
    }
    _timer?.cancel();
    ref.read(homeSearchQueryProvider.notifier).state = value;
    ref.read(recentSearchesProvider.notifier).add(value);
  }

  void _clear() {
    _timer?.cancel();
    _controller.clear();
    ref.read(homeSearchQueryProvider.notifier).state = '';
    setState(() {});
  }

  /// Fills the field with [text] and searches straight away.
  void _searchFor(String text) {
    AppHaptics.selection();
    _timer?.cancel();
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    ref.read(homeSearchQueryProvider.notifier).state = text;
    ref.read(recentSearchesProvider.notifier).add(text);
    setState(() {});
  }

  void _setAiMode(bool value) {
    if (value == _aiMode) return;
    AppHaptics.selection();
    setState(() => _aiMode = value);
    if (!value) {
      // Back to catalogue search: show results for what was typed.
      _timer?.cancel();
      ref.read(homeSearchQueryProvider.notifier).state = _controller.text;
    }
  }

  /// Hands [raw] to Gem AI: its panel opens over the screen as search closes.
  void _askAi(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return;
    final navigator = Navigator.of(context);
    if (!ref.read(authProvider).isAuthenticated) {
      navigator.pop(AppRouteNames.login);
      return;
    }
    AppHaptics.light();
    ref.read(aiChatUiProvider.notifier).open();
    unawaited(ref.read(aiChatPanelProvider.notifier).sendMessage(text));
    navigator.pop();
  }

  void _openCollection(String route) => Navigator.of(context).pop(route);

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    final animation = widget.animation;
    // Keeps recent searches loaded while search is open, whichever view shows.
    ref.watch(recentSearchesProvider.notifier);
    final hasQuery =
        !_aiMode &&
        ref.watch(homeSearchQueryProvider.select((q) => q.trim().isNotEmpty));
    final animate = !MediaQuery.disableAnimationsOf(context);
    final typed = _controller.text.trim().isNotEmpty;

    Widget arrive(double order, Widget child) => HomeSearchArrive(
      animation: animation,
      order: order,
      distance: 14,
      child: child,
    );

    final field = Container(
      height: 52,
      decoration: ShapeDecoration(
        color: palette.canvas,
        shape: StadiumBorder(side: BorderSide(color: palette.hairline)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 18),
          AnimatedSwitcher(
            duration: HomeMotion.medium,
            switchInCurve: HomeMotion.settle,
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: Icon(
              _aiMode ? Icons.auto_awesome_rounded : Icons.search_rounded,
              key: ValueKey(_aiMode),
              color: palette.accent,
              size: 21,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: _aiMode
                  ? TextInputAction.send
                  : TextInputAction.search,
              onChanged: _onChanged,
              onSubmitted: _onSubmitted,
              cursorColor: palette.accent,
              style: HomeType.body(palette.ink),
              decoration: InputDecoration(
                hintText: context.tr(
                  _aiMode ? HomeL10n.aiModeHint : HomeL10n.searchPlaceholder,
                ),
                hintStyle: HomeType.body(palette.inkFaint),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          if (_aiMode && typed)
            IconButton(
              tooltip: context.tr(HomeL10n.aiModeAsk),
              onPressed: () => _askAi(_controller.text),
              icon: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.accent,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    size: 18,
                    color: palette.onAccent,
                  ),
                ),
              ),
            )
          else if (_controller.text.isNotEmpty)
            IconButton(
              tooltip: context.tr(RemainingL10n.clear),
              onPressed: _clear,
              icon: Icon(
                Icons.close_rounded,
                size: 20,
                color: palette.inkMuted,
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
    );

    Widget panel = DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.4 : 0.08),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.paddingOf(context).top + 8,
          16,
          16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            arrive(
              0,
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.tr(HomeL10n.searchPrefix),
                      style: HomeType.display(32, palette.ink),
                    ),
                  ),
                  _CloseButton(onTap: () => Navigator.of(context).pop()),
                ],
              ),
            ),
            const SizedBox(height: 14),
            arrive(1, field),
            const SizedBox(height: 12),
            arrive(
              2,
              HomeSearchModeSwitch(aiMode: _aiMode, onChanged: _setAiMode),
            ),
          ],
        ),
      ),
    );
    if (animate) {
      // The whole panel drops from above the screen edge.
      final drop = animation.drive(
        CurveTween(curve: const Interval(0, 0.7, curve: HomeMotion.settle)),
      );
      panel = AnimatedBuilder(
        animation: drop,
        builder: (context, child) => FractionalTranslation(
          translation: Offset(0, drop.value - 1),
          child: child,
        ),
        child: panel,
      );
    }

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: FadeTransition(
              opacity: animation.drive(
                CurveTween(
                  curve: const Interval(0, 0.45, curve: Curves.easeOut),
                ),
              ),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: ColoredBox(color: palette.canvas.withValues(alpha: 0.9)),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              panel,
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: AnimatedSwitcher(
                      duration: HomeMotion.medium,
                      switchInCurve: HomeMotion.settle,
                      child: _aiMode
                          ? HomeAiModeSuggestions(
                              key: const ValueKey('ai'),
                              animate: animate,
                              onAsk: _askAi,
                            )
                          : hasQuery
                          ? const KeyedSubtree(
                              key: ValueKey('results'),
                              child: HomeSearchResultsList(),
                            )
                          : HomeSearchBrowse(
                              key: const ValueKey('browse'),
                              animation: animation,
                              onOpenRoute: _openCollection,
                              onSearch: _searchFor,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return Tooltip(
      message: context.tr(HomeL10n.closeSearch),
      child: Material(
        color: palette.canvas,
        shape: CircleBorder(side: BorderSide(color: palette.hairline)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox.square(
            dimension: 40,
            child: Icon(Icons.close_rounded, size: 20, color: palette.ink),
          ),
        ),
      ),
    );
  }
}
