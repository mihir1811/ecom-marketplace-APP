import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../diamond_viewer/presentation/widgets/view_in_360_button.dart';
import '../../../diamond_viewer/utils/viewer_url_resolver.dart';
import '../../../diamonds/presentation/widgets/diamond_svg_data.dart';
import '../../domain/models/product_detail.dart';
import '../screens/certificate_viewer_screen.dart';

/// Hero media frame. Identical framing for every segment — only the content
/// inside the frame changes, so the page never shifts between categories.
class ProductDetailMedia extends StatefulWidget {
  const ProductDetailMedia({required this.media, super.key});

  final ProductMedia media;

  @override
  State<ProductDetailMedia> createState() => _ProductDetailMediaState();
}

class _ProductDetailMediaState extends State<ProductDetailMedia> {
  int _index = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showcaseAssets = widget.media.showcaseAssets;
    final hasMultiple = showcaseAssets.length > 1;
    final videoUrl = ViewerUrlResolver.resolve(widget.media.videoUrl);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.warmWhite,
              borderRadius: BorderRadius.circular(AppSpacing.r24),
              border: Border.all(color: AppColors.warmBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (showcaseAssets.isEmpty)
                  _Fallback(media: widget.media)
                else if (!hasMultiple)
                  _ShowcaseFrame(
                    media: widget.media,
                    asset: showcaseAssets.first,
                  )
                else
                  PageView.builder(
                    controller: _pageController,
                    itemCount: showcaseAssets.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) => _ShowcaseFrame(
                      media: widget.media,
                      asset: showcaseAssets[i],
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (videoUrl != null) ...[
          const SizedBox(height: AppSpacing.s12),
          ViewIn360Button(
            viewerUrl: videoUrl,
            title: widget.media.videoLabel ?? '360° View',
          ),
        ],
        if (widget.media.hasCertificate) ...[
          const SizedBox(height: AppSpacing.s12),
          _ViewCertificateButton(
            url: widget.media.certificateUrl!,
            label: widget.media.certificateLabel ?? 'Certificate',
          ),
        ],
        if (hasMultiple) ...[
          const SizedBox(height: AppSpacing.s12),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: showcaseAssets.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.s8),
              itemBuilder: (context, i) => _Thumb(
                media: widget.media,
                asset: showcaseAssets[i],
                isActive: i == _index,
                onTap: () {
                  setState(() => _index = i);
                  _pageController.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < showcaseAssets.length; i++)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _index ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _index
                        ? AppColors.charcoal
                        : AppColors.warmBorder,
                    borderRadius: BorderRadius.circular(AppSpacing.circular),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ShowcaseFrame extends StatelessWidget {
  const _ShowcaseFrame({required this.media, required this.asset});

  final ProductMedia media;
  final ProductShowcaseAsset asset;

  @override
  Widget build(BuildContext context) {
    switch (asset.type) {
      case ProductShowcaseAssetType.image:
        final image = media.imageAt(asset.imageIndex ?? 0);
        if (image == null) return _Fallback(media: media);
        return _Frame(image: image, fit: media.fit);
      case ProductShowcaseAssetType.certificate:
        // Certificates open via the dedicated CTA, not the carousel.
        return _Fallback(media: media);
      case ProductShowcaseAssetType.video:
        return _VideoFrame(label: asset.label, media: media);
    }
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.image, required this.fit});

  final ProductImage image;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (!image.isAsset) {
      return AppNetworkImage(url: image.path, fit: fit);
    }
    return Padding(
      padding: EdgeInsets.all(fit == BoxFit.contain ? AppSpacing.s40 : 0),
      child: Image.asset(
        image.path,
        fit: fit,
        errorBuilder: (_, __, ___) => const ColoredBox(
          color: AppColors.sandSurface,
          child: Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              color: AppColors.bronzeLight,
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.media,
    required this.asset,
    required this.isActive,
    required this.onTap,
  });

  final ProductMedia media;
  final ProductShowcaseAsset asset;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isActive ? AppColors.charcoal : AppColors.warmBorder;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        decoration: BoxDecoration(
          color: AppColors.warmWhite,
          borderRadius: BorderRadius.circular(AppSpacing.r12),
          border: Border.all(color: borderColor, width: isActive ? 1.5 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            switch (asset.type) {
              ProductShowcaseAssetType.image => () {
                  final image = media.imageAt(asset.imageIndex ?? 0);
                  if (image == null) return _Fallback(media: media);
                  return _Frame(image: image, fit: BoxFit.cover);
                }(),
              ProductShowcaseAssetType.certificate => const ColoredBox(
                  color: AppColors.sandSurface,
                  child: Icon(
                    Icons.description_outlined,
                    size: 24,
                    color: AppColors.bronze,
                  ),
                ),
              ProductShowcaseAssetType.video => const ColoredBox(
                  color: AppColors.charcoal,
                  child: Icon(
                    Icons.play_circle_outline,
                    size: 24,
                    color: AppColors.warmWhite,
                  ),
                ),
            },
          ],
        ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.media});

  final ProductMedia media;

  @override
  Widget build(BuildContext context) {
    final shape = media.shapeKey?.trim();
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            media.fallbackTint.withValues(alpha: 0.16),
            AppColors.sandSurface,
          ],
        ),
      ),
      child: Center(
        child: shape != null && shape.isNotEmpty
            ? renderShapeSvg(
                shape,
                size: 96,
                color: media.fallbackTint,
              )
            : Icon(media.fallbackIcon, size: 72, color: media.fallbackTint),
      ),
    );
  }
}

class _VideoFrame extends StatelessWidget {
  const _VideoFrame({required this.label, required this.media});

  final String label;
  final ProductMedia media;

  @override
  Widget build(BuildContext context) {
    final videoUrl = ViewerUrlResolver.resolve(media.videoUrl);
    final preview = media.imageAt(0);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (preview != null)
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              AppColors.charcoal.withValues(alpha: 0.35),
              BlendMode.darken,
            ),
            child: _Frame(image: preview, fit: media.fit),
          )
        else
          _Fallback(media: media),
        Center(
          child: Icon(
            videoUrl != null
                ? Icons.threed_rotation
                : Icons.play_circle_fill_rounded,
            size: 72,
            color: AppColors.warmWhite,
          ),
        ),
        Positioned(
          left: AppSpacing.s12,
          bottom: AppSpacing.s12,
          child: _MediaBadge(
            icon: Icons.videocam_outlined,
            label: label,
          ),
        ),
        if (videoUrl != null)
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => ViewIn360Button.open(
                  context,
                  viewerUrl: videoUrl,
                  title: label,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MediaBadge extends StatelessWidget {
  const _MediaBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(AppSpacing.circular),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColors.warmWhite,
          ),
          const SizedBox(width: AppSpacing.s8),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.warmWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewCertificateButton extends StatelessWidget {
  const _ViewCertificateButton({
    required this.url,
    required this.label,
  });

  final String url;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warmWhite,
      borderRadius: BorderRadius.circular(AppSpacing.r16),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.r16),
        onTap: () => openCertificateViewer(
          url: url,
          title: label,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.r16),
            border: Border.all(color: AppColors.warmBorder),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.description_outlined,
                color: AppColors.charcoal,
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'View certificate',
                      style: AppTypography.label.copyWith(
                        color: AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.open_in_new,
                size: 16,
                color: AppColors.charcoal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
