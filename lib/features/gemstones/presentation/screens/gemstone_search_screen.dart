import 'package:flutter/material.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/global_search_bar.dart';
import '../../../../core/widgets/melee_background_shell.dart';
import '../../../../core/widgets/paired_showcase_carousel.dart';
import '../../../../core/widgets/search_action_bottom_bar.dart';
import '../../../../core/widgets/showcase_select_card.dart';
import '../../../../core/widgets/filters/catalog_measurement_filters.dart';
import '../../../../core/widgets/filters/catalog_preferences_filters.dart';
import '../../../../core/widgets/filters/catalog_search_add_field.dart';
import '../widgets/gemstone_filter_category_basic.dart';
import '../../../diamonds/presentation/widgets/filter_origin_dropdown.dart';
import '../../application/gemstone_list_provider.dart';
import '../../application/gemstone_search_provider.dart';
import '../../domain/gemstone_assets.dart';
import '../../domain/models/gemstone_filter_state.dart';

/// Featured gemstone types shown in the top carousel.
const List<String> _kFeaturedGemstones = [
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
    final isMelee = ref.watch(
      gemstoneSearchProvider.select((s) => s.lotType == 'Melee'),
    );

    return MeleeBackgroundShell(
      isMelee: isMelee,
      family: MeleeBgFamily.gemstone,
      child: AppScaffold(
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
            const GlobalSearchBar(),
            Expanded(
              child: SafeArea(
                top: false,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        _buildStickyNav(),
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
                                _buildShowcaseCarousel(),
                                const SizedBox(height: AppSpacing.s24),
                                _buildSearchCardHeader(),
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
                                  child: _buildPreferenceFilters(),
                                ),
                                const SizedBox(height: AppSpacing.s32),
                                _buildSection(
                                  key: _measKey,
                                  title: 'Measurements',
                                  child: _buildMeasurementFilters(),
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
                      child: SearchActionBottomBar(
                        primaryLabel: 'SEARCH GEMSTONES',
                        onPrimary: () {
                          ref.invalidate(gemstoneListProvider);
                          context.push(AppRouteNames.gemstoneResults);
                        },
                        clearLabel: 'CLEAR ALL',
                        onClear: () =>
                            ref.read(gemstoneSearchProvider.notifier).reset(),
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

  Widget _buildShowcaseCarousel() {
    final selectedTypes = ref.watch(
      gemstoneSearchProvider.select((s) => s.selectedGemstoneTypes),
    );
    final notifier = ref.read(gemstoneSearchProvider.notifier);

    return PairedShowcaseCarousel(
      title: 'Explore Gemstone\nTypes',
      itemCount: _kFeaturedGemstones.length,
      itemBuilder: (context, index) {
        final name = _kFeaturedGemstones[index];
        final isSelected = selectedTypes.contains(name) &&
            GemstoneFilterState.allGemstoneTypes.contains(name);
        final hue = gemstoneHue(name);
        final imagePath = gemstoneImagePath(name);
        final fallback = _GemstoneHueFallback(hue: hue);

        return ShowcaseSelectCard(
          name: name,
          isSelected: isSelected,
          onTap: () => notifier.toggleGemstoneType(name),
          media: imagePath == null
              ? fallback
              : Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => fallback,
                ),
        );
      },
    );
  }

  Widget _buildPreferenceFilters() {
    final state = ref.watch(gemstoneSearchProvider);
    final notifier = ref.read(gemstoneSearchProvider.notifier);

    return CatalogPreferencesFilters(
      locationField: CatalogSearchAddField(
        title: "Vendor's Location",
        infoText:
            'Search for gemstones located in a specific city, state, or region.',
        hintText: 'Search by location (City, State, Country)',
        onChanged: notifier.updateVendorLocation,
        onAdd: () {},
      ),
      originDropdown: FilterOriginDropdown(
        title: 'Origin Country',
        hint: 'Select origin country',
        infoText: "Filter by the gemstone's origin country.",
        pickerTitle: 'Select Origin Country',
        options: GemstoneFilterState.origins,
        flags: GemstoneFilterState.originFlags,
        showFlags: true,
        selectedOrigin: state.selectedOriginCountry,
        onSelected: notifier.updateOriginCountry,
      ),
      companyField: CatalogSearchAddField(
        title: 'Company Name',
        infoText:
            'Search for gemstones supplied by a specific company name.',
        hintText: 'Search by company name',
        onChanged: notifier.updateCompanyName,
        onAdd: () {},
      ),
    );
  }

  Widget _buildMeasurementFilters() {
    final state = ref.watch(gemstoneSearchProvider);
    final notifier = ref.read(gemstoneSearchProvider.notifier);

    return CatalogMeasurementFilters(
      lengthMin: state.minLength,
      lengthMax: state.maxLength,
      onLengthMinChanged: (v) =>
          notifier.updateLengthRange(v, state.maxLength),
      onLengthMaxChanged: (v) =>
          notifier.updateLengthRange(state.minLength, v),
      widthMin: state.minWidth,
      widthMax: state.maxWidth,
      onWidthMinChanged: (v) => notifier.updateWidthRange(v, state.maxWidth),
      onWidthMaxChanged: (v) => notifier.updateWidthRange(state.minWidth, v),
      heightMin: state.minHeight,
      heightMax: state.maxHeight,
      onHeightMinChanged: (v) =>
          notifier.updateHeightRange(v, state.maxHeight),
      onHeightMaxChanged: (v) =>
          notifier.updateHeightRange(state.minHeight, v),
      ratioMin: state.minRatio,
      ratioMax: state.maxRatio,
      onRatioMinChanged: (v) => notifier.updateRatioRange(v, state.maxRatio),
      onRatioMaxChanged: (v) => notifier.updateRatioRange(state.minRatio, v),
      dimensionLimits: (
        GemstoneFilterState.dimensionMin,
        GemstoneFilterState.dimensionMax,
      ),
      ratioLimits: (
        GemstoneFilterState.ratioMin,
        GemstoneFilterState.ratioMax,
      ),
    );
  }

  Widget _buildSearchCardHeader() {
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
            color: AppColors.textSecondaryLight,
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

  Widget _buildStickyNav() {
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
            color: AppColors.warmBorder,
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
                          : Colors.black38,
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
                            : Colors.black54,
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

class _GemstoneHueFallback extends StatelessWidget {
  const _GemstoneHueFallback({required this.hue});

  final Color hue;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.4, -0.4),
          colors: [
            Color.lerp(hue, Colors.white, 0.55)!,
            hue,
            Color.lerp(hue, Colors.black, 0.25)!,
          ],
          stops: const [0.0, 0.65, 1.0],
        ),
      ),
      child: Icon(
        Icons.diamond_outlined,
        size: 30,
        color: Colors.white.withValues(alpha: 0.55),
      ),
    );
  }
}
