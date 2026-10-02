import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../application/home_search_provider.dart';
import '../home_content.dart';
import '../theme/home_tokens.dart';
import 'home_search_results_list.dart';

/// Opens the spotlight search over the home screen. Picking a collection
/// closes the overlay and navigates from the home [context].
Future<void> showHomeSearch(BuildContext context) async {
  final route = await showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: context.tr(HomeL10n.closeSearch),
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (context, _, _) => const _HomeSearchOverlay(),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: HomeMotion.settle,
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(opacity: curved, child: child);
    },
  );
  if (route != null && context.mounted) context.openRoute(route);
}

class _HomeSearchOverlay extends ConsumerStatefulWidget {
  const _HomeSearchOverlay();

  @override
  ConsumerState<_HomeSearchOverlay> createState() => _HomeSearchOverlayState();
}

class _HomeSearchOverlayState extends ConsumerState<_HomeSearchOverlay> {
  static const _debounce = Duration(milliseconds: 280);
  final _controller = TextEditingController();
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {});
    _timer?.cancel();
    _timer = Timer(_debounce, () {
      if (mounted) ref.read(homeSearchQueryProvider.notifier).state = value;
    });
  }

  void _clear() {
    _timer?.cancel();
    _controller.clear();
    ref.read(homeSearchQueryProvider.notifier).state = '';
    setState(() {});
  }

  void _openCollection(String route) => Navigator.of(context).pop(route);

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    final hasQuery = ref.watch(
      homeSearchQueryProvider.select((q) => q.trim().isNotEmpty),
    );
    final animate = !MediaQuery.disableAnimationsOf(context);

    Widget field = Container(
      height: 56,
      decoration: ShapeDecoration(
        color: palette.surface,
        shape: StadiumBorder(side: BorderSide(color: palette.hairline)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 18),
          Icon(Icons.search_rounded, color: palette.accent, size: 21),
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _onChanged,
              onSubmitted: (value) {
                _timer?.cancel();
                ref.read(homeSearchQueryProvider.notifier).state = value;
              },
              cursorColor: palette.accent,
              style: HomeType.body(palette.ink),
              decoration: InputDecoration(
                hintText: context.tr(HomeL10n.searchPlaceholder),
                hintStyle: HomeType.body(palette.inkFaint),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          if (_controller.text.isNotEmpty)
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
    if (animate) {
      field = field
          .animate()
          .moveY(begin: -18, end: 0, duration: 500.ms, curve: HomeMotion.settle)
          .fadeIn(duration: 300.ms);
    }

    return BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
      child: Material(
        color: palette.canvas.withValues(alpha: 0.9),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                child: Row(
                  children: [
                    Expanded(child: field),
                    IconButton(
                      tooltip: context.tr(HomeL10n.closeSearch),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded, color: palette.ink),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: hasQuery
                    ? const HomeSearchResultsList()
                    : _BrowseSuggestions(
                        animate: animate,
                        onOpen: _openCollection,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrowseSuggestions extends StatelessWidget {
  const _BrowseSuggestions({required this.animate, required this.onOpen});

  final bool animate;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    const items = HomeContent.collections;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Text(
          context.tr(HomeL10n.collectionsEyebrow).toUpperCase(),
          style: HomeType.eyebrow(palette.inkMuted),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < items.length; i++)
          _maybeAnimate(
            InkWell(
              onTap: () => onOpen(items[i].route),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: palette.hairline, width: 0.8),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr(items[i].titleKey),
                        style: HomeType.display(26, palette.ink),
                      ),
                    ),
                    Icon(
                      Icons.arrow_outward_rounded,
                      size: 18,
                      color: palette.accent,
                    ),
                  ],
                ),
              ),
            ),
            i,
          ),
      ],
    );
  }

  Widget _maybeAnimate(Widget child, int i) {
    if (!animate) return child;
    return child
        .animate(delay: (80 + i * 50).ms)
        .fadeIn(duration: 400.ms)
        .moveX(begin: 16, end: 0, duration: 600.ms, curve: HomeMotion.settle);
  }
}
