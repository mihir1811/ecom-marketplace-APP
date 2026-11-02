import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/haptics/app_haptics.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/theme/luxe_tokens.dart';
import '../../../../../core/widgets/app_network_image.dart';
import '../../../../../core/widgets/catalog_missing_image.dart';
import '../../../../diamond_viewer/presentation/widgets/view_in_360_button.dart';
import '../../../../diamond_viewer/utils/viewer_url_resolver.dart';
import '../../../../diamonds/presentation/widgets/diamond_svg_data.dart';
import '../../../../recently_viewed/presentation/widgets/recently_viewed_badge.dart';
import '../../../domain/models/product_detail.dart';
import '../../screens/certificate_viewer_screen.dart';

/// Immersive product gallery: swipeable media on a soft stage, status,
/// page indicator, thumbnails, quick links to the 360° viewer and the
/// certificate, and tap-to-zoom fullscreen.
class LuxeDetailGallery extends StatefulWidget {
  const LuxeDetailGallery({
    required this.media,
    super.key,
    this.availabilityStatus,
    this.topInset = 0,
    this.aspectRatio = 1,
    this.thumbsFactor = 1,
    this.badgeTop = 14,
    this.clampEnds = false,
  });

  final ProductMedia media;
  final String? availabilityStatus;

  /// Space reserved at the top for the floating header.
  final double topInset;

  /// Width / height of the picture stage. The sheet uses a wider stage while
  /// it is a pop-up so the title and price stay in view.
  final double aspectRatio;

  /// 0…1 share of the thumbnail strip that is shown.
  final double thumbsFactor;

  /// Offset of the availability badge, clear of floating header controls.
  final double badgeTop;

  /// Reports over-swiping past the first / last picture as an
  /// [OverscrollNotification] on every platform, so a parent can carry the
  /// swipe on to the next product.
  final bool clampEnds;

  @override
  State<LuxeDetailGallery> createState() => _LuxeDetailGalleryState();
}

class _LuxeDetailGalleryState extends State<LuxeDetailGallery> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openZoom(int imageIndex) {
    final image = widget.media.imageAt(imageIndex);
    if (image == null) return;
    AppHaptics.light();
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).closeButtonTooltip,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, _, _) =>
          _ZoomView(image: image, media: widget.media),
      transitionBuilder: (context, a, _, child) => FadeTransition(
        opacity: a,
        child: ScaleTransition(
          scale: Tween(
            begin: 0.96,
            end: 1.0,
          ).animate(CurvedAnimation(parent: a, curve: LuxeMotion.settle)),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final assets = widget.media.showcaseAssets;
    final videoUrl = ViewerUrlResolver.resolve(widget.media.videoUrl);

    Widget frame(ProductShowcaseAsset asset) {
      switch (asset.type) {
        case ProductShowcaseAssetType.image:
          final image = widget.media.imageAt(asset.imageIndex ?? 0);
          if (image == null) return _Fallback(media: widget.media);
          return GestureDetector(
            onTap: () => _openZoom(asset.imageIndex ?? 0),
            child: _Picture(image: image, fit: widget.media.fit),
          );
        case ProductShowcaseAssetType.video:
          return _VideoFrame(media: widget.media, label: asset.label);
        case ProductShowcaseAssetType.certificate:
          return const SizedBox.shrink();
      }
    }

    final stage = Container(
      color: p.surfaceRaised,
      padding: EdgeInsets.only(top: widget.topInset),
      child: AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (assets.isEmpty)
              _Fallback(media: widget.media)
            else
              PageView.builder(
                controller: _controller,
                // One picture has nothing to swipe to; leaving the gesture
                // free lets parents use horizontal swipes.
                physics: assets.length < 2
                    ? const NeverScrollableScrollPhysics()
                    : widget.clampEnds
                    ? const PageScrollPhysics(parent: ClampingScrollPhysics())
                    : null,
                itemCount: assets.length,
                onPageChanged: (i) {
                  AppHaptics.selection();
                  setState(() => _index = i);
                },
                itemBuilder: (context, i) => AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    // Gentle depth: neighbouring frames recede while swiping.
                    final page =
                        _controller.hasClients &&
                            _controller.position.haveDimensions
                        ? _controller.page ?? 0
                        : 0.0;
                    final d = (page - i).abs().clamp(0.0, 1.0);
                    return Transform.scale(scale: 1 - d * 0.06, child: child);
                  },
                  child: frame(assets[i]),
                ),
              ),
            Positioned(
              left: 16,
              top: widget.badgeTop,
              child: AvailabilityStatusBadge(
                status: widget.availabilityStatus,
                dotOnly: false,
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Wraps rather than overflows on narrow pop-ups.
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: [
                        if (videoUrl != null)
                          _GlassPill(
                            icon: Icons.threed_rotation_rounded,
                            label: context.tr(DiamondFlowL10n.view360),
                            onTap: () => ViewIn360Button.open(
                              context,
                              viewerUrl: videoUrl,
                              title: widget.media.videoLabel ?? '360° View',
                            ),
                          ),
                        if (widget.media.hasCertificate)
                          _GlassPill(
                            icon: Icons.verified_outlined,
                            label: context.tr(DiamondFlowL10n.viewCertificate),
                            onTap: () => openCertificateViewer(
                              context,
                              url: widget.media.certificateUrl!,
                              title:
                                  widget.media.certificateLabel ??
                                  context.tr(CatalogL10n.certification),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (assets.length > 1)
                    _Dots(count: assets.length, index: _index),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        stage,
        if (assets.length > 1 && widget.thumbsFactor > 0.02)
          SizedBox(
            height: 78 * widget.thumbsFactor,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topCenter,
                minHeight: 78,
                maxHeight: 78,
                child: Opacity(
                  opacity: widget.thumbsFactor,
                  child: SizedBox(
                    height: 78,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
                      itemCount: assets.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (context, i) => _Thumb(
                        media: widget.media,
                        asset: assets[i],
                        active: i == _index,
                        onTap: () => _controller.animateToPage(
                          i,
                          duration: LuxeMotion.medium,
                          curve: LuxeMotion.settle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Picture extends StatelessWidget {
  const _Picture({required this.image, required this.fit});

  final ProductImage image;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (!image.isAsset) {
      return AppNetworkImage(url: image.path, fit: fit);
    }
    if (image.path == CatalogMissingImage.assetPath) {
      return const CatalogMissingImage(showLabel: false);
    }
    return Image.asset(
      image.path,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const CatalogMissingImage(showLabel: false),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.media});

  final ProductMedia media;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final shape = media.shapeKey;
    Widget art = shape != null
        ? renderShapeSvg(shape, size: 150, color: p.accent)
        : Icon(media.fallbackIcon, size: 96, color: p.accent);
    if (!MediaQuery.disableAnimationsOf(context)) {
      art = art
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 0.97, end: 1.03, duration: 2600.ms);
    }
    return Center(child: art);
  }
}

class _VideoFrame extends StatelessWidget {
  const _VideoFrame({required this.media, required this.label});

  final ProductMedia media;
  final String label;

  @override
  Widget build(BuildContext context) {
    final videoUrl = ViewerUrlResolver.resolve(media.videoUrl);
    final preview = media.imageAt(0);
    return GestureDetector(
      onTap: videoUrl == null
          ? null
          : () => ViewIn360Button.open(
              context,
              viewerUrl: videoUrl,
              title: label,
            ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (preview != null)
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.35),
                BlendMode.darken,
              ),
              child: _Picture(image: preview, fit: media.fit),
            )
          else
            _Fallback(media: media),
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.35),
                border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
              ),
              child: Icon(
                videoUrl != null
                    ? Icons.threed_rotation_rounded
                    : Icons.play_arrow_rounded,
                size: 34,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.media,
    required this.asset,
    required this.active,
    required this.onTap,
  });

  final ProductMedia media;
  final ProductShowcaseAsset asset;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final image = asset.type == ProductShowcaseAssetType.image
        ? media.imageAt(asset.imageIndex ?? 0)
        : null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: LuxeMotion.medium,
        width: 62,
        decoration: BoxDecoration(
          color: p.surfaceRaised,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? p.ink : p.hairline,
            width: active ? 1.4 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: image != null
            ? _Picture(image: image, fit: BoxFit.cover)
            : Icon(Icons.threed_rotation_rounded, color: p.inkMuted),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: ShapeDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: LuxeMotion.medium,
              curve: LuxeMotion.settle,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: i == index ? 14 : 5,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: i == index ? 1 : 0.5),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ],
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final fg = p.isDark ? Colors.white : p.ink;
    return Material(
      color: p.isDark
          ? Colors.black.withValues(alpha: 0.42)
          : Colors.white.withValues(alpha: 0.85),
      shape: StadiumBorder(
        side: BorderSide(
          color: p.isDark
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () {
          AppHaptics.selection();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuxeType.label(fg, size: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZoomView extends StatelessWidget {
  const _ZoomView({required this.image, required this.media});

  final ProductImage image;
  final ProductMedia media;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Center(
                child: _Picture(image: image, fit: BoxFit.contain),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
