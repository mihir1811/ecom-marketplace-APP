import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../home_feed_data.dart';
import 'home_diamond_pointer_field.dart';

/// Auto-advancing editorial banner carousel (Farfetch-style hero).
class HomeBannerCarousel extends StatefulWidget {
  const HomeBannerCarousel({
    required this.items,
    required this.onTap,
    super.key,
  });

  final List<HomeBannerItem> items;
  final ValueChanged<HomeBannerItem> onTap;

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel>
    with WidgetsBindingObserver {
  late final PageController _controller;
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = PageController();
  }

  bool? _dark;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (_dark == dark) return;
    _dark = dark;
    if (dark) {
      _timer?.cancel();
      return;
    }
    _start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed &&
        mounted &&
        Theme.of(context).brightness != Brightness.dark) {
      _start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    if (widget.items.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_index + 1) % widget.items.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = (MediaQuery.sizeOf(context).height * 0.48).clamp(
      320.0,
      480.0,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDark && widget.items.isNotEmpty) {
      final item = widget.items.first;
      return Column(
        children: [
          SizedBox(
            height: height,
            width: double.infinity,
            child: _BannerSlide(
              item: item,
              diamondField: true,
            ),
          ),
          // Carousel page dots — commented out in dark mode, not deleted.
          // const SizedBox(height: AppSpacing.s16),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   children: List.generate(widget.items.length, (i) {
          //     final active = i == _index;
          //     return AnimatedContainer(
          //       duration: const Duration(milliseconds: 200),
          //       margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
          //       width: active ? 22 : 6,
          //       height: 6,
          //       decoration: BoxDecoration(
          //         color: active ? AppColors.bronze : AppColors.border(context),
          //         borderRadius: BorderRadius.circular(AppSpacing.circular),
          //       ),
          //     );
          //   }),
          // ),
        ],
      );
    }

    return Column(
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.items.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final item = widget.items[i];
              return _BannerSlide(
                item: item,
                onTap: () => widget.onTap(item),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.items.length, (i) {
            final active = i == _index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
              width: active ? 22 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.bronze
                    : AppColors.border(context),
                borderRadius: BorderRadius.circular(AppSpacing.circular),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _BannerSlide extends StatelessWidget {
  const _BannerSlide({
    required this.item,
    this.onTap,
    this.diamondField = false,
  });

  final HomeBannerItem item;
  final VoidCallback? onTap;
  final bool diamondField;

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      fit: StackFit.expand,
      children: [
        if (diamondField)
          const Positioned.fill(child: HomeDiamondPointerField())
        else
          AppNetworkImage(url: item.imageUrl, memCacheWidth: 1600),
        // Dark mode swaps the hero photo for the diamond field.
        // AppNetworkImage(url: item.imageUrl, memCacheWidth: 1600),
        IgnorePointer(
          ignoring: diamondField,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: diamondField
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x00000000),
                        Color(0x00000000),
                        Color(0x99000000),
                      ],
                      stops: [0.0, 0.55, 1.0],
                    )
                  : const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x33111827),
                        Color(0x99111827),
                        Color(0xE6111827),
                      ],
                      stops: [0.0, 0.4, 1.0],
                    ),
            ),
          ),
        ),
        IgnorePointer(
          ignoring: diamondField,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s24,
              AppSpacing.s32,
              AppSpacing.s24,
              AppSpacing.s32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Text(
                  'GemWorld',
                  style: AppTypography.label.copyWith(
                    color: AppColors.warmWhite.withValues(alpha: 0.85),
                    letterSpacing: 2.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
                Text(
                  item.titleKey,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.display.copyWith(
                    color: AppColors.warmWhite,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  item.subtitleKey,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    color: AppColors.warmWhite.withValues(alpha: 0.9),
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.s20),
                Text(
                  item.ctaKey.toUpperCase(),
                  style: AppTypography.label.copyWith(
                    color: AppColors.warmWhite,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.warmWhite.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (diamondField) return content;

    return GestureDetector(
      onTap: onTap,
      child: content,
    );
  }
}
