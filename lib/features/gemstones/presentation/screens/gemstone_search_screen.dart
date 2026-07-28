import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/catalog_search_filter_layout.dart';
import '../../../../core/widgets/catalog_search_filter_shell.dart';
import '../../../../core/widgets/paired_showcase_carousel.dart';
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

/// Gemstone search/filter screen using the shared catalog search shell.
class GemstoneSearchScreen extends ConsumerStatefulWidget {
  const GemstoneSearchScreen({super.key});

  @override
  ConsumerState<GemstoneSearchScreen> createState() =>
      _GemstoneSearchScreenState();
}

class _GemstoneSearchScreenState extends ConsumerState<GemstoneSearchScreen>
    with CatalogSearchScrollMixin {
  @override
  final ScrollController catalogScrollController = ScrollController();
  @override
  final GlobalKey catalogNavKey = GlobalKey();

  GemstoneSection _activeSection = GemstoneSection.basic;

  final GlobalKey _basicKey = GlobalKey();
  final GlobalKey _prefKey = GlobalKey();
  final GlobalKey _measKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    catalogScrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    catalogScrollController.removeListener(_onScroll);
    catalogScrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final active = catalogActiveSectionFromScroll([
          (_basicKey, GemstoneSection.basic),
          (_prefKey, GemstoneSection.preferences),
          (_measKey, GemstoneSection.measurements),
        ]) ??
        GemstoneSection.basic;
    if (active != _activeSection) {
      setState(() => _activeSection = active);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMelee = ref.watch(
      gemstoneSearchProvider.select((s) => s.lotType == 'Melee'),
    );

    final sections = <CatalogSearchNavSection<GemstoneSection>>[
      CatalogSearchNavSection(
        id: GemstoneSection.basic,
        label: 'Basic',
        icon: Icons.diamond_outlined,
        key: _basicKey,
      ),
      CatalogSearchNavSection(
        id: GemstoneSection.preferences,
        label: 'PREF',
        icon: Icons.tune,
        key: _prefKey,
      ),
      CatalogSearchNavSection(
        id: GemstoneSection.measurements,
        label: 'MEAS',
        icon: Icons.straighten,
        key: _measKey,
      ),
    ];

    return CatalogSearchFilterShell(
      title: 'GEMSTONE FINDER',
      isMelee: isMelee,
      meleeFamily: MeleeBgFamily.gemstone,
      stickyNav: CatalogSearchSectionNav<GemstoneSection>(
        navKey: catalogNavKey,
        sections: sections,
        activeId: _activeSection,
        onSectionTap: (section) {
          setState(() => _activeSection = section.id);
          catalogScrollToSection(section.key);
        },
      ),
      scrollController: catalogScrollController,
      primaryLabel: 'SEARCH GEMSTONES',
      onPrimary: () {
        ref.invalidate(gemstoneListProvider);
        context.push(AppRouteNames.gemstoneResults);
      },
      onClear: () => ref.read(gemstoneSearchProvider.notifier).reset(),
      bodyChildren: [
        _buildShowcaseCarousel(),
        const SizedBox(height: AppSpacing.s24),
        const _GemstoneSearchCardHeader(),
        const SizedBox(height: AppSpacing.s24),
        CatalogSearchSection(
          sectionKey: _basicKey,
          title: 'Basic',
          child: const GemstoneFilterCategoryBasic(),
        ),
        const SizedBox(height: AppSpacing.s32),
        CatalogSearchSection(
          sectionKey: _prefKey,
          title: 'Preferences',
          child: _buildPreferenceFilters(),
        ),
        const SizedBox(height: AppSpacing.s32),
        CatalogSearchSection(
          sectionKey: _measKey,
          title: 'Measurements',
          child: _buildMeasurementFilters(),
        ),
        const SizedBox(height: AppSpacing.s32),
      ],
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
}

class _GemstoneSearchCardHeader extends StatelessWidget {
  const _GemstoneSearchCardHeader();

  @override
  Widget build(BuildContext context) {
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
