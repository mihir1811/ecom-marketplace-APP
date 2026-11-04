import 'package:flutter/material.dart';

import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_network_image.dart';

/// Review photo thumbnails; a tap opens them full screen.
class JewelryReviewPhotoStrip extends StatelessWidget {
  const JewelryReviewPhotoStrip({required this.urls, this.size = 64, super.key});

  final List<String> urls;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();
    final p = LuxePalette.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < urls.length; i++)
          Semantics(
            button: true,
            image: true,
            child: GestureDetector(
              onTap: () => showJewelryPhotoViewer(context, urls, i),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox.square(
                  dimension: size,
                  child: AppNetworkImage(
                    url: urls[i],
                    memCacheWidth: (size * 3).round(),
                    error: ColoredBox(
                      color: p.surfaceRaised,
                      child: Icon(Icons.image_outlined, color: p.inkFaint),
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

/// Full-screen, swipeable, pinch-to-zoom photos.
Future<void> showJewelryPhotoViewer(
  BuildContext context,
  List<String> urls,
  int initial,
) => showDialog<void>(
  context: context,
  barrierColor: Colors.black,
  useSafeArea: false,
  builder: (_) => _PhotoViewer(urls: urls, initial: initial),
);

class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.urls, required this.initial});

  final List<String> urls;
  final int initial;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final _pages = PageController(initialPage: widget.initial);
  late int _index = widget.initial;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pages,
            itemCount: widget.urls.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => InteractiveViewer(
              maxScale: 4,
              child: Center(
                child: AppNetworkImage(
                  url: widget.urls[i],
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                  ),
                  const Spacer(),
                  if (widget.urls.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(
                        '${_index + 1} / ${widget.urls.length}',
                        style: LuxeType.label(Colors.white, size: 14),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
