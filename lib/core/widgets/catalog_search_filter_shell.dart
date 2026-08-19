import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// One sticky-nav section in a catalog search/filter screen.
class CatalogSearchNavSection<T> {
  const CatalogSearchNavSection({
    required this.id,
    required this.label,
    required this.icon,
    required this.key,
  });

  final T id;
  final String label;
  final IconData icon;
  final GlobalKey key;
}

/// Sticky section nav that highlights based on scroll position.
class CatalogSearchSectionNav<T> extends StatelessWidget {
  const CatalogSearchSectionNav({
    required this.navKey,
    required this.sections,
    required this.activeId,
    required this.onSectionTap,
    this.height = 52,
    super.key,
  });

  final GlobalKey navKey;
  final List<CatalogSearchNavSection<T>> sections;
  final T activeId;
  final ValueChanged<CatalogSearchNavSection<T>> onSectionTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: navKey,
      height: height,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(color: AppColors.border(context)),
        ),
      ),
      child: Row(
        children: [
          for (final section in sections)
            Expanded(
              child: GestureDetector(
                onTap: () => onSectionTap(section),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: activeId == section.id
                            ? AppColors.bronze
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        section.icon,
                        size: 16,
                        color: activeId == section.id
                            ? AppColors.bronze
                            : AppColors.textMuted(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        section.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                          color: activeId == section.id
                              ? AppColors.bronze
                              : AppColors.textMuted(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Titled filter section with a stable GlobalKey for scroll anchoring.
class CatalogSearchSection extends StatelessWidget {
  const CatalogSearchSection({
    required this.sectionKey,
    required this.title,
    required this.child,
    super.key,
  });

  final GlobalKey sectionKey;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: sectionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.headline.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

/// Shared scroll + sticky-nav helpers for diamond/gemstone search screens.
mixin CatalogSearchScrollMixin<T extends StatefulWidget> on State<T> {
  ScrollController get catalogScrollController;
  GlobalKey get catalogNavKey;
  double get catalogNavHeight => 52;

  /// True after a tab tap until the user scrolls by hand.
  /// Prevents short trailing sections (MEAS/ADV) from snapping the tab back.
  bool _catalogSpyLocked = false;
  bool _catalogProgrammaticScroll = false;

  bool get catalogSpyLocked => _catalogSpyLocked;

  double catalogNavBottom() {
    final navCtx = catalogNavKey.currentContext;
    if (navCtx == null) return catalogNavHeight;
    final navBox = navCtx.findRenderObject() as RenderBox?;
    if (navBox == null) return catalogNavHeight;
    return navBox.localToGlobal(Offset(0, navBox.size.height)).dy;
  }

  S? catalogActiveSectionFromScroll<S>(
    List<(GlobalKey, S)> sections,
  ) {
    final navBottom = catalogNavBottom();
    S? found;
    S? lastVisible;
    for (final entry in sections) {
      final ctx = entry.$1.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final top = box.localToGlobal(Offset.zero).dy;
      final bottom = top + box.size.height;
      if (bottom > navBottom) lastVisible = entry.$2;
      if (top <= navBottom + 4) {
        found = entry.$2;
      } else {
        break;
      }
    }
    if (catalogScrollController.hasClients) {
      final position = catalogScrollController.position;
      if (position.maxScrollExtent > 0 &&
          position.pixels >= position.maxScrollExtent - 2 &&
          lastVisible != null) {
        return lastVisible;
      }
    }
    return found;
  }

  /// Unlocks scroll-spy when the user drags or wheels the list.
  bool catalogHandleScrollNotification(ScrollNotification notification) {
    final userDrag = (notification is ScrollStartNotification &&
            notification.dragDetails != null) ||
        (notification is ScrollUpdateNotification &&
            notification.dragDetails != null);
    if (userDrag) {
      _catalogProgrammaticScroll = false;
      _catalogSpyLocked = false;
      return false;
    }
    if (_catalogSpyLocked &&
        !_catalogProgrammaticScroll &&
        notification is ScrollUpdateNotification &&
        notification.scrollDelta != null &&
        notification.scrollDelta != 0) {
      _catalogSpyLocked = false;
    }
    return false;
  }

  void catalogScrollToSection(GlobalKey key) {
    _catalogSpyLocked = true;
    final ctx = key.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    if (!catalogScrollController.hasClients) return;
    final pos = box.localToGlobal(Offset.zero);
    final navBottom = catalogNavBottom();
    final target = catalogScrollController.offset + pos.dy - navBottom;
    _catalogProgrammaticScroll = true;
    catalogScrollController
        .animateTo(
          target.clamp(0.0, catalogScrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        )
        .whenComplete(() {
          _catalogProgrammaticScroll = false;
        });
  }
}
