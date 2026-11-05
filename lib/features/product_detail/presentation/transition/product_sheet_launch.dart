import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/widgets/luxe/product_card_anchor.dart';
import '../../domain/models/product_detail.dart';

/// Where a product was tapped on screen: the card the detail sheet grows out
/// of (and shrinks back into), plus a snapshot of that card.
class ProductSheetOrigin {
  ProductSheetOrigin({
    required this.rect,
    this.radius = 20,
    this.index,
    this.scrollable,
  });

  final Rect rect;
  final double radius;

  /// Position in its list and the list itself, when the tapped card is a
  /// [ProductCardAnchor]; lets the sheet find (and scroll to) any card of
  /// that list later.
  final int? index;
  final ScrollableState? scrollable;

  /// Pixels of the tapped card, filled in a frame or two after the tap.
  final ValueNotifier<ui.Image?> snapshot = ValueNotifier<ui.Image?>(null);

  bool _disposed = false;

  bool get isDisposed => _disposed;

  /// Hands over the grabbed pixels; ignored once the route is gone.
  void _offer(ui.Image image) {
    if (_disposed) {
      image.dispose();
    } else {
      snapshot.value = image;
    }
  }

  void dispose() {
    _disposed = true;
    snapshot.value?.dispose();
    snapshot.dispose();
  }
}

/// Live source behind a [ProductSwitchSet]: the listing's current rows and
/// a way to ask it for the next page (a no-op when nothing is left).
class ProductListFeed<T> {
  const ProductListFeed({required this.items, required this.loadMore});

  final List<T> Function() items;
  final Future<void> Function() loadMore;
}

/// Products the sheet can switch between (the list the tap came from).
///
/// Details are adapted on demand and memoised, so handing over a thousand
/// listing rows costs nothing until the dock scrolls past them. With a
/// [ProductListFeed] the set grows as the listing loads more pages, and
/// asks for the next page once the user nears the end.
class ProductSwitchSet {
  ProductSwitchSet._(
    int length,
    this.initialIndex,
    this._resolve, [
    this._liveLength,
    this._loadMore,
  ]) : _length = ValueNotifier<int>(length);

  /// Pages left before the end at which the next page is requested.
  static const _prefetch = 5;

  /// [adapt] maps one catalog row to its detail view model; [initial] is
  /// the already-resolved detail of the tapped row.
  static ProductSwitchSet? of<T>(
    List<T>? items,
    T tapped,
    ProductDetail Function(T) adapt,
    ProductDetail initial, {
    ProductListFeed<T>? feed,
  }) {
    if (items == null || items.length < 2) return null;
    final index = items.indexOf(tapped);
    if (index < 0) return null;
    // The live rows, or the tapped snapshot if the listing has gone or
    // shrunk (a refresh) so indices already shown stay valid.
    List<T> rows() {
      if (feed == null) return items;
      try {
        final live = feed.items();
        return live.length >= items.length ? live : items;
      } catch (_) {
        return items;
      }
    }

    final set = ProductSwitchSet._(
      items.length,
      index,
      (i) => adapt(rows()[i]),
      feed == null ? null : () => rows().length,
      feed?.loadMore,
    );
    set._cache[index] = initial;
    return set;
  }

  final ValueNotifier<int> _length;
  final int Function()? _liveLength;
  final Future<void> Function()? _loadMore;
  bool _loading = false;

  final int initialIndex;
  final ProductDetail Function(int index) _resolve;
  final Map<int, ProductDetail> _cache = {};

  int get length => _length.value;

  /// Fires when more products join the set.
  ValueListenable<int> get lengthListenable => _length;

  ProductDetail detailAt(int index) =>
      _cache.putIfAbsent(index, () => _resolve(index));

  /// Call as the carousel passes [index] (while dragging or animating too);
  /// picks up rows the listing already has and requests the next page near
  /// the end.
  void reached(int index) {
    _sync();
    final load = _loadMore;
    if (load == null || _loading || index < length - _prefetch) return;
    _loading = true;
    Future<void>.sync(load).catchError((Object _) {}).whenComplete(() {
      _loading = false;
      _sync();
    });
  }

  void _sync() {
    final n = _liveLength?.call() ?? 0;
    if (n > _length.value) _length.value = n;
  }
}

/// Everything the detail route needs to know about how it was opened.
class ProductSheetLaunch {
  const ProductSheetLaunch({this.origin, this.switchSet});

  static const none = ProductSheetLaunch();

  final ProductSheetOrigin? origin;
  final ProductSwitchSet? switchSet;

  static ProductSheetLaunch? _pending;
  static DateTime _stagedAt = DateTime.fromMillisecondsSinceEpoch(0);
  static final Map<String, ProductSheetLaunch> _byPage = {};

  /// Called by the opener just before it pushes the route.
  static void stage(ProductSheetLaunch launch) {
    _pending = launch;
    _stagedAt = DateTime.now();
  }

  /// Called by the route builder. A staged launch belongs to the push that
  /// is being built; later router rebuilds of that page get the same one.
  static ProductSheetLaunch forPage(String pageKey) {
    final staged = _pending;
    _pending = null;
    if (staged != null &&
        DateTime.now().difference(_stagedAt) < const Duration(seconds: 2)) {
      if (_byPage.length > 24) _byPage.remove(_byPage.keys.first);
      return _byPage[pageKey] = staged;
    }
    final cached = _byPage[pageKey];
    if (cached != null && !(cached.origin?.isDisposed ?? false)) return cached;
    return none;
  }
}

/// Remembers the last pointer-down so a tap handler that only receives a
/// `BuildContext` can still tell which card was tapped.
abstract final class ProductTapTracker {
  static bool _attached = false;
  static Offset? _downAt;
  static int _viewId = 0;
  static DateTime _downTime = DateTime.fromMillisecondsSinceEpoch(0);

  /// Taps older than this are not what opened the page (deep links, chat).
  static const _fresh = Duration(milliseconds: 2500);

  static void attach() {
    if (_attached) return;
    _attached = true;
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
  }

  static void _onPointer(PointerEvent event) {
    if (event is! PointerDownEvent) return;
    _downAt = event.position;
    _viewId = event.viewId;
    _downTime = DateTime.now();
  }

  /// The card under the last tap, or a small anchor at the tap itself.
  /// Returns null when there was no recent tap.
  static ProductSheetOrigin? capture() {
    final at = _downAt;
    if (at == null || DateTime.now().difference(_downTime) > _fresh) {
      return null;
    }
    final binding = WidgetsBinding.instance;
    final view = binding.platformDispatcher.view(id: _viewId);
    if (view == null) return null;
    final ratio = view.devicePixelRatio.clamp(1.0, 2.0);

    // Listing cards announce themselves: exact rectangle and list.
    final card = ProductCardRegistry.at(at);
    if (card != null) {
      final origin = ProductSheetOrigin(
        rect: card.rect,
        index: card.index,
        scrollable: card.scrollable,
      );
      card.boundary
          ?.toImage(pixelRatio: ratio)
          .then<void>(origin._offer, onError: (Object _) {});
      return origin;
    }

    // Anywhere else: the smallest card-sized repaint boundary under the tap.
    final screen = view.physicalSize / view.devicePixelRatio;
    final result = HitTestResult();
    binding.hitTestInView(result, at, _viewId);

    RenderRepaintBoundary? best;
    Rect? bestRect;
    for (final entry in result.path) {
      final target = entry.target;
      if (target is! RenderRepaintBoundary ||
          !target.attached ||
          !target.hasSize) {
        continue;
      }
      final rect = target.localToGlobal(Offset.zero) & target.size;
      // A card: big enough to be one, never a whole viewport or row strip.
      if (rect.width < 96 ||
          rect.height < 96 ||
          rect.width > screen.width + 1 ||
          rect.height > screen.height * 0.6) {
        continue;
      }
      if (bestRect == null ||
          rect.width * rect.height < bestRect.width * bestRect.height) {
        best = target;
        bestRect = rect;
      }
    }

    if (best == null || bestRect == null) {
      return ProductSheetOrigin(
        rect: Rect.fromCenter(center: at, width: 140, height: 140),
        radius: 28,
      );
    }

    final origin = ProductSheetOrigin(rect: bestRect);
    // Boundaries only expose pixels once painted; a failed grab just means
    // the card is not cross-faded, the sheet still grows from its rect.
    best
        .toImage(pixelRatio: ratio)
        .then<void>(origin._offer, onError: (Object _) {});
    return origin;
  }
}
