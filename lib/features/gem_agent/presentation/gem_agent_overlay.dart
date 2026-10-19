import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/navigation/bottom_nav/app_bottom_nav_bar.dart';
import '../../../core/widgets/navigation/bottom_nav/app_bottom_nav_destinations.dart';
import '../application/gem_agent_controller.dart';
import 'widgets/gem_agent_flash.dart';
import 'widgets/gem_agent_sheet.dart';

/// App-wide Gem Agent layer: the command sheet (opened from the dock's
/// Agent slot) and the result flash above the dock. Self-contained — mounting or removing this
/// widget is the only app-level wiring.
class GemAgentOverlay extends ConsumerStatefulWidget {
  const GemAgentOverlay({super.key});

  @override
  ConsumerState<GemAgentOverlay> createState() => _GemAgentOverlayState();
}

class _GemAgentOverlayState extends ConsumerState<GemAgentOverlay> {
  // Supplies the Overlay that the sheet's text field needs; this layer
  // sits outside the router navigator.
  late final OverlayEntry _sheetEntry = OverlayEntry(
    builder: (_) => const _SheetLayer(),
  );

  @override
  void initState() {
    super.initState();
    appRouter.routerDelegate.addListener(_onRoute);
  }

  @override
  void dispose() {
    appRouter.routerDelegate.removeListener(_onRoute);
    super.dispose();
  }

  void _onRoute() {
    if (mounted) setState(() {});
  }

  String get _path {
    try {
      return appRouter.state.uri.path;
    } catch (_) {
      return appRouter.routerDelegate.currentConfiguration.uri.path;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = ref.watch(
      gemAgentControllerProvider.select((s) => s.isOpen),
    );
    // The flash lives where the dock does, so it never covers page CTAs.
    final flashAllowed = AppBottomNav.isVisibleOn(_path);
    if (!isOpen && !flashAllowed) return const SizedBox.shrink();

    final inset = MediaQuery.paddingOf(context).bottom;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (isOpen) Overlay(initialEntries: [_sheetEntry]),
        if (!isOpen)
          Positioned(
            left: 16,
            right: 16,
            bottom: AppBottomNavBar.clearance(inset) + 4,
            child: const Center(child: GemAgentFlash()),
          ),
      ],
    );
  }
}

class _SheetLayer extends ConsumerWidget {
  const _SheetLayer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(gemAgentControllerProvider.notifier);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final safe = MediaQuery.paddingOf(context).bottom;
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: controller.close,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.32)),
          ),
        ),
        AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: (keyboard > 0 ? keyboard : safe) + 12,
          ),
          child: const Align(
            alignment: Alignment.bottomCenter,
            child: GemAgentSheet(),
          ),
        ),
      ],
    );
  }
}
