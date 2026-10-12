import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'luxe_listing.dart';

/// Marks a listing card so the product sheet can find it on screen: where
/// to grow out of when a product is opened, and where to settle back into
/// when it is closed (which may be another card than the one tapped).
class ProductCardAnchor extends StatefulWidget {
  const ProductCardAnchor({
    required this.index,
    required this.child,
    super.key,
  });

  /// Position of the card in its list.
  final int index;
  final Widget child;

  @override
  State<ProductCardAnchor> createState() => _ProductCardAnchorState();
}

class _ProductCardAnchorState extends State<ProductCardAnchor> {
  final _boundary = GlobalKey();

  @override
  void initState() {
    super.initState();
    ProductCardRegistry._anchors.add(this);
  }

  @override
  void dispose() {
    ProductCardRegistry._anchors.remove(this);
    super.dispose();
  }

  RenderBox? get _box {
    final object = _boundary.currentContext?.findRenderObject();
    return object is RenderBox && object.attached && object.hasSize
        ? object
        : null;
  }

  @override
  Widget build(BuildContext context) =>
      RepaintBoundary(key: _boundary, child: widget.child);
}

/// A card found on screen.
class ProductCardHandle {
  const ProductCardHandle._(this._state, this.rect);

  final _ProductCardAnchorState _state;

  /// Global rectangle of the card.
  final Rect rect;

  int get index => _state.widget.index;

  /// The list this card scrolls in.
  ScrollableState? get scrollable => Scrollable.maybeOf(_state.context);

  /// Boundary whose pixels are the card, for a snapshot.
  RenderRepaintBoundary? get boundary {
    final box = _state._box;
    return box is RenderRepaintBoundary ? box : null;
  }
}

/// Lookup of the [ProductCardAnchor]s currently mounted.
abstract final class ProductCardRegistry {
  static final Set<_ProductCardAnchorState> _anchors = {};
  static int _generation = 0;

  static ProductCardHandle? _handle(_ProductCardAnchorState state) {
    final box = state._box;
    if (box == null) return null;
    return ProductCardHandle._(
      state,
      box.localToGlobal(Offset.zero) & box.size,
    );
  }

  /// The smallest card containing the global [point].
  static ProductCardHandle? at(Offset point) {
    ProductCardHandle? best;
    for (final anchor in _anchors) {
      final handle = _handle(anchor);
      if (handle == null || !handle.rect.contains(point)) continue;
      if (best == null ||
          handle.rect.width * handle.rect.height <
              best.rect.width * best.rect.height) {
        best = handle;
      }
    }
    return best;
  }

  /// The card at [index] of [scrollable]'s list, when it is built.
  static ProductCardHandle? find(int index, ScrollableState? scrollable) {
    if (scrollable == null) return null;
    for (final anchor in _anchors) {
      if (anchor.widget.index != index) continue;
      if (Scrollable.maybeOf(anchor.context) != scrollable) continue;
      final handle = _handle(anchor);
      if (handle != null) return handle;
    }
    return null;
  }

  /// Scrolls the list so the card at [index] sits comfortably in view.
  ///
  /// Cards the list has not built yet are approached by their estimated
  /// distance, then centred exactly once they exist. A newer call replaces
  /// an older one.
  static Future<void> reveal(int index, ScrollableState? scrollable) async {
    if (scrollable == null || !scrollable.mounted) return;
    final run = ++_generation;
    final viewport = scrollable.context.findRenderObject();
    if (viewport is! RenderBox || !viewport.hasSize) return;

    for (var attempt = 0; attempt < 6; attempt++) {
      if (run != _generation || !scrollable.mounted) return;
      final view = viewport.localToGlobal(Offset.zero) & viewport.size;
      final exact = find(index, scrollable);
      if (exact != null) {
        final comfortable = view.deflate(72);
        final r = exact.rect;
        if (r.top >= comfortable.top && r.bottom <= comfortable.bottom) return;
        await Scrollable.ensureVisible(
          exact._state.context,
          alignment: 0.5,
          duration: const Duration(milliseconds: 460),
          curve: Curves.easeInOutCubic,
        );
        return;
      }

      // Not built yet: head towards it by the nearest built card.
      ProductCardHandle? near;
      for (final anchor in _anchors) {
        if (Scrollable.maybeOf(anchor.context) != scrollable) continue;
        final handle = _handle(anchor);
        if (handle == null) continue;
        if (near == null ||
            (handle.index - index).abs() < (near.index - index).abs()) {
          near = handle;
        }
      }
      if (near == null) return;
      var perRow = 0;
      for (final anchor in _anchors) {
        if (Scrollable.maybeOf(anchor.context) != scrollable) continue;
        final handle = _handle(anchor);
        if (handle != null && (handle.rect.top - near.rect.top).abs() < 2) {
          perRow++;
        }
      }
      final rows = (index - near.index) / perRow.clamp(1, 6);
      final stride = near.rect.height + LuxeListingMetrics.gap;
      final position = scrollable.position;
      final target = (position.pixels + rows * stride).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      if ((target - position.pixels).abs() < 1) return;
      await position.animateTo(
        target,
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeInOutCubic,
      );
      await WidgetsBinding.instance.endOfFrame;
    }
  }
}
