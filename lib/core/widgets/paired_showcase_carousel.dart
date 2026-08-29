import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Infinite paired-card carousel with auto-scroll and a progress scrubber.
/// Used by diamond shapes and gemstone types — same layout/animation.
class PairedShowcaseCarousel extends StatefulWidget {
  const PairedShowcaseCarousel({
    required this.title,
    required this.itemCount,
    required this.itemBuilder,
    this.height = 180,
    this.pairGap = 16,
    this.autoScrollInterval = const Duration(seconds: 3),
    super.key,
  });

  final String title;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double height;
  final double pairGap;
  final Duration autoScrollInterval;

  @override
  State<PairedShowcaseCarousel> createState() => _PairedShowcaseCarouselState();
}

class _PairedShowcaseCarouselState extends State<PairedShowcaseCarousel>
    with WidgetsBindingObserver {
  late final PageController _pageController;
  Timer? _autoScrollTimer;
  double _scrollProgress = 0.0;

  int get _pairCount => (widget.itemCount / 2).ceil();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(initialPage: _pairCount * 100);
    _pageController.addListener(_onPageScroll);
    _startAutoScroll();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _autoScrollTimer?.cancel();
    } else if (state == AppLifecycleState.resumed && mounted) {
      _startAutoScroll();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoScrollTimer?.cancel();
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageScroll() {
    if (!_pageController.hasClients) return;
    final page = _pageController.page ?? 0;
    if (mounted) {
      setState(() {
        _scrollProgress = (_pairCount > 0)
            ? ((page % _pairCount) / _pairCount).clamp(0.0, 1.0)
            : 0.0;
      });
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(widget.autoScrollInterval, (_) {
      if (!mounted || !_pageController.hasClients) return;
      final page = _pageController.page ?? 0;
      _pageController.animateToPage(
        page.round() + 1,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: AppTypography.display.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.1,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          SizedBox(
            height: widget.height,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const horizontalPad = AppSpacing.s8;
                final available =
                    constraints.maxWidth - horizontalPad * 2 - widget.pairGap;
                final cardWidth = available / 2;

                return PageView.builder(
                  controller: _pageController,
                  itemBuilder: (context, pageIndex) {
                    final pairIndex = pageIndex % _pairCount;
                    final leftIndex = (pairIndex * 2) % widget.itemCount;
                    final rightIndex = (leftIndex + 1) % widget.itemCount;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: horizontalPad,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: cardWidth,
                            child: widget.itemBuilder(context, leftIndex),
                          ),
                          SizedBox(width: widget.pairGap),
                          SizedBox(
                            width: cardWidth,
                            child: widget.itemBuilder(context, rightIndex),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Center(
            child: Container(
              width: 140,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border(context),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: _scrollProgress * (140 - 24),
                    child: Container(
                      width: 24,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.bronze,
                        borderRadius: BorderRadius.circular(2),
                      ),
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
