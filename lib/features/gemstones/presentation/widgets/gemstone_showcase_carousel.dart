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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(viewportFraction: 0.46);
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
    final maxScroll = _pageController.position.maxScrollExtent;
    final currentScroll = _pageController.position.pixels;
    if (mounted) {
      setState(() {
        _scrollProgress =
            maxScroll > 0 ? (currentScroll / maxScroll).clamp(0.0, 1.0) : 0.0;
      });
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted || !_pageController.hasClients) return;
      final page = _pageController.page ?? 0;
      final nextPage = (page.round() + 1) % kFeaturedGemstones.length;
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
            child: PageView.builder(
              controller: _pageController,
              itemCount: kFeaturedGemstones.length,
              itemBuilder: (context, index) {
                final name = kFeaturedGemstones[index];
                final isSelected = selectedTypes.contains(name) &&
                    GemstoneFilterState.allGemstoneTypes.contains(name);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: GemstoneShowcaseCard(
                    name: name,
                    isSelected: isSelected,
                    onTap: () => notifier.toggleGemstoneType(name),
                  ),
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
