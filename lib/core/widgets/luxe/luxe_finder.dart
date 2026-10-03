import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../haptics/app_haptics.dart';
import '../../theme/luxe_tokens.dart';
import '../catalog_search_filter_shell.dart';
import 'luxe_button.dart';
import 'luxe_layout.dart';

/// Scroll-spy, pill index and jump-to-section behaviour shared by every
/// luxe finder (diamonds, gemstones, …).
///
/// Sections are expected to be built eagerly (a plain column, not a lazy
/// sliver list) so every section key resolves and any pill can jump
/// straight to its section.
mixin LuxeFinderMixin<W extends StatefulWidget, S>
    on CatalogSearchScrollMixin<W> {
  /// Page scroll offset, for the top bar's frosted backdrop.
  final finderOffset = ValueNotifier<double>(0);
  final _sectionKeys = <S, GlobalKey<LuxeSectionState>>{};
  final _pillKeys = <S, GlobalKey>{};
  S? _active;

  /// Sections currently shown, in screen order.
  List<S> get finderVisibleSections;

  S get finderActive => _active ?? finderVisibleSections.first;

  GlobalKey<LuxeSectionState> finderSectionKey(S section) =>
      _sectionKeys.putIfAbsent(section, GlobalKey<LuxeSectionState>.new);

  GlobalKey finderPillKey(S section) =>
      _pillKeys.putIfAbsent(section, GlobalKey.new);

  /// Wire to the finder's scroll controller.
  void finderOnScroll() {
    if (!catalogScrollController.hasClients) return;
    finderOffset.value = catalogScrollController.offset;
    if (catalogSpyLocked) return;
    final sections = finderVisibleSections;
    final active =
        catalogActiveSectionFromScroll([
          for (final s in sections) (finderSectionKey(s), s),
        ]) ??
        sections.first;
    _setActive(active);
  }

  void _setActive(S section) {
    if (section == finderActive) return;
    setState(() => _active = section);
    revealSectionPill(finderPillKey(section));
  }

  /// Opens [section] and scrolls it under the pinned index.
  void finderJumpTo(S section) {
    AppHaptics.selection();
    _setActive(section);
    finderSectionKey(section).currentState?.expand();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => catalogScrollToSection(finderSectionKey(section)),
    );
  }

  void disposeFinder() => finderOffset.dispose();
}

/// Horizontally scrolling index of finder sections. Pills carry a dot when
/// their section holds active filters.
class LuxeFinderIndex<S> extends StatelessWidget {
  const LuxeFinderIndex({
    required this.sections,
    required this.active,
    required this.labelOf,
    required this.countOf,
    required this.pillKeyOf,
    required this.onTap,
    super.key,
  });

  final List<S> sections;
  final S active;
  final String Function(S) labelOf;
  final int Function(S) countOf;
  final GlobalKey Function(S) pillKeyOf;
  final ValueChanged<S> onTap;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: sections.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, i) {
        final s = sections[i];
        final selected = s == active;
        final hasActive = countOf(s) > 0;
        return Semantics(
          button: true,
          selected: selected,
          label: labelOf(s),
          excludeSemantics: true,
          child: GestureDetector(
            key: pillKeyOf(s),
            onTap: () => onTap(s),
            child: AnimatedContainer(
              duration: LuxeMotion.medium,
              curve: LuxeMotion.settle,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: selected ? p.ink : p.surface,
                shape: StadiumBorder(
                  side: BorderSide(color: selected ? p.ink : p.hairline),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    labelOf(s),
                    style: LuxeType.label(
                      selected ? p.canvas : p.inkMuted,
                      size: 12.5,
                    ),
                  ),
                  if (hasActive) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.accent,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Editorial finder opening: serif headline, one-line guidance and the
/// catalog mode controls.
class LuxeFinderIntro extends StatelessWidget {
  const LuxeFinderIntro({
    required this.headline,
    required this.intro,
    super.key,
    this.controls,
  });

  final String headline;
  final String intro;
  final Widget? controls;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final animate = !MediaQuery.disableAnimationsOf(context);
    Widget title = Text(headline, style: LuxeType.display(36, p.ink));
    if (animate) {
      title = title
          .animate()
          .fadeIn(duration: 600.ms)
          .moveY(begin: 14, end: 0, duration: 800.ms, curve: LuxeMotion.settle);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          const SizedBox(height: 8),
          Text(intro, style: LuxeType.body(p.inkMuted, size: 14)),
          if (controls != null) ...[const SizedBox(height: 18), controls!],
        ],
      ),
    );
  }
}

/// Sticky footer: reset (when anything is set) and the primary search with
/// the active-filter count.
class LuxeFinderActionBar extends StatelessWidget {
  const LuxeFinderActionBar({
    required this.activeCount,
    required this.onReset,
    required this.onShow,
    required this.showLabel,
    required this.resetLabel,
    super.key,
  });

  final int activeCount;
  final VoidCallback? onReset;
  final VoidCallback onShow;
  final String showLabel;
  final String resetLabel;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.hairline, width: 0.6)),
      ),
      child: Row(
        children: [
          AnimatedSize(
            duration: LuxeMotion.medium,
            curve: LuxeMotion.settle,
            child: onReset == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: LuxeButton(
                      label: resetLabel,
                      onPressed: onReset,
                      variant: LuxeButtonVariant.secondary,
                    ),
                  ),
          ),
          Expanded(
            child: LuxeButton(
              label: showLabel,
              onPressed: onShow,
              expand: true,
              badge: activeCount,
              trailingIcon: Icons.arrow_forward_rounded,
            ),
          ),
        ],
      ),
    );
  }
}
