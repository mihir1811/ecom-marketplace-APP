import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Decodes [imageProvider] at the smallest size that still fills a
/// [width] × [height] (physical pixels) box under [fit], keeping the image's
/// aspect ratio and never upscaling.
///
/// Unlike [ResizeImage] with a fixed width, the target is chosen from the
/// image's real dimensions at decode time, so a wide photo in a `cover` box is
/// never decoded narrower than it is drawn (which would blur it), and a
/// 4000 px photo in a 400 px tile is not held in memory at full size.
@immutable
class FitResizeImage extends ImageProvider<FitResizeImageKey> {
  const FitResizeImage(
    this.imageProvider, {
    required this.width,
    required this.height,
    required this.fit,
  });

  final ImageProvider<Object> imageProvider;
  final int width;
  final int height;
  final BoxFit fit;

  @override
  Future<FitResizeImageKey> obtainKey(ImageConfiguration configuration) {
    // Stay synchronous when the wrapped provider is, as ResizeImage does, so
    // images already in the cache show on the first frame.
    Completer<FitResizeImageKey>? completer;
    SynchronousFuture<FitResizeImageKey>? result;
    imageProvider.obtainKey(configuration).then((Object key) {
      final resized = FitResizeImageKey._(key, width, height, fit);
      if (completer == null) {
        result = SynchronousFuture<FitResizeImageKey>(resized);
      } else {
        completer.complete(resized);
      }
    });
    if (result != null) return result!;
    completer = Completer<FitResizeImageKey>();
    return completer.future;
  }

  @override
  ImageStreamCompleter loadImage(
    FitResizeImageKey key,
    ImageDecoderCallback decode,
  ) {
    Future<ui.Codec> decodeResized(
      ui.ImmutableBuffer buffer, {
      ui.TargetImageSizeCallback? getTargetSize,
    }) {
      return decode(buffer, getTargetSize: targetSize);
    }

    return imageProvider.loadImage(key._providerKey, decodeResized);
  }

  /// Decode size for an image of [iw] × [ih] pixels. Visible for tests.
  @visibleForTesting
  ui.TargetImageSize targetSize(int iw, int ih) {
    if (iw <= 0 || ih <= 0) return ui.TargetImageSize(width: iw, height: ih);
    final sx = width / iw;
    final sy = height / ih;
    final scale = switch (fit) {
      BoxFit.cover => math.max(sx, sy),
      BoxFit.contain || BoxFit.scaleDown => math.min(sx, sy),
      BoxFit.fitWidth => sx,
      BoxFit.fitHeight => sy,
      BoxFit.fill => math.max(sx, sy),
      BoxFit.none => 1.0,
    };
    if (scale >= 1) return ui.TargetImageSize(width: iw, height: ih);
    return ui.TargetImageSize(
      width: math.max(1, (iw * scale).ceil()),
      height: math.max(1, (ih * scale).ceil()),
    );
  }
}

@immutable
class FitResizeImageKey {
  const FitResizeImageKey._(
    this._providerKey,
    this.width,
    this.height,
    this.fit,
  );

  final Object _providerKey;
  final int width;
  final int height;
  final BoxFit fit;

  @override
  bool operator ==(Object other) =>
      other is FitResizeImageKey &&
      other._providerKey == _providerKey &&
      other.width == width &&
      other.height == height &&
      other.fit == fit;

  @override
  int get hashCode => Object.hash(_providerKey, width, height, fit);
}
