import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../haptics/app_haptics.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/luxe_tokens.dart';
import '../app_scaffold.dart';
import '../catalog_search_filter_shell.dart';
import 'luxe_button.dart';
import 'luxe_layout.dart';
import 'luxe_listing.dart';

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

  /// Collapsible section for [section] with its active-filter badge and a
  /// one-line summary ("Any", the picked names, or "3 selected").
  Widget finderSection(
    S section, {
    required String title,
    required IconData icon,
    required int count,
    required Widget child,
    bool initiallyExpanded = false,
    List<String> names = const [],
  }) {
    final summary = count == 0
        ? context.tr(DiamondFlowL10n.any)
        : names.isNotEmpty && names.length == count
        ? names.join(' · ')
        : context.tr(DiamondFlowL10n.selectedCount, {'count': count});
    return LuxeSection(
      key: finderSectionKey(section),
      title: title,
      icon: icon,
      summary: summary,
      activeCount: count,
      initiallyExpanded: initiallyExpanded,
      child: child,
    );
  }
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

/// Page frame shared by every luxe finder / filter screen: luxe top bar,
/// optional mode controls, pinned section index, eagerly built collapsible
/// sections and a sticky action bar.
///
/// Pair it with [LuxeFinderMixin] on the screen state.
class LuxeFinderScaffold<S> extends StatelessWidget {
  const LuxeFinderScaffold({
    required this.title,
    required this.sections,
    required this.active,
    required this.labelOf,
    required this.countOf,
    required this.pillKeyOf,
    required this.onJump,
    required this.navKey,
    required this.sectionBuilder,
    required this.scrollController,
    required this.scrollOffset,
    required this.onScrollNotification,
    required this.actionBar,
    super.key,
    this.controls,
    this.header,
    this.onBack,
    this.actions = const [],
  });

  final String title;
  final VoidCallback? onBack;
  final List<Widget> actions;

  /// Full-width content above the mode controls (e.g. paid banners). It
  /// brings its own spacing and may collapse to nothing.
  final Widget? header;

  /// Catalog mode switches shown above the section index.
  final Widget? controls;
  final List<S> sections;
  final S active;
  final String Function(S) labelOf;
  final int Function(S) countOf;
  final GlobalKey Function(S) pillKeyOf;
  final ValueChanged<S> onJump;
  final GlobalKey navKey;
  final Widget Function(S) sectionBuilder;
  final ScrollController scrollController;
  final ValueListenable<double> scrollOffset;
  final NotificationListenerCallback<ScrollNotification> onScrollNotification;
  final Widget actionBar;

  @override
  Widget build(BuildContext context) {
    final bg = LuxePalette.of(context).canvas;
    return AppScaffold(
      backgroundColor: bg,
      appBar: LuxeTopBar(
        title: title,
        scrollOffset: scrollOffset,
        onBack: onBack,
        actions: actions,
      ),
      bottomNavigationBar: actionBar,
      body: ColoredBox(
        color: bg,
        child: NotificationListener<ScrollNotification>(
          onNotification: onScrollNotification,
          child: CustomScrollView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              if (header != null) SliverToBoxAdapter(child: header),
              if (controls != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
                    child: controls,
                  ),
                ),
              LuxePinnedBar(
                background: bg,
                child: LuxeFinderIndex<S>(
                  key: navKey,
                  sections: sections,
                  active: active,
                  labelOf: labelOf,
                  countOf: countOf,
                  pillKeyOf: pillKeyOf,
                  onTap: onJump,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                // Built eagerly so every section key resolves and any pill
                // can jump straight to its section; expanded state also
                // survives scrolling.
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [for (final s in sections) sectionBuilder(s)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
