import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/global_search_bar.dart';
import '../../../../core/widgets/melee_background_shell.dart';
import '../widgets/gemstone_showcase_carousel.dart';
import '../widgets/gemstone_filter_category_basic.dart';
import '../widgets/gemstone_filter_category_measurements.dart';
import '../widgets/gemstone_filter_category_preferences.dart';
import '../widgets/gemstone_search_bottom_bar.dart';
import '../../application/gemstone_list_provider.dart';

enum GemstoneSection { basic, preferences, measurements }

/// Gemstone search and filter screen. Mirrors the diamond search screen:
/// fixed top search bar, sticky category navigation, scrollable filter
/// sections, and a sticky bottom action bar.
class GemstoneSearchScreen extends ConsumerStatefulWidget {
  const GemstoneSearchScreen({super.key});

  @override
  ConsumerState<GemstoneSearchScreen> createState() =>
      _GemstoneSearchScreenState();
}

class _GemstoneSearchScreenState extends ConsumerState<GemstoneSearchScreen> {
  final ScrollController _scrollController = ScrollController();
  GemstoneSection _activeSection = GemstoneSection.basic;

  final GlobalKey _basicKey = GlobalKey();
  final GlobalKey _prefKey = GlobalKey();
  final GlobalKey _measKey = GlobalKey();
  final GlobalKey _navKey = GlobalKey();

  static const double _navHeight = 52.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  double _getNavBottom() {
    final navCtx = _navKey.currentContext;
    if (navCtx == null) return _navHeight;
    final navBox = navCtx.findRenderObject() as RenderBox?;
    if (navBox == null) return _navHeight;
    return navBox.localToGlobal(Offset(0, navBox.size.height)).dy;
  }

  void _onScroll() {
    final sections = [
      (_basicKey, GemstoneSection.basic),
      (_prefKey, GemstoneSection.preferences),
      (_measKey, GemstoneSection.measurements),
    ];

    final navBottom = _getNavBottom();
    GemstoneSection? found;
    for (final entry in sections) {
      final ctx = entry.$1.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final pos = box.localToGlobal(Offset.zero);
      if (pos.dy <= navBottom + 4) {
        found = entry.$2;
      } else {
        break;
      }
    }

    final active = found ?? GemstoneSection.basic;
    if (active != _activeSection) {
      setState(() => _activeSection = active);
    }
  }

  void _scrollToSection(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final pos = box.localToGlobal(Offset.zero);
    final navBottom = _getNavBottom();
    final target = _scrollController.offset + pos.dy - navBottom;
    _scrollController.animateTo(
      target.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MeleeBackgroundShell(
      isMelee: false,
      isDark: isDark,
      family: MeleeBgFamily.gemstone,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'GEMSTONE FINDER',
            style: AppTypography.title.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            GlobalSearchBar(isDark: isDark),
            Expanded(
              child: SafeArea(
                top: false,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        _buildStickyNav(isDark),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            padding: const EdgeInsets.only(
                              left: AppSpacing.s16,
                              right: AppSpacing.s16,
                              bottom: 120.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const GemstoneShowcaseCarousel(),
                                const SizedBox(height: AppSpacing.s24),
                                _buildSearchCardHeader(isDark),
                                const SizedBox(height: AppSpacing.s24),
                                _buildSection(
                                  key: _basicKey,
                                  title: 'Basic',
                                  child: const GemstoneFilterCategoryBasic(),
                                ),
                                const SizedBox(height: AppSpacing.s32),
                                _buildSection(
                                  key: _prefKey,
                                  title: 'Preferences',
                                  child: const GemstoneFilterCategoryPreferences(),
                                ),
                                const SizedBox(height: AppSpacing.s32),
                                _buildSection(
                                  key: _measKey,
                                  title: 'Measurements',
                                  child:
                                      const GemstoneFilterCategoryMeasurements(),
                                ),
                                const SizedBox(height: AppSpacing.s32),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: GemstoneSearchBottomBar(
                        onSearch: () {
                          ref.invalidate(gemstoneListProvider);
                          context.push(AppRouteNames.gemstoneResults);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchCardHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gemstone Search',
          style: AppTypography.headline.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          'Refine by type, shape, origin, and certification.',
          style: AppTypography.body.copyWith(
            fontSize: 14,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required GlobalKey key,
    required String title,
    required Widget child,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.headline.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        child,
      ],
    );
  }

  Widget _buildStickyNav(bool isDark) {
    final sections = [
      (GemstoneSection.basic, 'Basic', Icons.diamond_outlined),
      (GemstoneSection.preferences, 'PREF', Icons.tune),
      (GemstoneSection.measurements, 'MEAS', Icons.straighten),
    ];

    return Container(
      key: _navKey,
      height: _navHeight,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.slateBorder : AppColors.warmBorder,
          ),
        ),
      ),
      child: Row(
        children: sections.map((entry) {
          final section = entry.$1;
          final label = entry.$2;
          final icon = entry.$3;
          final isSelected = _activeSection == section;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _activeSection = section);
                final key = switch (section) {
                  GemstoneSection.basic => _basicKey,
                  GemstoneSection.preferences => _prefKey,
                  GemstoneSection.measurements => _measKey,
                };
                _scrollToSection(key);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? AppColors.bronze : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: isSelected
                          ? AppColors.bronze
                          : (isDark ? Colors.white38 : Colors.black38),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                        color: isSelected
                            ? AppColors.bronze
                            : (isDark ? Colors.white60 : Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
