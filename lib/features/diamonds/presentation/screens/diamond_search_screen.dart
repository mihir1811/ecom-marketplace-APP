import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/global_search_bar.dart';
import '../../../../core/widgets/melee_background_shell.dart';
import '../../application/diamond_search_provider.dart';
import '../../domain/models/diamond_catalog_type.dart';
import '../../domain/models/diamond_filter_state.dart';
import '../widgets/search_bottom_bar.dart';
import '../widgets/diamond_shape_carousel.dart';
import '../widgets/filter_category_basic.dart';
import '../widgets/filter_category_preferences.dart';
import '../widgets/filter_category_measurements.dart';
import '../widgets/filter_category_advanced.dart';

enum Section { basic, preferences, measurements, advanced }

class DiamondSearchScreen extends ConsumerStatefulWidget {
  const DiamondSearchScreen({
    super.key,
    this.catalog = DiamondCatalogType.natural,
    this.title = 'DIAMOND FINDER',
    this.resultsRoute = AppRouteNames.diamondResults,
  });

  final DiamondCatalogType catalog;
  final String title;
  final String resultsRoute;

  @override
  ConsumerState<DiamondSearchScreen> createState() => _DiamondSearchScreenState();
}

class _DiamondSearchScreenState extends ConsumerState<DiamondSearchScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  Section _activeSection = Section.basic;
  bool _expandAdvanced = false;

  final GlobalKey _basicKey = GlobalKey();
  final GlobalKey _prefKey = GlobalKey();
  final GlobalKey _measKey = GlobalKey();
  final GlobalKey _advancedKey = GlobalKey();
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
    _companyController.dispose();
    _locationController.dispose();
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
    final filterState = ref.read(diamondSearchProvider);
    final useMeleeFilters = _usesMeleeFilters(filterState);

    final sections = <(GlobalKey, Section)>[
      (_basicKey, Section.basic),
      (_prefKey, Section.preferences),
      (_measKey, Section.measurements),
      if (!useMeleeFilters) (_advancedKey, Section.advanced),
    ];

    final navBottom = _getNavBottom();
    Section? found;
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

    final active = found ?? Section.basic;
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

  bool _usesMeleeFilters(DiamondFilterState state) {
    if (widget.catalog == DiamondCatalogType.labGrown) {
      return state.labCategory == 'Lab Melee';
    }
    return state.labNatural.usesMeleeFilters;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filterState = ref.watch(diamondSearchProvider);
    final useMeleeFilters = _usesMeleeFilters(filterState);

    if (useMeleeFilters && _activeSection == Section.advanced) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _activeSection = Section.basic);
      });
    }

    return MeleeBackgroundShell(
      isMelee: useMeleeFilters,
      isDark: isDark,
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
            widget.title,
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
                        _buildStickyNav(isDark, useMeleeFilters),
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
                                const DiamondShapeCarousel(),
                                const SizedBox(height: AppSpacing.s24),
                                _buildSection(
                                  key: _basicKey,
                                  title: 'Basic',
                                  child: FilterCategoryBasic(
                                    sectionTitle: widget.catalog.label,
                                    showOriginToggle: widget.catalog ==
                                        DiamondCatalogType.natural,
                                    isLabCatalog: widget.catalog ==
                                        DiamondCatalogType.labGrown,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.s32),
                                _buildSection(
                                  key: _prefKey,
                                  title: 'Preferences',
                                  child: FilterCategoryPreferences(
                                    companyController: _companyController,
                                    locationController: _locationController,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.s32),
                                _buildSection(
                                  key: _measKey,
                                  title: 'Measurements',
                                  child: const FilterCategoryMeasurements(),
                                ),
                                if (!useMeleeFilters) ...[
                                  const SizedBox(height: AppSpacing.s32),
                                  _buildSection(
                                    key: _advancedKey,
                                    title: 'Advanced',
                                    child: FilterCategoryAdvanced(
                                      expandAdvanced: _expandAdvanced,
                                    ),
                                  ),
                                ],
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
                      child: SearchBottomBar(
                        resultsRoute: widget.resultsRoute,
                        onClear: () {
                          _companyController.clear();
                          _locationController.clear();
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

  Widget _buildStickyNav(bool isDark, bool useMeleeFilters) {
    final sections = [
      (Section.basic, 'Basic', Icons.diamond_outlined),
      (Section.preferences, 'PREF', Icons.tune),
      (Section.measurements, 'MEAS', Icons.straighten),
      if (!useMeleeFilters) (Section.advanced, 'ADV', Icons.add),
    ];

    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(
        end: AppColors.surfaceBg(isDark: isDark, melee: useMeleeFilters),
      ),
      duration: AppColors.meleeBgDuration,
      curve: Curves.easeInOutCubic,
      builder: (context, color, child) {
        return Container(
          key: _navKey,
          height: _navHeight,
          decoration: BoxDecoration(
            color: color,
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.slateBorder : AppColors.warmBorder,
              ),
            ),
          ),
          child: child,
        );
      },
      child: Row(
        children: sections.map((entry) {
          final section = entry.$1;
          final label = entry.$2;
          final icon = entry.$3;
          final isSelected = _activeSection == section;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeSection = section;
                  if (section == Section.advanced) {
                    _expandAdvanced = true;
                  }
                });
                final key = section == Section.basic
                    ? _basicKey
                    : section == Section.preferences
                        ? _prefKey
                        : section == Section.measurements
                            ? _measKey
                            : _advancedKey;
                _scrollToSection(key);
                if (section == Section.advanced) {
                  Future.delayed(const Duration(milliseconds: 350), () {
                    setState(() => _expandAdvanced = false);
                  });
                }
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
