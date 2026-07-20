import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/gemstone_search_provider.dart';
import '../../domain/models/gemstone_filter_state.dart';
import 'gemstone_showcase_card.dart';

/// Featured gemstone types shown in the top carousel.
/// Names match files in `public/images/gemstones/`.
const List<String> kFeaturedGemstones = [
  'Lapis Lazuli',
  'Moonstone',
  'Ruby',
  'Sapphire',
  'Emerald',
  'Tanzanite',
  'Amethyst',
  'Aquamarine',
  'Opal',
  'Tourmaline',
  'Garnet',
  'Peridot',
  'Topaz',
  'Citrine',
  'Pearl',
];

/// Gap between the two cards shown on each carousel page.
const double _kPairGap = 16.0;

/// Auto-playing carousel of featured gemstone types with navigation buttons,
/// progress indicator, and pause/play control. Mirrors the diamond shape carousel.
class GemstoneShowcaseCarousel extends ConsumerStatefulWidget {
  const GemstoneShowcaseCarousel({super.key});

  @override
  ConsumerState<GemstoneShowcaseCarousel> createState() =>
      _GemstoneShowcaseCarouselState();
}

class _GemstoneShowcaseCarouselState
    extends ConsumerState<GemstoneShowcaseCarousel> with WidgetsBindingObserver {
  late final PageController _pageController;
  Timer? _autoScrollTimer;
  double _scrollProgress = 0.0;

  static int get _pairCount => (kFeaturedGemstones.length / 2).ceil();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Start mid-range so the user can scroll either direction infinitely.
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
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted || !_pageController.hasClients) return;
      final page = _pageController.page ?? 0;
      final nextPage = page.round() + 1;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedTypes = ref.watch(
      gemstoneSearchProvider.select((s) => s.selectedGemstoneTypes),
    );
    final notifier = ref.read(gemstoneSearchProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Explore Gemstone\nTypes',
                  style: AppTypography.display.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          SizedBox(
            height: 180,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const horizontalPad = AppSpacing.s8;
                final available =
                    constraints.maxWidth - horizontalPad * 2 - _kPairGap;
                final cardWidth = available / 2;

                return PageView.builder(
                  controller: _pageController,
                  // No itemCount → infinite scroll (same pattern as diamond).
                  itemBuilder: (context, pageIndex) {
                    final pairIndex = pageIndex % _pairCount;
                    final leftIndex =
                        (pairIndex * 2) % kFeaturedGemstones.length;
                    final rightIndex =
                        (leftIndex + 1) % kFeaturedGemstones.length;

                    Widget cardAt(int index) {
                      final name = kFeaturedGemstones[index];
                      final isSelected = selectedTypes.contains(name) &&
                          GemstoneFilterState.allGemstoneTypes.contains(name);
                      return GemstoneShowcaseCard(
                        name: name,
                        isSelected: isSelected,
                        onTap: () => notifier.toggleGemstoneType(name),
                      );
                    }

                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: horizontalPad),
                      child: Row(
                        children: [
                          SizedBox(
                            width: cardWidth,
                            child: cardAt(leftIndex),
                          ),
                          const SizedBox(width: _kPairGap),
                          SizedBox(
                            width: cardWidth,
                            child: cardAt(rightIndex),
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
                color: isDark ? AppColors.slateBorder : AppColors.warmBorder,
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
