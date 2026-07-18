import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/diamond_search_provider.dart';
import 'diamond_shape_card.dart';

const List<Map<String, String>> kAllShapes = [
  {'name': 'Round', 'image': 'public/images/round.png'},
  {'name': 'Cushion', 'image': 'public/images/Cushion.png'},
  {'name': 'Emerald', 'image': 'public/images/Emerald.png'},
  {'name': 'Pear', 'image': 'public/images/Pear.png'},
  {'name': 'Oval', 'image': 'public/images/Oval.png'},
  {'name': 'Princess', 'image': 'public/images/princess.png'},
  {'name': 'Marquise', 'image': 'public/images/Marquise.png'},
  {'name': 'Heart', 'image': 'public/images/Heart.png'},
  {'name': 'Radiant', 'image': 'public/images/Radiant.png'},
  {'name': 'Asscher', 'image': 'public/images/Asscher.png'},
  {'name': 'Trilliant', 'image': 'public/images/trilliant.png'},
  {'name': 'Baguette', 'image': 'public/images/baguatte.png'},
  {'name': 'Flanders', 'image': 'public/images/flanders.png'},
  {'name': 'Shield', 'image': 'public/images/Shield.png'},
  {'name': 'Polki', 'image': 'public/images/polki.png'},
  {'name': 'Rose Cut', 'image': 'public/images/rose-cut.png'},
  {'name': 'Tapered Baguette', 'image': 'public/images/tapered-baguette.png'},
  {'name': 'Trapezoid', 'image': 'public/images/trapezoid.png'},
  {'name': 'Half Moon', 'image': 'public/images/half-moon.png'},
  {'name': 'Bullet', 'image': 'public/images/bullet.png'},
  {'name': 'Lozenge', 'image': 'public/images/lozenge.png'},
];

class DiamondShapeCarousel extends ConsumerStatefulWidget {
  const DiamondShapeCarousel({super.key});

  @override
  ConsumerState<DiamondShapeCarousel> createState() => _DiamondShapeCarouselState();
}

class _DiamondShapeCarouselState extends ConsumerState<DiamondShapeCarousel>
    with WidgetsBindingObserver {
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
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
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
        _scrollProgress = maxScroll > 0 ? (currentScroll / maxScroll).clamp(0.0, 1.0) : 0.0;
      });
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted || !_pageController.hasClients) return;
      final page = _pageController.page ?? 0;
      final nextPage = (page.round() + 1) % kAllShapes.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diamondSearchProvider);
    final notifier = ref.read(diamondSearchProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Diamond\nShapes',
                style: AppTypography.display.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          SizedBox(
            height: 180,
            child: PageView.builder(
              controller: _pageController,
              itemCount: kAllShapes.length,
              itemBuilder: (context, index) {
                final item = kAllShapes[index];
                final name = item['name']!;
                final image = item['image']!;
                final isSelected = state.shapes.contains(name);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: DiamondShapeCard(
                    name: name,
                    shapeType: getShapeType(name),
                    imagePath: image,
                    isSelected: isSelected,
                    onTap: () => notifier.toggleShape(name),
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
